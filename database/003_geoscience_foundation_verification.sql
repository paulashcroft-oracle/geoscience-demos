-- Geoscience 003 - Verify foundation objects

select 'GS_ENVIRONMENTS' object_name, count(*) row_count from gs_environments
union all
select 'GS_PEOPLE', count(*) from gs_people
union all
select 'GS_ACCOUNT_REQUESTS', count(*) from gs_account_requests
union all
select 'GS_ENV_ACCOUNTS', count(*) from gs_env_accounts
union all
select 'GS_APEX_APPLICATIONS', count(*) from gs_apex_applications
union all
select 'GS_BOREHOLE_SOURCES', count(*) from gs_borehole_sources
union all
select 'GS_BOREHOLES', count(*) from gs_boreholes
union all
select 'GS_DATA_REFRESH_RUNS', count(*) from gs_data_refresh_runs;

select status_code, request_type_code, request_count
  from gs_account_dashboard_v
 order by status_code, request_type_code;

select state_code, region_name, borehole_count, avg_depth_metres
  from gs_borehole_summary_v
 order by state_code, region_name;

select application_id,
       application_name,
       application_alias,
       app_status,
       health_status,
       last_health_check_at
  from gs_apex_applications
 order by application_id;
