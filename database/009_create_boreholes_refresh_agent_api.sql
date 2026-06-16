set define off

prompt Geoscience 009 - Create Boreholes refresh and agent APIs

declare
  procedure add_column_if_missing(
    p_table_name  in varchar2,
    p_column_name in varchar2,
    p_column_sql  in varchar2
  ) is
    l_count number;
  begin
    select count(*)
      into l_count
      from user_tab_cols
     where table_name = upper(p_table_name)
       and column_name = upper(p_column_name);

    if l_count = 0 then
      execute immediate 'alter table ' || p_table_name || ' add (' || p_column_sql || ')';
    end if;
  end add_column_if_missing;
begin
  add_column_if_missing('GS_BOREHOLES', 'EXTERNAL_ID', 'external_id varchar2(120 char)');
  add_column_if_missing('GS_BOREHOLES', 'IDENTIFIER_URI', 'identifier_uri varchar2(1000 char)');
  add_column_if_missing('GS_BOREHOLES', 'PURPOSE', 'purpose varchar2(240 char)');
  add_column_if_missing('GS_BOREHOLES', 'OPERATOR_NAME', 'operator_name varchar2(240 char)');
  add_column_if_missing('GS_BOREHOLES', 'DRILLER_NAME', 'driller_name varchar2(240 char)');
  add_column_if_missing('GS_BOREHOLES', 'DRILL_START_DATE', 'drill_start_date date');
  add_column_if_missing('GS_BOREHOLES', 'DRILL_END_DATE', 'drill_end_date date');
  add_column_if_missing('GS_BOREHOLES', 'ELEVATION_M', 'elevation_m number');
  add_column_if_missing('GS_BOREHOLES', 'POSITIONAL_ACCURACY', 'positional_accuracy varchar2(240 char)');
  add_column_if_missing('GS_BOREHOLES', 'DATA_CUSTODIAN', 'data_custodian varchar2(240 char)');
  add_column_if_missing('GS_BOREHOLES', 'GEOLOGICAL_PROVINCES', 'geological_provinces varchar2(1000 char)');
  add_column_if_missing('GS_BOREHOLES', 'METADATA_URI', 'metadata_uri varchar2(1000 char)');
  add_column_if_missing('GS_BOREHOLES', 'BOREHOLE_REPORT_URI', 'borehole_report_uri varchar2(1000 char)');
  add_column_if_missing('GS_BOREHOLES', 'QA_STATUS', 'qa_status varchar2(120 char)');
  add_column_if_missing('GS_BOREHOLES', 'STATE_NAME', 'state_name varchar2(120 char)');
  add_column_if_missing('GS_BOREHOLES', 'LAST_REFRESH_RUN_ID', 'last_refresh_run_id number');

  add_column_if_missing('GS_DATA_REFRESH_RUNS', 'SOURCE_URL', 'source_url varchar2(1000 char)');
  add_column_if_missing('GS_DATA_REFRESH_RUNS', 'REQUEST_URL', 'request_url varchar2(4000 char)');
  add_column_if_missing('GS_DATA_REFRESH_RUNS', 'FEATURE_TYPE', 'feature_type varchar2(120 char)');
  add_column_if_missing('GS_DATA_REFRESH_RUNS', 'BBOX_TEXT', 'bbox_text varchar2(240 char)');
  add_column_if_missing('GS_DATA_REFRESH_RUNS', 'REQUESTED_LIMIT', 'requested_limit number');
  add_column_if_missing('GS_DATA_REFRESH_RUNS', 'RESPONSE_BYTES', 'response_bytes number');
end;
/

merge into gs_borehole_sources d
using (
  select 'Geoscience Australia Boreholes WFS' source_name,
         'https://services.ga.gov.au/gis/boreholes/ows' source_url,
         'ACTIVE' source_status,
         'OGC WFS endpoint discovered from portal.ga.gov.au National Drilling Initiative configuration. Feature type bh:Boreholes returns GeoJSON borehole headers and collar coordinates.' notes
    from dual
) s
on (d.source_name = s.source_name)
when matched then update set
  d.source_url = s.source_url,
  d.source_status = s.source_status,
  d.notes = s.notes,
  d.updated_at = systimestamp
when not matched then insert (source_name, source_url, source_status, notes)
values (s.source_name, s.source_url, s.source_status, s.notes)
/

create or replace view gs_borehole_summary_v as
select coalesce(state_code, 'UNKNOWN') state_code,
       coalesce(region_name, geological_provinces, 'Unknown region') region_name,
       coalesce(commodity_group, purpose, 'Unknown purpose') commodity_group,
       count(*) borehole_count,
       round(avg(depth_metres), 1) avg_depth_metres,
       min(drilled_year) first_drilled_year,
       max(drilled_year) latest_drilled_year
  from gs_boreholes
 group by coalesce(state_code, 'UNKNOWN'),
          coalesce(region_name, geological_provinces, 'Unknown region'),
          coalesce(commodity_group, purpose, 'Unknown purpose')
/

create or replace view gs_borehole_refresh_status_v as
select r.refresh_run_id,
       s.source_name,
       r.refresh_type,
       r.status_code,
       r.requested_by,
       r.started_at,
       r.finished_at,
       r.rows_loaded,
       r.rows_rejected,
       r.bbox_text,
       r.requested_limit,
       r.source_url,
       r.request_url,
       r.message
  from gs_data_refresh_runs r
  left join gs_borehole_sources s on s.source_id = r.source_id
 where s.source_name in ('Geoscience Australia Boreholes WFS', 'Geoscience Australia Boreholes')
 order by r.started_at desc
/

create or replace package gs_borehole_refresh_api as
  function wfs_request_url(
    p_min_lon in number default 129,
    p_min_lat in number default -24,
    p_max_lon in number default 139,
    p_max_lat in number default -17,
    p_limit   in number default 250
  ) return varchar2;

  function load_geojson_clob(
    p_geojson     in clob,
    p_request_url in varchar2,
    p_bbox_text   in varchar2,
    p_limit       in number,
    p_notes       in varchar2 default null
  ) return number;

  function remote_refresh_json(
    p_min_lon in number default 129,
    p_min_lat in number default -24,
    p_max_lon in number default 139,
    p_max_lat in number default -17,
    p_limit   in number default 250
  ) return clob;
