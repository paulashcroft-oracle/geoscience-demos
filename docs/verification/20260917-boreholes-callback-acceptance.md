# Boreholes callback and native Explorer acceptance

Prepared 17 September 2026 for AIDEMODB workspace/schema `GEOSCIENCE`, app105. This note retains the reviewed Page Designer process bodies and acceptance steps, plus the coordinating task's observed delivery receipt below; it is not a metadata SQL installer. The immutable baseline is `exports/apex/geoscience/105/20260917-before-boreholes-review`; preserve it. Root owns live delivery and post-change APEXlang export. The documenting subagent performed no browser or database actions.

## Observed delivery and limited runtime receipt

Root saved all three app105 process bodies through Page Designer and verified exact complete stored-source readback on 17 September 2026. The target was AIDEMODB `tcelkxkd`, workspace/current schema `GEOSCIENCE`, session user `ORDS_PLSQL_GATEWAY`, APEX user `CODEX`. Sizes and hashes below describe the UTF-8 process body, with LF line separators, no BOM, no trailing newline and no SQLcl slash.

| Page / process | Observed component ID | Body bytes / SHA-256 | Preserved metadata |
| --- | --- | --- | --- |
| 4 / `GS_BOREHOLES_REFRESH` | `1050100402` | 959 / `9e2a8fc8d7d03a63575d1b3a86e379e47908fe3426ea1de3211cb5f92966f36c` | Ajax, sequence10, authorization null |
| 5 / `GS_BOREHOLES_AGENT_ASK` | `1050100502` | 265 / `bbb81f6d83c903a19f3f5fff86b4c896a18042747234891d43c825429000ccc9` | Ajax, sequence10, authorization null |
| 10030 / `Queue AI Hub Feedback` | `1050600000` | 556 / `c9bd8a167c8469d2f75ba5bb9ec8820f7783f9373a91cf39c70de76c0f602c23` | Sequence20, After Computations and Validations, Request=SUBMIT, authorization null |

Native `Submit Feedback`, ID `16507522493979144`, remained unchanged at sequence10. The page10030 body retains its original queue call and the nonfatal diagnostic fragment in [the feedback note](../../tests/feedback/README.md).

A separate fresh CODEX SQLcl session compiled both exact page4/page5 bodies as uncalled nested procedures, with GEOSCIENCE package qualification added only in memory. CODEX / `tcelkxkd` / no-APEX-session guards passed and the process exited0. No DML, model call, APEX session creation or callback invocation occurred; this establishes compilation, not response transport.

One subsequent app105 browser request as `DEMO_USER` returned the ordinary deterministic count **255**, with no AI invocation, reported server total **10 ms**, context **10 ms**, provider **0 ms**, render **0 ms**, request ID `5bac95db4962c03de063bc5e000a34ff`. This verifies one ordinary count response after callback and Unicode-body delivery. It does not establish long-response/Unicode browser transport, refresh, feedback, provider/fallback, Explorer or app104 acceptance. Root released all browser interaction to POLICING and GEO/children returned to HOLD. The native page2 replacement, remaining runtime checks and post-change APEXlang exports remain pending.

## Ajax callback replacements

The baseline page4 and page5 sources passed package CLOB results to `HTP.PRN`, whose text overload accepts `VARCHAR2`. The saved replacements below use native `APEX_UTIL.PRN(p_clob => ..., p_escape => false)` for the already serialized JSON. Both package APIs serialize responses with `APEX_JSON.WRITE`; leave that output unchanged. Root's fresh `CODEX` SQLcl control on `tcelkxkd` passed **14 checks, 183,584 UTF-8 bytes, ASCII_wire=Y**, including exact captured-CLOB equality, Unicode and supplementary-character round trips through both VARCHAR2 and large CLOB inputs, and the final sentinel. This supports the minimal native callback for the tested serializer contract; long/Unicode ORDS/browser validation remains pending beyond the ordinary count receipt above. [Oracle HTP](https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/HTP.html), [APEX 26.1 PRN](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PRN-Procedure.html).

