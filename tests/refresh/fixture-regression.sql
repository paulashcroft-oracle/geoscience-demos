-- Controlled database fixture test, never an AIDEMODB GEOSCIENCE runtime test.
-- Run as the isolated schema owner BOREHOLES_TEST after installing the required
-- three tables and GS_BOREHOLE_REFRESH_API there. No HTTP requests, DDL or commits.
-- SQLcl example after selecting a saved TEST connection:
--   @tests/refresh/fixture-regression.sql
set define off
set serveroutput on
whenever sqlerror exit failure rollback

declare
  l_token varchar2(32) := rawtohex(sys_guid());
  l_ref varchar2(100);
  l_bad_ref varchar2(100);
  l_caller_ref varchar2(100);
  l_url varchar2(1000);
  l_run number;
  l_count number;
  l_loaded number;
  l_rejected number;
  l_before_runs number;
  l_status varchar2(30);
  l_name varchar2(240);
  l_json clob;
  l_values apex_json.t_values;
  l_source_id number;
  l_source_refresh timestamp with local time zone;
  l_actual_refresh timestamp with local time zone;
  l_test_started boolean := false;

  procedure check_true(p_condition boolean, p_message varchar2) is
  begin
    if p_condition is null or not p_condition then
      raise_application_error(-20990, 'FAIL: ' || p_message);
    end if;
  end;

  function feature(p_ref varchar2, p_name varchar2, p_depth varchar2 default '42',
                   p_status varchar2 default 'ABANDONED') return varchar2 is
  begin
    -- All arguments below are fixed fixture text or generated hex identifiers.
    return '{"type":"Feature","properties":{"ENO":"' || p_ref ||
           '","NAME":"' || p_name || '","STATE":"NT","COLLAR_LAT_GDA94":-20,' ||
           '"COLLAR_LONG_GDA94":135,"BOREHOLELENGTH_M":' || p_depth ||
           ',"STATUS":"' || p_status || '"}}';
  end;

  function collection(p_features varchar2) return clob is
  begin
    return '{"type":"FeatureCollection","features":[' || p_features || ']}';
  end;

  procedure expect_failure(p_payload clob, p_label varchar2, p_limit number default 10,
                           p_expected_rejected number default 0) is
    l_failed boolean := false;
    l_failed_run number;
  begin
    begin
      l_failed_run := gs_borehole_refresh_api.load_geojson_clob(
        p_payload, l_url, '129,-24,139,-17', p_limit, 'Fixture: ' || p_label);
    exception
      when others then
        l_failed := true;
    end;
    check_true(l_failed, p_label || ' must fail');
    select status_code, rows_loaded, rows_rejected
      into l_status, l_loaded, l_rejected
      from gs_data_refresh_runs
     where refresh_run_id = (select max(refresh_run_id) from gs_data_refresh_runs where request_url = l_url);
    check_true(l_status = 'FAILED' and l_loaded = 0 and l_rejected = p_expected_rejected,
               p_label || ' must retain FAILED diagnostics with zero committed batch rows');
  end;

  procedure expect_invalid_request(p_min_lon number, p_min_lat number,
                                   p_max_lon number, p_max_lat number, p_limit number,
                                   p_code number) is
    l_actual_code number;
    l_request varchar2(4000);
  begin
    begin
      l_request := gs_borehole_refresh_api.wfs_request_url(
        p_min_lon, p_min_lat, p_max_lon, p_max_lat, p_limit);
    exception when others then l_actual_code := sqlcode;
    end;
    check_true(l_actual_code = p_code, 'invalid BBOX/limit must be rejected before HTTP');
  end;
