# Boreholes surgical delivery checklist

Prepared 17 September 2026 for the already-authorized review implementation. Target: AIDEMODB (`DB_UNIQUE_NAME=tcelkxkd`), workspace/schema `GEOSCIENCE`, APEX user `CODEX`, app 105 Boreholes Demo; shared feedback also affects app 104 Geoscience Demos. Root owns delivery, application acceptance and both post-change exports. This checklist adds no approval requirement.

**Current status: production package bodies and application components are still unchanged.** GEO released the shared Builder window to POLICING; the next GEO implementation window is pending. Resume within the coordinator's serialized ownership, revalidate the target and continue the existing authorization. Do not use another task's Builder window.

AI Hub implementation owner: **`boreholes-005` — Implement approved Boreholes reliability and performance review**, in the [Boreholes project board](https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/aihub/ai-hub/project-kanban?request=PROJECT-boreholes). Fresh full-bundle readback at `2026-09-17T09:04:24Z` verified project `boreholes`/ID 10, app 105, current row **1202/version 2**, **BUILD/HIGH**, actor `codex-boreholes`, and `needsHumanReview=true`. Paul’s existing 17 September proceed instruction and coordinator task `01a0ad1c-f2e0-76f0-a3a9-69342e3c67db` are recorded as the authority source; no approval row or human acceptance was fabricated. The four older completed migration cards remain unchanged.

Workflow writes used only the guarded canonical Boreholes AIDEMODB profile: create key `boreholes-review-20260917-create-v1` (201, row 1201/version 1), evidence key `boreholes-review-20260917-evidence-v1` (201, thread **1871**), version-guarded correction key `boreholes-review-20260917-serializer-state-v1` (200, row 1202/version 2), and correction evidence key `boreholes-review-20260917-serializer-evidence-v1` (201, thread **1872**). Full readback confirmed both exact comments, the details-only version diff, unchanged review state and empty approval collection. Thread 1872 supersedes thread 1871’s earlier unresolved serializer result. Re-read the live bundle before delivery; this dated receipt is not current queue authority.

## Exact source and order

Use [the package extractor](../../scripts/Get-BoreholesPackageSource.ps1) with the selected package, `-Unit Body -AsSource -ExpectedSha256 <hash>`. It emits only that package statement. Submit one body at a time, in this order; retain the unchanged specifications. Never execute D006/D009/D010 wholesale: their surrounding installers are outside this surgical delivery.

| Order | Package body | Source | UTF-8 bytes / characters | Extracted statement SHA-256 |
| ---: | --- | --- | ---: | --- |
| 1 | `GS_BOREHOLE_REFRESH_API` | D009 | 20,445 | `39c352c0728239794291865c1e844d4d31747a857a70eab7e6056d6ff7a44b42` |
| 2 | `GS_BOREHOLE_AGENT_API` | D009 | 31,222 | `e9113312116420acda8a52977e289d0f28c35ab241b57cc5d848392c89b51e62` |
| 3 | `GS_BOREHOLE_PAGE_API` | D010 | 36,814 | `00e9a25839e9da2b8aec8ed5d183f45e92ede60a3fbf1814670568f6b4ce575e` |
| 4 | `GS_AI_HUB_FEEDBACK` | D006 | 13,383 | `c595cf0ec443f9a39293dda3980901c82a435013adef4b7dc9c418baf5f19710` |

These hashes describe the extractor's current UTF-8 statement, including `CREATE OR REPLACE` and retained internal line endings, without BOM or a terminal SQLcl slash. Reinspect after any source edit or line-ending change. D006 is `database/006_create_geoscience_feedback_queue.sql`; D009 is `database/009_create_boreholes_refresh_agent_api.sql`; D010 is `database/010_create_boreholes_page_api.sql`.

For the registered feedback delivery copy use **`gs_ai_hub_feedback-review-fix-v2.sql` only**; its upload hash is `bb5d8848b927d163aa405273ba42aa575c667d73c664ddb2b0d806e92b3ec24d`. The older copy is superseded. Upload-file and extracted-statement hashes have different framing; do not interchange them.

## Baseline, transport and compile checks

- [App 105 baseline](../../exports/apex/geoscience/105/20260917-before-boreholes-review/README.md), [app 104 baseline](../../exports/apex/geoscience/104/20260917-before-boreholes-review/README.md), and [eight verified package baseline units](../../exports/database/geoscience/20260917-before-boreholes-review/README.md) are captured in pushed checkpoint `f696b98d8876a0cc3cfce37273cd1b5a492d68ce`. Keep these directories immutable. The raw app ZIPs remain registered private rollback evidence in the existing task run.
- Before the first mutation, confirm the current live source still matches that baseline and the four existing package bodies remain VALID. Use the already-verified CODEX GEOSCIENCE SQL Workshop identity; no privilege expansion or full application replacement is part of this work.
- Supported CUA `setValue` on the observed AX SQL editor has been verified with a 23,203-character block and exact normalized SHA-256 readback. Clipboard/paste was ineffective; the native file chooser timed out and uploaded nothing. Use the verified editor path, not those failed methods. The 36,814-character page body still needs its own complete readback and compile evidence; the smaller fixture did not prove every larger statement.
- For SQL Commands, prepare the selected statement with CR characters removed and no standalone `/` or SQLcl meta-command lines. Compute the normalized candidate hash and compare the entire observed editor text before Run. Do not truncate, wrap, or split a package body. After an uncertain response, inspect current source/status before retrying.
- After **each** body, inspect its `USER_ERRORS` rows and `USER_OBJECTS` status: no compilation errors and `PACKAGE BODY` VALID. Record warnings separately. Compare complete ordered `USER_SOURCE` against the submitted unit using the baseline's documented prefix/newline/space normalization; a success banner alone is insufficient. Verify the associated specification remains VALID and unchanged.
- If delivery fails, preserve the actual error and current source. Repair the source and regenerate its hash, or surgically restore the affected `.pkb` from the package baseline and verify validity/source equality. Restore only changed page components from the corresponding APEXlang baseline when needed. The baseline is recovery evidence, not authority to import/replace either whole application.

