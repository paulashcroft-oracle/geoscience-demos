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
