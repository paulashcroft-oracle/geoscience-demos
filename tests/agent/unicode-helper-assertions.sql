-- Declaration fragment; unicode-helper-probe.ps1 supplies exact current helpers.
-- Tests UTF-16/UCS2 CLOB lengths against independent LENGTH2-based construction.
-- No business data, HTTP, model, APEX session creation, DDL or DML.
-- Failure cases continue to report only case IDs, counts and Oracle error codes.
procedure run_unicode_helper_probes is
  l_checks pls_integer := 0;
  l_failed pls_integer := 0;
  l_payload clob;
  l_expected clob;
  l_actual clob;
  l_html clob;
  l_evidence t_evidence;

  procedure check_true(p_ok boolean, p_label varchar2) is
  begin
    if p_ok is null or not p_ok then
      raise_application_error(-20991, p_label);
    end if;
    l_checks := l_checks + 1;
  end;

  procedure free_clob(p_value in out nocopy clob) is
  begin
    if dbms_lob.istemporary(p_value) = 1 then dbms_lob.freetemporary(p_value); end if;
    p_value := null;
  end;

  procedure cleanup is
  begin
    free_clob(l_payload); free_clob(l_expected); free_clob(l_actual);
    free_clob(l_html); free_clob(l_evidence.html);
  end;

  procedure add_input(p_piece varchar2) is
    l_escaped varchar2(32767) := apex_escape.html(p_piece);
  begin
    dbms_lob.writeappend(l_payload, length2(p_piece), p_piece);
    dbms_lob.writeappend(l_expected, length2(l_escaped), l_escaped);
  end;

  procedure run_case(p_case pls_integer) is
    c_open constant varchar2(80) := '<div class="gs-bore-narrative">' || chr(10);
    c_close constant varchar2(80) := '</div></section>' || chr(10);
    l_start integer;
    l_finish integer;
    l_piece varchar2(32767);
    l_before pls_integer := l_checks;
    l_stage varchar2(30) := 'construct';
  begin
    dbms_lob.createtemporary(l_payload, true, dbms_lob.call);
    dbms_lob.createtemporary(l_expected, true, dbms_lob.call);
    dbms_lob.createtemporary(l_actual, true, dbms_lob.call);
    case p_case
      when 1 then -- ASCII full-render control beyond 32 KB.
        for i in 1..40 loop add_input(rpad('a', 1000, 'a')); end loop;
        add_input('ASCII_FINAL_SENTINEL');
      when 2 then -- BMP append_text control.
        add_input(unistr('\00E9\6F22\03A9') || 'BMP_FINAL_SENTINEL');
      when 3 then -- One supplementary codepoint and a truncation-sensitive tail.
        add_input(unistr('\D83D\DE80') || 'ASTRAL_FINAL_SENTINEL');
      when 4 then -- 4000 BMP characters exceed a 4000-byte local buffer.
        -- RPAD counts display width for Han; concatenate exact characters instead.
        l_piece := null;
        for i in 1..4000 loop l_piece := l_piece || unistr('\6F22'); end loop;
        add_input(l_piece);
        check_true(dbms_lob.getlength(l_payload) = 4000, 'exact BMP boundary fixture size');
        add_input('BMP_BOUNDARY_FINAL_SENTINEL');
      when 5 then -- A surrogate pair straddles the requested 4000-unit boundary.
        add_input(rpad('a', 3999, 'a'));
        add_input(unistr('\D83D\DE80') || '<' || chr(38) || 'BOUNDARY_ONE');
        add_input(rpad('b', 3998, 'b'));
        add_input(unistr('\D83D\DE80') || '<BOUNDARY_FINAL_SENTINEL>');
      when 6 then -- Full Unicode render: literal markup, multiple chunks, >32 KB.
        add_input(rpad('x', 3999, 'x'));
        add_input(unistr('\D83D\DE80'));
        l_piece := unistr('\00E9\6F22\03A9\D83D\DE80')
          || ' <img data-bh-probe="literal" onerror="void(0)"> ' || chr(38)
          || ' "quoted" ' || rpad('z', 96, 'z') || chr(10);
        for i in 1..512 loop add_input(l_piece); end loop;
        add_input('UNICODE_RENDER_FINAL_SENTINEL');
    end case;

    if p_case in (2, 3) then
      l_stage := 'append_text';
      append_text(l_actual, dbms_lob.substr(l_payload, 1000, 1));
    elsif p_case in (4, 5) then
      l_stage := 'append_escaped';
      append_escaped(l_actual, l_payload);
    else
      check_true(dbms_lob.getlength(l_payload) > 32767, 'long-render fixture size');
      dbms_lob.createtemporary(l_evidence.html, true, dbms_lob.call);
      l_piece := '<section>EVIDENCE_FINAL_SENTINEL</section>';
      dbms_lob.writeappend(l_evidence.html, length2(l_piece), l_piece);
      l_stage := 'render_answer';
      l_html := render_answer(l_evidence, l_payload);
      l_stage := 'extract_narrative';
      l_start := dbms_lob.instr(l_html, c_open);
      check_true(l_start > 0, 'narrative opening');
      l_start := l_start + length2(c_open);
      l_finish := dbms_lob.instr(l_html, c_close, l_start);
      check_true(l_finish > l_start, 'narrative closing');
      dbms_lob.copy(l_actual, l_html, l_finish - l_start, 1, l_start);
      check_true(dbms_lob.instr(l_html, 'EVIDENCE_FINAL_SENTINEL') > l_finish,
        'evidence after complete narrative');
      check_true(dbms_lob.instr(l_html, '<img data-bh-probe=') = 0, 'literal markup not executable');
    end if;
    l_stage := 'compare';
    check_true(dbms_lob.getlength(l_actual) = dbms_lob.getlength(l_expected), 'exact UCS2 length');
    check_true(dbms_lob.compare(l_actual, l_expected) = 0, 'full escaped Unicode parity');
    dbms_output.put_line('Unicode probe case=' || p_case || ' PASS checks=' || (l_checks - l_before)
      || ' input_units=' || dbms_lob.getlength(l_payload));
    cleanup;
  exception
    when others then
      l_failed := l_failed + 1;
      dbms_output.put_line('Unicode probe case=' || p_case || ' FAIL stage=' || l_stage
        || ' sqlcode=' || sqlcode || ' completed_checks=' || (l_checks - l_before));
      cleanup;
  end;
begin
  check_true(sys_context('USERENV', 'SESSION_USER') = 'CODEX'
    and lower(sys_context('USERENV', 'DB_UNIQUE_NAME')) = 'tcelkxkd', 'execution identity');
  check_true(nvl(apex_application.g_instance, 0) = 0
    and nvl(sys_context('APEX$SESSION', 'APP_SESSION'), '0') = '0', 'no APEX session');
  for i in 1..6 loop run_case(i); end loop;
  if l_failed > 0 then
    raise_application_error(-20990, 'Unicode helpers: failed_cases=' || l_failed
      || ', completed_checks=' || l_checks);
  end if;
  dbms_output.put_line('PASS Unicode helpers: cases=6, checks=' || l_checks);
exception
  when others then cleanup; raise;
end run_unicode_helper_probes;
