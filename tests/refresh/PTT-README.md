# Source-derived loader rollback harness

This is a separate, narrowly scoped alternative for testing the loader's transaction behavior. `fixture-regression.sql` and its `BOREHOLES_TEST` guard remain unchanged. Do not run that existing script in GEOSCIENCE.

`New-BoreholesRefreshPttHarness.ps1` runs offline. It reads the current refresh package body through the package extractor, selects `apply_geojson`, `fail_run`, their four parsing helpers and the response-size constant, and remaps exactly three table identifiers. It embeds those actual declarations in `ptt-loader-fixtures.sql.template`; it does not duplicate the loader implementation. Its default output is inspection metadata. It never connects to a database, writes a file, changes the clipboard or launches a process.

## Review and generate

First verify private temporary table creation and anonymous PL/SQL access in the owning SQL Workshop session. Root owns that capability check and the current checkpoint/exclusive-window gates. The generated harness has not itself been executed merely because its offline checks pass.

Capture the current `sys_context('USERENV','DB_UNIQUE_NAME')` in the approved AIDEMODB / GEOSCIENCE SQL Workshop session; do not infer it from the database display name. The generated block also requires current schema `GEOSCIENCE`, active APEX workspace `GEOSCIENCE`, and `v('APP_USER') = 'CODEX'`. It does not require `USER = GEOSCIENCE`: the observed SQL Workshop session user is the ORDS gateway.

