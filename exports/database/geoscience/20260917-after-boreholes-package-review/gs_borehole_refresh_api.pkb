CREATE OR REPLACE package body gs_borehole_refresh_api as
  c_source_name constant varchar2(200) := 'Geoscience Australia Boreholes WFS';
  c_source_url  constant varchar2(1000) := 'https://services.ga.gov.au/gis/boreholes/ows';
  c_transfer_timeout constant pls_integer := 30;
  c_max_response_chars constant pls_integer := 30000000;

  -- No commits or autonomous transactions: the caller owns diagnostic durability.
  function elapsed_ms(p_start in number) return number is
  begin
    return mod(dbms_utility.get_time - p_start + 4294967296, 4294967296) * 10;
  end elapsed_ms;

  procedure validate_limit(p_limit in number) is
  begin
    if p_limit is null or p_limit <> trunc(p_limit) or p_limit not between 1 and 10000 then
      raise_application_error(-20151, 'Limit must be a whole number from 1 to 10000.');
    end if;
  end validate_limit;

  procedure validate_bbox(p_min_lon in number, p_min_lat in number,
                          p_max_lon in number, p_max_lat in number) is
  begin
    if p_min_lon is null or p_min_lat is null or p_max_lon is null or p_max_lat is null
       or p_min_lon not between -180 and 180 or p_max_lon not between -180 and 180
       or p_min_lat not between -90 and 90 or p_max_lat not between -90 and 90
       or round(p_min_lon, 6) >= round(p_max_lon, 6)
       or round(p_min_lat, 6) >= round(p_max_lat, 6) then
      raise_application_error(-20152, 'BBOX requires valid longitude/latitude ranges and minima below maxima.');
    end if;
  end validate_bbox;
 
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
      raise_application_error(-20155, 'A borehole numeric field is invalid.');
  end clean_number; 
 
  function clean_date(p_value in varchar2) return date is 
  begin 
    if clean_text(p_value) is null then 
      return null; 
    end if; 
    return to_date(substr(p_value, 1, 10), 'FXYYYY-MM-DD');
  exception
    when others then
      raise_application_error(-20155, 'A borehole date must have a valid YYYY-MM-DD date portion.');
  end clean_date; 
 
  function source_id return number is
    l_source_id number;
  begin
    select source_id
      into l_source_id
      from gs_borehole_sources
     where source_name = c_source_name;
    return l_source_id;
  exception
    when no_data_found then
      insert into gs_borehole_sources(source_name, source_url, source_status, notes)
      values (c_source_name, c_source_url, 'PLANNED', 'OGC WFS feature type bh:Boreholes.')
      returning source_id into l_source_id;
      return l_source_id;
  end source_id;

  function start_run(p_request_url in varchar2, p_bbox_text in varchar2,
                     p_limit in number, p_notes in varchar2) return number is
    l_source_id number := source_id;
    l_run_id number;
  begin
    insert into gs_data_refresh_runs (
      source_id, refresh_type, status_code, source_url, request_url, feature_type,
      bbox_text, requested_limit, message
    ) values (
      l_source_id, 'REMOTE_REFRESH', 'STARTED', c_source_url, p_request_url, 'bh:Boreholes',
      p_bbox_text, p_limit, substr(p_notes, 1, 2000)
    ) returning refresh_run_id into l_run_id;
    return l_run_id;
  end start_run;

  procedure fail_run(p_run_id in number, p_message in varchar2, p_rejected in number default 0) is
  begin
    update gs_data_refresh_runs
       set status_code = 'FAILED', finished_at = systimestamp,
           rows_loaded = 0, rows_rejected = p_rejected,
           message = substr(p_message, 1, 2000)
     where refresh_run_id = p_run_id;
  end fail_run;
 
  function wfs_request_url( 
    p_min_lon in number default 129, 
    p_min_lat in number default -24, 
    p_max_lon in number default 139, 
    p_max_lat in number default -17, 
    p_limit   in number default 250 
  ) return varchar2 is
  begin
    validate_limit(p_limit);
    validate_bbox(p_min_lon, p_min_lat, p_max_lon, p_max_lat);
    return c_source_url ||
           '?service=WFS&version=2.0.0&request=GetFeature&typeNames=bh%3ABoreholes&outputFormat=application%2Fjson' || 
           '&count=' || to_char(p_limit, 'FM99990') ||
           '&bbox=' || nfmt(p_min_lon) || ',' || nfmt(p_min_lat) || ',' || 
           nfmt(p_max_lon) || ',' || nfmt(p_max_lat) || ',EPSG%3A4326'; 
  end wfs_request_url; 
 
  function apply_geojson(
    p_geojson in clob,
    p_run_id in number,
    p_limit in number
  ) return number is
    l_source_id number;
    l_refresh_run_id number := p_run_id;
    l_count number := 0;
    l_loaded number := 0;
    l_row_in_progress boolean := false;
    type t_seen_refs is table of boolean index by varchar2(100);
    l_seen_refs t_seen_refs;
    l_values apex_json.t_values;
    l_value apex_json.t_value;
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

    function prop_varchar(p_index in pls_integer, p_name in varchar2) return varchar2 is
    begin
      return clean_text(apex_json.get_varchar2(
        p_path => 'features[%d].properties.' || p_name, p0 => p_index, p_values => l_values));
    end prop_varchar;

    function prop_number(p_index in pls_integer, p_name in varchar2) return number is
    begin
      return clean_number(prop_varchar(p_index, p_name));
    end prop_number;
  begin
    -- Retain the attempt row, but undo the entire batch if any feature fails.
    savepoint gs_borehole_batch;
    validate_limit(p_limit);
    if p_geojson is null or dbms_lob.getlength(p_geojson) = 0 then
      raise_application_error(-20150, 'Boreholes GeoJSON payload is required.');
    end if;
    if dbms_lob.getlength(p_geojson) > c_max_response_chars then
      raise_application_error(-20153, 'Boreholes response exceeds the 30 million character limit.');
    end if;

    select source_id into l_source_id from gs_data_refresh_runs where refresh_run_id = p_run_id;
    apex_json.parse(p_values => l_values, p_source => p_geojson);
    if nvl(apex_json.get_varchar2(p_path => 'type', p_values => l_values), '?') <> 'FeatureCollection' then
      raise_application_error(-20154, 'Expected a GeoJSON FeatureCollection.');
    end if;
    l_value := apex_json.get_value(p_path => 'features', p_values => l_values);
    if l_value.kind is null or l_value.kind <> apex_json.c_array then
      raise_application_error(-20154, 'GeoJSON features must be an array; an empty array is valid.');
    end if;
    l_count := l_value.number_value;
    if l_count > p_limit then
      raise_application_error(-20154, 'GeoJSON feature count exceeds the requested limit.');
    end if;

    for i in 1 .. l_count loop
      l_row_in_progress := true;
      if nvl(apex_json.get_varchar2(p_path => 'features[%d].type', p0 => i, p_values => l_values), '?') <> 'Feature' then
        raise_application_error(-20154, 'Every GeoJSON entry must be a Feature.');
      end if;
      l_value := apex_json.get_value(p_path => 'features[%d].properties', p0 => i, p_values => l_values);
      if l_value.kind is null or l_value.kind <> apex_json.c_object then
        raise_application_error(-20154, 'Every borehole Feature requires a properties object.');
      end if;
      l_ref := coalesce(
        prop_varchar(i, 'ENO'), 
        prop_varchar(i, 'IDENTIFIER'), 
        prop_varchar(i, 'GMLID')
      );
      if l_ref is null then
        raise_application_error(-20155, 'A borehole requires a stable ENO, IDENTIFIER or GMLID.');
      end if;
      if l_seen_refs.exists(l_ref) then
        raise_application_error(-20155, 'A GeoJSON batch contains a repeated borehole identifier.');
      end if;
      l_seen_refs(l_ref) := true;
      l_name := coalesce(prop_varchar(i, 'NAME'), l_ref); 
      l_year := to_number(to_char(clean_date(coalesce(prop_varchar(i, 'DRILLSTARTDATE'), prop_varchar(i, 'DRILLENDDATE'))), 'YYYY')); 
      l_state_code := prop_varchar(i, 'STATE'); 
      l_state_name := prop_varchar(i, 'STATE'); 
      l_region_name := substr(coalesce(prop_varchar(i, 'GEOLOGICAL_PROVINCES'), prop_varchar(i, 'SOURCE')), 1, 160); 
      l_latitude := prop_number(i, 'COLLAR_LAT_GDA94'); 
      l_longitude := prop_number(i, 'COLLAR_LONG_GDA94'); 
      l_depth_metres := prop_number(i, 'BOREHOLELENGTH_M');
      if (l_latitude is null and l_longitude is not null)
         or (l_longitude is null and l_latitude is not null)
         or l_latitude not between -90 and 90 or l_longitude not between -180 and 180
         or l_depth_metres < 0 then
        raise_application_error(-20155, 'A borehole has invalid coordinates or a negative length.');
      end if;
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
          l_latitude, l_longitude, l_depth_metres, l_year, l_commodity_group,
          case when upper(l_source_status) like '%ABANDON%' then 'HISTORIC' else 'ACTIVE' end,
          l_external_id, l_identifier_uri, l_purpose, l_operator_name, l_driller_name, 
          l_drill_start_date, l_drill_end_date, l_elevation_m, l_positional_accuracy, 
          l_data_custodian, l_geological_provinces, l_metadata_uri, l_borehole_report_uri, 
          l_qa_status, l_refresh_run_id, systimestamp 
        ); 
      end if; 
 
      l_loaded := l_loaded + 1;
      l_row_in_progress := false;
    end loop; 
 
    update gs_data_refresh_runs 
       set status_code = 'SUCCESS', 
           finished_at = systimestamp, 
           rows_loaded = l_loaded, 
           rows_rejected = 0,
           -- Historical RESPONSE_BYTES stores CLOB characters, not wire bytes.
           response_bytes = dbms_lob.getlength(p_geojson),
           message = case when l_count = 0 then 'Valid empty FeatureCollection; no boreholes changed.'
                     else 'Loaded ' || l_loaded || ' boreholes from Geoscience Australia WFS.' end
     where refresh_run_id = l_refresh_run_id; 
 
    update gs_borehole_sources 
       set last_refresh_at = systimestamp, 
           source_status = 'ACTIVE', 
           updated_at = systimestamp 
     where source_id = l_source_id; 
 
    return l_loaded;
  exception
    when others then
      l_error_message := substr(sqlerrm, 1, 1800);
      rollback to gs_borehole_batch;
      fail_run(p_run_id, l_error_message || ' Batch rolled back; no boreholes changed.',
               case when l_row_in_progress then 1 else 0 end);
      raise;
  end apply_geojson;

  function load_geojson_clob(
    p_geojson     in clob,
    p_request_url in varchar2,
    p_bbox_text   in varchar2,
    p_limit       in number,
    p_notes       in varchar2 default null
  ) return number is
    l_run_id number;
    l_loaded number;
  begin
    validate_limit(p_limit);
    l_run_id := start_run(p_request_url, p_bbox_text, p_limit, p_notes);
    l_loaded := apply_geojson(p_geojson, l_run_id, p_limit);
    return l_run_id;
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
    l_rows_loaded number := 0;
    l_rows_rejected number := 0;
    l_http_status number;
    l_started number := dbms_utility.get_time;
    l_download_started number;
    l_load_started number;
    l_download_ms number := 0;
    l_load_ms number := 0;
    l_error varchar2(1000);
    l_sqlcode number;
    l_error_code varchar2(40);
    l_user_message varchar2(500);

    function result_json(p_success in boolean, p_message in varchar2) return clob is
      l_json clob;
    begin
      apex_json.initialize_clob_output;
      apex_json.open_object;
      apex_json.write('success', p_success);
      apex_json.write('refreshRunId', l_run_id);
      apex_json.write('requestUrl', l_url);
      apex_json.write('rowsLoaded', l_rows_loaded);
      apex_json.write('rowsRejected', l_rows_rejected);
      apex_json.write('emptyResult', p_success and l_rows_loaded = 0);
      apex_json.write('httpStatus', l_http_status);
      apex_json.write('errorCode', l_error_code);
      apex_json.write('responseCharacters', nvl(dbms_lob.getlength(l_response), 0));
      apex_json.write('transferTimeoutSeconds', c_transfer_timeout);
      apex_json.open_object('timingMs');
      apex_json.write('download', l_download_ms);
      apex_json.write('load', l_load_ms);
      apex_json.write('total', elapsed_ms(l_started));
      apex_json.close_object;
      apex_json.write('message', p_message);
      apex_json.close_object;
      -- Copy before freeing APEX_JSON's temporary output locator.
      dbms_lob.createtemporary(l_json, true, dbms_lob.call);
      dbms_lob.append(l_json, apex_json.get_clob_output);
      apex_json.free_output;
      return l_json;
    end result_json;
  begin
    l_url := wfs_request_url(p_min_lon, p_min_lat, p_max_lon, p_max_lat, p_limit);
    l_bbox := nfmt(p_min_lon) || ',' || nfmt(p_min_lat) || ',' || nfmt(p_max_lon) || ',' || nfmt(p_max_lat);
    -- This row starts the complete attempt, including HTTP wait and HTTP failure.
    l_run_id := start_run(l_url, l_bbox, p_limit, 'Triggered from Boreholes Data Refresh page.');
    savepoint gs_borehole_attempt;
    l_download_started := dbms_utility.get_time;
    l_response := apex_web_service.make_rest_request(
      p_url => l_url, p_http_method => 'GET', p_transfer_timeout => c_transfer_timeout);
    l_download_ms := elapsed_ms(l_download_started);
    l_http_status := apex_web_service.g_status_code;
    if l_http_status is null or l_http_status not between 200 and 299 then
      raise_application_error(-20156, 'Boreholes WFS HTTP request failed (status ' || nvl(to_char(l_http_status), 'unknown') || ').');
    end if;

    l_load_started := dbms_utility.get_time;
    l_rows_loaded := apply_geojson(l_response, l_run_id, p_limit);
    l_load_ms := elapsed_ms(l_load_started);
    return result_json(true, case when l_rows_loaded = 0
      then 'Refresh complete: the requested area returned no boreholes; existing data is unchanged.'
      else 'Boreholes refreshed from Geoscience Australia WFS.' end);
  exception
    when others then
      l_sqlcode := sqlcode;
      l_error := substr(sqlerrm, 1, 1000);
      if l_load_started is not null then
        l_load_ms := elapsed_ms(l_load_started);
      elsif l_download_started is not null then
        l_download_ms := elapsed_ms(l_download_started);
      end if;
      l_rows_loaded := 0;
      if l_run_id is not null then
        select rows_rejected into l_rows_rejected
          from gs_data_refresh_runs where refresh_run_id = l_run_id;
        -- Also covers an error while serializing a successful load result.
        -- Read the first rejected-row count before undoing loader diagnostics.
        rollback to gs_borehole_attempt;
        fail_run(l_run_id, l_error, l_rows_rejected);
      end if;
      if l_sqlcode = -20151 then
        l_error_code := 'INVALID_REQUEST';
        l_user_message := 'Limit must be a whole number from 1 to 10000.';
      elsif l_sqlcode = -20152 then
        l_error_code := 'INVALID_REQUEST';
        l_user_message := 'Enter valid longitude/latitude ranges with minima below maxima.';
      elsif l_load_started is not null then
        l_error_code := 'SOURCE_RESPONSE_INVALID';
        l_user_message := 'The source response could not be loaded. No boreholes changed. Use the refresh run number when reporting this issue.';
      elsif l_sqlcode = -20156 then
        l_error_code := 'SOURCE_HTTP_ERROR';
        l_user_message := 'Geoscience Australia WFS returned an unsuccessful response. Please try again later.';
      elsif l_download_started is not null then
        l_error_code := 'SOURCE_UNAVAILABLE';
        l_user_message := 'The Geoscience Australia WFS request could not be completed. Please try again later.';
      else
        l_error_code := 'REFRESH_FAILED';
        l_user_message := 'Refresh could not start. Please try again or ask an administrator.';
      end if;
      return result_json(false, l_user_message);
  end remote_refresh_json;
end gs_borehole_refresh_api;
/
