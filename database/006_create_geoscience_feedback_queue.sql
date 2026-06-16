-- Geoscience 006 - Shared AI Hub feedback queue foundation
--
-- This keeps native APEX Feedback as the user capture surface and queues each
-- feedback record into a Geoscience-owned ledger using the shared AI Hub source
-- feedback payload shape. It deliberately stores no API key in source.

declare
  c_workspace_id constant number := 16120412504054324;
  c_schema       constant varchar2(30) := 'GEOSCIENCE';
  l_count        number;

  procedure add_feedback_queue_process(
    p_app_id       in number,
    p_component_id in number
  ) is
    l_process_count number;
  begin
    apex_application_install.set_workspace_id(c_workspace_id);
    apex_application_install.set_application_id(p_app_id);
    apex_application_install.set_schema(c_schema);

    wwv_flow_imp.import_begin(
      p_version_yyyy_mm_dd => '2024.11.30',
      p_release => '24.2.16',
      p_default_workspace_id => c_workspace_id,
      p_default_application_id => p_app_id,
      p_default_id_offset => 0,
      p_default_owner => c_schema
    );

    select count(*)
      into l_process_count
      from apex_application_page_proc
     where application_id = p_app_id
       and page_id = 10030
       and process_name = 'Queue AI Hub Feedback';

    if l_process_count = 0 then
      wwv_flow_imp_page.create_page_process(
        p_id => wwv_flow_imp.id(p_component_id),
        p_flow_id => p_app_id,
        p_flow_step_id => 10030,
        p_process_sequence => 20,
        p_process_point => 'AFTER_SUBMIT',
        p_process_type => 'NATIVE_PLSQL',
        p_process_name => 'Queue AI Hub Feedback',
        p_process_sql_clob => q'~
begin
  gs_ai_hub_feedback.queue_latest_feedback(
    p_application_id => :APP_ID,
    p_page_id        => :P10030_PAGE_ID,
    p_created_by     => :APP_USER,
    p_feedback       => :P10030_FEEDBACK
  );
exception
  when others then
    null;
end;
~',
        p_process_clob_language => 'PLSQL',
        p_error_display_location => 'INLINE_IN_NOTIFICATION',
        p_process_when => 'SUBMIT',
        p_process_when_type => 'REQUEST_EQUALS_CONDITION'
      );
    end if;

    wwv_flow_imp.import_end(p_auto_install_sup_obj => false);
  end add_feedback_queue_process;
