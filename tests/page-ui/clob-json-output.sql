-- Direct buffer regression; run as CODEX through SQLcl on tcelkxkd, with no
-- active APEX session. Submit this one anonymous block, not a live page/process.
-- Only call-duration temporary LOBs and local OWA/APEX_JSON buffer state change.
-- No application session creation, business DML, DDL, HTTP or provider calls.
-- This proves buffer parity, not the complete ORDS/browser AJAX response path.
-- APEX 26.1 API Reference: PRN section 63.99, INITIALIZE_CLOB_OUTPUT 40.23:
-- https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/oracle-apex-api-reference.pdf
-- Oracle Ask TOM example of OWA.GET_PAGE into HTP.HTBUF_ARR:
-- https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:347617533333
declare
  c_pieces constant pls_integer := 1024;
  c_capture_limit constant pls_integer := 10000;
  c_sentinel constant varchar2(80) := 'BOREHOLES_FINAL_SENTINEL_AFTER_32767_END';
  l_token varchar2(32) := rawtohex(sys_guid());
  l_begin_marker varchar2(80);
  l_end_marker varchar2(80);
  l_sample varchar2(4000);
  l_expected clob;
  l_wire clob;
  l_actual clob;
  l_json_open boolean := false;
  l_owa_written boolean := false;
  l_owa_read boolean := false;
  l_page htp.htbuf_arr;
  l_rows integer;
  l_names owa.vc_arr;
  l_values owa.vc_arr;
  l_json apex_json.t_values;
  l_start pls_integer;
  l_finish pls_integer;
  l_expected_bytes number;
  l_actual_bytes number;
  l_checks pls_integer := 0;

  procedure check_true(p_condition boolean, p_label varchar2) is
  begin
    if p_condition is null or not p_condition then
      raise_application_error(-20990, 'CLOB JSON output: ' || p_label);
    end if;
    l_checks := l_checks + 1;
  end;

  function utf8_bytes(p_text clob) return number is
    l_offset pls_integer := 1;
    l_piece varchar2(16000);
    l_total number := 0;
  begin
    -- Fixture Unicode is BMP-only; 4000 characters fit safely in this buffer.
    while l_offset <= dbms_lob.getlength(p_text) loop
      l_piece := dbms_lob.substr(p_text, 4000, l_offset);
      l_total := l_total + utl_raw.length(utl_i18n.string_to_raw(l_piece, 'AL32UTF8'));
      l_offset := l_offset + length(l_piece);
    end loop;
    return l_total;
  end;

  procedure free_clob(p_lob in out nocopy clob) is
  begin
    if dbms_lob.istemporary(p_lob) = 1 then dbms_lob.freetemporary(p_lob); end if;
  end;

  procedure cleanup is
  begin
    if l_json_open then
      apex_json.free_output;
      l_json_open := false;
    end if;
    if l_owa_written and not l_owa_read then
      l_rows := c_capture_limit;
      owa.get_page(l_page, l_rows);
      l_owa_read := true;
    end if;
    free_clob(l_actual);
    free_clob(l_wire);
    free_clob(l_expected);
  end;
