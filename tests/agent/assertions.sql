-- Declaration fragment for the source-only anonymous harness described in README.md.
-- Uses private routines from the current GS_BOREHOLE_AGENT_API body; no duplicated router.
procedure run_agent_regressions is
  l_query t_query;
  l_evidence t_evidence;
  l_expected number;
  l_json clob;
  l_object json_object_t;
  l_timings json_object_t;
  l_answer clob;
  l_html clob;
  l_count pls_integer := 0;
  procedure assert_true(p_ok boolean, p_name varchar2) is
  begin
    if p_ok is null or not p_ok then
      raise_application_error(-20800, 'Agent regression: ' || p_name);
    end if;
    l_count := l_count + 1;
  end;
  procedure check_route(p_prompt varchar2, p_intent varchar2, p_clarify boolean default false,
    p_state varchar2 default null, p_explain boolean default false) is
    l_actual t_query := resolve_query(p_prompt);
  begin
    assert_true((l_actual.clarification is not null) = p_clarify, p_prompt || ' clarification');
    if not p_clarify then
      assert_true(l_actual.intent = p_intent, p_prompt || ' intent');
      assert_true(coalesce(l_actual.state_code, '-') = coalesce(p_state, '-'), p_prompt || ' state');
      assert_true(l_actual.explain = p_explain, p_prompt || ' explanation flag');
    end if;
  end;
