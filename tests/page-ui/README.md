# Long-response and unavailable-service browser acceptance

`long-response-callback.sql` is a temporary test fixture for app **105**, page **5**, process **GS_BOREHOLES_AGENT_ASK**. It is not an installer or canonical application source. It handles only the two exact nonces below when `APP_USER` is `CODEX` or `DEMO_USER`; every other request keeps the approved package call and its existing CLOB ownership. The long-response branch uses no business data or model. It escapes synthetic HTML text, passes the complete CLOB through unchanged `APEX_JSON.WRITE` serialization and prints with native `APEX_UTIL.PRN`. The fallback branch reads current borehole evidence through the installed API using an explicitly unallowlisted service; it changes no business records or shared-service settings.

1. Within the authorized, exclusive browser verification window, confirm the current callback matches the minimal restore body below. Temporarily replace its PL/SQL body with the fixture, omitting the final SQLcl `/`, and read it back.
2. Use the existing Ask UI to submit `BH_LONG_5AA6E506ED0E4414B62A9B0D5E2AA8C3`. Do not inject fetch/APEX calls or create another UI entry point.
3. Inspect `#bhLongResponseTest` through DOM reads. Its `textContent` must have exactly **514 lines**: `BEGIN <nonce>`, `LINE 0001` through `LINE 0512` in order, and `END <nonce>`. Each numbered line must equal `LINE NNNN | é漢Ω🚀 | <img data-bh-probe="literal"> & "quoted" | ` followed by exactly 96 `x` characters. Expected JavaScript text length is **82,011**, with the ending marker at offset **81,967** (zero-based), both greater than **32,767**. Require `childElementCount = 0` and no `img` element: the markup is visible text. The synthetic image text has no `src` or event handler.
4. Confirm the renderer reports a deterministic answer, no model name, a request ID, nonnegative timings and provider time **0**. Ask/model controls must be enabled again with the loading state cleared.
5. Submit `BH_FALLBACK_D61D8013299446B08CA23F098F144708` through the same native Ask UI. This branch calls the installed `ask_json` with fixed prompt `explain count by state`, service `BH_TEST_NO_PROVIDER`, and null screen context. First verify the installed allowlist still excludes that service: current source returns null before service lookup or `APEX_AI.CHAT`. Require `DETERMINISTIC_FALLBACK` / `SERVICE_UNAVAILABLE` behavior: visible **Data answer - AI unavailable**, **AI explanation unavailable**, the safe `SERVICE_UNAVAILABLE` classification, no model-used label, request ID and nonnegative timings. Do not require provider time0: this stage includes local allowlist validation. Verify factual state counts against current SQL evidence and safely rendered text; at the captured255-row baseline the counts were NT187, WA65, NSW1, QLD1 and SA1. The submitted fallback nonce must remain in the prompt, with retry guidance visible, Ask/model controls enabled, the prompt editable and loading state cleared. Retaining the nonce tests UI retry-text preservation; the nonce is not the semantic prompt sent to the API.
6. **Immediately restore the exact minimal body below after these two native UI prompts, or sooner if either acceptance fails.** Read the complete saved source back: the restore body is **265 UTF-8 bytes**, SHA256 `bbb81f6d83c903a19f3f5fff86b4c896a18042747234891d43c825429000ccc9` with LF, no BOM/trailing newline/slash. Verify both nonces, `c_fallback_nonce`, `BH_TEST_NO_PROVIDER`, `fixture_json`, and `bhLongResponseTest` are absent. Reload the page and verify a normal `count loaded boreholes` request. Record concise results without session URLs or full payloads.
7. Capture final application exports only after restoration and the normal request are verified. If restoration cannot be verified, stop final export/handoff and report the temporary callback state to the owning coordinator.

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

The earlier in-memory serializer, Unicode-helper and installed-API checks remain separate evidence. The fallback extension exercises native UI submission, actual ORDS/AJAX transport, installed classified-fallback JSON, rendering and control/retry recovery together; it does not simulate a provider timeout, HTTP/authentication failure, empty response or interrupted network, and does not establish shared-service configuration. No provider invocation follows from the verified unallowlisted-source path, not from a zero timing value. The fixture frees only the temporary locators it creates; installed API responses retain the normal callback's call-duration ownership. Exceptions are re-raised. Preparing or compiling this fixture is not browser acceptance.

On 17 September 2026 the revised fixture compiled successfully as an **uncalled nested procedure** in a fresh saved `aidemodb` SQLcl session, with verified CODEX / `tcelkxkd` / no-APEX-session guards and exit0. The terminal slash was removed and both `gs_borehole_agent_api.ask_json` references qualified with `geoscience.` only in memory. Fixture invocations, HTTP/model requests, business DML, APEX session creation and persistent database objects were zero. The first sandboxed SQLcl launch failed during Java security initialization before connection; supported scoped normal-user execution succeeded without runtime/security changes. Browser installation and both native UI checks remain pending.

Revised fixture file: **3,813 bytes**, SHA256 `8e0f7070e1b937ee4b0b1dc3f8e22ceac05396b85e9bb2cadd870bd1c1b7feb2`. Page Designer body after removing the terminal slash and final newline: **3,810 UTF-8 bytes / 101 lines**, SHA256 `eb873d298de0c003efe2a9bcf843ddbb3c0e2e5281ef4406b56ad66c5a7f63a8`. These are different from the 265-byte restore body above. The SQL fixture has no literal ampersand; the long-response nonce is unchanged.