Retained diagnostic limitation: earlier fixtures deliberately converted three BMP Unicode escapes and a surrogate-pair escape into literal Unicode on the wire. That extended the test beyond the observed package serialization. Native `APEX_UTIL.PRN` failed with `ORA-06502` at SYS.HTP line1531 through the APEX HTP writer; the proposed 4,000-unit `DBMS_LOB.READ`/`HTP.PRN` loop also failed at SYS.HTP line1531. Both still failed in fresh SQLcl sessions after explicitly closing HTTP headers. No generic literal-Unicode emitter fix was proven, and the chunked callback proposal is withdrawn. The successful control copies `APEX_JSON.GET_CLOB_OUTPUT` without unescaping or alteration; it does not erase or resolve those separate failures.

Keep each process's name, Ajax Callback execution point, sequence and existing authorization. Change only its PL/SQL body. Do not add commits, new authentication rules, output chunking, response wrappers or broad exception handlers. Page10030 feedback handling is a separate scope. The standalone SQLcl control initializes CGI and closes its own HTTP header; the callbacks retain APEX's request/header lifecycle.

Page **4**, process **GS_BOREHOLES_REFRESH**:

```sql
declare
  function request_number(p_text in varchar2) return number is
    l_text varchar2(32767) := trim(p_text);
  begin
    if l_text is null
       or not regexp_like(
         l_text,
         '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$',
         'c'
       ) then
      return null;
    end if;
    if substr(l_text, 1, 1) = '+' then
      l_text := substr(l_text, 2);
    end if;
    return to_number(
      l_text default null on conversion error,
      '999999999D999999',
      'NLS_NUMERIC_CHARACTERS=''.,'''
    );
  end request_number;
begin
  apex_util.prn(
    p_clob => gs_borehole_refresh_api.remote_refresh_json(
      p_min_lon => request_number(apex_application.g_x01),
      p_min_lat => request_number(apex_application.g_x02),
      p_max_lon => request_number(apex_application.g_x03),
      p_max_lat => request_number(apex_application.g_x04),
      p_limit   => request_number(apex_application.g_x05)
    ),
    p_escape => false
  );
end;
```

Trim outer spaces, require an optional sign plus a plain decimal, and remove a leading `+` before conversion. The grammar permits `.5`, `1.` and signed decimals, but rejects commas and exponent notation. The lexical check is necessary: the observed Oracle format conversion alone silently interpreted commas as grouping separators. Conversion failures become null rather than escaping before `remote_refresh_json` runs. The package rejects a null/nonintegral/out-of-range limit and null/invalid BBOX before creating a run or contacting WFS; it returns `success:false` and `errorCode:INVALID_REQUEST`. Explicit numeric settings remove the count's previous session-locale dependency. Do not default invalid values to zero, a bounding box or 250. [Oracle TO_NUMBER](https://docs.oracle.com/en/database/oracle/oracle-database/26/sqlrf/TO_NUMBER.html).

Page **5**, process **GS_BOREHOLES_AGENT_ASK**:

```sql
begin
  apex_util.prn(
    p_clob => gs_borehole_agent_api.ask_json(
      p_user_prompt       => apex_application.g_x01,
      p_service_static_id => apex_application.g_x02,
      p_screen_context    => apex_application.g_x03
    ),
    p_escape => false
  );
end;
```

This preserves the current API arguments. D010 sends only `x01` and `x02`; the optional `x03` remains null in that UI. Both current packages copy the completed JSON into a separate temporary CLOB before freeing APEX_JSON output. The callbacks do not parse JSON again or convert the whole response to `VARCHAR2`.

## Targeted checks before acceptance

Root's read-only Oracle probes on 17 September 2026 observed the following with format `999999999D999999` and explicit numeric characters `.,`:

| Probe | Observed result |
| --- | --- |
| Format conversion without grammar/normalization | `1,5` became `15`; `1,000` became `1000`. `+135.5` and outer spaces returned null. `.5`, `1.` and `-20.5` preserved their values; excess fractional digits and exponents returned null. |
| Candidate `CASE` with the grammar above, `trim`, and leading-plus removal (16 rows) | `.5`, `1.`, `-20.5`, `+135.5` and outer-space `129` preserved values. Commas, exponents, `NaN`, `abc`, more than six fractional digits and `1.0000001` returned null. `10001` and `1.5` remained unchanged for package rejection. |

