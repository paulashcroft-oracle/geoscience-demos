CREATE OR REPLACE package gs_ai_hub_feedback authid definer as
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
/
