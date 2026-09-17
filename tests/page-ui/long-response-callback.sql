-- Temporary app 105 / page 5 / GS_BOREHOLES_AGENT_ASK acceptance fixture.
-- Install only for the owned verification window; restore per README immediately.
-- Test fixture only: never retain this branch in canonical APEX exports.
declare
  c_nonce constant varchar2(80) := 'BH_LONG_5AA6E506ED0E4414B62A9B0D5E2AA8C3';
  c_fallback_nonce constant varchar2(80) := 'BH_FALLBACK_D61D8013299446B08CA23F098F144708';
  l_fixture_json clob;

  procedure free_clob(p_value in out nocopy clob) is
  begin
    if dbms_lob.istemporary(p_value) = 1 then dbms_lob.freetemporary(p_value); end if;
    p_value := null;
  end;

  procedure append_text(p_target in out nocopy clob, p_text varchar2) is
  begin
    if p_text is not null then
      dbms_lob.writeappend(p_target, length2(p_text), p_text);
    end if;
  end;

  function fixture_json return clob is
    l_html clob;
    l_result clob;
    l_line varchar2(32767);
    l_started number := dbms_utility.get_time;
    l_render_ms number;
    l_json_open boolean := false;
  begin
    dbms_lob.createtemporary(l_html, true, dbms_lob.call);
    append_text(l_html, '<section class="gs-bore-viz-card"><h3>Synthetic transport acceptance fixture</h3>'
      || '<pre id="bhLongResponseTest" style="white-space:pre-wrap;overflow-wrap:anywhere">');
    append_text(l_html, apex_escape.html('BEGIN ' || c_nonce) || chr(10));
    for i in 1..512 loop
      l_line := 'LINE ' || to_char(i, 'FM0000') || ' | '
        || unistr('\00E9\6F22\03A9\D83D\DE80')
        || ' | <img data-bh-probe="literal"> ' || chr(38) || ' "quoted" | '
        || rpad('x', 96, 'x');
      append_text(l_html, apex_escape.html(l_line) || chr(10));
    end loop;
    append_text(l_html, apex_escape.html('END ' || c_nonce) || '</pre></section>');
    l_render_ms := greatest(0, (dbms_utility.get_time - l_started) * 10);

    apex_json.initialize_clob_output;
    l_json_open := true;
    apex_json.open_object;
    apex_json.write('success', true);
    apex_json.write('requestId', lower(rawtohex(sys_guid())));
    apex_json.write('mode', 'DETERMINISTIC');
    apex_json.write('status', 'OK');
    apex_json.write('contextChars', 0);
    apex_json.write('answerHtml', l_html);
    apex_json.open_object('timings');
    apex_json.write('contextMs', 0);
    apex_json.write('providerMs', 0);
    apex_json.write('renderMs', l_render_ms);
    apex_json.write('totalMs', greatest(0, (dbms_utility.get_time - l_started) * 10));
    apex_json.close_object;
    apex_json.close_object;
    dbms_lob.createtemporary(l_result, true, dbms_lob.call);
    dbms_lob.append(l_result, apex_json.get_clob_output);
    apex_json.free_output;
    l_json_open := false;
    free_clob(l_html);
    return l_result;
  exception
    when others then
      if l_json_open then apex_json.free_output; end if;
      free_clob(l_html);
      free_clob(l_result);
      raise;
  end;
begin
  if apex_application.g_x01 = c_nonce and v('APP_USER') in ('CODEX', 'DEMO_USER') then
    l_fixture_json := fixture_json;
    apex_util.prn(p_clob => l_fixture_json, p_escape => false);
    free_clob(l_fixture_json);
  elsif apex_application.g_x01 = c_fallback_nonce and v('APP_USER') in ('CODEX', 'DEMO_USER') then
    apex_util.prn(
      p_clob => gs_borehole_agent_api.ask_json(
        p_user_prompt       => 'explain count by state',
        p_service_static_id => 'BH_TEST_NO_PROVIDER',
        p_screen_context    => null
      ),
      p_escape => false
    );
  else
    apex_util.prn(
      p_clob => gs_borehole_agent_api.ask_json(
        p_user_prompt       => apex_application.g_x01,
        p_service_static_id => apex_application.g_x02,
        p_screen_context    => apex_application.g_x03
      ),
      p_escape => false
    );
  end if;
exception
  when others then
    free_clob(l_fixture_json);
    raise;
end;
/