begin
  select count(*)
    into l_count
    from user_tables
   where table_name = 'GS_AI_HUB_FEEDBACK_FORWARDS';

  if l_count = 0 then
    execute immediate q'[
      create table gs_ai_hub_feedback_forwards (
        feedback_id number not null,
        idempotency_key varchar2(255 char) not null,
        source_task_key varchar2(128 char) not null,
        ai_hub_feedback_key varchar2(128 char),
        ai_hub_task_key varchar2(128 char),
        forward_status varchar2(30 char) default 'PENDING' not null,
        payload_json clob,
        response_json clob,
        error_message varchar2(4000 char),
        source_application_id number,
        source_page_id number,
        source_created_by varchar2(255 char),
        source_created_on timestamp with time zone,
        created_at timestamp with time zone default systimestamp not null,
        updated_at timestamp with time zone default systimestamp not null,
        constraint gs_ai_hub_feedback_fwd_pk primary key (feedback_id),
        constraint gs_ai_hub_feedback_fwd_uk unique (idempotency_key),
        constraint gs_ai_hub_feedback_fwd_status_ck check (
          forward_status in ('PENDING', 'FORWARDED', 'FAILED', 'SKIPPED')
        ),
        constraint gs_ai_hub_feedback_payload_ck check (payload_json is json),
        constraint gs_ai_hub_feedback_response_ck check (response_json is json)
      )
    ]';
  end if;

  execute immediate q'[
    create or replace view gs_ai_hub_feedback_candidates_v as
    select f.feedback_id,
           f.feedback_number,
           f.application_id,
           f.application_name,
           case f.application_id
             when 104 then 'geoscience-001'
             when 105 then 'geoscience-003'
             else 'geoscience-002'
           end as source_task_key,
           f.page_id,
           f.page_name,
           f.feedback,
           f.feedback_rating,
           f.feedback_status,
           f.created_by,
           f.created_on,
           f.screen_width,
           f.screen_height,
           f.http_user_agent,
           f.logging_session_id
      from apex_team_feedback f
     where f.application_id in (104, 105)
       and f.feedback is not null
       and not exists (
             select 1
               from gs_ai_hub_feedback_forwards x
              where x.feedback_id = f.feedback_id
                and x.forward_status = 'FORWARDED'
           )
  ]';

  execute immediate q'[
    create or replace package gs_ai_hub_feedback authid definer as
      c_project_key constant varchar2(30) := 'geoscience';

      function idempotency_key(
        p_feedback_id in number
      ) return varchar2;

      function source_task_key(
        p_application_id in number
      ) return varchar2;

      function build_endpoint_payload(
        p_feedback_id in number
      ) return clob;

      procedure mark_pending(
        p_feedback_id in number
      );

      procedure mark_forwarded(
        p_feedback_id      in number,
        p_ai_hub_feedback_key in varchar2,
        p_ai_hub_task_key  in varchar2,
        p_response_json    in clob default null
      );

      procedure mark_failed(
        p_feedback_id   in number,
        p_error_message in varchar2
      );

      procedure queue_latest_feedback(
        p_application_id in number,
        p_page_id        in number,
        p_created_by     in varchar2,
        p_feedback       in varchar2
      );
    end gs_ai_hub_feedback;
  ]';

  execute immediate q'~
    create or replace package body gs_ai_hub_feedback as
      function normalized_text(
        p_text in varchar2
      ) return varchar2 is
      begin
        return trim(regexp_replace(replace(replace(nvl(p_text, ''), chr(13), ' '), chr(10), ' '), '\s+', ' '));
      end normalized_text;

      function short_text(
        p_text   in varchar2,
        p_length in pls_integer
      ) return varchar2 is
        l_text varchar2(4000) := normalized_text(p_text);
      begin
        if length(l_text) <= p_length then
          return l_text;
        end if;

        return substr(l_text, 1, greatest(1, p_length - 3)) || '...';
      end short_text;

      function idempotency_key(
        p_feedback_id in number
      ) return varchar2 is
      begin
        return 'geoscience-apex-feedback-' || to_char(p_feedback_id);
      end idempotency_key;

      function source_task_key(
        p_application_id in number
      ) return varchar2 is
      begin
        if p_application_id = 104 then
          return 'geoscience-001';
        elsif p_application_id = 105 then
          return 'geoscience-003';
        end if;

        return 'geoscience-002';
      end source_task_key;

      function build_endpoint_payload(
        p_feedback_id in number
      ) return clob is
        l_feedback_id        apex_team_feedback.feedback_id%type;
        l_application_id     apex_team_feedback.application_id%type;
        l_application_name   apex_team_feedback.application_name%type;
        l_page_id            apex_team_feedback.page_id%type;
        l_page_name          apex_team_feedback.page_name%type;
        l_feedback           apex_team_feedback.feedback%type;
        l_feedback_rating    apex_team_feedback.feedback_rating%type;
        l_screen_width       apex_team_feedback.screen_width%type;
        l_screen_height      apex_team_feedback.screen_height%type;
        l_http_user_agent    apex_team_feedback.http_user_agent%type;
        l_logging_session_id apex_team_feedback.logging_session_id%type;
        l_created_by         apex_team_feedback.created_by%type;
        l_created_on         apex_team_feedback.created_on%type;
        l_source_task_key    varchar2(128);
        l_payload            clob;
        l_details            clob;
      begin
        select feedback_id,
               application_id,
               application_name,
               page_id,
               page_name,
               feedback,
               feedback_rating,
               screen_width,
               screen_height,
               http_user_agent,
               logging_session_id,
               created_by,
               created_on
          into l_feedback_id,
               l_application_id,
               l_application_name,
               l_page_id,
               l_page_name,
               l_feedback,
               l_feedback_rating,
               l_screen_width,
               l_screen_height,
               l_http_user_agent,
               l_logging_session_id,
               l_created_by,
               l_created_on
          from apex_team_feedback
         where feedback_id = p_feedback_id
           and application_id in (104, 105);

        l_source_task_key := source_task_key(l_application_id);

        l_details :=
          'Source: Geoscience native APEX Feedback' || chr(10) ||
          'Source task: ' || l_source_task_key || chr(10) ||
          'Feedback ID: ' || l_feedback_id || chr(10) ||
          'Application: ' || l_application_name || ' (' || l_application_id || ')' || chr(10) ||
          'Page: ' || nvl(l_page_name, 'Unknown') || ' (' || l_page_id || ')' || chr(10) ||
          'Submitted by: ' || nvl(l_created_by, 'Unknown') || chr(10) ||
          'Submitted on: ' || to_char(l_created_on, 'YYYY-MM-DD"T"HH24:MI:SS TZH:TZM') || chr(10) ||
          'Rating: ' || nvl(to_char(l_feedback_rating), 'Not supplied') || chr(10) ||
          'Screen: ' || nvl(l_screen_width, '?') || ' x ' || nvl(l_screen_height, '?') || chr(10) ||
          'Logging session: ' || nvl(l_logging_session_id, 'Not captured') || chr(10) ||
          'User agent: ' || nvl(short_text(l_http_user_agent, 500), 'Not captured') || chr(10) ||
          chr(10) ||
          'Feedback:' || chr(10) ||
          l_feedback || chr(10) ||
          chr(10) ||
          'Forwarding note:' || chr(10) ||
          '- Queued locally in GEOSCIENCE until an approved AI Hub feedback endpoint credential is activated.' || chr(10) ||
          '- Replay with Idempotency-Key ' || idempotency_key(l_feedback_id) || '.';

        apex_json.initialize_clob_output;
        apex_json.open_object;
        apex_json.write('idempotencyKey', idempotency_key(l_feedback_id));
        apex_json.write('title', short_text(nvl(l_page_name, 'Geoscience') || ': ' || l_feedback, 160));
        apex_json.write('description', short_text('User feedback from ' || nvl(l_page_name, 'Geoscience') || ': ' || l_feedback, 360));
        apex_json.write('priority', 'MEDIUM');
        apex_json.write('feedbackType', 'APEX_FEEDBACK');
        apex_json.write('feedback', l_feedback);
        apex_json.write('details', l_details);
        apex_json.open_object('source');
        apex_json.write('system', 'Geoscience Demos');
        apex_json.write('projectKey', c_project_key);
        apex_json.write('taskKey', l_source_task_key);
        apex_json.write('application', nvl(l_application_name, 'Geoscience'));
        apex_json.write('applicationId', to_char(l_application_id));
        apex_json.write('pageId', to_char(l_page_id));
        apex_json.write('pageName', l_page_name);
        apex_json.write('recordType', 'APEX_TEAM_FEEDBACK');
        apex_json.write('recordId', to_char(l_feedback_id));
        apex_json.write('feedbackId', to_char(l_feedback_id));
        apex_json.write('feedbackNumber', to_char(l_feedback_id));
        apex_json.write('user', l_created_by);
        apex_json.write('submittedAt', to_char(l_created_on, 'YYYY-MM-DD"T"HH24:MI:SS TZH:TZM'));
        apex_json.close_object;
        apex_json.close_object;
        l_payload := apex_json.get_clob_output;
        apex_json.free_output;

        return l_payload;
      exception
        when no_data_found then
          apex_json.free_output;
          raise_application_error(-20000, 'Geoscience APEX feedback not found: ' || p_feedback_id);
        when others then
          apex_json.free_output;
          raise;
      end build_endpoint_payload;

      procedure upsert_status(
        p_feedback_id       in number,
        p_forward_status    in varchar2,
        p_ai_hub_feedback_key in varchar2,
        p_ai_hub_task_key   in varchar2,
        p_response_json     in clob,
        p_error_message     in varchar2
      ) is
        l_payload               clob;
        l_source_task_key       varchar2(128);
        l_source_application_id apex_team_feedback.application_id%type;
        l_source_page_id        apex_team_feedback.page_id%type;
        l_source_created_by     apex_team_feedback.created_by%type;
        l_source_created_on     apex_team_feedback.created_on%type;
      begin
        l_payload := build_endpoint_payload(p_feedback_id);

        select application_id,
               page_id,
               created_by,
               created_on
          into l_source_application_id,
               l_source_page_id,
               l_source_created_by,
               l_source_created_on
          from apex_team_feedback
         where feedback_id = p_feedback_id
           and application_id in (104, 105);

        l_source_task_key := source_task_key(l_source_application_id);

        update gs_ai_hub_feedback_forwards
           set source_task_key = l_source_task_key,
               ai_hub_feedback_key = p_ai_hub_feedback_key,
               ai_hub_task_key = p_ai_hub_task_key,
               forward_status = p_forward_status,
               payload_json = l_payload,
               response_json = p_response_json,
               error_message = p_error_message,
               source_application_id = l_source_application_id,
               source_page_id = l_source_page_id,
               source_created_by = l_source_created_by,
               source_created_on = l_source_created_on,
               updated_at = systimestamp
         where feedback_id = p_feedback_id;

        if sql%rowcount = 0 then
          insert into gs_ai_hub_feedback_forwards (
            feedback_id,
            idempotency_key,
            source_task_key,
            ai_hub_feedback_key,
            ai_hub_task_key,
            forward_status,
            payload_json,
            response_json,
            error_message,
            source_application_id,
            source_page_id,
            source_created_by,
            source_created_on
          ) values (
            p_feedback_id,
            idempotency_key(p_feedback_id),
            l_source_task_key,
            p_ai_hub_feedback_key,
            p_ai_hub_task_key,
            p_forward_status,
            l_payload,
            p_response_json,
            p_error_message,
            l_source_application_id,
            l_source_page_id,
            l_source_created_by,
            l_source_created_on
          );
        end if;
      end upsert_status;

      procedure mark_pending(
        p_feedback_id in number
      ) is
      begin
        upsert_status(
          p_feedback_id => p_feedback_id,
          p_forward_status => 'PENDING',
          p_ai_hub_feedback_key => null,
          p_ai_hub_task_key => null,
          p_response_json => null,
          p_error_message => null
        );
      end mark_pending;

      procedure mark_forwarded(
        p_feedback_id      in number,
        p_ai_hub_feedback_key in varchar2,
        p_ai_hub_task_key  in varchar2,
        p_response_json    in clob default null
      ) is
      begin
        upsert_status(
          p_feedback_id => p_feedback_id,
          p_forward_status => 'FORWARDED',
          p_ai_hub_feedback_key => p_ai_hub_feedback_key,
          p_ai_hub_task_key => p_ai_hub_task_key,
          p_response_json => p_response_json,
          p_error_message => null
        );
      end mark_forwarded;

      procedure mark_failed(
        p_feedback_id   in number,
        p_error_message in varchar2
      ) is
      begin
        upsert_status(
          p_feedback_id => p_feedback_id,
          p_forward_status => 'FAILED',
          p_ai_hub_feedback_key => null,
          p_ai_hub_task_key => null,
          p_response_json => null,
          p_error_message => substr(p_error_message, 1, 4000)
        );
      end mark_failed;

      procedure queue_latest_feedback(
        p_application_id in number,
        p_page_id        in number,
        p_created_by     in varchar2,
        p_feedback       in varchar2
      ) is
        l_feedback_id apex_team_feedback.feedback_id%type;
      begin
        select feedback_id
          into l_feedback_id
          from (
            select feedback_id
              from apex_team_feedback
             where application_id = p_application_id
               and page_id = p_page_id
               and created_on >= systimestamp - interval '10' minute
               and upper(nvl(created_by, '')) = upper(nvl(p_created_by, ''))
               and nvl(feedback, chr(0)) = nvl(p_feedback, chr(0))
             order by created_on desc
          )
         where rownum = 1;

        mark_pending(l_feedback_id);
      exception
        when no_data_found then
          null;
      end queue_latest_feedback;
    end gs_ai_hub_feedback;
  ~';

  execute immediate q'[
    comment on table gs_ai_hub_feedback_forwards is
      'Geoscience ledger for native APEX Feedback queued for the shared AI Hub source feedback API.'
  ]';

  add_feedback_queue_process(104, 1040600000);
  add_feedback_queue_process(105, 1050600000);

  commit;
end;
