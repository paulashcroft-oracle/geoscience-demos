# Boreholes review implementation

## Authority and scope

Paul approved proceeding with the recommendations in this task on 17 September 2026. Target: AIDEMODB workspace/schema GEOSCIENCE, app 105 Boreholes Demo. The approved review is `docs/reviews/2026-09-17-boreholes-performance-ai-review.md`.

Implement the focused Phase 1/2 reliability, deterministic-answer and native reporting changes. Preserve DEMO_USER entry, app104 shared dependencies and pending feedback provenance. Optional infrastructure, caching, file extraction, native agent migration and permission changes requiring a persona decision remain conditional. No full APEX application replacement is authorized.

## Source checkpoint and live-access exception

- Worktree: `C:/Users/pashcrof/.codex/worktrees/e908/Geoscience Demos`.
- Branch: `codex/boreholes-review-fixes`, based on saved-project commit `72f9d7f9d63cb1e123a4ef033f7246c25b0fc828`.
- Saved checkout's modified `.gitignore` and untracked `_gitignore_for_mac_migration` remain untouched.
- Required current pre-change app105 APEXlang export is not yet available. The review established that CODEX SQLcl cannot read the required APEX metadata. The current browser inventory exposes only the in-app browser, while the project requires the approved shared external Chrome workflow.
- Shared launcher verified profile `.tmp-visible-chrome-shared-oracle-work`, port 9333, process 38552 as reusable. No browser-control connection to that Chrome is exposed in this task.
- A source-only checkpoint preserves the approved review and the committed historical implementation. It is not proof of live source equality and does not replace the required live baseline.
- Proceed with local source preparation and non-mutating/local verification. Capture current app/package/service definitions, reconcile drift and commit a repository-safe current baseline before deployment once the approved browser capability is available.

No AI Hub implementation card/version is assigned by the original review handoff. No approval record has been invented. Live deployment and runtime verification are pending; this is not a completed implementation handoff.

## Prepared changes

| Review | Prepared source | Remaining acceptance |
| --- | --- | --- |
| BH01 | Page and server allowlist: Gemini 2.5 Pro, Gemini 2.5 Flash, Command A 03/2025. Pro remains the explanation baseline. | Verify target service definitions and compare quality/latency before changing the default. No workspace catalog changes. |
| BH02–03 | Bounded intent/filter parser; deterministic counts, group charts, ranked lengths, reference lookup, quality and map navigation. SQL evidence supplies both charts and explanation context; state leaders come from counts. Unsupported filters and conversation references request clarification. | Run live page and representative model comparisons after source reconciliation. |
| BH04 | Request/run correlation, separate context/provider/render and download/load timings, classified user errors, complete escaped AI output and explicit fallback. | Provider timeout/error and measured runtime acceptance. |
| BH05 | Validate request/HTTP/GeoJSON/features and values; explicit 30-second transfer timeout; whole-batch rollback preserving the caller transaction and failed-run diagnostic; consistent inserted/updated status; explicit zero/nonzero counts. | Full parsing-schema compilation and isolated transaction/HTTP fixtures. |
| BH06 | Independent-question, pasted-text-only UI; no attachment claims; duplicate-submit prevention and retained retry text; actual execution mode shown. | Browser rendering, keyboard and accessibility checks in app105. |
| BH08 | New feedback payloads select `boreholes` for app105, preserving app104 `geoscience`, historical source task keys and idempotency keys. | Reconcile the endpoint contract before any activation/replay; current pending rows remain untouched. |

The package implementation is in the existing database source files D006, D009 and D010. Deploy only reconciled package changes through the approved GEOSCIENCE workspace path. Do not run these historical installers wholesale: they also contain bootstrap operations unrelated to this fix. The shared feedback package also affects app104, so capture and verify both apps before deploying that package.

## Native Explorer work still required (BH07)

After obtaining current app105 APEXlang, replace the capped custom Explorer list with a native Interactive Report over the loaded boreholes. Keep the existing app105 page3 record route and page6 native Reports map, resolving current IDs and checksum behavior from live metadata. Provide search, pagination, state/operator/purpose filters and useful reference/name/length/source columns over all loaded rows. Verify filters and result counts against SQL, narrow-screen layout, map navigation and existing DEMO_USER/CODEX access. Export the resulting components to canonical APEXlang. No historical SQL export has been edited to masquerade as the current application.

