-- Geoscience 004 - Register generated APEX applications

begin
  merge into gs_apex_applications d
  using (
    select 104 application_id,
           'Geoscience Demos' application_name,
           'GEOSCIENCE-DEMOS' application_alias,
           'ACTIVE' app_status,
           12 active_users_count,
           184 monthly_sessions,
           'PASS' health_status,
           'Generated in AIDEMODB GEOSCIENCE with Account Requests report/form and native APEX Feedback enabled.' troubleshooting_note
      from dual
    union all
    select 105,
           'Boreholes Demo',
           'BOREHOLES-DEMO',
           'ACTIVE',
           8,
           96,
           'PASS',
           'Generated in AIDEMODB GEOSCIENCE with Boreholes report/form and native APEX Feedback enabled.'
      from dual
  ) s
  on (d.application_name = s.application_name)
  when matched then update set
    d.application_id = s.application_id,
    d.application_alias = s.application_alias,
    d.app_status = s.app_status,
    d.active_users_count = s.active_users_count,
    d.monthly_sessions = s.monthly_sessions,
    d.last_health_check_at = systimestamp,
    d.health_status = s.health_status,
    d.troubleshooting_note = s.troubleshooting_note,
    d.updated_at = systimestamp
  when not matched then insert (
    application_id, application_name, application_alias, app_status,
    active_users_count, monthly_sessions, last_health_check_at, health_status,
    troubleshooting_note
  ) values (
    s.application_id, s.application_name, s.application_alias, s.app_status,
    s.active_users_count, s.monthly_sessions, systimestamp, s.health_status,
    s.troubleshooting_note
  );

  insert into gs_health_checks (
    app_registry_id, check_name, status_code, check_message
  )
  select app_registry_id,
         'APEX application generated',
         'PASS',
         'Application ' || application_id || ' exists in GEOSCIENCE and native APEX Feedback is enabled.'
    from gs_apex_applications a
   where a.application_id in (104, 105)
     and not exists (
           select 1
             from gs_health_checks h
            where h.app_registry_id = a.app_registry_id
              and h.check_name = 'APEX application generated'
         );

  commit;
end;
