-- Geoscience 002 - Seed demo data

begin
merge into gs_environments d
using (
  select 'DEV' environment_code, 'Development' environment_name, 'Non-production' environment_tier from dual union all
  select 'TEST', 'Test', 'Non-production' from dual union all
  select 'PROD', 'Production', 'Production' from dual
) s
on (d.environment_code = s.environment_code)
when matched then update set
  d.environment_name = s.environment_name,
  d.environment_tier = s.environment_tier,
  d.status_code = 'ACTIVE',
  d.updated_at = systimestamp
when not matched then insert (environment_code, environment_name, environment_tier, status_code)
values (s.environment_code, s.environment_name, s.environment_tier, 'ACTIVE');

merge into gs_people d
using (
  select 'Maya Chen' display_name, 'maya.chen@geoscience.example' email_address, 'Exploration Systems' team_name, 'Spatial Analyst' role_name, 'Alex Morgan' manager_name from dual union all
  select 'Noah Williams', 'noah.williams@geoscience.example', 'Data Platforms', 'Database Engineer', 'Alex Morgan' from dual union all
  select 'Isla Brown', 'isla.brown@geoscience.example', 'Field Operations', 'Field Coordinator', 'Priya Singh' from dual union all
  select 'Ethan Taylor', 'ethan.taylor@geoscience.example', 'Security', 'Access Reviewer', 'Priya Singh' from dual
) s
on (d.email_address = s.email_address)
when matched then update set
  d.display_name = s.display_name,
  d.team_name = s.team_name,
  d.role_name = s.role_name,
  d.manager_name = s.manager_name,
  d.active_yn = 'Y',
  d.updated_at = systimestamp
when not matched then insert (display_name, email_address, team_name, role_name, manager_name)
values (s.display_name, s.email_address, s.team_name, s.role_name, s.manager_name);

merge into gs_account_requests d
using (
  select 'GAR-1001' request_number, 'maya.chen@geoscience.example' email_address, 'ONBOARD' request_type_code, 'alex.morgan@geoscience.example' requested_by, 'APPROVED' status_code, 'Access for new spatial analysis project across DEV and TEST.' business_reason, trunc(sysdate + 2) target_due_date from dual union all
  select 'GAR-1002', 'noah.williams@geoscience.example', 'CHANGE', 'alex.morgan@geoscience.example', 'IN_PROGRESS', 'Add PROD read-only access for application health check reporting.', trunc(sysdate + 5) from dual union all
  select 'GAR-1003', 'isla.brown@geoscience.example', 'ONBOARD', 'priya.singh@geoscience.example', 'SUBMITTED', 'Field operations user needs borehole refresh monitoring.', trunc(sysdate + 7) from dual union all
  select 'GAR-1004', 'ethan.taylor@geoscience.example', 'OFFBOARD', 'priya.singh@geoscience.example', 'IN_REVIEW', 'Deactivate temporary PROD review account after audit.', trunc(sysdate + 1) from dual
) s
on (d.request_number = s.request_number)
when matched then update set
  d.person_id = (select p.person_id from gs_people p where p.email_address = s.email_address),
  d.request_type_code = s.request_type_code,
  d.requested_by = s.requested_by,
  d.status_code = s.status_code,
  d.business_reason = s.business_reason,
  d.ai_summary = 'AI draft: ' || s.business_reason,
  d.target_due_date = s.target_due_date,
  d.updated_at = systimestamp
when not matched then insert (
  request_number, person_id, request_type_code, requested_by, status_code,
  business_reason, ai_summary, target_due_date
) values (
  s.request_number,
  (select p.person_id from gs_people p where p.email_address = s.email_address),
  s.request_type_code,
  s.requested_by,
  s.status_code,
  s.business_reason,
  'AI draft: ' || s.business_reason,
  s.target_due_date
);

merge into gs_env_accounts d
using (
  select 'maya.chen@geoscience.example' email_address, 'DEV' environment_code, 'MCHEN_DEV' username, 'ACTIVE' account_status, systimestamp - interval '5' day last_login_at from dual union all
  select 'maya.chen@geoscience.example', 'TEST', 'MCHEN_TEST', 'READY', null from dual union all
  select 'noah.williams@geoscience.example', 'PROD', 'NWILLIAMS_PROD', 'ACTIVE', systimestamp - interval '1' day from dual union all
  select 'isla.brown@geoscience.example', 'DEV', 'IBROWN_DEV', 'REQUESTED', null from dual union all
  select 'ethan.taylor@geoscience.example', 'PROD', 'ETAYLOR_PROD', 'LOCKED', systimestamp - interval '30' day from dual
) s
on (
  d.person_id = (select p.person_id from gs_people p where p.email_address = s.email_address)
  and d.environment_id = (select e.environment_id from gs_environments e where e.environment_code = s.environment_code)
)
when matched then update set
  d.username = s.username,
  d.account_status = s.account_status,
  d.last_login_at = s.last_login_at,
  d.updated_at = systimestamp