begin
  if user <> 'BOREHOLES_TEST' or sys_context('USERENV', 'CURRENT_SCHEMA') <> 'BOREHOLES_TEST' then
    raise_application_error(-20991, 'Run only as isolated BOREHOLES_TEST owner, never against GEOSCIENCE.');
  end if;
  savepoint gs_refresh_test;
  l_test_started := true;
  l_ref := 'BH-TEST-' || l_token;
  l_bad_ref := 'BH-BAD-' || l_token;
  l_caller_ref := 'BH-CALLER-' || l_token;
  l_url := 'fixture://boreholes-refresh/' || l_token;

  insert into gs_boreholes(borehole_ref, borehole_name) values(l_caller_ref, 'Caller work before refresh');
  expect_invalid_request(129, -24, 139, -17, 0, -20151);
  expect_invalid_request(129, -24, 139, -17, 10001, -20151);
  expect_invalid_request(129, -24, 139, -17, 1.5, -20151);
  expect_invalid_request(129, -24, 139, -17, null, -20151);
  expect_invalid_request(139, -24, 129, -17, 10, -20152);
  expect_invalid_request(129, -91, 139, -17, 10, -20152);
  expect_invalid_request(129, -24, 181, -17, 10, -20152);
  expect_invalid_request(null, -24, 139, -17, 10, -20152);
  expect_invalid_request(129, -24, 129.00000001, -17, 10, -20152);
  check_true(instr(gs_borehole_refresh_api.wfs_request_url(129, -24, 139, -17, 10),
    '&count=10&bbox=129,-24,139,-17,EPSG%3A4326') > 0, 'canonical WFS request');

  select count(*) into l_before_runs from gs_data_refresh_runs;
  -- Invalid input guarantees this wrapper test never reaches the network.
  l_json := gs_borehole_refresh_api.remote_refresh_json(139, -24, 129, -17, 10);
  apex_json.parse(p_values => l_values, p_source => l_json);
  check_true(not apex_json.get_boolean(p_path => 'success', p_values => l_values), 'invalid wrapper input returns failure JSON');
  check_true(apex_json.get_number(p_path => 'rowsLoaded', p_values => l_values) = 0, 'failure JSON loaded count');
  check_true(apex_json.get_number(p_path => 'timingMs.total', p_values => l_values) >= 0, 'failure JSON timing');
  check_true(apex_json.get_varchar2(p_path => 'errorCode', p_values => l_values) = 'INVALID_REQUEST', 'classified UI error');
  check_true(instr(apex_json.get_varchar2(p_path => 'message', p_values => l_values), 'ORA-') = 0, 'UI error does not expose Oracle error text');
  select count(*) into l_count from gs_data_refresh_runs;
  check_true(l_count = l_before_runs, 'invalid request creates no network attempt');

  expect_failure('{broken', 'malformed JSON');
  expect_failure('{"type":"Other","features":[]}', 'wrong collection type');
  expect_failure('{"type":"FeatureCollection"}', 'missing features');
  expect_failure('{"type":"FeatureCollection","features":{}}', 'features is not array');
  expect_failure(collection('{"type":"Feature","properties":null}'), 'missing properties', 10, 1);
  expect_failure(collection('{"type":"Feature","properties":{"NAME":"No stable ID"}}'), 'missing stable ID', 10, 1);

  l_run := gs_borehole_refresh_api.load_geojson_clob(collection(null), l_url, '129,-24,139,-17', 10, 'Empty fixture');
  select status_code, rows_loaded into l_status, l_loaded from gs_data_refresh_runs where refresh_run_id = l_run;
  check_true(l_status = 'SUCCESS' and l_loaded = 0, 'valid empty collection succeeds with zero rows');

  l_run := gs_borehole_refresh_api.load_geojson_clob(collection(feature(l_ref, 'Original')), l_url, '129,-24,139,-17', 10);
  select status_code, source_id into l_status, l_source_id from gs_boreholes where borehole_ref = l_ref;
  check_true(l_status = 'HISTORIC', 'abandoned status on first insert');
  l_run := gs_borehole_refresh_api.load_geojson_clob(collection(feature(l_ref, 'Original')), l_url, '129,-24,139,-17', 10);
  select count(*), max(status_code) into l_count, l_status from gs_boreholes where borehole_ref = l_ref;
  check_true(l_count = 1 and l_status = 'HISTORIC', 'repeat load preserves identity and status');
  select last_refresh_at into l_source_refresh from gs_borehole_sources where source_id = l_source_id;

  -- First row updates an existing record; second fails. Both business changes
  -- must roll back while the failed run and unrelated caller work remain.
  expect_failure(collection(feature(l_ref, 'Should roll back', '100', 'ACTIVE') || ',' ||
    feature(l_bad_ref, 'Invalid', '-1')), 'mid-batch bad length', 10, 1);
  select borehole_name, status_code into l_name, l_status from gs_boreholes where borehole_ref = l_ref;
  check_true(l_name = 'Original' and l_status = 'HISTORIC', 'failed batch restores earlier update');
  select count(*) into l_count from gs_boreholes where borehole_ref = l_bad_ref;
  check_true(l_count = 0, 'failed batch inserts no bad record');
  select last_refresh_at into l_actual_refresh from gs_borehole_sources where source_id = l_source_id;
  check_true(l_source_refresh = l_actual_refresh, 'failed batch leaves source success timestamp unchanged');
  select count(*) into l_count from gs_boreholes where borehole_ref = l_caller_ref;
  check_true(l_count = 1, 'batch rollback preserves caller work');

  expect_failure(collection(feature(l_ref, 'Should not change') || ',' || feature(l_bad_ref, 'Over limit')),
                 'feature count exceeds request', 1);
  expect_failure(collection(feature(l_bad_ref, 'Bad number', '"not-a-number"')), 'invalid numeric field', 10, 1);
  expect_failure(collection(feature(l_ref, 'Should roll back') || ',' ||
    replace(feature(l_bad_ref, 'Bad date'), '"STATUS"', '"DRILLSTARTDATE":"2026-02-31","STATUS"')),
    'mid-batch invalid date', 10, 1);
  expect_failure(collection(feature(l_ref, 'Should roll back') || ',' || feature(l_ref, 'Repeated ID')),
    'repeated batch identifier', 10, 1);
  select borehole_name into l_name from gs_boreholes where borehole_ref = l_ref;
  check_true(l_name = 'Original', 'date and duplicate failures restore earlier row update');
  rollback to gs_refresh_test;
  dbms_output.put_line('PASS: refresh fixtures; all fixture business and diagnostic rows rolled back.');
exception
  when others then
    if l_test_started then rollback to gs_refresh_test; end if;
    raise;
end;
/
