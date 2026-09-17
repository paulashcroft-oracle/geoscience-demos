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

## Isolated queue regression preparation

The corrected fixture passed **18 assertions** on 17 September 2026, with same-session verification that its private table was removed. The execution evidence and prior diagnostic failures are retained below; this remains source-derived testing with the stated storage, concurrency and native-capture limits.

`New-BoreholesFeedbackQueueHarness.ps1` is separate from the unchanged payload-only harness. It never connects or executes SQL. Inspect its metadata, then emit with `-AsSql -ExpectedSourceSha256 <inspected-body-hash> -ExpectedSqlSha256 <inspected-sql-hash> -Nonce <inspected-nonce>`. Reinspect after source changes; the emitted-SQL hash also pins the table schema, specification constant, page handler and nonce. It reports body/spec/handler and emitted-SQL hashes, the exact nonce table, nine extracted routines, and substitutions. Execution has **not** been established by preparation or local generator checks.

The emitted anonymous block requires a fresh `CODEX` connection with `CURRENT_SCHEMA=CODEX` on `DB_UNIQUE_NAME=tcelkxkd`, no APEX session and no existing transaction. It creates only `ORA$PTT_BH08_<nonce>` with `ON COMMIT DROP DEFINITION`, then dynamically compiles the extracted routines after that private table exists. The three `FROM APEX_TEAM_FEEDBACK` sites become the same inline synthetic rows; the two ledger DML references become the nonce table. `%TYPE` declarations still use installed APEX view metadata. No real feedback, queue table, installed package, HTTP endpoint, model or credential is accessed. A missing existing `CREATE TABLE` privilege or nondefault private-table prefix is a stop condition; do not add privileges, alter parameters or substitute a permanent table.

One extraction adaptation is necessary in `upsert_status`: exactly one fixture-local `VARCHAR2(255)` declaration, one call to the unchanged `idempotency_key(p_feedback_id)` function inside the existing `sql%rowcount = 0` branch, and replacement of that single function call in the `INSERT VALUES` expression with its variable. Each substitution is count-guarded. This bridges Oracle's restriction on calling an anonymous-block local function from SQL; the other eight extracted routines remain unchanged apart from the disclosed table/view substitutions. The inserted-key assertions still test the original function result. Production D006 is not edited.

Eighteen assertions include two complete-payload size guards before queue DML, then latest matching feedback selection, two sequential queue calls producing one row, stable idempotency/provenance, failed-to-pending retry behavior, nonfatal missing-match diagnostics with caller JSON preservation, an unchanged propagated `-20000` for an unsupported synthetic app, and nonfatal caller flow through the exact page diagnostic fragment above. Its bind values are synthetic app `106` and page `5`; the fragment is not rewritten or stubbed. Queue snapshots must remain equal across failure cases. These checks do not force an `APEX_DEBUG` failure or prove that an administrator log entry was persisted, nor do they establish native feedback/browser capture.