end gs_borehole_refresh_api;
/

create or replace package body gs_borehole_refresh_api as
  c_source_name constant varchar2(200) := 'Geoscience Australia Boreholes WFS';
  c_source_url  constant varchar2(1000) := 'https://services.ga.gov.au/gis/boreholes/ows';

  function nfmt(p_value in number) return varchar2 is
    l_value varchar2(80);
  begin
    l_value := to_char(p_value, 'FM9999990D999999', 'NLS_NUMERIC_CHARACTERS=.,');
    l_value := rtrim(rtrim(l_value, '0'), '.');
    return case when l_value in ('', '-0') then '0' else l_value end;
  end nfmt;

  function clean_text(p_value in varchar2) return varchar2 is
  begin
    return nullif(trim(p_value), '');
  end clean_text;

  function clean_number(p_value in varchar2) return number is
  begin
    return to_number(nullif(trim(p_value), ''), '999999999999D999999999', 'NLS_NUMERIC_CHARACTERS=.,');
  exception
    when others then
      return null;
  end clean_number;

  function clean_date(p_value in varchar2) return date is
  begin
    if clean_text(p_value) is null then
      return null;
    end if;
    return to_date(substr(p_value, 1, 10), 'YYYY-MM-DD');
  exception
    when others then
      return null;
  end clean_date;

  function source_id return number is
    l_source_id number;
  begin
    merge into gs_borehole_sources d
    using (
      select c_source_name source_name,
             c_source_url source_url,
             'ACTIVE' source_status,
             'OGC WFS endpoint for Australian onshore and offshore boreholes, feature type bh:Boreholes.' notes
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

    select source_id
      into l_source_id
      from gs_borehole_sources
     where source_name = c_source_name;

    return l_source_id;
  end source_id;

  function prop_varchar(p_index in pls_integer, p_name in varchar2) return varchar2 is
  begin
    return clean_text(apex_json.get_varchar2(p_path => 'features[%d].properties.' || p_name, p0 => p_index));
  exception
    when others then
      return null;
  end prop_varchar;

  function prop_number(p_index in pls_integer, p_name in varchar2) return number is
  begin
    return clean_number(prop_varchar(p_index, p_name));
  end prop_number;

  function wfs_request_url(
    p_min_lon in number default 129,
    p_min_lat in number default -24,
    p_max_lon in number default 139,
    p_max_lat in number default -17,
    p_limit   in number default 250
  ) return varchar2 is
  begin
    return c_source_url ||
           '?service=WFS&version=2.0.0&request=GetFeature&typeNames=bh%3ABoreholes&outputFormat=application%2Fjson' ||
           '&count=' || to_char(least(greatest(coalesce(p_limit, 250), 1), 10000)) ||
           '&bbox=' || nfmt(p_min_lon) || ',' || nfmt(p_min_lat) || ',' ||
           nfmt(p_max_lon) || ',' || nfmt(p_max_lat) || ',EPSG%3A4326';
  end wfs_request_url;

  function load_geojson_clob(
    p_geojson     in clob,
    p_request_url in varchar2,
    p_bbox_text   in varchar2,
    p_limit       in number,
    p_notes       in varchar2 default null
  ) return number is
    l_source_id number := source_id;
    l_refresh_run_id number;
    l_count number := 0;
    l_loaded number := 0;
    l_rejected number := 0;
    l_ref varchar2(100);
    l_name varchar2(240);
    l_year number;
    l_error_message varchar2(2000);
    l_state_code varchar2(20);
    l_state_name varchar2(120);
    l_region_name varchar2(160);
    l_latitude number;
    l_longitude number;
    l_depth_metres number;
    l_commodity_group varchar2(160);
    l_source_status varchar2(40);
    l_external_id varchar2(120);
    l_identifier_uri varchar2(1000);
    l_purpose varchar2(240);
    l_operator_name varchar2(240);
    l_driller_name varchar2(240);
    l_drill_start_date date;
    l_drill_end_date date;
    l_elevation_m number;
    l_positional_accuracy varchar2(240);
    l_data_custodian varchar2(240);
    l_geological_provinces varchar2(1000);
    l_metadata_uri varchar2(1000);
    l_borehole_report_uri varchar2(1000);
    l_qa_status varchar2(120);
  begin
    if p_geojson is null or dbms_lob.getlength(p_geojson) = 0 then
      raise_application_error(-20150, 'Boreholes GeoJSON payload is required.');
    end if;

    insert into gs_data_refresh_runs (
      source_id, refresh_type, status_code, source_url, request_url, feature_type,
      bbox_text, requested_limit, response_bytes, message
    ) values (
      l_source_id, 'REMOTE_REFRESH', 'STARTED', c_source_url, p_request_url, 'bh:Boreholes',
      p_bbox_text, p_limit, dbms_lob.getlength(p_geojson), p_notes
    )
    returning refresh_run_id into l_refresh_run_id;

    apex_json.parse(p_geojson);
    l_count := coalesce(apex_json.get_count(p_path => 'features'), 0);

    for i in 1 .. l_count loop
      l_ref := coalesce(
        prop_varchar(i, 'ENO'),
        prop_varchar(i, 'IDENTIFIER'),
        prop_varchar(i, 'GMLID'),
        prop_varchar(i, 'NAME'),
        'GA-WFS-' || to_char(l_refresh_run_id) || '-' || to_char(i)
      );
      l_name := coalesce(prop_varchar(i, 'NAME'), l_ref);
      l_year := to_number(to_char(clean_date(coalesce(prop_varchar(i, 'DRILLSTARTDATE'), prop_varchar(i, 'DRILLENDDATE'))), 'YYYY'));
      l_state_code := prop_varchar(i, 'STATE');
      l_state_name := prop_varchar(i, 'STATE');
      l_region_name := substr(coalesce(prop_varchar(i, 'GEOLOGICAL_PROVINCES'), prop_varchar(i, 'SOURCE')), 1, 160);
      l_latitude := prop_number(i, 'COLLAR_LAT_GDA94');
      l_longitude := prop_number(i, 'COLLAR_LONG_GDA94');
      l_depth_metres := prop_number(i, 'BOREHOLELENGTH_M');
      l_commodity_group := prop_varchar(i, 'PURPOSE');
      l_source_status := substr(coalesce(prop_varchar(i, 'STATUS'), 'ACTIVE'), 1, 40);
      l_external_id := prop_varchar(i, 'ENO');
      l_identifier_uri := prop_varchar(i, 'IDENTIFIER');
      l_purpose := prop_varchar(i, 'PURPOSE');
      l_operator_name := prop_varchar(i, 'OPERATOR');
      l_driller_name := prop_varchar(i, 'DRILLER');
      l_drill_start_date := clean_date(prop_varchar(i, 'DRILLSTARTDATE'));
      l_drill_end_date := clean_date(prop_varchar(i, 'DRILLENDDATE'));
      l_elevation_m := prop_number(i, 'ELEVATION_M');
      l_positional_accuracy := prop_varchar(i, 'POSITIONALACCURACY');
      l_data_custodian := prop_varchar(i, 'DATA_CUSTODIAN');
      l_geological_provinces := prop_varchar(i, 'GEOLOGICAL_PROVINCES');
      l_metadata_uri := prop_varchar(i, 'METADATA_URI');
      l_borehole_report_uri := prop_varchar(i, 'BOREHOLE_REPORT_URI');
      l_qa_status := prop_varchar(i, 'QA_STATUS');

      update gs_boreholes
         set source_id = l_source_id,
             borehole_name = substr(l_name, 1, 240),
             state_code = l_state_code,
             state_name = l_state_name,
             region_name = l_region_name,
             latitude = l_latitude,
             longitude = l_longitude,
             depth_metres = l_depth_metres,
             drilled_year = l_year,
             commodity_group = l_commodity_group,
             status_code = case when upper(l_source_status) like '%ABANDON%' then 'HISTORIC' else 'ACTIVE' end,
             external_id = l_external_id,
             identifier_uri = l_identifier_uri,
             purpose = l_purpose,
             operator_name = l_operator_name,
             driller_name = l_driller_name,
             drill_start_date = l_drill_start_date,
             drill_end_date = l_drill_end_date,
             elevation_m = l_elevation_m,
             positional_accuracy = l_positional_accuracy,
             data_custodian = l_data_custodian,
             geological_provinces = l_geological_provinces,
             metadata_uri = l_metadata_uri,
             borehole_report_uri = l_borehole_report_uri,
             qa_status = l_qa_status,
             last_refresh_run_id = l_refresh_run_id,
             source_updated_at = systimestamp,
             updated_at = systimestamp
       where borehole_ref = substr(l_ref, 1, 100);

      if sql%rowcount = 0 then
        insert into gs_boreholes (
          source_id, borehole_ref, borehole_name, state_code, state_name, region_name,
          latitude, longitude, depth_metres, drilled_year, commodity_group, status_code,
          external_id, identifier_uri, purpose, operator_name, driller_name,
          drill_start_date, drill_end_date, elevation_m, positional_accuracy,
          data_custodian, geological_provinces, metadata_uri, borehole_report_uri,
          qa_status, last_refresh_run_id, source_updated_at
        ) values (
          l_source_id, substr(l_ref, 1, 100), substr(l_name, 1, 240), l_state_code, l_state_name, l_region_name,
          l_latitude, l_longitude, l_depth_metres, l_year, l_commodity_group, 'ACTIVE',
          l_external_id, l_identifier_uri, l_purpose, l_operator_name, l_driller_name,
          l_drill_start_date, l_drill_end_date, l_elevation_m, l_positional_accuracy,
          l_data_custodian, l_geological_provinces, l_metadata_uri, l_borehole_report_uri,
          l_qa_status, l_refresh_run_id, systimestamp
        );
      end if;

      l_loaded := l_loaded + 1;
    end loop;

    update gs_data_refresh_runs
       set status_code = 'SUCCESS',
           finished_at = systimestamp,
           rows_loaded = l_loaded,
           rows_rejected = l_rejected,
           message = 'Loaded ' || l_loaded || ' boreholes from Geoscience Australia WFS.'
     where refresh_run_id = l_refresh_run_id;

    update gs_borehole_sources
       set last_refresh_at = systimestamp,
           source_status = 'ACTIVE',
           updated_at = systimestamp
     where source_id = l_source_id;

    return l_refresh_run_id;
  exception
    when others then
      if l_refresh_run_id is not null then
        l_error_message := substr(sqlerrm, 1, 2000);
        update gs_data_refresh_runs
           set status_code = 'FAILED',
               finished_at = systimestamp,
               rows_loaded = l_loaded,
               rows_rejected = l_rejected,
               message = l_error_message
         where refresh_run_id = l_refresh_run_id;
      end if;
      raise;
  end load_geojson_clob;

  function remote_refresh_json(
    p_min_lon in number default 129,
    p_min_lat in number default -24,
    p_max_lon in number default 139,
    p_max_lat in number default -17,
    p_limit   in number default 250
  ) return clob is
    l_url varchar2(4000);
    l_bbox varchar2(240);
    l_response clob;
    l_run_id number;
    l_json clob;
  begin
    l_url := wfs_request_url(p_min_lon, p_min_lat, p_max_lon, p_max_lat, p_limit);
    l_bbox := nfmt(p_min_lon) || ',' || nfmt(p_min_lat) || ',' || nfmt(p_max_lon) || ',' || nfmt(p_max_lat);
    l_response := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'GET');
    l_run_id := load_geojson_clob(l_response, l_url, l_bbox, p_limit, 'Triggered from Boreholes Data Refresh page.');

    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write('success', true);
    apex_json.write('refreshRunId', l_run_id);
    apex_json.write('requestUrl', l_url);
    apex_json.write('message', 'Boreholes refreshed from Geoscience Australia WFS.');
    apex_json.close_object;
    l_json := apex_json.get_clob_output;
    apex_json.free_output;
    return l_json;
  exception
    when others then
      apex_json.initialize_clob_output;
      apex_json.open_object;
      apex_json.write('success', false);
      apex_json.write('requestUrl', l_url);
      apex_json.write('message', substr(sqlerrm, 1, 1000));
      apex_json.close_object;
      l_json := apex_json.get_clob_output;
      apex_json.free_output;
      return l_json;
  end remote_refresh_json;
