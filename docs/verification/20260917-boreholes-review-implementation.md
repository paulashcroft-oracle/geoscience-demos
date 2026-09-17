# Boreholes review implementation

## Authority and scope

Paul approved proceeding with the recommendations in this task on 17 September 2026. Target: AIDEMODB workspace/schema GEOSCIENCE, app 105 Boreholes Demo. The approved review is `docs/reviews/2026-09-17-boreholes-performance-ai-review.md`.

Implement the focused Phase 1/2 reliability, deterministic-answer and native reporting changes. Preserve DEMO_USER entry, app104 shared dependencies and pending feedback provenance. Optional infrastructure, caching, file extraction, native agent migration and permission changes requiring a persona decision remain conditional. No full APEX application replacement is authorized.

## Source checkpoint and deployment prerequisites

- Worktree: `C:/Users/pashcrof/.codex/worktrees/e908/Geoscience Demos`.
- Branch: `codex/boreholes-review-fixes`, based on saved-project commit `72f9d7f9d63cb1e123a4ef033f7246c25b0fc828`.
- Saved checkout's modified `.gitignore` and untracked `_gitignore_for_mac_migration` remain untouched.
- Required current pre-change app105 APEXlang export is not yet available. CODEX SQLcl cannot read the required APEX metadata; browser access has now been restored through the existing extension-enabled Default Chrome profile.
- The retained CDP profile/port 9333 was reusable but did not provide the extension connection required by this task's browser tool. It remains untouched. The coordinator authorized the existing Default profile, and both runtime entry and CODEX Builder login succeeded there.
- The coordinator then identified shared-profile Builder session contention across projects. Operation `browser-recovery-20260917` v2 assigns POLICING first, GOVERNMATE second, GEOSCIENCE third. This task acknowledged the hold and will perform no Builder login, logout, workspace switch or navigation until explicit ownership handoff. Independent source and runtime inspection may continue.
- A source-only checkpoint preserves the approved review and the committed historical implementation. It is not proof of live source equality and does not replace the required live baseline.
- Capture current app/package/service definitions, reconcile drift and commit a repository-safe current baseline during the assigned Builder window before deployment.

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

`scripts/Get-BoreholesPackageSource.ps1` inspects or returns one explicitly selected package unit and supports an expected SHA-256 guard. It excludes D006 wrappers and outer COMMIT, D009 bootstrap statements and D010 SQLcl commands. Eight current units and three refusal cases were checked. This line-based extractor supports the current source framing; it is not a PL/SQL parser, deployment tool or proof of live equality. Inspect the emitted unit and compile it through the approved target path.

## Native Explorer work still required (BH07)

After obtaining current app105 APEXlang, replace the capped custom Explorer list with a native Interactive Report over the loaded boreholes. Keep the existing app105 page3 record route and page6 native Reports map, resolving current IDs and checksum behavior from live metadata. Provide search, pagination, state/operator/purpose filters and useful reference/name/length/source columns over all loaded rows. Verify filters and result counts against SQL, narrow-screen layout, map navigation and existing DEMO_USER/CODEX access. Export the resulting components to canonical APEXlang. No historical SQL export has been edited to masquerade as the current application.

BH09 permissions changes remain conditional on a persona decision. BH10 infrastructure, indexing and caching remain conditional on measured need. No authorization, credential, scheduler, forwarding or full-application replacement changes have been made.

## Verification and access evidence

- `node --test tests/page-ui/boreholes.test.mjs`: 13 checks passed, including the observed workspace model IDs and Pro ordering. Behaviour checks execute the actual embedded JavaScript with a small DOM/APEX test double; they are not browser rendering evidence.
- D010 complete package-body declarations compiled successfully in a non-persistent anonymous Oracle block whose executable body was only `null`.
- D009 agent package-body declarations also compiled in the same non-persistent form. The final unmodified declarations (including the real APEX_AI signature) and final D010 body were recompiled successfully after review fixes.
- `tests/agent/assertions.sql`: 79 assertions passed against the actual body in an anonymous source harness, using the existing data read-only. A harness-only replacement for the provider call counted attempts and raised if invoked; the final counter was zero. Checks cover routing, unsupported/conflicting filters, SQL counts/state leader, older reference retrieval, deterministic/fallback modes, correlation/timing, complete escaped responses and useful evidence. The reserved test-helper name `check` was corrected to `assert_true` following the first compiler result.
- Nineteen assertions against the actual extracted refresh helpers passed in Oracle: canonical URL, valid extrema, integer-zero formatting, invalid limits, invalid/null/equal/rounded-equal BBOX bounds, valid/absent date and numeric fields, and rejected invalid values. No WFS call or data mutation occurred.
- With SQLcl `serveroutput` enabled, the adapter additionally printed `Insufficient privileges to create table. Contact your DBA.` before the successful block result and `PASS: 79 agent regression assertions`. The harness contains no project DDL/DML. No privilege change or workaround was attempted. Subsequent final body compilation with `serveroutput` off returned clean successful results. This diagnostic does not establish live deployment or refresh transaction verification.
- Full refresh-body anonymous compilation was attempted without calling any functions. Oracle returned `ORA-01031` at the INSERT/UPDATE references because the saved CODEX database identity lacks those rights. This does not establish successful package compilation. No grants or alternate account were used.
- Prepared `tests/refresh/fixture-regression.sql` is guarded to an isolated `BOREHOLES_TEST` owner/current schema. It exercises actual loader rollback and diagnostics, rolls back its fixtures, and makes no HTTP calls. It has not been executed; do not run it against live GEOSCIENCE.
- The original `Browser is not available: chrome` transport failure is resolved. The task now has two owned tabs in the verified Chrome extension connection. Continue as Demo User succeeded, and fresh CODEX sign-in succeeded using native password autofill. A first stale form returned `Your session has ended`; it was not credential rejection. No password was read into a prompt, command or source.
- Runtime baseline: Home shows 255 loaded records, 250 from WFS. Explorer renders 75 table rows and no search input. Reports renders the native map and state counts NT187, WA65, NSW1, QLD1, SA1, while the stale caption incorrectly says WA dominates. These findings confirm the prepared grounding fix and remaining native Explorer work.
- The live assistant selector exposes `google_gemini_2_5_pro`, `google_gemini_2_5_flash` and `cohere-command-a-03-2025`. The prepared allowlists had used underscores for Command A; both were corrected to the observed hyphenated ID. No model or refresh request was triggered during baseline inspection.

