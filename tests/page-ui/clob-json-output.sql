-- Native APEX_JSON serializer control; run as CODEX on tcelkxkd without an APEX session.
-- Root observed PASS: 14 checks, UTF8_bytes=183584, ASCII_wire=Y on 17 September 2026.
-- Only call-duration temporary LOBs and local OWA/APEX_JSON buffers are changed.
-- No DDL, business DML, HTTP, provider call or APEX session creation.
-- Literal-unescaped-wire failures remain recorded in the callback acceptance note.
-- This proves unchanged serializer buffer parity, not ORDS/browser AJAX transport.
declare
  c_sentinel constant varchar2(80) := 'BH_SERIALIZER_FINAL_SENTINEL_AFTER_32767';
  l_sample varchar2(4000);
  l_payload clob;
  l_expected clob;
  l_wire clob;
  l_actual clob;
  l_decoded clob;
  l_json apex_json.t_values;
  l_json_open boolean := false;
  l_owa_written boolean := false;
  l_owa_read boolean := false;
  l_names owa.vc_arr;
  l_values owa.vc_arr;
  l_page htp.htbuf_arr;
  l_rows integer := 10000;
  l_token varchar2(32) := rawtohex(sys_guid());
  l_begin_marker varchar2(80);
  l_end_marker varchar2(80);
  l_start integer;
  l_finish integer;
  l_bytes number;
  l_ascii varchar2(1);
  l_checks pls_integer := 0;

  procedure check_true(p_ok boolean, p_label varchar2) is
  begin
    if p_ok is null or not p_ok then
      raise_application_error(-20990, 'Serializer control: ' || p_label);
    end if;
    l_checks := l_checks + 1;
  end;

  function utf8_bytes(p_text clob) return number is
    l_offset integer := 1;
    l_amount integer;
    l_piece varchar2(32767);
    l_total number := 0;
  begin
    while l_offset <= dbms_lob.getlength(p_text) loop
      l_amount := least(4000, dbms_lob.getlength(p_text) - l_offset + 1);
      dbms_lob.read(p_text, l_amount, l_offset, l_piece);
      if l_amount is null or l_amount <= 0 or l_piece is null then
        raise_application_error(-20992, 'UTF-8 read made no progress');
      end if;
      l_total := l_total +
        utl_raw.length(utl_i18n.string_to_raw(l_piece, 'AL32UTF8'));
      l_offset := l_offset + l_amount;
    end loop;
    return l_total;
  end;

  procedure free_clob(p_lob in out nocopy clob) is
  begin
    if dbms_lob.istemporary(p_lob) = 1 then
      dbms_lob.freetemporary(p_lob);
    end if;
  end;

  procedure cleanup is
  begin
    if l_json_open then
      apex_json.free_output;
      l_json_open := false;
    end if;
    if l_owa_written and not l_owa_read then
      l_rows := 10000;
      owa.get_page(l_page, l_rows);
      l_owa_read := true;
    end if;
    free_clob(l_decoded);
    free_clob(l_actual);
    free_clob(l_wire);
    free_clob(l_expected);
    free_clob(l_payload);
  end;
