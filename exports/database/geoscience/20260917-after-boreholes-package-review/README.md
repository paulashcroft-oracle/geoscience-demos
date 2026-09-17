# GEOSCIENCE packages after Boreholes package review

Evidence date: 17 September 2026. This checkpoint contains four deployed package bodies reconstructed from the current canonical package statements, plus four unchanged specifications copied byte-for-byte from `../20260917-before-boreholes-review`. It is **not a direct Oracle file download**. The coordinating task supplied the live observations below; this reconstruction task performed only local source extraction, hash comparison and file creation.

## Target and deployment evidence

The coordinating task reported freshly verified identity: AIDEMODB; `DB_UNIQUE_NAME=tcelkxkd`; workspace and `CURRENT_SCHEMA=GEOSCIENCE`; `SESSION_USER=ORDS_PLSQL_GATEWAY`; APEX user `CODEX`; workspace ID `16120412504054324`. Before deployment it read all eight current package units and verified exact agreement with the immutable before-checkpoint. The browser slice and live deployment remained owned by that task.

Each body was delivered separately through the native SQL Scripts file chooser. The coordinating task observed these results, then read the complete ordered `USER_SOURCE` for the affected unit, verified contiguous line numbers, exact source parity, BODY/specification `VALID` status and zero compilation errors. Specifications were unchanged.

| Deployed body | SQL Scripts result | Duration | Observed result |
| --- | --- | ---: | --- |
| `GS_BOREHOLE_REFRESH_API` | `29484226036504975` | 0.23 s | Complete; 1 successful; 0 errors |
| `GS_BOREHOLE_AGENT_API` | `29542662954535684` | 0.25 s | Complete; 1 successful; 0 errors |
| `GS_BOREHOLE_PAGE_API` | `29590051518547888` | 0.17 s | Complete; 1 successful; 0 errors |
| `GS_AI_HUB_FEEDBACK` | `29624219688558451` | 0.11 s | Complete; 1 successful; 0 errors |

These durations describe the SQL Scripts deployment results, not application response or refresh latency. This reconstruction task did not repeat any browser, database or API operation.

## Reconstruction and source parity

Bodies came from `scripts/Get-BoreholesPackageSource.ps1`, which selects one named unit and excludes the surrounding D006 q-quoted installer and the D009/D010 installer statements. The canonical paths are D006 `database/006_create_geoscience_feedback_queue.sql` for feedback, D009 `database/009_create_boreholes_refresh_agent_api.sql` for refresh/agent, and D010 `database/010_create_boreholes_page_api.sql` for page rendering.

For the deployed bodies, the observed SQL Scripts representation maps each carriage return to one ordinary space. The exact local comparison removed the leading `CREATE OR REPLACE `, replaced every CR with an ordinary space (it did **not** drop CR), preserved LF, and applied `TrimEnd`. Every resulting UTF-8 byte count, SHA-256 and logical-line count matched the coordinating task's complete observed source. Trailing spaces before LF are therefore intentional evidence; removing them changes these hashes.

Specifications retain the before-checkpoint's documented normalization and exact executable files. The coordinating task confirmed that they remained unchanged. The feedback specification has 39 live source rows but 38 normalized logical lines, as documented in the baseline; the other specification counts agree.

| File | Origin | Live source rows | Logical lines | Compared UTF-8 bytes | Compared SHA-256 |
| --- | --- | ---: | ---: | ---: | --- |
| [gs_ai_hub_feedback.pks](gs_ai_hub_feedback.pks) | Unchanged baseline spec | 39 | 38 | 996 | `139e832308b1f9078fbfca8cab36297c5c4c420f0b1c24aa4b2cee666ca8a4b1` |
| [gs_ai_hub_feedback.pkb](gs_ai_hub_feedback.pkb) | Current D006 body | 337 | 337 | 13365 | `e7e8300e7be0117330d96bf3dfc8b5e2fd8ea4327f0d84df7037a69e7262958d` |
| [gs_borehole_refresh_api.pks](gs_borehole_refresh_api.pks) | Unchanged baseline spec | 25 | 25 | 741 | `f90bc3fd75b4e1dcba3ff1e284da4c72a37202f012430e8edf7711ce536d80fd` |
| [gs_borehole_refresh_api.pkb](gs_borehole_refresh_api.pkb) | Current D009 body | 458 | 458 | 20427 | `b539e67439d2b7f8b82fb24a999bb4798d7937fe802ce86172efc886ad619cac` |
| [gs_borehole_agent_api.pks](gs_borehole_agent_api.pks) | Unchanged baseline spec | 11 | 11 | 496 | `92e4caa31ef322b92c5924647004a543bfed5a205fed1e38fcef5d12a368fb5d` |
| [gs_borehole_agent_api.pkb](gs_borehole_agent_api.pkb) | Current D009 body | 577 | 577 | 31204 | `b9a6b2e292cd21b0f7582e1b33a8f76342aefcf95319ac25666b1a94d49a3718` |
| [gs_borehole_page_api.pks](gs_borehole_page_api.pks) | Unchanged baseline spec | 8 | 8 | 285 | `166a78e7a21f19312de24d5fdc499783ea9606f0ffecf6449d01d33cc30ee8af` |
| [gs_borehole_page_api.pkb](gs_borehole_page_api.pkb) | Current D010 body | 469 | 469 | 36796 | `9e9d1d75c22c879e222751bc86cefe99002153a2a02e6365a8c6d70cca9f0b62` |

Each file is UTF-8 without BOM. Its framing is `CREATE OR REPLACE `, followed by the matching compared source text, then LF, `/`, and a final LF. Table hashes and byte counts exclude this 21-byte executable framing. No CR remains in these checkpoint files. All eight comparisons passed before file creation; byte-for-byte readback then verified each written file. The total is 1,924 observed source rows and 1,923 logical lines, with 104,310 compared source bytes (104,478 bytes including eight executable frames).

A bounded local candidate scan found no private-key markers or literal authenticated session URLs. No credentials, table data, grants, workspace service definitions, installer wrappers or task scratch were added. The immutable before-checkpoint and canonical implementation source were not modified.

## Verification and recovery limits

At this checkpoint the four package bodies are deployed, source-matched and compile-valid according to the coordinating task's live evidence. Application-component delivery, runtime acceptance, installed public-refresh integration tests and post-change APEXlang exports remain pending. Compilation/source parity does not establish those outcomes or human acceptance. Root owns subsequent review, commit and push; this reconstruction task performed no Git operations.

This directory is the installed package-source recovery checkpoint, not a full database backup or an application export. The before-directory is the pre-change package rollback reference. Any restoration must revalidate the exact target and current source and use the authorized surgical package-unit workflow. Replaying unchanged specifications is unnecessary for a body-only restoration and can invalidate dependents. Do not replay full installers, replace an APEX application, restore business data or infer authority for unrelated changes from these files.
