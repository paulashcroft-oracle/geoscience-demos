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