## Resume and delivery sequence

1. Receive explicit GEOSCIENCE Builder ownership from the coordinator and revalidate the current page/workspace. Chrome transport and CODEX/native-autofill access have already succeeded; no repeat login authorization is required.
2. Capture current app105 (and app104 for shared-feedback changes) repository-safe APEXlang plus relevant package bodies; compare against prepared source and preserve intervening work. Commit that current baseline.
3. Compile/test the reconciled packages using the approved workspace identity; run isolated refresh failure fixtures and targeted runtime checks. Apply native Explorer changes surgically.
4. Verify ordinary deterministic prompts make no model calls; test supported explanation services/fallback and refresh JSON/UI counts. Preserve the pending feedback row and demo login behavior.
5. Capture post-change APEXlang/package evidence, commit and push; record actual runtime/model results and remaining human acceptance.

Browser profiles and unrelated files were preserved. The transient audit excludes this worktree because it is beneath `.codex`; this coverage limitation is retained, not reported as a clean full scan. The saved project's ignore checker passed all 22 checks before preparing export storage.

The example lifecycle Init command failed in Windows PowerShell with `SecurityError / UnauthorizedAccess: running scripts is disabled on this system`. A supported scoped normal-user retry failed identically. Its child context was `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`, version `5.1.26100.9168`, Desktop, host `PASHCROF-99QG4M`, culture `en-US`, identity `PASHCROF-99QG4M\pashcrof`. A read-only probe returned effective `Restricted` with every execution-policy scope `Undefined`.

The coordinator reconciled the discrepancy: the supported installed PowerShell 7 runner has a separate existing `RemoteSigned` policy. Before any successful Init or Plan, the task selected that runbook-supported initial runner and verified `C:\Users\pashcrof\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\powershell\pwsh.exe`, `7.6.5` Core, `en-AG`, host `PASHCROF-99QG4M`, normal-user identity `pashcrof`. Init succeeded without an execution-policy override/change. Owned run `95453d56b8ba4af48f8e43387463c979` is under the saved project's `.local/tasks/boreholes-review-20260917`, with its manifest under `.local/artifact-hygiene/manifests` and an active lease. Registration and final lease/cleanup checks remain pending. All Plan/Apply steps must assert this same selected engine/version/edition/host/culture.

Shared-guidance refresh `2026-09-17.1` selected credentials, APEX source control, APEX browser, GitHub delivery and artifact hygiene. The required parent/project instructions and all nine routed standards were fully reread. The current Git standard supersedes older skill advice to rebind worktrees or dump all Git configuration; this task preserves its existing worktree and uses scoped diagnostics.

## Git and recovery

The source baseline/review checkpoint is `f200ac0` on `codex/boreholes-review-fixes`. Implementation checkpoint `b71e0ab25852f1e87a569172f99b23d4c04707d9` was pushed and its exact remote ref verified; it remains explicitly undeployed. The configured recovery repository is `https://github.com/paulashcroft-oracle/geoscience-demos`. Restore the exact reviewed revision from the branch's commit history into a separate checkout, then reconcile it against the required current live baseline before delivery.

A read-only remote check initially failed with Windows Schannel `SEC_E_NO_CREDENTIALS`. The documented command-scoped `-c http.sslBackend=openssl` retry succeeded. No global or repository Git configuration was changed. Final commit/push identity is reported by the task after verification; no PR is being represented as runtime-verified.

Following guidance revision `2026-09-17.1`, the next read-only `git ls-remote --exit-code origin refs/heads/codex/boreholes-review-fixes` succeeded through supported normal-user scoped execution with native Git settings and returned exact commit `b71e0ab25852f1e87a569172f99b23d4c04707d9`. Subsequent authorized remote commands use that working context, with TLS verification preserved and no backend override.