when not matched then insert (person_id, environment_id, username, account_status, last_login_at, provisioned_at)
values (
  (select p.person_id from gs_people p where p.email_address = s.email_address),
  (select e.environment_id from gs_environments e where e.environment_code = s.environment_code),
  s.username,
  s.account_status,
  s.last_login_at,
  case when s.account_status in ('ACTIVE','READY','LOCKED') then systimestamp - interval '10' day end
);

merge into gs_apex_applications d
using (
  select 1 sort_order, null application_id, 'Geoscience Demos' application_name, 'GEOSCIENCE-DEMOS' application_alias, 'BUILD' app_status, 12 active_users_count, 184 monthly_sessions, 'WARN' health_status, 'Application shell pending live creation; dashboard data is ready.' troubleshooting_note from dual union all
  select 2, null, 'Boreholes Demo', 'BOREHOLES-DEMO', 'PLANNED', 0, 0, 'UNKNOWN', 'Application shell pending live creation.' from dual
) s
on (d.application_name = s.application_name)
when matched then update set
  d.application_alias = s.application_alias,
  d.app_status = s.app_status,
  d.active_users_count = s.active_users_count,
  d.monthly_sessions = s.monthly_sessions,
  d.health_status = s.health_status,
  d.troubleshooting_note = s.troubleshooting_note,
  d.updated_at = systimestamp
when not matched then insert (
  application_id, application_name, application_alias, app_status,
  active_users_count, monthly_sessions, health_status, troubleshooting_note
) values (
  s.application_id, s.application_name, s.application_alias, s.app_status,
  s.active_users_count, s.monthly_sessions, s.health_status, s.troubleshooting_note
);

merge into gs_borehole_sources d
using (
  select 'Geoscience Australia Boreholes' source_name,
         'https://portal.ga.gov.au/' source_url,
         'PLANNED' source_status,
         'Demo seed rows stand in for the first portal.ga.gov.au refresh slice.' notes
    from dual
) s
on (d.source_name = s.source_name)
when matched then update set
  d.source_url = s.source_url,
  d.source_status = s.source_status,
  d.notes = s.notes,
  d.updated_at = systimestamp
when not matched then insert (source_name, source_url, source_status, notes)
values (s.source_name, s.source_url, s.source_status, s.notes);

merge into gs_boreholes d
using (
  select 'BH-NT-0001' borehole_ref, 'Tanami North 1' borehole_name, 'NT' state_code, 'Tanami' region_name, -19.745 latitude, 129.112 longitude, 320 depth_metres, 2018 drilled_year, 'Gold' commodity_group from dual union all
  select 'BH-WA-0002', 'Pilbara East 2', 'WA', 'Pilbara', -21.091, 119.869, 540, 2021, 'Iron Ore' from dual union all
  select 'BH-SA-0003', 'Gawler Craton 3', 'SA', 'Gawler', -31.152, 135.625, 410, 2019, 'Copper' from dual union all
  select 'BH-QLD-0004', 'Mount Isa West 4', 'QLD', 'Mount Isa', -20.724, 139.493, 685, 2022, 'Base Metals' from dual union all
  select 'BH-NSW-0005', 'Lachlan Fold 5', 'NSW', 'Lachlan', -33.391, 148.012, 260, 2020, 'Gold' from dual
) s
on (d.borehole_ref = s.borehole_ref)
when matched then update set
  d.borehole_name = s.borehole_name,
  d.state_code = s.state_code,
  d.region_name = s.region_name,
  d.latitude = s.latitude,
  d.longitude = s.longitude,
  d.depth_metres = s.depth_metres,
  d.drilled_year = s.drilled_year,
  d.commodity_group = s.commodity_group,
  d.updated_at = systimestamp
when not matched then insert (
  source_id, borehole_ref, borehole_name, state_code, region_name,
  latitude, longitude, depth_metres, drilled_year, commodity_group, status_code
) values (
  (select source_id from gs_borehole_sources where source_name = 'Geoscience Australia Boreholes'),
  s.borehole_ref, s.borehole_name, s.state_code, s.region_name,
  s.latitude, s.longitude, s.depth_metres, s.drilled_year, s.commodity_group, 'KNOWN'
);

insert into gs_data_refresh_runs (
  source_id, refresh_type, status_code, rows_loaded, rows_rejected, message, finished_at
)
select s.source_id, 'SEED_DATA', 'SUCCESS', 5, 0, 'Seeded initial borehole demo rows.', systimestamp
  from gs_borehole_sources s
 where s.source_name = 'Geoscience Australia Boreholes'
   and not exists (
         select 1
           from gs_data_refresh_runs r
          where r.source_id = s.source_id
            and r.refresh_type = 'SEED_DATA'
       );

commit;
end;