begin
  if nvl(sys_context('USERENV', 'SESSION_USER'), '?') <> 'CODEX'
     or nvl(sys_context('USERENV', 'DB_UNIQUE_NAME'), '?') <> 'tcelkxkd'
     or nvl(apex_application.g_instance, 0) <> 0 then
    raise_application_error(-20991,
      'Use CODEX SQLcl on tcelkxkd without an active APEX session.');
  end if;

  l_begin_marker := 'BH_CONTROL_BEGIN_' || l_token || ':';
  l_end_marker := ':BH_CONTROL_END_' || l_token;
  l_sample := unistr('\00E9\6F22\03A9\D83D\DE80') ||
    ' <tag>' || chr(38) || ' "quoted" \ backslash ' ||
    chr(10) || rpad('x', 96, 'x');
  check_true(lengthb(l_sample) > length(l_sample),
    'input contains actual multibyte characters');
  check_true(length2(l_sample) > length4(l_sample),
    'input contains actual supplementary Unicode');

  dbms_lob.createtemporary(l_payload, true, dbms_lob.call);
  for i in 1 .. 1024 loop
    dbms_lob.writeappend(l_payload, length2(l_sample), l_sample);
  end loop;
  check_true(dbms_lob.getlength(l_payload) > 32767,
    'CLOB input exceeds 32767 units');

  apex_json.initialize_clob_output(
    p_dur => dbms_lob.call, p_indent => 0, p_preserve => true);
  l_json_open := true;
  apex_json.open_object;
  apex_json.write('success', true);
  apex_json.write('sample', l_sample);
  apex_json.write('answerHtml', l_payload);
  apex_json.write('finalSentinel', c_sentinel);
  apex_json.close_object;
  dbms_lob.createtemporary(l_expected, true, dbms_lob.call);
  dbms_lob.append(l_expected, apex_json.get_clob_output);
  apex_json.free_output;
  l_json_open := false;

  -- No unescaping, replacement or modification of serialized output.
  l_bytes := utf8_bytes(l_expected);
  l_ascii := case
    when l_bytes = dbms_lob.getlength(l_expected) then 'Y' else 'N' end;
  check_true(dbms_lob.getlength(l_expected) > 32767 and l_bytes > 32767,
    'serialized response exceeds 32767 units and bytes');
  check_true(dbms_lob.instr(l_expected, c_sentinel) > 32767,
    'sentinel follows 32767 boundary');

  l_names(1) := 'REQUEST_PROTOCOL'; l_values(1) := 'HTTP';
  l_names(2) := 'REQUEST_CHARSET'; l_values(2) := 'AL32UTF8';
  l_names(3) := 'REQUEST_IANA_CHARSET'; l_values(3) := 'UTF-8';
  owa.init_cgi_env(l_names.count, l_names, l_values);
  l_owa_written := true;
  owa_util.mime_header('application/json', true);
  htp.prn(l_begin_marker);
  apex_util.prn(p_clob => l_expected, p_escape => false);
  htp.prn(l_end_marker);

  owa.get_page(l_page, l_rows);
  l_owa_read := true;
  check_true(l_rows > 0 and l_rows < 10000, 'bounded OWA capture');
  dbms_lob.createtemporary(l_wire, true, dbms_lob.call);
  for i in 1 .. l_rows loop
    if l_page(i) is not null then
      dbms_lob.writeappend(l_wire, length2(l_page(i)), l_page(i));
    end if;
  end loop;

  l_start := dbms_lob.instr(l_wire, l_begin_marker);
  l_finish := dbms_lob.instr(l_wire, l_end_marker);
  check_true(l_start > 0 and l_finish > l_start, 'framing markers intact');
  check_true(dbms_lob.instr(l_wire, l_begin_marker, 1, 2) = 0 and
    dbms_lob.instr(l_wire, l_end_marker, 1, 2) = 0, 'markers unique');
  l_start := l_start + length2(l_begin_marker);
  dbms_lob.createtemporary(l_actual, true, dbms_lob.call);
  dbms_lob.copy(l_actual, l_wire, l_finish - l_start, 1, l_start);
  check_true(dbms_lob.compare(l_expected, l_actual) = 0,
    'entire serialized CLOB preserved exactly');
  check_true(utf8_bytes(l_actual) = l_bytes, 'UTF-8 byte parity');

  apex_json.parse(p_values => l_json, p_source => l_actual);
  check_true(apex_json.get_boolean(
    p_path => 'success', p_values => l_json), 'JSON boolean parses');
  l_decoded := apex_json.get_clob(p_path => 'answerHtml', p_values => l_json);
  check_true(dbms_lob.compare(l_payload, l_decoded) = 0,
    'complete Unicode CLOB input round-trips');
  check_true(apex_json.get_varchar2(
    p_path => 'sample', p_values => l_json) = l_sample,
    'Unicode VARCHAR2 input round-trips');
  check_true(apex_json.get_varchar2(
    p_path => 'finalSentinel', p_values => l_json) = c_sentinel,
    'final sentinel parses intact');

  cleanup;
  dbms_output.put_line('PASS native serializer control: checks=' || l_checks ||
    ' UTF8_bytes=' || l_bytes || ' ASCII_wire=' || l_ascii ||
    '. Browser AJAX remains untested.');
exception
  when others then
    begin
      cleanup;
    exception
      when others then
        dbms_output.put_line('Control cleanup error: ' ||
          substr(sqlerrm, 1, 250));
    end;
    raise;
end;
/