begin
  check_route('show longest boreholes', 'LONGEST');
  check_route('chart count by operator', 'OPERATOR');
  check_route('chart count by state', 'STATE');
  check_route('show purpose breakdown', 'PURPOSE');
  check_route('count boreholes in NT', 'COUNT', false, 'NT');
  check_route('count boreholes in Western Australia', 'COUNT', false, 'WA');
  check_route('show locations', 'MAP');
  check_route('open map', 'MAP');
  check_route('explain count by state', 'STATE', false, null, true);
  check_route('summarize pasted text: This sample is supplied by the user.', 'TEXT', false, null, true);
  check_route('count boreholes drilled after 2000', null, true);
  check_route('count boreholes excluding NT', null, true);
  check_route('count boreholes near Darwin', null, true);
  check_route('count boreholes in WA and NT', null, true);
  check_route('count by state and purpose', null, true);
  check_route('map boreholes in NT', null, true);
  check_route('show top 26 longest boreholes', null, true);
  check_route('show top 0 longest boreholes', null, true);
  check_route('top 5 longest boreholes top 3', null, true);
  check_route('what about those?', null, true);
  check_route('show gold boreholes', null, true);
  check_route('count operator Acme', null, true);
  check_route('count operator "Acme" operator "Other"', null, true);
  check_route('count by province', null, true);
  check_route('count "unexpected words"', null, true);
  check_route(rpad('x', 3001, 'x'), null, true);
  l_query := resolve_query('top 5 longest boreholes in NT operator "Acme" purpose "Exploration"');
  assert_true(l_query.clarification is null and l_query.top_n = 5 and l_query.state_code = 'NT'
    and l_query.operator_name = 'acme' and l_query.purpose = 'exploration', 'combined explicit equality filters');

  l_query := resolve_query('count boreholes in NT');
  l_evidence := collect_evidence(l_query);
  select count(*) into l_expected from gs_boreholes where upper(state_code) = 'NT';
  assert_true(l_evidence.matched_rows = l_expected, 'state count equals SQL');
  assert_true(dbms_lob.instr(l_evidence.html, 'Matching boreholes: ' || number_text(l_expected) || '.') > 0,
    'HTML count equals SQL evidence');

  l_query := resolve_query('chart count by state');
  l_evidence := collect_evidence(l_query);
  for r in (
    select coalesce(state_code, 'Unknown') label, count(*) cnt from gs_boreholes
     group by coalesce(state_code, 'Unknown') order by cnt desc, label fetch first 1 row only
  ) loop
    assert_true(dbms_lob.instr(l_evidence.markdown, r.label || ': ' || number_text(r.cnt) || ' boreholes.') > 0,
      'leading state derived from current data');
  end loop;

  -- Retrieval must not depend on membership of a latest-40 sample.
  for r in (
    select borehole_ref from gs_boreholes where instr(borehole_ref, '"') = 0
     order by updated_at, borehole_id fetch first 1 row only
  ) loop
    l_query := resolve_query('explain ref "' || r.borehole_ref || '"');
    l_evidence := collect_evidence(l_query);
    assert_true(l_query.intent = 'RECORD' and l_query.explain, 'explicit old reference route');
    assert_true(l_evidence.matched_rows >= 1 and dbms_lob.instr(l_evidence.markdown, r.borehole_ref) > 0,
      'old reference has relevant evidence');
  end loop;

  -- These calls cannot use a model: deterministic or explicitly disallowed service.
  l_json := ask_json('chart count by operator', 'cohere.command-latest');
  l_object := json_object_t.parse(l_json);
  assert_true(l_object.get_string('mode') = 'DETERMINISTIC', 'common query bypasses provider');
  assert_true(l_object.get_string('status') = 'OK', 'deterministic status');
  assert_true(length(l_object.get_string('requestId')) = 32, 'correlation ID');
  l_timings := l_object.get_object('timings');
  assert_true(l_timings.get_number('providerMs') = 0, 'zero provider time on bypass');
  assert_true(l_timings.get_number('totalMs') >= 0, 'nonnegative total time');
  assert_true(not l_object.has('selectedServiceName') or l_object.get_string('selectedServiceName') is null,
    'no model label for deterministic answer');
  l_json := ask_json('explain count by state', 'cohere.command-latest');
  l_object := json_object_t.parse(l_json);
  assert_true(l_object.get_string('mode') = 'DETERMINISTIC_FALLBACK', 'disallowed service fallback');
  assert_true(l_object.get_string('status') = 'SERVICE_UNAVAILABLE', 'disallowed service classified');
  assert_true(dbms_lob.instr(l_object.get_clob('answerHtml'), 'Boreholes by state') > 0,
    'fallback preserves useful exact evidence');
  l_json := ask_json('what about those?', 'google_gemini_2_5_pro');
  l_object := json_object_t.parse(l_json);
  assert_true(l_object.get_string('status') = 'CLARIFICATION_REQUIRED', 'followup does not infer history');
  assert_true(provider_error_class(-29276, 'secret timeout text') = 'PROVIDER_TIMEOUT', 'timeout classification');
  assert_true(provider_error_class(-20001, 'HTTP 429 secret payload') = 'PROVIDER_THROTTLED', 'throttle classification');
  assert_true(provider_error_class(-20001, 'HTTP 403 secret payload') = 'PROVIDER_AUTH', 'auth classification');
  assert_true(provider_error_class(-20001, 'raw private SQL') = 'PROVIDER_ERROR', 'safe generic provider class');

  dbms_lob.createtemporary(l_answer, true);
  append_text(l_answer, rpad('x', 4000, 'x'));
  append_text(l_answer, '<script>alert("untrusted")</script>');
  append_text(l_answer, rpad('y', 5000, 'y') || 'UNCLIPPED_TAIL');
  l_html := render_answer(l_evidence, l_answer);
  assert_true(dbms_lob.instr(l_html, 'UNCLIPPED_TAIL') > 0, 'complete model output');
  assert_true(dbms_lob.instr(l_html, '<script>') = 0 and dbms_lob.instr(l_html, '&lt;script&gt;') > 0,
    'model HTML escaped');
  assert_true(dbms_lob.instr(build_ai_context('count boreholes drilled after 2000'), 'BEGIN DATABASE EVIDENCE') = 0,
    'unsupported filter never supplies a broader AI dataset');
  dbms_output.put_line('PASS: ' || l_count || ' agent regression assertions');
end run_agent_regressions;