BH09 permissions changes remain conditional on a persona decision. BH10 infrastructure, indexing and caching remain conditional on measured need. No authorization, credential, scheduler, forwarding or full-application replacement changes have been made.

## Verification and access evidence

- `node --test tests/page-ui/boreholes.test.mjs`: 12 behaviour tests passed. These execute the actual embedded JavaScript with a small DOM/APEX test double; they are not browser rendering evidence.
- D010 complete package-body declarations compiled successfully in a non-persistent anonymous Oracle block whose executable body was only `null`.
- D009 agent package-body declarations also compiled in the same non-persistent form. The final unmodified declarations (including the real APEX_AI signature) and final D010 body were recompiled successfully after review fixes.
- `tests/agent/assertions.sql`: 79 assertions passed against the actual body in an anonymous source harness, using the existing data read-only. A harness-only replacement for the provider call counted attempts and raised if invoked; the final counter was zero. Checks cover routing, unsupported/conflicting filters, SQL counts/state leader, older reference retrieval, deterministic/fallback modes, correlation/timing, complete escaped responses and useful evidence. The reserved test-helper name `check` was corrected to `assert_true` following the first compiler result.
- Nineteen assertions against the actual extracted refresh helpers passed in Oracle: canonical URL, valid extrema, integer-zero formatting, invalid limits, invalid/null/equal/rounded-equal BBOX bounds, valid/absent date and numeric fields, and rejected invalid values. No WFS call or data mutation occurred.
- With SQLcl `serveroutput` enabled, the adapter additionally printed `Insufficient privileges to create table. Contact your DBA.` before the successful block result and `PASS: 79 agent regression assertions`. The harness contains no project DDL/DML. No privilege change or workaround was attempted. Subsequent final body compilation with `serveroutput` off returned clean successful results. This diagnostic does not establish live deployment or refresh transaction verification.
- Full refresh-body anonymous compilation was attempted without calling any functions. Oracle returned `ORA-01031` at the INSERT/UPDATE references because the saved CODEX database identity lacks those rights. This does not establish successful package compilation. No grants or alternate account were used.
- Prepared `tests/refresh/fixture-regression.sql` is guarded to an isolated `BOREHOLES_TEST` owner/current schema. It exercises actual loader rollback and diagnostics, rolls back its fixtures, and makes no HTTP calls. It has not been executed; do not run it against live GEOSCIENCE.
- Browser control returned `Browser is not available: chrome`; its inventory exposed only an empty in-app browser. The approved shared Chrome profile/port exists, but this task cannot connect through its available browser capability. No login rejection occurred. CODEX standing authorization and the ability to use Continue as Demo User remain valid.

## Resume and delivery sequence

1. Restore this task's supported connection to the existing shared external Chrome session. No new login authorization is required. Use CODEX for Builder/SQL Workshop and Continue as Demo User for persona checks.
2. Capture current app105 (and app104 for shared-feedback changes) repository-safe APEXlang plus relevant package bodies; compare against prepared source and preserve intervening work. Commit that current baseline.
3. Compile/test the reconciled packages using the approved workspace identity; run isolated refresh failure fixtures and targeted runtime checks. Apply native Explorer changes surgically.
4. Verify ordinary deterministic prompts make no model calls; test supported explanation services/fallback and refresh JSON/UI counts. Preserve the pending feedback row and demo login behavior.
5. Capture post-change APEXlang/package evidence, commit and push; record actual runtime/model results and remaining human acceptance.

No task scratch was created. Browser profiles and unrelated files were preserved. The transient audit excludes this worktree because it is beneath `.codex`; this coverage limitation is retained, not reported as a clean full scan.

## Git and recovery

The source baseline/review checkpoint is `f200ac0` on `codex/boreholes-review-fixes`. The implementation checkpoint on that branch contains the prepared source, tests and this evidence; it remains explicitly undeployed. The configured recovery repository is `https://github.com/paulashcroft-oracle/geoscience-demos`. Restore the exact reviewed revision from the branch's commit history into a separate checkout, then reconcile it against the required current live baseline before delivery.

A read-only remote check initially failed with Windows Schannel `SEC_E_NO_CREDENTIALS`. The documented command-scoped `-c http.sslBackend=openssl` retry succeeded. No global or repository Git configuration was changed. Final commit/push identity is reported by the task after verification; no PR is being represented as runtime-verified.
