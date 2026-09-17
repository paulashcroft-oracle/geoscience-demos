# GEOSCIENCE agent body after Unicode repair

Evidence date: 17 September 2026. This directory is a separate checkpoint for the deployed `GS_BOREHOLE_AGENT_API` Unicode repair. It leaves `../20260917-after-boreholes-package-review` immutable as evidence of the initial four-body deployment. The single body here was reconstructed from canonical source with exact parity against the coordinating task's complete live-source observation; it is **not a direct Oracle file download**.

## Live evidence supplied by the coordinating task

Root verified the target as `DB_UNIQUE_NAME=tcelkxkd`, workspace/current schema `GEOSCIENCE`, session user `ORDS_PLSQL_GATEWAY`, APEX user `CODEX`. Before replacement, the complete agent body still matched the prior deployed SHA-256 `b9a6b2e292cd21b0f7582e1b33a8f76342aefcf95319ac25666b1a94d49a3718`.

Native SQL Scripts result **`29812023568838814`** reported **Complete, 1 successful statement, 0 errors, 0.29 seconds**. Root's complete ordered post-deployment `USER_SOURCE` read found **579 body rows, 31,381 compared UTF-8 bytes**, SHA-256 **`8327bbd58574fd4104528d6a790ada40dd7828e9cd1dad3c2c7b8d74d0ce053d`**. The body and specification were both `VALID`, with zero compilation errors.

The specification was unchanged: **11 rows, 496 compared UTF-8 bytes**, SHA-256 **`92e4caa31ef322b92c5924647004a543bfed5a205fed1e38fcef5d12a368fb5d`**. Its byte-identical executable checkpoint remains [in the earlier eight-unit directory](../20260917-after-boreholes-package-review/gs_borehole_agent_api.pks); it was not replayed or duplicated here. These database/browser observations belong to root, not the local reconstruction task.

## Source reconstruction

`scripts/Get-BoreholesPackageSource.ps1 -Package GS_BOREHOLE_AGENT_API -Unit Body` selected the canonical statement from `database/009_create_boreholes_refresh_agent_api.sql`: **31,399 UTF-8 bytes**, extracted-statement SHA-256 **`bbee732020f37658e703d3b0f2bffce1f8c908bdc61152488f1166e3f5ced0a0`**. The repair uses UCS2-aware `LENGTH2` append amounts and offsets, a 32,767-byte buffer, and bounded 4,000-unit reads.

The local comparison removed the leading `CREATE OR REPLACE `, replaced every CR with one ordinary space, preserved LF, and applied `TrimEnd`. This is the observed SQL Scripts mapping: CR is replaced, not dropped. All 579 logical lines, 31,381 bytes and the complete compared-source hash matched the supplied live evidence before file creation. Trailing spaces before LF are intentional; trimming them changes parity.

[gs_borehole_agent_api.pkb](gs_borehole_agent_api.pkb) is UTF-8 without BOM, framed as `CREATE OR REPLACE ` plus compared source plus LF, `/`, LF. Its complete executable file is **31,402 bytes**, SHA-256 **`535f530b7ae97ecb66ca0c82930240eccc3e559f0326f881589ebfed5d56719c`**. Byte-for-byte readback verified the written file. File, extracted-statement and compared-source hashes have different framing and must not be interchanged.

## Acceptance and recovery limits

The six-case Unicode source probe passed 25 assertions, and the existing source-derived agent regression passed 79 assertions with zero provider attempts before delivery. Root subsequently reported a post-repair installed-API fixture pass: **122 checks / 13 calls / 255 rows / five ranked records / reference with 250 newer records**, reported server total **200 ms**, maximum **30 ms**, exit0. Guards verified CODEX / `tcelkxkd` / no APEX session. No business DML, model call or APEX session creation occurred. These reported times are server observations at 10-ms resolution, not browser latency or percentile evidence; the prior 240/40-ms run is a distinct historical result.

Root also saved and read back the three app105 callback sources and observed one DEMO_USER browser count of255, as detailed in the implementation evidence. That ordinary response does not establish Unicode/long-response browser transport, provider, refresh, feedback or native Explorer acceptance. Remaining runtime acceptance and post-change APEXlang exports remain separately owned by root.

For a rollback of this Unicode repair, the agent body in the earlier four-body checkpoint is the immediately preceding source. For forward recovery, this directory is the source-matched Unicode version. Revalidate current target/source and use a surgical body-only replacement under the applicable authorization and checkpoint gates; do not replay a full installer, specification or application import based on this checkpoint.

This reconstruction made no database, browser, API or Git call, changed no earlier checkpoint or canonical package source, and created no task scratch. Root owns review, commit/push and remaining application verification.