The workspace guard compares documented [`APEX_CUSTOM_AUTH.GET_SECURITY_GROUP_ID`](https://docs.oracle.com/en/database/oracle/apex/26.1/aeapi/GET_SECURITY_GROUP_ID-Function.html) with `APEX_UTIL.FIND_SECURITY_GROUP_ID('GEOSCIENCE')`; the getter does not belong to `APEX_UTIL`. Both missing values fail closed using different sentinels.

```powershell
$inspection = & .\tests\refresh\New-BoreholesRefreshPttHarness.ps1
$inspection | Format-List
$sql = & .\tests\refresh\New-BoreholesRefreshPttHarness.ps1 `
  -AsSql -ExpectedSourceSha256 $inspection.SourceSha256 `
  -Nonce $inspection.Nonce -ExpectedDbUniqueName '<observed DB_UNIQUE_NAME>'
# Review $sql, then submit the complete single block through the owning SQL
# Workshop session only after its baseline and scoped execution gates pass.
```

The target value is mandatory when emitting SQL and is validated as an identifier before becoming a SQL literal. The source SHA must match the inspected body. A new source shape, unexpected relation, installed package reference, qualified dependency, dynamic execution, full rollback, DDL or network API inside the loader block causes generation to fail closed. This is a bounded extractor for current source forms, not a general PL/SQL parser; source changes still require review.

The one outer block creates three nonce-named `ORA$PTT_BH_<16 hex digits>_[BSR]` tables with `ON COMMIT DROP DEFINITION`. It refuses existing names before creation, creates no defaults, constraints, identity columns or indexes, and seeds only synthetic values with explicit run/source IDs. It dynamically parses the loader block after the tables exist, keeping creation, fixtures and cleanup in the same database call/session. No installed refresh package or public wrapper is invoked. The generated SQL contains no business-table references in the executed loader block.

Cleanup runs on both success and error, drops only exact allowlisted names whose creation succeeded in that invocation, and checks their absence in `USER_PRIVATE_TEMP_TABLES`. A cleanup error is reported with the original test error; it must not be reported as a passing run. `-FailAfterFirstTable` intentionally raises after the first creation to exercise partial-creation cleanup. Use it only as an explicitly reviewed second test, not as a normal fixture run. If a call is interrupted or its response is lost, inspect its evidence/session state before retrying; ordinary exception cleanup cannot prove completion after a session/process interruption.

Oracle documents that transaction-scoped PTT creation and explicit PTT drop do not commit an existing transaction. The harness contains no commit or full rollback, and dropping a PTT does not use the recycle bin. See [CREATE TABLE restrictions and lifecycle](https://docs.oracle.com/en/database/oracle/oracle-database/26/sqlrf/CREATE-TABLE.html), [DROP TABLE](https://docs.oracle.com/en/database/oracle/oracle-database/26/sqlrf/DROP-TABLE.html), and [private temporary tables](https://docs.oracle.com/en/database/oracle/oracle-database/26/admin/managing-tables.html).

## Evidence and limits

The assertions exercise valid empty collections, insert/update HISTORIC status, repeated loads, malformed/wrong-shaped GeoJSON, identifiers, row-count cap, numeric/date errors and duplicate identifiers. They verify rollback after an earlier update and after an earlier insert, retained FAILED diagnostics, preserved source timestamp and unrelated caller work. The final PASS is printed only after cleanup verification.

This does **not** establish production identity/default/constraint/index behavior, concurrent upsert behavior, installed-package execution or privileges, public run creation, HTTP status/timeout behavior, or the outer response-serialization rollback. The run rows are preseeded, and the loader calls use explicit run IDs. These are meaningful loader transaction tests, not a replacement for the full isolated-schema regression and approved remote-path acceptance.

Run local generator tests without a database:

```powershell
& .\tests\refresh\Test-BoreholesRefreshPttHarness.ps1
```

Record the source hash, generated nonce/table names, exact target, assertion output and cleanup output when the authorized owner eventually executes the harness. Generated SQL stays in memory unless a caller explicitly retains it in the task's approved artifact location. No task scratch is created by these helpers.

## Installed public API acceptance

`installed-api-acceptance.sql` is a separate integration test, not an installer or a PTT fixture. It is prepared source only until the owner records actual execution. Before running it, root must freshly verify its own SQL Commands page, baseline/checkpoint, exclusive execution window, and installed `GS_BOREHOLE_REFRESH_API` body against extracted SHA256 `39c352c0728239794291865c1e844d4d31747a857a70eab7e6056d6ff7a44b42` (20,445 UTF-8 bytes). The block does not perform that source comparison. Its runtime guard requires database unique name `tcelkxkd`, current schema/workspace `GEOSCIENCE`, session user `ORDS_PLSQL_GATEWAY` and APEX user `CODEX`; these identities alone do not prove the active page is SQL Commands.

Submit the complete anonymous block in one SQL Commands invocation, omitting its final slash. It refuses missing/nonpermanent target tables, any enabled trigger on the three tables, or anything other than one existing `Geoscience Australia Boreholes WFS` source row. Do not disable triggers to pass the guard; unexpected triggers need separate review. It snapshots all three tables into ordered JSON CLOBs in memory, including source timestamps and run history. No snapshot, returned response, source URL or provider message is printed.

Three invalid calls test zero/fractional limits and reversed longitude bounds without a run or HTTP according to the verified source path. One valid public call requests limit 1 in BBOX `129,-24,139,-17`; there is no retry. The test checks JSON, the correlated run and changed-row lineage, then rolls back to its distinct outer savepoint and verifies exact snapshot/count/latest-run/source-timestamp restoration before PASS. Errors also attempt rollback and restoration, then raise a failure containing numeric stage and error codes only. Stages are 1 target/preflight, 2 baseline, 3-5 invalid calls, 6 valid call/JSON, 7 own-change inspection, 8 rollback/parity, 9 LOB release. No commits, DDL or compensating deletes are present. SQL Commands may commit after the block, so rollback remains inside the same invocation.

The normalized installed `USER_SOURCE` comparison is 20,270 UTF-8 bytes with SHA256 `a43f90464c3276cbb1d8f796a707b8675407b79691029a5e3437d7fb94b47b2e`: exclude the `CREATE OR REPLACE ` prefix, remove CR, map NBSP to ordinary space and trim trailing whitespace, preserving complete ordered lines. Failure diagnostics additionally retain only the API's allowlisted error classification; no raw message is emitted. Once rollback parity passes, LOB cleanup failures are reported separately without comparing freed baseline locators.

This test temporarily writes real business tables and takes locks; it does not persist those rows when rollback verification passes. Identity sequence consumption, the external GET and possible platform logs are not reversible. Concurrent writers can cause parity failure and must not be compensated or undone. A valid empty result tests HTTP/wrapper behavior but does not demonstrate rollback of a modified borehole. The 30-second transfer timeout is not a strict end-to-end deadline. This does not cover commit-time deferred constraints, forced HTTP/serialization failures, browser Ajax transport or UI behavior. A lost/interrupted response is uncertain execution: inspect current evidence/state before deciding any retry. The original isolated-schema fixture guard remains unchanged.