Root also ran [the exact anonymous helper assertions](../../tests/page-ui/refresh-request-number.sql) successfully: **36 PASS**. They use the helper above and perform no DDL, DML, package call, commit or network request. Full callback/runtime integration remains pending. This local preparation task did not execute Oracle or browser checks; the observed results here were supplied by root.

| Check | Required result |
| --- | --- |
| `.5`, `1.`, signed decimals, surrounding spaces | Preserve their numeric values, including leading `+`. |
| `1,5`, `1,000`, `NaN`, `Infinity`, `abc`, blank/null | Null conversion and classified package rejection; never reinterpret commas as decimal/group separators. |
| More than six fractional digits | Null conversion, as observed with this format; never silently turn `1.0000001` into valid integer limit `1`. BBOX serialization uses six decimals; the package rejects bounds that collapse at that precision. |
| Exponent forms | Null conversion and classified package rejection; the plain-decimal grammar deliberately excludes exponents. |
| Limits `0`, `10001`, `1.5` | `INVALID_REQUEST`, zero loaded rows, no new attempt and no WFS call. `10000` and `10000.0` are equivalent valid limits; check conversion/range only unless a refresh is explicitly part of the controlled test. |
| Invalid/reversed/out-of-range BBOX | Parseable failure JSON without raw Oracle errors; no attempt or WFS call. |
| CLOB output | [The guarded serializer control](../../tests/page-ui/clob-json-output.sql) is the exact passing native-PRN control: 14 checks, 183,584 UTF-8 bytes, ASCII wire, unchanged APEX_JSON output. Both Unicode VARCHAR2 and large CLOB values round-trip exactly. It retains CODEX/tcelkxkd/no-APEX-session guards, contains no literal ampersand and performs no DDL, business DML, HTTP or provider call. The prior literal-wire failures remain recorded above. A buffer pass does not prove the ORDS/browser response. |
| Ordinary runtime envelopes | Preserve success/fallback/clarification/error modes, timing/correlation and zero-row refresh display. Quotes, ampersands and HTML must survive JSON transport without double escaping. |

Compile both exact callbacks and check the response MIME/body in the target APEX context. If the numeric probe violates a required result, adjust only conversion handling and rerun affected cases before deployment. A source review is not a conversion, transport or browser pass.

## Minimal native Explorer change from the current baseline

Current page2 `BOREHOLES-EXPLORER` contains one Dynamic Content region calling `gs_borehole_page_api.explorer_html`. Page6 `BOREHOLES-REPORTS` already contains a clustered native Map over every row with coordinates. Current page3 `BOREHOLE` remains an editable modal form; preserve its existing path without adding a new edit entry.

1. Keep page2's route, checksum protection, navigation and breadcrumb. Resolve current components by the live page/region; do not reuse historical numeric IDs.
2. Replace the old capped map/table region with a native read-only Interactive Report using the query below. Use native search, pagination and column filters for State, Operator and Purpose; no new filter page items or custom JavaScript are needed.
3. Save the primary report with Ref, Name, State, Operator, Purpose, Province and Length (m) visible; sort by `UPDATED_AT` descending then `BOREHOLE_ID`. Keep IDs/lineage out of the initial display. Keep text escaping enabled, including plain-text `REPORT_URL`.
4. Add native buttons to Home1, Reports6 (label **View all boreholes map**), Refresh4 and AskAI5. Page6 retains the all-loaded-data map; do not imply it inherits report filters. Preserve page3 unchanged and add no Create/Edit action.
5. Verify the reset count matches SQL (255 at the captured baseline), search an older row beyond the former 75-row cap, combine state/operator/purpose filters, page through results and check narrow-screen layout/map navigation. Capture post-change APEXlang.

```sql
select b.borehole_id,
       b.borehole_ref,
       b.borehole_name,
       b.state_code,
       b.operator_name,
       b.purpose,
       coalesce(b.geological_provinces, b.region_name) province,
       b.depth_metres,
       b.latitude,
       b.longitude,
       s.source_name,
       b.last_refresh_run_id,
       b.borehole_report_uri report_url,
       b.updated_at
  from gs_boreholes b
  left join gs_borehole_sources s on s.source_id = b.source_id
```

Guidance refresh `2026-09-17.2`, topic `apex-source-control`: the six required sources were reread after compaction and their paths/hashes were unchanged. No task scratch was created. This note is the durable local handoff, not an application export or a claim of live acceptance.
