CREATE OR REPLACE package body gs_borehole_refresh_api as
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
