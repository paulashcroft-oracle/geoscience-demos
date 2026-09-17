-- Integration acceptance only: invokes the installed public refresh API.
-- Expected extracted GS_BOREHOLE_REFRESH_API BODY SHA256 (20,445 UTF-8 bytes):
-- 39c352c0728239794291865c1e844d4d31747a857a70eab7e6056d6ff7a44b42
-- Normalized USER_SOURCE: 20,270 bytes, SHA256
-- a43f90464c3276cbb1d8f796a707b8675407b79691029a5e3437d7fb94b47b2e
-- Normalization excludes CREATE OR REPLACE, removes CR, maps NBSP to space,
-- and trims trailing whitespace; compare complete ordered source lines.
-- Root must first verify that installed source, the current SQL Commands page,
-- baseline checkpoint and exclusive execution window. This block cannot attest
-- that source hash or distinguish SQL Workshop from every APEX runtime session.
-- One real WFS call requests one feature. Real table writes are transient;
-- identity sequence use, HTTP and possible platform logs are not rolled back.
-- Submit this complete anonymous block in one SQL Commands invocation. Omit the
-- final slash there. No installer, SQLcl directives, commits or cleanup deletes.
declare
  c_source_name constant varchar2(200) := 'Geoscience Australia Boreholes WFS';
  type t_snapshot is record (
    boreholes clob,
    sources clob,
    runs clob,
    borehole_count number,
    source_count number,
    run_count number,
    latest_run number,
    source_id number,
    source_status varchar2(30),
    source_refresh timestamp with local time zone,
    source_updated timestamp with local time zone
  );
  l_before t_snapshot;
  l_current t_snapshot;
  l_json clob;
  l_values apex_json.t_values;
  l_savepoint_set boolean := false;
  l_assertions pls_integer := 0;
  l_stage pls_integer := 1;
  l_count number;
  l_run_id number;
  l_http number;
  l_loaded number;
  l_rejected number;
  l_download_ms number;
  l_load_ms number;
  l_total_ms number;
  l_response_chars number;
  l_api_error_code varchar2(40);
  l_run_source number;
  l_run_limit number;
  l_run_loaded number;
  l_run_rejected number;
  l_run_chars number;
  l_run_status varchar2(30);
  l_run_bbox varchar2(240);
  l_run_started timestamp with local time zone;
  l_run_finished timestamp with local time zone;
  l_original_code number;
  l_restore_code number := 0;
  l_lob_code number := 0;

  procedure check_true(p_condition boolean) is
  begin
    l_assertions := l_assertions + 1;
    if p_condition is null or not p_condition then
      raise_application_error(-20990, 'Assertion failed.');
    end if;
  end;

  procedure free_lob(p_lob in out nocopy clob) is
  begin
    if p_lob is not null and dbms_lob.istemporary(p_lob) = 1 then
      dbms_lob.freetemporary(p_lob);
    end if;
    p_lob := null;
  end;

  procedure release_snapshot(p_snapshot in out nocopy t_snapshot) is
  begin
    free_lob(p_snapshot.boreholes);
    free_lob(p_snapshot.sources);
    free_lob(p_snapshot.runs);
  end;

  procedure capture(p_snapshot in out nocopy t_snapshot) is
  begin
    release_snapshot(p_snapshot);
    select count(*),
           json_arrayagg(json_object(b.* returning clob)
                         order by b.borehole_id returning clob)
      into p_snapshot.borehole_count, p_snapshot.boreholes
      from geoscience.gs_boreholes b;
    select count(*),
           json_arrayagg(json_object(s.* returning clob)
                         order by s.source_id returning clob)
      into p_snapshot.source_count, p_snapshot.sources
      from geoscience.gs_borehole_sources s;
    select count(*), max(r.refresh_run_id),
           json_arrayagg(json_object(r.* returning clob)
                         order by r.refresh_run_id returning clob)
      into p_snapshot.run_count, p_snapshot.latest_run, p_snapshot.runs
      from geoscience.gs_data_refresh_runs r;
    select source_id, source_status, last_refresh_at, updated_at
      into p_snapshot.source_id, p_snapshot.source_status,
           p_snapshot.source_refresh, p_snapshot.source_updated
      from geoscience.gs_borehole_sources
     where source_name = c_source_name;
  end;

  function same_lob(p_left clob, p_right clob) return boolean is
  begin
    if p_left is null or p_right is null then
      return p_left is null and p_right is null;
    end if;
    return dbms_lob.getlength(p_left) = dbms_lob.getlength(p_right)
       and dbms_lob.compare(p_left, p_right) = 0;
  end;

  procedure verify_restored is
  begin
    capture(l_current);
    check_true(l_before.borehole_count = l_current.borehole_count);
    check_true(l_before.source_count = l_current.source_count);
    check_true(l_before.run_count = l_current.run_count);
    check_true(l_before.latest_run = l_current.latest_run or
               (l_before.latest_run is null and l_current.latest_run is null));
    check_true(l_before.source_id = l_current.source_id);
    check_true(l_before.source_status = l_current.source_status);
    check_true(l_before.source_refresh = l_current.source_refresh or
               (l_before.source_refresh is null and l_current.source_refresh is null));
    check_true(l_before.source_updated = l_current.source_updated or
               (l_before.source_updated is null and l_current.source_updated is null));
    check_true(same_lob(l_before.boreholes, l_current.boreholes));
    check_true(same_lob(l_before.sources, l_current.sources));
    check_true(same_lob(l_before.runs, l_current.runs));
    if l_run_id is not null then
      select count(*) into l_count from geoscience.gs_data_refresh_runs
       where refresh_run_id = l_run_id;
      check_true(l_count = 0);
    end if;
  end;

  procedure expect_invalid(p_min_lon number, p_max_lon number, p_limit number) is
  begin
    free_lob(l_json);
    l_json := geoscience.gs_borehole_refresh_api.remote_refresh_json(
      p_min_lon => p_min_lon, p_min_lat => -24,
      p_max_lon => p_max_lon, p_max_lat => -17, p_limit => p_limit);
    apex_json.parse(p_values => l_values, p_source => l_json);
    check_true(not apex_json.get_boolean(p_path => 'success', p_values => l_values));
    check_true(apex_json.get_varchar2(p_path => 'errorCode', p_values => l_values) = 'INVALID_REQUEST');
    check_true(apex_json.get_number(p_path => 'refreshRunId', p_values => l_values) is null);
    check_true(apex_json.get_number(p_path => 'httpStatus', p_values => l_values) is null);
    check_true(apex_json.get_number(p_path => 'rowsLoaded', p_values => l_values) = 0);
    check_true(apex_json.get_number(p_path => 'rowsRejected', p_values => l_values) = 0);
    check_true(apex_json.get_number(p_path => 'responseCharacters', p_values => l_values) = 0);
    check_true(apex_json.get_number(p_path => 'timingMs.download', p_values => l_values) = 0);
    check_true(apex_json.get_number(p_path => 'timingMs.load', p_values => l_values) = 0);
    check_true(apex_json.get_number(p_path => 'timingMs.total', p_values => l_values) >= 0);
    verify_restored;
  end;