The private table substitutes exactly `payload_json CLOB` and `response_json CLOB` with `VARCHAR2(4000 BYTE)` because [Oracle confirms LOB columns are unsupported in private temporary tables](https://asktom.oracle.com/ords/asktom.search?tag=clob-in-temporary-table). Before queue DML, the unchanged payload builder produces the complete synthetic payload; guards require its CLOB length to be at most 4000, its extracted text to have the identical UCS2 length, and its full byte length to fit 4000. Nothing is clipped. The fixture frees this owned CLOB and reads the stored payload into VARCHAR2. All other canonical column types remain, while constraints/defaults are omitted as required by [Oracle CREATE TABLE](https://docs.oracle.com/en/database/oracle/oracle-database/26/sqlrf/CREATE-TABLE.html). Coverage is sequential update-before-insert behavior, **not** production CLOB storage, primary-key/unique/check enforcement, concurrent-call idempotency, or production audit-column defaults. The separate unchanged 16-assertion payload harness retains the independent CLOB ownership checks.

The block refuses a pre-existing nonce table, tracks successful creation, and drops only its owned table on success or error. Success verifies its disappearance. A cleanup error is reported separately from the original error; stop and end that dedicated session rather than broadening cleanup. No commits, rollback or permanent DDL are emitted. [Oracle DROP TABLE](https://docs.oracle.com/en/database/oracle/oracle-database/26/sqlrf/DROP-TABLE.html) documents that dropping a private temporary table does not commit an existing transaction. The private definition/data also disappear when its transaction/session ends. Temporary fixture LOB copies are freed; production helper LOB lifecycle is preserved and left to the enclosing call/session.

### First execution and fixture correction, 17 September 2026

The initial CLOB-column fixture failed in a fresh saved-alias `aidemodb` SQLcl 26.2.0.181.2110 session verified as `CODEX`, current schema `CODEX`, database unique name `tcelkxkd`, no APEX session. SQLcl exited 2 with `ORA-20993: Queue fixture failed; originalCode=-14451; cleanupCode=0` (wrapper line 534). No assertion result was emitted. The original wrapper did not identify the failure stage; the emitted DDL included `payload_json CLOB` and `response_json CLOB`, consistent with Oracle's documented PTT restriction. `cleanupCode=0` reports no cleanup error, not verified table absence: the separate absence query was not reached before SQLcl exited. No retry was made before the approved two-column correction above.

Preserved SHA-256 evidence for that failed run:

| Artifact | SHA-256 |
| --- | --- |
| D006 extracted body | `c595cf0ec443f9a39293dda3980901c82a435013adef4b7dc9c418baf5f19710` |
| D006 extracted spec | `5064b8a9551e75242ca4f30f0e2dcf1de0b179b55cce2253cabd437065f365e9` |
| Page diagnostic fragment | `218854d3387db2c8fd0bcedb560d9f2c5a41edb40f45d86101c6a8f55a0e31b2` |
| Generated SQL, nonce `ADC67578F1C141C6` (23,341 characters) | `135169bef24492a8ec660fd02c951479c4ceb9c3c7a1f8cc27cf9a2b640f68b8` |
| Complete submitted SQLcl input | `5218ecbdaf4a47ae8482972dd30108ee8be86b8b0293fcb227f5ff154b4c1604` |
| Raw stdout, 304 UTF-8 bytes | `9048dfd430f99540d538eb5d484d4306a329d7c489d258695ce9955ecbe46888` |
| Raw stderr, 0 bytes | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |

The correction changes only the test generator/template and this evidence. It preserves all nine copied production routines and adds diagnostic stages: 0 guards, 1 CREATE, 2 inner assertions, 3 DROP, 4 absence check. Independent source review found no blocker; production D006 is unchanged.

### Corrected fixture execution, 17 September 2026

One approved corrected run used a fresh connection with the same verified identity and no APEX session. Existing `CREATE TABLE` privilege was confirmed without changing grants. SQLcl exited 2 with `ORA-20993: Queue fixture failed; originalCode=-6550; cleanupCode=0; stage=2` (wrapper line 548). Stage 2 establishes successful private-table creation followed by failure while compiling/executing the inner block. No assertion result was emitted; the numeric wrapper did not retain the underlying PL/SQL compiler message. Owned-table error cleanup reported no error, but the separate absence query was not reached. The dedicated SQLcl process ended. Further execution stopped pending diagnosis; this is **not** a queue test pass.

| Artifact | SHA-256 |
| --- | --- |
| Reviewed generator | `e21ae3f979588913a2003565d2433c8c044d25ae5bc8a8bbd510e837cf8359c5` |
| Reviewed assertion template | `188e694b88ae8263baa6038f3c90d96cb40d132dd600f804279011e0e85258be` |
| Generated SQL, nonce `6832C531BD2546BF` (24,029 characters) | `828d5756706d37501fdf3191f88847a2cfc12b7d30c663b8ab942df9fa7a77bc` |
| Complete submitted SQLcl input | `aeab9593596abf6b7575a95dd6af239526715927717b73dd8b4e14d719b53ff4` |
| Raw stdout, 312 UTF-8 bytes | `4e89f4b820fc9b5dbeb78e636bf8efa58d018dc8de63da06d71f261c44c81caa` |
| Raw stderr, 0 bytes | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |

Body, specification and page-fragment hashes remain those recorded for the first execution. Both runs used memory-only input/output capture; no task scratch or full payload output was created.

### Original compiler diagnostic, 17 September 2026

An approved in-memory `DBMS_SQL.PARSE`-only diagnostic of the exact inner block passed with zero inner executions; its cursor was closed and nonce-table absence verified. This did not reproduce the full fixture failure or establish assertion acceptance. Diagnostic SQL SHA-256: `111d625e3e9276a94585ea293221fbf68dba3ad6f0b46a3d9a982f30957599c8`; complete input: `3f9e2bd73fbf832357fb5224de38743d282106a4d148a4f086e9deb0062ca107`; stdout (236 UTF-8 bytes): `d73e2370e454f1bae67a1e73816a213e4ef415a651092b4de1706ff372529646`; stderr was empty. The diagnostic was not retained as another harness.

The generator then gained only bounded stage-2 `ORA-06550` stack/backtrace output before owned cleanup. One authorized full run, again with verified `CODEX`/`tcelkxkd` identity and no APEX session, failed with the original compiler diagnostic:

```text
ORA-06550: line 281, column 13:
PLS-00231: function 'IDEMPOTENCY_KEY' may not be used in SQL
ORA-06550: line 281, column 13:
PL/SQL: ORA-03066: invalid PL/SQL expression
ORA-06550: line 265, column 11:
PL/SQL: SQL Statement ignored
```

The extracted local helper is not callable from the `INSERT` SQL expression in this anonymous fixture. This does not establish a production package defect. SQLcl exited 2; the outer error remained `originalCode=-6550; cleanupCode=0; stage=2` (line 555), with no assertion result. Cleanup reported no error; the subsequent separate absence query was not reached. Execution stopped without changing the idempotency call or retrying.

| Artifact | SHA-256 |
| --- | --- |
| Generator with bounded diagnostic | `a364fe466e15edbf879d37feb1109188a9844f39547ecf0bbccbe66e10b4209f` |
| Generated SQL, nonce `F4BD50F1C74D44FD` (24,363 characters) | `55994103bd89eabb86ac12241e6571558214162b4916c19953a7dd202b2af89b` |
| Complete submitted SQLcl input | `30b6db8236530885a1618e8c173073584ac4f7761e21c0fad4ad9da993efd5e8` |
| Raw stdout, 569 UTF-8 bytes | `c146e987ca369e1d47934482c4702268f09d8bd4d798c0900a6cf950821cf17d` |
| Raw stderr, 0 bytes | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |

The assertion template, D006 body/specification and page-fragment hashes are unchanged from the corrected-fixture run.

### Verified isolated queue regression, 17 September 2026

After independent review of the disclosed `upsert_status` bridge, one fresh guarded `aidemodb` run verified `CODEX`, current schema `CODEX`, `DB_UNIQUE_NAME=tcelkxkd` and no APEX session. SQLcl exited **0** with `Feedback queue assertions=18; repeatedRows=1; callerFlowSteps=2`. The fixture reported its owned private table removed; a separate same-session query confirmed `POSTCHECK owned_nonce_tables=0`. No production forwarding or business-table DML was performed. This verifies the bounded synthetic sequential queue/error-flow behavior, not production CLOB storage, concurrent idempotency, persisted debug logging or native browser capture.

| Artifact | SHA-256 |
| --- | --- |
| Peer-reviewed generator | `22c38f64fa7b9d07f9710a70db02d5babcb00288a61eced3dcfe4d60359f0a3c` |
| Generated SQL, nonce `849DEA42AE734A81` (24,477 characters) | `595089304a909a72cf4e022ebe9ee09f9d0108b3d2db3ecdb6e47aba757dfbc5` |
| Complete submitted SQLcl input | `d39f1968e0aff75a8713a286ed38b9812b08fca4283240fc7bb648ba9844db42` |
| Raw stdout, 380 UTF-8 bytes | `3b3de848fb7301b3403670aea00785f4e59bae6c37d6c27a4b46873359bc7b27` |
| Raw stderr, 0 bytes | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |

The assertion-template hash remains `188e694b88ae8263baa6038f3c90d96cb40d132dd600f804279011e0e85258be`; D006 body/specification and page-fragment hashes remain those recorded above. Production source and the original 16-assertion CLOB payload harness were unchanged. Input/output stayed in memory, no task scratch was created, and the dedicated SQLcl process ended.
