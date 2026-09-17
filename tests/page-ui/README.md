# Long-response browser acceptance

`long-response-callback.sql` is a temporary test fixture for app **105**, page **5**, process **GS_BOREHOLES_AGENT_ASK**. It is not an installer or canonical application source. It handles only the exact nonce below when `APP_USER` is `CODEX` or `DEMO_USER`; every other request keeps the approved package call and its existing CLOB ownership. The fixture branch uses no business data or model. It escapes synthetic HTML text, passes the complete CLOB through unchanged `APEX_JSON.WRITE` serialization and prints with native `APEX_UTIL.PRN`.

1. Within the authorized, exclusive browser verification window, confirm the current callback matches the minimal restore body below. Temporarily replace its PL/SQL body with the fixture, omitting the final SQLcl `/`, and read it back.
2. Use the existing Ask UI to submit `BH_LONG_5AA6E506ED0E4414B62A9B0D5E2AA8C3`. Do not inject fetch/APEX calls or create another UI entry point.
3. Inspect `#bhLongResponseTest` through DOM reads. Its `textContent` must have exactly **514 lines**: `BEGIN <nonce>`, `LINE 0001` through `LINE 0512` in order, and `END <nonce>`. Each numbered line must equal `LINE NNNN | é漢Ω🚀 | <img data-bh-probe="literal"> & "quoted" | ` followed by exactly 96 `x` characters. Expected JavaScript text length is **82,011**, with the ending marker at offset **81,967** (zero-based), both greater than **32,767**. Require `childElementCount = 0` and no `img` element: the markup is visible text. The synthetic image text has no `src` or event handler.
4. Confirm the renderer reports a deterministic answer, no model name, a request ID, nonnegative timings and provider time **0**. Ask/model controls must be enabled again with the loading state cleared.
5. **Immediately restore the exact minimal body below, even if acceptance fails.** Read the saved source back and verify the nonce, `fixture_json`, and `bhLongResponseTest` are absent. Reload the page and verify a normal `count loaded boreholes` request. Record concise results without session URLs or full payloads.
6. Capture final application exports only after restoration and the normal request are verified. If restoration cannot be verified, stop final export/handoff and report the temporary callback state to the owning coordinator.

Approved minimal restore body:

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

The earlier in-memory serializer and Unicode-helper checks remain separate evidence. This fixture tests the actual ORDS/AJAX/renderer path only when submitted through the application and verified as described; preparing or compiling it is not a browser acceptance result.