begin
  -- Stage 1: exact observed identity and ordinary-table/trigger preflight.
  if nvl(sys_context('USERENV', 'DB_UNIQUE_NAME'), '?') <> 'tcelkxkd'
     or nvl(sys_context('USERENV', 'CURRENT_SCHEMA'), '?') <> 'GEOSCIENCE'
     or nvl(sys_context('USERENV', 'SESSION_USER'), '?') <> 'ORDS_PLSQL_GATEWAY'
     or nvl(v('APP_USER'), '?') <> 'CODEX'
     or nvl(apex_custom_auth.get_security_group_id, -1)
        <> nvl(apex_util.find_security_group_id('GEOSCIENCE'), -2) then
    raise_application_error(-20991, 'Target guard refused.');
  end if;
  select count(*) into l_count from all_tables
   where owner = 'GEOSCIENCE' and temporary = 'N'
     and table_name in ('GS_BOREHOLES', 'GS_BOREHOLE_SOURCES', 'GS_DATA_REFRESH_RUNS');
  check_true(l_count = 3);
  select count(*) into l_count from all_triggers
   where table_owner = 'GEOSCIENCE' and status = 'ENABLED'
     and table_name in ('GS_BOREHOLES', 'GS_BOREHOLE_SOURCES', 'GS_DATA_REFRESH_RUNS');
  if l_count <> 0 then
    raise_application_error(-20992, 'Enabled-trigger guard refused.');
  end if;
  select count(*) into l_count from geoscience.gs_borehole_sources
   where source_name = c_source_name;
  check_true(l_count = 1);

  l_stage := 2;
  capture(l_before);
  -- Distinct from the package's gs_borehole_attempt and gs_borehole_batch.
  savepoint bh_accept_20260917;
  l_savepoint_set := true;

  -- Stages 3-5 must return before run creation and HTTP in verified source.
  l_stage := 3;
  expect_invalid(129, 139, 0);
  l_stage := 4;
  expect_invalid(129, 139, 1.5);
  l_stage := 5;
  expect_invalid(139, 129, 1);

  l_stage := 6;
  free_lob(l_json);
  l_api_error_code := null;
  -- Exactly one valid call; no retry and no default limit of 250.
  l_json := geoscience.gs_borehole_refresh_api.remote_refresh_json(
    p_min_lon => 129, p_min_lat => -24,
    p_max_lon => 139, p_max_lat => -17, p_limit => 1);
  apex_json.parse(p_values => l_values, p_source => l_json);
  l_api_error_code := apex_json.get_varchar2(p_path => 'errorCode', p_values => l_values);
  if l_api_error_code is not null and l_api_error_code not in
     ('INVALID_REQUEST', 'SOURCE_RESPONSE_INVALID', 'SOURCE_HTTP_ERROR',
      'SOURCE_UNAVAILABLE', 'REFRESH_FAILED') then
    l_api_error_code := 'UNEXPECTED';
  end if;
  l_run_id := apex_json.get_number(p_path => 'refreshRunId', p_values => l_values);
  l_http := apex_json.get_number(p_path => 'httpStatus', p_values => l_values);
  l_loaded := apex_json.get_number(p_path => 'rowsLoaded', p_values => l_values);
  l_rejected := apex_json.get_number(p_path => 'rowsRejected', p_values => l_values);
  l_response_chars := apex_json.get_number(p_path => 'responseCharacters', p_values => l_values);
  l_download_ms := apex_json.get_number(p_path => 'timingMs.download', p_values => l_values);
  l_load_ms := apex_json.get_number(p_path => 'timingMs.load', p_values => l_values);
  l_total_ms := apex_json.get_number(p_path => 'timingMs.total', p_values => l_values);
  check_true(apex_json.get_boolean(p_path => 'success', p_values => l_values));
  check_true(apex_json.get_varchar2(p_path => 'errorCode', p_values => l_values) is null);
  check_true(l_run_id is not null and l_run_id = trunc(l_run_id));
  check_true(l_http between 200 and 299);
  check_true(l_loaded in (0, 1) and l_rejected = 0);
  check_true(apex_json.get_boolean(p_path => 'emptyResult', p_values => l_values) = (l_loaded = 0));
  check_true(apex_json.get_number(p_path => 'transferTimeoutSeconds', p_values => l_values) = 30);
  check_true(l_response_chars > 0 and l_response_chars <= 30000000);
  check_true(l_download_ms >= 0 and l_load_ms >= 0 and l_total_ms >= 0);
  check_true(l_total_ms >= l_download_ms + l_load_ms);

  l_stage := 7;
  select source_id, requested_limit, status_code, rows_loaded, rows_rejected,
         response_bytes, bbox_text, started_at, finished_at
    into l_run_source, l_run_limit, l_run_status, l_run_loaded, l_run_rejected,
         l_run_chars, l_run_bbox, l_run_started, l_run_finished
    from geoscience.gs_data_refresh_runs where refresh_run_id = l_run_id;
  check_true(l_run_source = l_before.source_id and l_run_limit = 1);
  check_true(l_run_status = 'SUCCESS' and l_run_loaded = l_loaded and l_run_rejected = 0);
  check_true(l_run_chars = l_response_chars and l_run_bbox = '129,-24,139,-17');
  check_true(l_run_started is not null and l_run_finished >= l_run_started);
  select count(*) into l_count from geoscience.gs_boreholes
   where last_refresh_run_id = l_run_id;
  check_true(l_count = l_loaded);
  capture(l_current);
  check_true(l_current.run_count = l_before.run_count + 1);
  check_true(l_current.source_count = l_before.source_count);
  check_true(l_current.source_id = l_before.source_id and l_current.source_status = 'ACTIVE');
  check_true(l_current.source_refresh >= l_run_started and l_current.source_updated >= l_run_started);
  check_true(l_current.borehole_count between l_before.borehole_count
             and l_before.borehole_count + l_loaded);

  l_stage := 8;
  rollback to bh_accept_20260917;
  verify_restored;
  -- Restoration is now proven; a LOB cleanup error must not compare freed LOBs.
  l_savepoint_set := false;
  l_stage := 9;
  free_lob(l_json);
  release_snapshot(l_current);
  release_snapshot(l_before);
  -- All writes have been undone and exact table snapshots matched before PASS.
  dbms_output.put_line('PASS installed refresh; invalidCases=3; httpStatus=' || l_http ||
    '; rowsLoaded=' || l_loaded || '; rowsRejected=' || l_rejected ||
    '; downloadMs=' || l_download_ms || '; loadMs=' || l_load_ms ||
    '; totalMs=' || l_total_ms || '; restored=1; assertions=' || l_assertions);
exception
  when others then
    l_original_code := sqlcode;
    if l_savepoint_set then
      begin
        rollback to bh_accept_20260917;
        verify_restored;
      exception
        when others then l_restore_code := sqlcode;
      end;
    end if;
    begin
      free_lob(l_json);
      release_snapshot(l_current);
      release_snapshot(l_before);
    exception
      when others then l_lob_code := sqlcode;
    end;
    -- Do not propagate provider URLs/bodies or raw SQLERRM from a nested call.
    -- Every failure remains a raised error, including restoration/LOB failures.
    raise_application_error(-20993, 'Acceptance failed; stage=' || l_stage ||
      '; originalCode=' || l_original_code || '; restoreCode=' || l_restore_code ||
      '; lobCode=' || l_lob_code || '; apiErrorCode=' || nvl(l_api_error_code, 'NONE'), false);
end;
/
