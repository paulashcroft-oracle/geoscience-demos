-- Read-only installed API acceptance: CODEX / tcelkxkd / no APEX session.
-- Review the installed allowlist against D009 before running: every call uses
-- BH_TEST_NO_PROVIDER, which must remain unallowlisted (no HTTP/model calls).
-- Requires SELECT on GEOSCIENCE.GS_BOREHOLES and EXECUTE on the installed API.
-- No DDL, DML, commits, APEX session creation, or map-URL acceptance.
-- Run without concurrent data refresh/edit; only counts/timings are printed.
declare
  l_checks pls_integer := 0;
  l_calls pls_integer := 0;
  l_total number;
  l_expected number;
  l_newer number;
  l_rank_count pls_integer := 0;
  l_previous integer := 0;
  l_position integer;
  l_state varchar2(20);
  l_label varchar2(4000);
  l_filter varchar2(4000);
  l_old_ref geoscience.gs_boreholes.borehole_ref%type;
  l_json clob;
  l_copy clob;
  l_first_json clob;
  l_first_copy clob;
  l_html clob;
  l_object json_object_t;
  l_request_ids varchar2(4000) := '|';
  l_total_ms number := 0;
  l_max_ms number := 0;

  procedure check_true(p_ok boolean, p_label varchar2) is
  begin
    if p_ok is null or not p_ok then
      raise_application_error(-20990, 'Installed agent: case ' || l_calls || ' / ' || p_label);
    end if;
    l_checks := l_checks + 1;
  end;

  function num(p_value number) return varchar2 is
  begin
    return to_char(p_value, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
  end;

  procedure free_clob(p_value in out nocopy clob) is
  begin
    if dbms_lob.istemporary(p_value) = 1 then dbms_lob.freetemporary(p_value); end if;
    p_value := null;
  end;

  procedure cleanup is
  begin
    free_clob(l_html);
    if l_calls > 1 then free_clob(l_json); end if;
    free_clob(l_first_json);
    free_clob(l_first_copy);
    free_clob(l_copy);
  end;

  procedure ask(p_prompt varchar2, p_intent varchar2, p_rows number,
    p_status varchar2 default 'OK', p_mode varchar2 default 'DETERMINISTIC') is
    l_timings json_object_t;
    l_id varchar2(32);
    l_actual_rows number;
    l_context number;
    l_provider number;
    l_render number;
    l_elapsed number;
  begin
    free_clob(l_html);
    if l_calls > 1 then free_clob(l_json); end if;
    l_json := geoscience.gs_borehole_agent_api.ask_json(
      p_user_prompt => p_prompt, p_service_static_id => 'BH_TEST_NO_PROVIDER',
      p_screen_context => null);
    l_calls := l_calls + 1;
    dbms_lob.trim(l_copy, 0);
    dbms_lob.append(l_copy, l_json);
    if l_calls = 1 then
      l_first_json := l_json;
      dbms_lob.append(l_first_copy, l_json);
    end if;
    l_object := json_object_t.parse(l_json);
    check_true(l_object.get_boolean('success') and l_object.get_string('intent') = p_intent
      and l_object.get_string('status') = p_status and l_object.get_string('mode') = p_mode,
      'success and classification');
    l_actual_rows := l_object.get_number('matchedRows');
    if p_rows is null then
      check_true(l_actual_rows is null, 'no database match claim');
    else
      check_true(l_actual_rows = p_rows, 'matchedRows equals independent SQL');
    end if;
    l_id := l_object.get_string('requestId');
    check_true(regexp_like(l_id, '^[0-9a-f]{32}$')
      and instr(l_request_ids, '|' || l_id || '|') = 0, 'fresh request ID');
    l_request_ids := l_request_ids || l_id || '|';
    check_true(l_object.get_string('selectedServiceStaticId') is null
      and l_object.get_string('selectedServiceName') is null
      and l_object.get_string('answerMarkdown') is null, 'no generated answer or model claim');
    l_timings := l_object.get_object('timings');
    l_context := l_timings.get_number('contextMs');
    l_provider := l_timings.get_number('providerMs');
    l_render := l_timings.get_number('renderMs');
    l_elapsed := l_timings.get_number('totalMs');
    check_true(l_context >= 0 and l_provider >= 0 and l_render >= 0
      and l_elapsed >= l_context + l_provider + l_render, 'complete nonnegative timings');
    if p_mode = 'DETERMINISTIC' then
      check_true(l_provider = 0 and l_object.get_number('contextChars') = 0
        and l_object.get_string('aiError') is null, 'deterministic bypass');
    else
      -- providerMs includes allowlist validation; it need not be exactly zero.
      check_true(l_object.get_number('contextChars') > 0
        and l_object.get_string('aiError') = 'SERVICE_UNAVAILABLE', 'safe unavailable-service fallback');
    end if;
    l_html := l_object.get_clob('answerHtml');
    check_true(dbms_lob.getlength(l_html) > 0 and dbms_lob.compare(l_json, l_copy) = 0,
      'complete HTML and unchanged parsed JSON CLOB');
    if p_rows is not null then
      check_true(dbms_lob.instr(l_html, 'Matching boreholes: ' || num(p_rows) || '.') > 0,
        'visible count equals independent SQL');
    end if;
    l_total_ms := l_total_ms + l_elapsed;
    l_max_ms := greatest(l_max_ms, l_elapsed);
  end;

  procedure check_leader(p_label varchar2, p_count number) is
    l_start integer := dbms_lob.instr(l_html, '<div class="gs-bore-bar-row">');
    l_end integer;
    l_row varchar2(32767);
  begin
    check_true(l_start > 0, 'group chart exists');
    l_end := dbms_lob.instr(l_html, '</div>', l_start);
    l_row := dbms_lob.substr(l_html, l_end - l_start + 6, l_start);
    check_true(instr(l_row, '>' || apex_escape.html(p_label) || '</span>') > 0
      and instr(l_row, '<strong>' || num(p_count) || '</strong>') > 0,
      'leading group and count equal independent SQL');
  end;
begin
  check_true(sys_context('USERENV', 'SESSION_USER') = 'CODEX'
    and lower(sys_context('USERENV', 'DB_UNIQUE_NAME')) = 'tcelkxkd', 'execution identity');
  check_true(nvl(apex_application.g_instance, 0) = 0
    and nvl(sys_context('APEX$SESSION', 'APP_SESSION'), '0') = '0', 'no APEX session');
  dbms_lob.createtemporary(l_copy, true, dbms_lob.call);
  dbms_lob.createtemporary(l_first_copy, true, dbms_lob.call);
  select count(*) into l_total from geoscience.gs_boreholes;
  check_true(l_total > 75, 'dataset can exercise records beyond former sample');
  ask('count loaded boreholes', 'COUNT', l_total);

  select upper(state_code), count(*) into l_state, l_expected
    from geoscience.gs_boreholes
   where upper(state_code) in ('WA', 'NT', 'NSW', 'QLD', 'SA', 'VIC', 'TAS', 'ACT')
   group by upper(state_code) order by count(*) desc, upper(state_code) fetch first 1 row only;
  ask('count boreholes in ' || l_state, 'COUNT', l_expected);
  select coalesce(state_code, 'Unknown'), count(*) into l_label, l_expected
    from geoscience.gs_boreholes group by coalesce(state_code, 'Unknown')
   order by count(*) desc, coalesce(state_code, 'Unknown') fetch first 1 row only;
  ask('chart count by state', 'STATE', l_total);
  check_leader(l_label, l_expected);

  select coalesce(operator_name, 'Unknown'), count(*) into l_label, l_expected
    from geoscience.gs_boreholes group by coalesce(operator_name, 'Unknown')
   order by count(*) desc, coalesce(operator_name, 'Unknown') fetch first 1 row only;
  ask('chart count by operator', 'OPERATOR', l_total);
  check_leader(l_label, l_expected);
  select operator_name into l_filter from geoscience.gs_boreholes
   where operator_name is not null and instr(operator_name, '"') = 0
     and operator_name = trim(regexp_replace(operator_name, '[[:space:]]+', ' '))
   group by operator_name order by count(*) desc, operator_name fetch first 1 row only;
  select count(*) into l_expected from geoscience.gs_boreholes where lower(operator_name) = lower(l_filter);
  ask('count operator "' || l_filter || '"', 'COUNT', l_expected);

  select coalesce(purpose, 'Unknown'), count(*) into l_label, l_expected
    from geoscience.gs_boreholes group by coalesce(purpose, 'Unknown')
   order by count(*) desc, coalesce(purpose, 'Unknown') fetch first 1 row only;
  ask('count by purpose', 'PURPOSE', l_total);
  check_leader(l_label, l_expected);
  select purpose into l_filter from geoscience.gs_boreholes
   where purpose is not null and instr(purpose, '"') = 0
     and purpose = trim(regexp_replace(purpose, '[[:space:]]+', ' '))
   group by purpose order by count(*) desc, purpose fetch first 1 row only;
  select count(*) into l_expected from geoscience.gs_boreholes where lower(purpose) = lower(l_filter);
  ask('count purpose "' || l_filter || '"', 'COUNT', l_expected);

  ask('top 5 longest boreholes', 'LONGEST', l_total);
  for r in (
    select borehole_ref from geoscience.gs_boreholes where depth_metres is not null
     order by depth_metres desc, borehole_ref, borehole_id fetch first 5 rows only
  ) loop
    l_position := dbms_lob.instr(l_html, '<tr><td>' || apex_escape.html(r.borehole_ref) || '</td>', l_previous + 1);
    check_true(l_position > l_previous, 'ranked reference order equals SQL');
    l_previous := l_position;
    l_rank_count := l_rank_count + 1;
  end loop;
  check_true(l_rank_count = 5 and regexp_count(l_html, '<tr><td>') = 5, 'exactly five known-length records');

  -- Strictly newer timestamps prove exclusion regardless of ties in the former
  -- Explorer ORDER BY updated_at DESC FETCH FIRST 75 ROWS ONLY.
  select b.borehole_ref, (select count(*) from geoscience.gs_boreholes n where n.updated_at > b.updated_at)
    into l_old_ref, l_newer from geoscience.gs_boreholes b
   where length(b.borehole_ref) <= 100 and regexp_like(b.borehole_ref, '^[[:alnum:]_.:/-]+$')
     and (select count(*) from geoscience.gs_boreholes n where n.updated_at > b.updated_at) >= 75
   order by b.updated_at, b.borehole_id fetch first 1 row only;
  select count(*) into l_expected from geoscience.gs_boreholes where lower(borehole_ref) = lower(l_old_ref);
  ask('ref "' || l_old_ref || '"', 'RECORD', l_expected);
  check_true(l_newer >= 75 and dbms_lob.instr(l_html, '<td>' || apex_escape.html(l_old_ref) || '</td>') > 0,
    'older reference retrieved beyond former sample');

  ask('count boreholes drilled after 2000', 'CLARIFY', null, 'CLARIFICATION_REQUIRED');
  check_true(dbms_lob.instr(l_html, 'Matching boreholes:') = 0, 'unsupported filter never broadens scope');
  ask('what about those?', 'CLARIFY', null, 'CLARIFICATION_REQUIRED');
  check_true(dbms_lob.instr(l_html, 'Each question is independent.') > 0, 'follow-up asks for complete question');
  ask('explain count by state', 'STATE', l_total, 'SERVICE_UNAVAILABLE', 'DETERMINISTIC_FALLBACK');
  check_true(dbms_lob.instr(l_html, 'Boreholes by state') > 0
    and dbms_lob.instr(l_html, 'calculated directly from the loaded records.') > 0,
    'explanation fallback retains authoritative evidence');
  ask('summarize pasted text: Synthetic acceptance text.', 'TEXT', null,
    'SERVICE_UNAVAILABLE', 'DETERMINISTIC_FALLBACK');
  check_true(dbms_lob.instr(l_html, 'No interpretation of your pasted text was generated.') > 0
    and dbms_lob.instr(l_html, 'It is not verified against loaded borehole records.') > 0
    and dbms_lob.instr(l_html, 'Matching boreholes:') = 0, 'pasted-text fallback is truthful');
  check_true(dbms_lob.compare(l_first_json, l_first_copy) = 0,
    'first returned JSON CLOB survives subsequent calls unchanged');
  cleanup;
  dbms_output.put_line('PASS installed agent: checks=' || l_checks || ', calls=' || l_calls
    || ', loaded_rows=' || num(l_total) || ', ranked_rows=' || l_rank_count
    || ', newer_than_selected_ref=' || num(l_newer)
    || ', total_server_ms=' || num(l_total_ms) || ', max_server_ms=' || num(l_max_ms));
exception
  when others then
    cleanup;
    raise;
end;
/
