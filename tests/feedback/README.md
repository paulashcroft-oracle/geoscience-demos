# Feedback payload and queue visibility checks

`New-BoreholesFeedbackPayloadHarness.ps1` reads the current D006 package source and emits one anonymous PL/SQL block. It never connects to Oracle. Inspect it first, then pass the returned source hash to `-AsSql -ExpectedSourceSha256 <hash>` and execute only through the coordinating task's verified GEOSCIENCE path.

Submit only the generated anonymous block to SQL Workshop or the MCP SQL statement tool, without `SET DEFINE`, `PROMPT`, a standalone `/`, or other SQLcl script directives. Fixture and expected text construct the ampersand with `chr(38)`; the builder rejects any literal ampersand in the complete emitted block, preventing SQLcl substitution without session-setting changes. The earlier SQLcl attempt reported `Substitution cancelled`; subsequent empty tool results did not establish an Oracle test pass.

The block extracts the exact five payload helpers and specification constant. It substitutes two inline rows for the sole `APEX_TEAM_FEEDBACK` SELECT; column `%TYPE` declarations still depend on that installed APEX view's metadata. It emits no package installation, queue routine, table DML, business-table read, forwarding or provider call. A stale source hash and unexpected mutation/table dependency are rejected by the builder.

The 16 assertions check app 104 `geoscience` and app 105 `boreholes`, historical task keys `geoscience-001`/`geoscience-003`, unchanged `geoscience-apex-feedback-<id>` idempotency keys, original record/text preservation, and usable independent temporary CLOBs after later output cleanup. A missing-row test verifies the expected error while preserving an unrelated caller's active APEX_JSON output. The block releases its own temporary CLOBs on success/error. These fixtures do not establish queue insertion/idempotency behavior, HTTP readiness or live deployment.

## Contract reconciliation, 17 September 2026

Read-only local evidence from the current AI Hub checkout at `C:/Users/pashcrof/Documents/Codex Projects/AI Hub`:

- `database/apex-workspace/2090_restore_feedback_ords_routes_and_catalog.sql:144` routes `POST /projects/:project_key/feedback` to `HUB_SOURCE_FEEDBACK_API.CREATE_FEEDBACK`, passing the path project, body, client header and idempotency header.
- `database/apex-workspace/2030_harden_feedback_defect_classification.sql:135` validates the active project and client scope; lines 489/525 use the path project with `feedback.write`. Lines 613–626 accept the payload's source application, page, record, user, time, feedback and details fields. The raw body is retained as `SOURCE_PAYLOAD_JSON` at lines 691/710. Nested `source.projectKey` and `source.taskKey` are provenance, not routing overrides or instructions to change the historical source task.
- The same source at lines 277–290 accepts the supplied/header idempotency key before its JSON/record fallbacks. Lines 529–542 fingerprint the request and reject changed content under the same client/key with HTTP 409. `docs/feedback-agent-project-onboarding-checklist.md` requires per-project clients, preserved request/key on uncertain retry, and response-only outcomes without invented task creation. Current local source is not proof of deployed endpoint behavior.

The prepared mapping therefore preserves the current contract: new app 105 payloads identify `boreholes`; app 104 remains `geoscience`. Future delivery must also select the matching endpoint path and project client. It must not activate or replay anything as part of this patch. Existing pending payloads and statuses remain untouched; the existing `upsert_status` regenerates payloads when invoked, so reconciliation/replay needs its separately approved scope.

## Proposed surgical page 10030 diagnostic

The current app 105 checkpoint `pages/p10030-feedback.apx:252` queues at sequence 20 after native `APEX_UTIL.SUBMIT_FEEDBACK` at sequence 10. Its `WHEN OTHERS THEN NULL` hides errors. The subsequent branch goes to page 10031 and suppresses process success messages. A blocking APEX page error is unsuitable for a secondary queue failure because native capture must continue.

Keep the process sequence, condition and call unchanged; replace its exception handler with this non-fatal administrator diagnostic. This proposal is not a live edit:

```plsql
exception
  when others then
    begin
      apex_debug.error(
        p_message => 'GS_FEEDBACK_QUEUE_FAILED app=%s page=%s code=%s',
        p0 => to_char(:APP_ID),
        p1 => to_char(:P10030_PAGE_ID),
        p2 => to_char(sqlcode)
      );
    exception
      when others then null; -- Diagnostics must not reject native feedback.
    end;
```

D006 separately logs the previously silent `NO_DATA_FOUND` lookup using only app/page/error code and the numeric feedback ID when available; it preserves the existing swallowed-exception behavior. The page handler is still needed for other queue errors. Neither diagnostic logs feedback text, username, payload, raw SQLERRM, credential or session URL. Review failures through the APEX administrator debug log; this does not add a user notification or durable forwarding retry mechanism.

Oracle APEX 26.1 documents that [`APEX_DEBUG.ERROR`](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/ERROR-Procedure.html) logs even when debug mode is disabled. The [`APEX_DEBUG` reference](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/APEX_DEBUG.html) identifies the administrator debug UI and `APEX_DEBUG_MESSAGES` as viewing paths.

The D006 payload fix creates and copies to a call-duration temporary CLOB before freeing APEX_JSON output. Exception cleanup frees only output initialized by that invocation and any partial returned CLOB. No API, queue DML, activation, replay or database action was performed by the source task. No task scratch was created.