## Application dependencies after body delivery

Use [the callback and Explorer note](20260917-boreholes-callback-acceptance.md) and [the feedback note](../../tests/feedback/README.md); do not duplicate their implementation SQL here. Resolve current component identities in the owned Builder window. Keep existing routes, checksum protection, process conditions and authorization.

| Component | Surgical dependency and acceptance |
| --- | --- |
| Page 4 `GS_BOREHOLES_REFRESH` | Apply the reviewed decimal parser before calling the new refresh body, and use the current native CLOB output implementation from the linked callback note. Its actual-serializer buffer test passed; browser AJAX acceptance remains pending. Malformed input must return classified JSON without starting a run/WFS call; verify zero/nonzero counts and timing/error presentation. |
| Page 5 `GS_BOREHOLES_AGENT_ASK` | Use the current native complete-CLOB output implementation from the linked callback note; preserve x01/x02 and optional x03 signature. The new UI sends independent questions and no x03 context. Confirm browser AJAX delivery, deterministic/clarification/fallback/provider modes, correlation/timings, retained retry text, escaping and complete long responses. |
| Page 10030 `Queue AI Hub Feedback` | Preserve native submit at sequence 10 and queue at sequence 20. Apply the proposed non-fatal administrator error diagnostic for other queue failures; the body now diagnoses a missed lookup. Log only app/page/code and available numeric correlation. Preserve native capture and app104 behavior; do not activate forwarding, replay, rewrite pending payloads or change historical task/idempotency keys. |
| Page 2 Explorer | Replace the capped dynamic region with the reviewed native read-only Interactive Report over all loaded rows, with search/pagination/state/operator/purpose filters. Verify counts against current SQL, older-row retrieval, narrow layout and navigation. Preserve page3, and label page6 as the all-loaded-data map rather than implying report-filter propagation. This component work is not supplied by the package bodies. |

Retain DEMO_USER entry. Keep the observed service allowlist `google_gemini_2_5_pro`, `google_gemini_2_5_flash`, `cohere-command-a-03-2025`; Pro remains the explanation baseline. No service mutation, permissions redesign, cache or infrastructure change is included.

## Evidence and remaining acceptance

| Check | Status at preparation |
| --- | --- |
| Agent and page-body anonymous compilation; 79 agent assertions with zero provider attempts | Passed; source-level evidence, not installed-package/browser acceptance. |
| Refresh helper 19 assertions; exact callback-number helper 36 assertions | Passed. |
| Minimal private temporary table capability | Passed in owned GEOSCIENCE SQL Commands, reported 0.21 seconds. |
| Full source-derived loader fixture | **33 assertions passed**, reported 0.20 seconds; all three nonce PTTs verified removed. Production package was not called. |
| Payload CLOB/mapping fixture | **16 source-derived assertions passed** through SQLcl 26.2 in the normal-user context using the saved CODEX alias. No queue DML or forwarding occurred. The earlier substitution cancellation/empty MCP results are superseded by this observed direct-CLI pass. |
| Long CLOB JSON output | **14 assertions passed** through guarded direct SQLcl using the actual application serializer and native `APEX_UTIL.PRN`: **183,584-byte ASCII-escaped JSON**, with actual Unicode VARCHAR2 and CLOB inputs decoded intact and buffer parity verified. Earlier artificial literal-Unicode wire conversion failed native and 4,000-unit chunk output even with closed headers; the custom helper is abandoned. No generic literal-Unicode transport fix is claimed. Use the linked callback note/test, retain its SQLcl/no-active-APEX-session guard, and still verify actual browser AJAX/rendering acceptance. |
| Installed bodies, p4/p5/p10030 changes, native p2 and app104/app105 runtime checks | Not yet deployed or accepted. |

The loader fixture covers parse/validation errors, repeat loads, rollback of earlier insert/update work, retained failure diagnostics and cleanup. It does not establish production defaults/identity/constraints/indexes/concurrency, public-wrapper execution or HTTP behavior. The isolated `BOREHOLES_TEST` fixture retains its guard and must not run against GEOSCIENCE.

Root completes the remaining focused checks in the authorized target: feedback mapping/CLOB behavior without replay, actual callback transport, installed refresh success/failure behavior, deterministic questions without inference, representative explanation/fallback calls, native Explorer and both applications' preserved entry/feedback behavior. Keep any controlled data/model request attributable to its actual test; the single pre-change 13,973-ms observation is not a benchmark distribution.

After verification, root captures app104/app105 post-change APEXlang Standard Exports and relevant package source, excludes workspace credential/service definitions, records exact checks and unresolved acceptance, then commits/pushes the source and evidence. Root also owns the registered artifact lease/cleanup checks; this checklist created no task scratch. Detailed chronology remains in [the implementation evidence](20260917-boreholes-review-implementation.md).