end gs_borehole_refresh_api;
/

create or replace package gs_borehole_agent_api as
  function dataset_summary_markdown return clob;
  function deterministic_answer_html(p_user_prompt in clob) return clob;
  function build_ai_context(p_user_prompt in clob, p_screen_context in clob default null) return clob;
  function ask_json(
    p_user_prompt       in clob,
    p_service_static_id in varchar2 default null,
    p_screen_context    in clob default null
  ) return clob;
end gs_borehole_agent_api;
/

create or replace package body gs_borehole_agent_api as
  procedure append_text(p_clob in out nocopy clob, p_text in varchar2) is
  begin
    if p_text is not null then
      dbms_lob.writeappend(p_clob, length(p_text), p_text);
    end if;
  end append_text;

  procedure append_line(p_clob in out nocopy clob, p_text in varchar2 default null) is
  begin
    append_text(p_clob, p_text || chr(10));
  end append_line;

  function html_escape(p_value in varchar2) return varchar2 is
  begin
    return apex_escape.html(p_value);
  end html_escape;

  function compact_prompt(p_value in clob) return varchar2 is
  begin
    if p_value is null then
      return null;
    end if;
    return trim(dbms_lob.substr(p_value, 500, 1));
  end compact_prompt;

  function service_name_for_static_id(p_service_static_id in varchar2) return varchar2 is
    l_name varchar2(255);
  begin
    select remote_server_name
      into l_name
      from apex_workspace_ai_services
     where upper(remote_server_static_id) = upper(trim(p_service_static_id))
       and provider_type_code = 'OCI_GENAI'
       fetch first 1 row only;
    return l_name;
  exception
    when others then
      return null;
  end service_name_for_static_id;

  function valid_service_static_id(p_service_static_id in varchar2) return varchar2 is
    l_static_id varchar2(255);
  begin
    if p_service_static_id is null then
      return null;
    end if;

    select remote_server_static_id
      into l_static_id
      from apex_workspace_ai_services
     where upper(remote_server_static_id) = upper(trim(p_service_static_id))
       and provider_type_code = 'OCI_GENAI'
       fetch first 1 row only;

    return l_static_id;
  exception
    when others then
      return null;
  end valid_service_static_id;

  function default_service_static_id return varchar2 is
  begin
    return coalesce(
      valid_service_static_id('google_gemini_2_5_pro'),
      valid_service_static_id('google_gemini_2_5_flash'),
      valid_service_static_id('openai_gpt_oss_120b')
    );
  end default_service_static_id;

  function dataset_summary_markdown return clob is
    l_result clob;
    l_total number;
    l_real number;
    l_last_refresh varchar2(100);
  begin
    dbms_lob.createtemporary(l_result, true);

    select count(*),
           count(case when source_id in (select source_id from gs_borehole_sources where source_name = 'Geoscience Australia Boreholes WFS') then 1 end)
      into l_total, l_real
      from gs_boreholes;

    select max(to_char(finished_at, 'YYYY-MM-DD HH24:MI:SS'))
      into l_last_refresh
      from gs_data_refresh_runs
     where refresh_type = 'REMOTE_REFRESH'
       and status_code = 'SUCCESS';

    append_line(l_result, '# Boreholes Dataset Snapshot');
    append_line(l_result, '- Total loaded boreholes: ' || to_char(l_total, 'FM999G999G999'));
    append_line(l_result, '- Geoscience Australia WFS rows: ' || to_char(l_real, 'FM999G999G999'));
    append_line(l_result, '- Last successful refresh: ' || coalesce(l_last_refresh, 'not refreshed yet'));
    append_line(l_result, '- Source: https://services.ga.gov.au/gis/boreholes/ows feature type bh:Boreholes');
    append_line(l_result);
    append_line(l_result, '## Largest State/Region Groups');

    for r in (
      select coalesce(state_code, 'UNKNOWN') state_code,
             coalesce(region_name, geological_provinces, 'Unknown region') region_label,
             count(*) borehole_count,
             round(avg(depth_metres), 1) avg_depth_metres
        from gs_boreholes
       group by coalesce(state_code, 'UNKNOWN'),
                coalesce(region_name, geological_provinces, 'Unknown region')
       order by count(*) desc
       fetch first 12 rows only
    ) loop
      append_line(l_result, '- ' || r.state_code || ' / ' || r.region_label || ': ' ||
                            to_char(r.borehole_count, 'FM999G999G999') ||
                            ' boreholes, average length ' || coalesce(to_char(r.avg_depth_metres), '-') || ' m');
    end loop;

    return l_result;
  end dataset_summary_markdown;

  procedure append_match_table(p_html in out nocopy clob, p_user_prompt in clob) is
    l_query varchar2(500) := lower(compact_prompt(p_user_prompt));
    l_count number := 0;
  begin
    append_line(p_html, '<div class="gs-bore-section"><h3>Matching Boreholes</h3><div class="gs-bore-table-wrap"><table class="gs-bore-table">');
    append_line(p_html, '<thead><tr><th>Ref</th><th>Name</th><th>State</th><th>Province/Region</th><th>Length</th><th>Report</th></tr></thead><tbody>');

    for r in (
      select borehole_ref,
             borehole_name,
             state_code,
             coalesce(geological_provinces, region_name) region_label,
             depth_metres,
             borehole_report_uri
        from gs_boreholes
       where l_query is null
          or instr(lower(coalesce(borehole_ref, '') || ' ' ||
                         coalesce(borehole_name, '') || ' ' ||
                         coalesce(state_code, '') || ' ' ||
                         coalesce(region_name, '') || ' ' ||
                         coalesce(geological_provinces, '') || ' ' ||
                         coalesce(operator_name, '') || ' ' ||
                         coalesce(purpose, '')), l_query) > 0
       order by updated_at desc
       fetch first 25 rows only
    ) loop
      l_count := l_count + 1;
      append_line(
        p_html,
        '<tr><td><code>' || html_escape(r.borehole_ref) || '</code></td>' ||
        '<td><strong>' || html_escape(r.borehole_name) || '</strong></td>' ||
        '<td>' || html_escape(r.state_code) || '</td>' ||
        '<td>' || html_escape(r.region_label) || '</td>' ||
        '<td>' || coalesce(to_char(r.depth_metres, 'FM999G999G990D0'), '-') || '</td>' ||
        '<td>' || case when r.borehole_report_uri is not null then '<a href="' || apex_escape.html_attribute(r.borehole_report_uri) || '" target="_blank" rel="noopener">Open</a>' end || '</td></tr>'
      );
    end loop;

    if l_count = 0 then
      append_line(p_html, '<tr><td colspan="6">No boreholes matched that prompt in the loaded dataset.</td></tr>');
    end if;

    append_line(p_html, '</tbody></table></div></div>');
  end append_match_table;

  function graphical_insights_html(p_user_prompt in clob, p_model_markdown in clob default null) return clob is
    l_html clob;
    l_total number;
    l_states number;
    l_avg_depth number;
    l_max_depth number;
    l_last_run varchar2(100);
    l_max_count number;
    l_min_lon number;
    l_max_lon number;
    l_min_lat number;
    l_max_lat number;
    l_x number;
    l_y number;
    l_prompt varchar2(4000);
    l_focus_title varchar2(200);
    l_focus_summary varchar2(1000);
  begin
    dbms_lob.createtemporary(l_html, true);
    l_prompt := lower(coalesce(dbms_lob.substr(p_user_prompt, 4000, 1), ''));
    l_focus_title := 'Key insights from the loaded boreholes';
    l_focus_summary := 'Charts are generated directly from GEOSCIENCE schema data so the visual answer remains grounded while the selected model supplies question-specific interpretation.';

    if regexp_like(l_prompt, 'map|spatial|location|where|area|drill') then
      l_focus_title := 'Spatial borehole distribution';
      l_focus_summary := 'The map and location plot are the primary answer for this question; use narrower refresh areas to build state and local drill-down views.';
    elsif regexp_like(l_prompt, 'state|territor|wa|western australia|nsw|queensland|qld|south australia|northern territory|nt') then
      l_focus_title := 'State and territory borehole distribution';
      l_focus_summary := 'The state chart is the primary answer for this question; it shows the current loaded slice is heavily weighted toward Western Australia.';
    elsif regexp_like(l_prompt, 'operator|company|owner') then
      l_focus_title := 'Borehole operators and data quality';
      l_focus_summary := 'The operator chart is the primary answer for this question; unknown or inconsistent operators are useful follow-up targets before drawing prospectivity conclusions.';
    elsif regexp_like(l_prompt, 'length|depth|deep|longest|metre|meter') then
      l_focus_title := 'Borehole length and depth profile';
      l_focus_summary := 'The length profile and longest-record review are the primary answer for this question; missing lengths should be separated from interpreted depth trends.';
    elsif regexp_like(l_prompt, 'purpose|commodity|mineral|gold|copper|iron|groundwater|stratig') then
      l_focus_title := 'Borehole purpose and commodity mix';
      l_focus_summary := 'The purpose chart is the primary answer for this question; it separates mineral exploration, stratigraphic, groundwater, and unclassified records.';
    elsif regexp_like(l_prompt, 'report|source|refresh|wfs|data|quality|missing') then
      l_focus_title := 'Source, refresh, and data-quality evidence';
      l_focus_summary := 'The refresh provenance and quality notes are the primary answer for this question; the visuals stay tied to the loaded Geoscience Australia WFS records.';
    end if;

    select count(*),
           count(distinct state_code),
           round(avg(depth_metres), 1),
           max(depth_metres)
      into l_total, l_states, l_avg_depth, l_max_depth
      from gs_boreholes;

    select max(to_char(finished_at, 'YYYY-MM-DD HH24:MI:SS'))
      into l_last_run
      from gs_data_refresh_runs
     where refresh_type = 'REMOTE_REFRESH'
       and status_code = 'SUCCESS';

    append_line(l_html, '<style>');
    append_line(l_html, '.gs-bore-viz{display:grid;gap:1rem}.gs-bore-viz-hero{border:1px solid #d7dde5;border-radius:8px;background:linear-gradient(135deg,#f7fbff,#eef7f1);padding:1rem}.gs-bore-viz-hero h2{margin:.1rem 0 .35rem;font-size:1.45rem}.gs-bore-viz-hero p{margin:.2rem 0;color:#4e5c6c}.gs-bore-viz-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:1rem}.gs-bore-viz-card{border:1px solid #d7dde5;border-radius:8px;background:#fff;padding:1rem}.gs-bore-viz-card h3{margin:.1rem 0 .7rem;font-size:1rem}.gs-bore-viz-metrics{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:.65rem}.gs-bore-viz-metric{border:1px solid #d7dde5;border-radius:8px;background:#fff;padding:.85rem}.gs-bore-viz-metric span{display:block;color:#5d6876;font-size:.72rem;text-transform:uppercase;font-weight:850}.gs-bore-viz-metric strong{display:block;font-size:1.35rem;margin-top:.2rem}.gs-bore-bar-row{display:grid;grid-template-columns:minmax(5.5rem,.45fr) minmax(0,1fr) auto;gap:.55rem;align-items:center;margin:.45rem 0}.gs-bore-bar-label{font-weight:800;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.gs-bore-bar-track{height:1rem;border-radius:999px;background:#eef2f6;overflow:hidden}.gs-bore-bar-fill{height:100%;border-radius:999px;background:linear-gradient(90deg,#1d6fa5,#2f7d57)}.gs-bore-viz-note{font-size:.85rem;color:#5d6876}.gs-bore-mini-map{border:1px solid #d7dde5;border-radius:8px;background:#f8fbfd;overflow:hidden}.gs-bore-mini-map svg{width:100%;height:auto;display:block}.gs-bore-action-list{display:grid;gap:.5rem;margin:0;padding:0;list-style:none}.gs-bore-action-list li{border-left:4px solid #2f7d57;background:#f7fafc;padding:.55rem .7rem}.gs-bore-narrative{white-space:pre-wrap;max-height:14rem;overflow:auto;background:#f7fafc;border:1px solid #d7dde5;border-radius:8px;padding:.7rem}@media(max-width:900px){.gs-bore-viz-grid,.gs-bore-viz-metrics{grid-template-columns:1fr}}');
    append_line(l_html, '</style>');
    append_line(l_html, '<div class="gs-bore-viz">');
    append_line(l_html, '<section class="gs-bore-viz-hero"><span class="gs-bore-mode">Graphical Boreholes Insight</span><h2>' || html_escape(l_focus_title) || '</h2><p>' || html_escape(l_focus_summary) || '</p></section>');
    append_line(l_html, '<div class="gs-bore-viz-metrics">');
    append_line(l_html, '<div class="gs-bore-viz-metric"><span>Boreholes</span><strong>' || to_char(l_total, 'FM999G999G999') || '</strong></div>');
    append_line(l_html, '<div class="gs-bore-viz-metric"><span>States</span><strong>' || to_char(l_states, 'FM999G999G999') || '</strong></div>');
    append_line(l_html, '<div class="gs-bore-viz-metric"><span>Avg length</span><strong>' || coalesce(to_char(l_avg_depth, 'FM999G999G990D0'), '-') || ' m</strong></div>');
    append_line(l_html, '<div class="gs-bore-viz-metric"><span>Max length</span><strong>' || coalesce(to_char(l_max_depth, 'FM999G999G990D0'), '-') || ' m</strong></div>');
    append_line(l_html, '</div>');
    append_line(l_html, '<div class="gs-bore-viz-grid">');

    append_line(l_html, '<section class="gs-bore-viz-card"><h3>Boreholes by state</h3>');
    select max(cnt)
      into l_max_count
      from (
        select count(*) cnt
          from gs_boreholes
         group by coalesce(state_code, 'Unknown')
      );
    for r in (
      select coalesce(state_code, 'Unknown') label,
             count(*) cnt
        from gs_boreholes
       group by coalesce(state_code, 'Unknown')
       order by count(*) desc, label
       fetch first 8 rows only
    ) loop
      append_line(l_html, '<div class="gs-bore-bar-row"><div class="gs-bore-bar-label">' || html_escape(r.label) || '</div><div class="gs-bore-bar-track"><div class="gs-bore-bar-fill" style="width:' || to_char(round((r.cnt / greatest(l_max_count, 1)) * 100, 1), 'FM990D0', 'NLS_NUMERIC_CHARACTERS=.,') || '%"></div></div><strong>' || to_char(r.cnt, 'FM999G999G999') || '</strong></div>');
    end loop;
    append_line(l_html, '<p class="gs-bore-viz-note">WA dominates the current Tanami/central Australia slice; use this as a prompt to compare narrower BBOX refreshes.</p></section>');

    append_line(l_html, '<section class="gs-bore-viz-card"><h3>Borehole purpose mix</h3>');
    select max(cnt)
      into l_max_count
      from (
        select count(*) cnt
          from gs_boreholes
         group by coalesce(purpose, commodity_group, 'Unknown')
      );
    for r in (
      select coalesce(purpose, commodity_group, 'Unknown') label,
             count(*) cnt
        from gs_boreholes
       group by coalesce(purpose, commodity_group, 'Unknown')
       order by count(*) desc, label
       fetch first 8 rows only
    ) loop
      append_line(l_html, '<div class="gs-bore-bar-row"><div class="gs-bore-bar-label" title="' || apex_escape.html_attribute(r.label) || '">' || html_escape(r.label) || '</div><div class="gs-bore-bar-track"><div class="gs-bore-bar-fill" style="width:' || to_char(round((r.cnt / greatest(l_max_count, 1)) * 100, 1), 'FM990D0', 'NLS_NUMERIC_CHARACTERS=.,') || '%"></div></div><strong>' || to_char(r.cnt, 'FM999G999G999') || '</strong></div>');
    end loop;
    append_line(l_html, '<p class="gs-bore-viz-note">Purpose distribution helps separate mineral exploration, stratigraphic, groundwater, and unclassified records.</p></section>');

    append_line(l_html, '<section class="gs-bore-viz-card"><h3>Length profile</h3>');
    select max(cnt)
      into l_max_count
      from (
        select count(*) cnt
          from (
            select case
                     when depth_metres is null then 5
                     when depth_metres < 50 then 1
                     when depth_metres < 100 then 2
                     when depth_metres < 250 then 3
                     else 4
                   end bucket
              from gs_boreholes
          )
         group by bucket
      );
    for r in (
      select case bucket
               when 1 then '< 50 m'
               when 2 then '50-99 m'
               when 3 then '100-249 m'
               when 4 then '250 m+'
               else 'Unknown'
             end label,
             cnt
        from (
          select case
                   when depth_metres is null then 5
                   when depth_metres < 50 then 1
                   when depth_metres < 100 then 2
                   when depth_metres < 250 then 3
                   else 4
                 end bucket,
                 count(*) cnt
            from gs_boreholes
           group by case
                      when depth_metres is null then 5
                      when depth_metres < 50 then 1
                      when depth_metres < 100 then 2
                      when depth_metres < 250 then 3
                      else 4
                    end
        )
       order by bucket
    ) loop
      append_line(l_html, '<div class="gs-bore-bar-row"><div class="gs-bore-bar-label">' || html_escape(r.label) || '</div><div class="gs-bore-bar-track"><div class="gs-bore-bar-fill" style="width:' || to_char(round((r.cnt / greatest(l_max_count, 1)) * 100, 1), 'FM990D0', 'NLS_NUMERIC_CHARACTERS=.,') || '%"></div></div><strong>' || to_char(r.cnt, 'FM999G999G999') || '</strong></div>');
    end loop;
    append_line(l_html, '<p class="gs-bore-viz-note">Long holes deserve immediate detail/report review; missing lengths should be flagged before analysis claims.</p></section>');

    append_line(l_html, '<section class="gs-bore-viz-card"><h3>Top operators</h3>');
    select max(cnt)
      into l_max_count
      from (
        select count(*) cnt
          from gs_boreholes
         group by coalesce(operator_name, 'Unknown / Not Specified')
      );
    for r in (
      select coalesce(operator_name, 'Unknown / Not Specified') label,
             count(*) cnt
        from gs_boreholes
       group by coalesce(operator_name, 'Unknown / Not Specified')
       order by count(*) desc, label
       fetch first 8 rows only
    ) loop
      append_line(l_html, '<div class="gs-bore-bar-row"><div class="gs-bore-bar-label" title="' || apex_escape.html_attribute(r.label) || '">' || html_escape(r.label) || '</div><div class="gs-bore-bar-track"><div class="gs-bore-bar-fill" style="width:' || to_char(round((r.cnt / greatest(l_max_count, 1)) * 100, 1), 'FM990D0', 'NLS_NUMERIC_CHARACTERS=.,') || '%"></div></div><strong>' || to_char(r.cnt, 'FM999G999G999') || '</strong></div>');
    end loop;
    append_line(l_html, '<p class="gs-bore-viz-note">Operator quality is an early data-quality signal; unknown operators are useful feedback targets.</p></section>');

    append_line(l_html, '</div>');

    append_line(l_html, '<section class="gs-bore-viz-card"><h3>Spatial distribution</h3>');
    begin
      select min(longitude), max(longitude), min(latitude), max(latitude)
        into l_min_lon, l_max_lon, l_min_lat, l_max_lat
        from gs_boreholes
       where latitude is not null
         and longitude is not null;

      append_line(l_html, '<div class="gs-bore-mini-map"><svg viewBox="0 0 720 300" role="img" aria-label="Graphical plot of loaded borehole locations">');
      append_line(l_html, '<rect width="720" height="300" fill="#f8fbfd"/><path d="M35 252C128 206 190 236 274 176c89-64 154-26 244-87 60-40 111-44 164-22v233H35z" fill="#e7f2e8" stroke="#c7dcc9"/>');
      append_line(l_html, '<g fill="none" stroke="#d3dce6" stroke-width="1"><path d="M50 80H680M50 150H680M50 220H680M170 35V265M320 35V265M470 35V265M620 35V265"/></g><g>');
      for r in (
        select borehole_ref, borehole_name, state_code, latitude, longitude, depth_metres
          from gs_boreholes
         where latitude is not null
           and longitude is not null
         order by updated_at desc
         fetch first 120 rows only
      ) loop
        l_x := 55 + ((r.longitude - l_min_lon) / greatest(l_max_lon - l_min_lon, .0001)) * 610;
        l_y := 250 - ((r.latitude - l_min_lat) / greatest(l_max_lat - l_min_lat, .0001)) * 205;
        append_line(l_html, '<circle cx="' || to_char(round(l_x, 1), 'FM9990D0', 'NLS_NUMERIC_CHARACTERS=.,') || '" cy="' || to_char(round(l_y, 1), 'FM9990D0', 'NLS_NUMERIC_CHARACTERS=.,') || '" r="' || case when coalesce(r.depth_metres, 0) >= 250 then '6' else '4' end || '" fill="#1d6fa5" opacity=".8"><title>' || html_escape(r.borehole_name || ' (' || r.borehole_ref || ') ' || r.state_code || ' ' || r.depth_metres || 'm') || '</title></circle>');
      end loop;
      append_line(l_html, '</g><text x="55" y="285" fill="#5d6876" font-size="13">Lon ' || html_escape(to_char(round(l_min_lon, 2))) || ' to ' || html_escape(to_char(round(l_max_lon, 2))) || ', Lat ' || html_escape(to_char(round(l_min_lat, 2))) || ' to ' || html_escape(to_char(round(l_max_lat, 2))) || '</text></svg></div>');
    exception
      when others then
        append_line(l_html, '<p>No coordinate-bearing boreholes are loaded yet.</p>');
    end;
    append_line(l_html, '</section>');

    append_line(l_html, '<section class="gs-bore-viz-card"><h3>Recommended next actions</h3><ul class="gs-bore-action-list">');
    append_line(l_html, '<li>Open the longest borehole reports and compare purpose/operator consistency.</li>');
    append_line(l_html, '<li>Refresh a narrower BBOX around the densest cluster to reduce mixed regional signals.</li>');
    append_line(l_html, '<li>Ask the assistant to compare state, purpose, operator, or province slices shown in the charts.</li>');
    append_line(l_html, '<li>Flag missing operator/length values as data-quality follow-up before prospectivity claims.</li>');
    append_line(l_html, '</ul><p class="gs-bore-viz-note">Last successful refresh: ' || html_escape(coalesce(l_last_run, 'Pending')) || '. Source: Geoscience Australia Boreholes WFS, feature type bh:Boreholes.</p></section>');

    if p_model_markdown is not null then
      append_line(l_html, '<section class="gs-bore-viz-card"><h3>AI interpretation from selected model</h3><div class="gs-bore-narrative">' || html_escape(dbms_lob.substr(p_model_markdown, 3000, 1)) || '</div></section>');
    end if;

    append_line(l_html, '</div>');
    return l_html;
  end graphical_insights_html;

  function deterministic_answer_html(p_user_prompt in clob) return clob is
    l_html clob;
    l_total number;
    l_states number;
    l_last_run varchar2(100);
  begin
    dbms_lob.createtemporary(l_html, true);

    select count(*), count(distinct state_code)
      into l_total, l_states
      from gs_boreholes;

    select max(to_char(finished_at, 'YYYY-MM-DD HH24:MI:SS'))
      into l_last_run
      from gs_data_refresh_runs
     where refresh_type = 'REMOTE_REFRESH'
       and status_code = 'SUCCESS';

    append_line(l_html, '<div class="gs-bore-answer">');
    append_line(l_html, '<div class="gs-bore-answer-head"><span class="gs-bore-mode">Deterministic Boreholes Explorer</span>');
    append_line(l_html, '<h2>Borehole data answer</h2><p>This fallback is grounded directly in the loaded GEOSCIENCE schema tables.</p></div>');
    append_line(l_html, '<div class="gs-bore-stats"><div><span>Boreholes</span><strong>' || to_char(l_total, 'FM999G999G999') || '</strong></div><div><span>States</span><strong>' || to_char(l_states, 'FM999G999G999') || '</strong></div><div><span>Last refresh</span><strong>' || html_escape(coalesce(l_last_run, 'Pending')) || '</strong></div></div>');
    append_match_table(l_html, p_user_prompt);
    append_line(l_html, '</div>');
    return l_html;
  end deterministic_answer_html;

  function build_ai_context(p_user_prompt in clob, p_screen_context in clob default null) return clob is
    l_context clob;
  begin
    dbms_lob.createtemporary(l_context, true);
    append_line(l_context, 'You are the Geoscience Boreholes Agent in an Oracle APEX demo.');
    append_line(l_context, 'Answer from the supplied Geoscience Australia boreholes context only. If the data cannot answer the question, say what is missing.');
    append_line(l_context, 'Return 3 to 5 concise plain-text observations only. Do not return Mermaid, code fences, chart syntax, or large tables: the APEX UI renders grounded charts separately. Do not invent boreholes, coordinates, source URLs, or production claims.');
    append_line(l_context);
    append_line(l_context, dataset_summary_markdown);
    append_line(l_context);
    append_line(l_context, '## Recent/Loaded Borehole Rows');

    for r in (
      select borehole_ref, borehole_name, state_code, latitude, longitude, depth_metres,
             purpose, operator_name, data_custodian, geological_provinces, borehole_report_uri
        from gs_boreholes
       order by updated_at desc
       fetch first 40 rows only
    ) loop
      append_line(l_context, '- ' || r.borehole_ref || ': ' || r.borehole_name ||
                            ' | state: ' || r.state_code ||
                            ' | lat/lon: ' || r.latitude || ', ' || r.longitude ||
                            ' | length_m: ' || r.depth_metres ||
                            ' | purpose: ' || r.purpose ||
                            ' | operator: ' || r.operator_name ||
                            ' | province: ' || r.geological_provinces ||
                            ' | report: ' || r.borehole_report_uri);
    end loop;

    if p_screen_context is not null then
      append_line(l_context);
      append_line(l_context, '## Current Screen Or Pasted Context');
      append_line(l_context, dbms_lob.substr(p_screen_context, 3000, 1));
    end if;

    append_line(l_context);
    append_line(l_context, '## User Question');
    append_line(l_context, dbms_lob.substr(p_user_prompt, 3000, 1));
    return l_context;
  end build_ai_context;

  function ask_json(
    p_user_prompt       in clob,
    p_service_static_id in varchar2 default null,
    p_screen_context    in clob default null
  ) return clob is
    l_json clob;
    l_answer_markdown clob;
    l_answer_html clob;
    l_error varchar2(1000);
    l_service_static_id varchar2(255);
    l_messages apex_ai.t_chat_messages := apex_ai.c_chat_messages;
  begin
    if p_user_prompt is null or dbms_lob.getlength(p_user_prompt) = 0 then
      raise_application_error(-20160, 'Ask a Boreholes question before sending.');
    end if;

    l_service_static_id := coalesce(valid_service_static_id(p_service_static_id), default_service_static_id);

    if l_service_static_id is not null then
      begin
        l_answer_markdown := apex_ai.chat(
          p_prompt => build_ai_context(p_user_prompt, p_screen_context),
          p_system_prompt => 'You are the Geoscience Boreholes Agent. Answer from supplied borehole data only. Be concise and cite loaded fields. Do not output Mermaid, code fences, or raw chart syntax because the APEX app renders graphical charts separately.',
          p_service_static_id => l_service_static_id,
          p_temperature => 0.2,
          p_messages => l_messages
        );
      exception
        when others then
          l_error := substr(sqlerrm, 1, 1000);
          l_answer_markdown := null;
      end;
    end if;

    l_answer_html := graphical_insights_html(p_user_prompt, l_answer_markdown);

    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write('success', true);
    apex_json.write('mode', case when l_answer_markdown is not null then 'APEX_AI' else 'DETERMINISTIC_FALLBACK' end);
    apex_json.write('aiError', l_error);
    apex_json.write('selectedServiceStaticId', l_service_static_id);
    apex_json.write('selectedServiceName', service_name_for_static_id(l_service_static_id));
    apex_json.write('answerMarkdown', l_answer_markdown);
    apex_json.write('answerHtml', l_answer_html);
    apex_json.write('supportingHtml', deterministic_answer_html(p_user_prompt));
    apex_json.close_object;
    l_json := apex_json.get_clob_output;
    apex_json.free_output;
    return l_json;
  exception
    when others then
      apex_json.initialize_clob_output;
      apex_json.open_object;
      apex_json.write('success', false);
      apex_json.write('message', substr(sqlerrm, 1, 1000));
      apex_json.close_object;
      l_json := apex_json.get_clob_output;
      apex_json.free_output;
      return l_json;
  end ask_json;
end gs_borehole_agent_api;
/

prompt Geoscience 009 complete