begin
  if nvl(sys_context('USERENV', 'SESSION_USER'), '?') <> 'CODEX'
     or nvl(sys_context('USERENV', 'DB_UNIQUE_NAME'), '?') <> 'tcelkxkd'
     or nvl(apex_application.g_instance, 0) <> 0 then
    raise_application_error(-20991, 'Use CODEX SQLcl on tcelkxkd without an active APEX session.');
  end if;
  l_begin_marker := 'BH_JSON_BEGIN_' || l_token || ':';
  l_end_marker := ':BH_JSON_END_' || l_token;
  -- ASCII source file, actual multibyte characters at runtime; include JSON and
  -- HTML-sensitive characters so accidental escaping cannot pass parity checks.
  l_sample := unistr('\00E9\6F22\03A9') || ' <tag>& "quoted" \ backslash ' || chr(10) || rpad('x', 96, 'x');
  check_true(lengthb(l_sample) > length(l_sample), 'fixture must contain actual multibyte characters');

  apex_json.initialize_clob_output(p_dur => dbms_lob.call, p_indent => 0, p_preserve => true);
  l_json_open := true;
  apex_json.open_object;
  apex_json.write('success', true);
  apex_json.open_array('pieces');
  for i in 1 .. c_pieces loop apex_json.write(l_sample); end loop;
  apex_json.close_array;
  apex_json.write('finalSentinel', c_sentinel);
  apex_json.close_object;
  dbms_lob.createtemporary(l_expected, true, dbms_lob.call);
  -- APEX_JSON emits these BMP characters as ASCII Unicode escapes. JSON also
  -- permits literal BMP characters: convert only the three known fixture values
  -- so PRN is exercised with actual multibyte bytes. The fixture contains no
  -- literal backslash-u text; this is not a general-purpose JSON unescaper.
  dbms_lob.append(l_expected,
    regexp_replace(
      regexp_replace(
        regexp_replace(apex_json.get_clob_output, '\\u00[eE]9', unistr('\00E9')),
        '\\u6[fF]22', unistr('\6F22')),
      '\\u03[aA]9', unistr('\03A9')));
  apex_json.free_output;
  l_json_open := false;

  apex_json.parse(p_values => l_json, p_source => l_expected);
  check_true(apex_json.get_count(p_path => 'pieces', p_values => l_json) = c_pieces and
    apex_json.get_varchar2(p_path => 'pieces[1]', p_values => l_json) = l_sample and
    apex_json.get_varchar2(p_path => 'pieces[%d]', p0 => c_pieces, p_values => l_json) = l_sample,
    'literal BMP fixture must preserve decoded JSON values before PRN');

  l_expected_bytes := utf8_bytes(l_expected);
  check_true(dbms_lob.getlength(l_expected) > 32767 and l_expected_bytes > 32767,
    'serialized JSON must exceed 32767 characters and UTF-8 bytes');
  check_true(l_expected_bytes > dbms_lob.getlength(l_expected), 'serialized JSON must retain multibyte text');
  check_true(dbms_lob.instr(l_expected, c_sentinel) > 32767, 'final sentinel must follow the 32767 boundary');

  -- Initialize only this SQLcl connection's CGI package buffers. No APEX session
  -- is created/attached or altered, and these values send no network request.
  l_names(1) := 'REQUEST_PROTOCOL'; l_values(1) := 'HTTP';
  l_names(2) := 'REQUEST_CHARSET'; l_values(2) := 'AL32UTF8';
  l_names(3) := 'REQUEST_IANA_CHARSET'; l_values(3) := 'UTF-8';
  owa.init_cgi_env(l_names.count, l_names, l_values);
  l_owa_written := true;
  htp.prn(l_begin_marker);
  apex_util.prn(p_clob => l_expected, p_escape => false);
  htp.prn(l_end_marker);
  l_rows := c_capture_limit;
  owa.get_page(l_page, l_rows);
  l_owa_read := true;
  check_true(l_rows > 0 and l_rows < c_capture_limit, 'OWA capture must be nonempty and below its row bound');
  dbms_lob.createtemporary(l_wire, true, dbms_lob.call);
  for i in 1 .. l_rows loop
    if l_page(i) is not null then dbms_lob.writeappend(l_wire, length(l_page(i)), l_page(i)); end if;
  end loop;
  -- Keep each OWA fragment verbatim: adding line breaks would corrupt parity.
  l_start := dbms_lob.instr(l_wire, l_begin_marker);
  l_finish := dbms_lob.instr(l_wire, l_end_marker);
  check_true(l_start > 0 and l_finish > l_start, 'both framing markers must survive output');
  check_true(dbms_lob.instr(l_wire, l_begin_marker, 1, 2) = 0 and
    dbms_lob.instr(l_wire, l_end_marker, 1, 2) = 0, 'framing markers must be unique');
  l_start := l_start + length(l_begin_marker);
  dbms_lob.createtemporary(l_actual, true, dbms_lob.call);
  dbms_lob.copy(l_actual, l_wire, l_finish - l_start, 1, l_start);
  check_true(dbms_lob.compare(l_expected, l_actual) = 0, 'captured JSON must exactly match serialized CLOB');
  l_actual_bytes := utf8_bytes(l_actual);
  check_true(l_actual_bytes = l_expected_bytes, 'UTF-8 byte counts must match');
  apex_json.parse(p_values => l_json, p_source => l_actual);
  check_true(apex_json.get_boolean(p_path => 'success', p_values => l_json), 'JSON boolean must parse');
  check_true(apex_json.get_count(p_path => 'pieces', p_values => l_json) = c_pieces, 'all array elements must survive');
  check_true(apex_json.get_varchar2(p_path => 'pieces[1]', p_values => l_json) = l_sample and
    apex_json.get_varchar2(p_path => 'pieces[%d]', p0 => c_pieces, p_values => l_json) = l_sample,
    'first and last multibyte/escaped values must round-trip');
  check_true(apex_json.get_varchar2(p_path => 'finalSentinel', p_values => l_json) = c_sentinel,
    'final sentinel must parse intact');
  cleanup;
  dbms_output.put_line('PASS: ' || l_checks || ' CLOB JSON buffer assertions; UTF-8 bytes=' ||
    l_actual_bytes || '; pieces=' || c_pieces || '; final sentinel intact. Browser AJAX remains untested.');
exception
  when others then
    begin cleanup; exception when others then
      dbms_output.put_line('CLOB JSON buffer cleanup error: ' || substr(sqlerrm, 1, 500));
    end;
    raise;
end;
