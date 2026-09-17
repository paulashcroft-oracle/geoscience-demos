# Boreholes callback and native Explorer acceptance

Prepared 17 September 2026 for AIDEMODB workspace/schema `GEOSCIENCE`, app105. These are proposed Page Designer process bodies and acceptance steps, not deployment evidence or a metadata SQL installer. The immutable baseline is `exports/apex/geoscience/105/20260917-before-boreholes-review`; preserve it. Root owns the serialized Builder window, live delivery and post-change APEXlang export. No browser or database actions were performed while preparing this note.

## Ajax callback replacements

Current page4 and page5 sources pass package CLOB results to `HTP.PRN`. Its text overload accepts `VARCHAR2`; `APEX_UTIL.PRN` accepts a CLOB. Set `p_escape => false` for already serialized JSON, preserving the package's JSON encoding and HTML escaping rather than escaping the complete envelope again. [Oracle HTP](https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/HTP.html), [APEX 26.1 PRN](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/PRN-Procedure.html).

Keep each process's name, Ajax Callback execution point, sequence and existing authorization. Change only its PL/SQL body. Do not add commits, new authentication rules, manual output chunking, response wrappers or broad exception handlers.

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

This preserves the current API arguments. D010 sends only `x01` and `x02`; the optional `x03` remains null in that UI. Both current packages copy the completed JSON into a separate temporary CLOB before freeing APEX_JSON output. The callbacks do not need a second JSON parse or a `VARCHAR2` intermediate.

## Targeted checks before acceptance

Root's read-only Oracle probes on 17 September 2026 observed the following with format `999999999D999999` and explicit numeric characters `.,`:

| Probe | Observed result |
| --- | --- |
| Format conversion without grammar/normalization | `1,5` became `15`; `1,000` became `1000`. `+135.5` and outer spaces returned null. `.5`, `1.` and `-20.5` preserved their values; excess fractional digits and exponents returned null. |
| Candidate `CASE` with the grammar above, `trim`, and leading-plus removal (16 rows) | `.5`, `1.`, `-20.5`, `+135.5` and outer-space `129` preserved values. Commas, exponents, `NaN`, `abc`, more than six fractional digits and `1.0000001` returned null. `10001` and `1.5` remained unchanged for package rejection. |

The candidate query passed; the exact helper and complete callbacks still require their own checks. Run [the anonymous helper assertions](../../tests/page-ui/refresh-request-number.sql) in SQLcl before invoking any successful refresh. They use the exact helper above and perform no DDL, DML, package call, commit or network request. Repeat under both session `NLS_NUMERIC_CHARACTERS` settings `.,` and `,.` in an isolated test session; do not change a shared session's settings. This local preparation task did not execute Oracle or browser checks.

| Check | Required result |
| --- | --- |
| `.5`, `1.`, signed decimals, surrounding spaces | Preserve their numeric values, including leading `+`. |
| `1,5`, `1,000`, `NaN`, `Infinity`, `abc`, blank/null | Null conversion and classified package rejection; never reinterpret commas as decimal/group separators. |
| More than six fractional digits | Null conversion, as observed with this format; never silently turn `1.0000001` into valid integer limit `1`. BBOX serialization uses six decimals; the package rejects bounds that collapse at that precision. |
| Exponent forms | Null conversion and classified package rejection; the plain-decimal grammar deliberately excludes exponents. |
| Limits `0`, `10001`, `1.5` | `INVALID_REQUEST`, zero loaded rows, no new attempt and no WFS call. `10000` and `10000.0` are equivalent valid limits; check conversion/range only unless a refresh is explicitly part of the controlled test. |
| Invalid/reversed/out-of-range BBOX | Parseable failure JSON without raw Oracle errors; no attempt or WFS call. |
| CLOB output | In a controlled APEX test context, print fixed JSON exceeding 32,767 bytes, including multibyte text and a final sentinel. Collect the entire response and verify JSON parsing, text equality and final sentinel; no model call is needed. |
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
