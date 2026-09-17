# GEOSCIENCE package baseline before Boreholes review

Captured evidence date: 17 September 2026. This directory contains eight package units reconstructed from verified Git text at commit `72f9d7f9d63cb1e123a4ef033f7246c25b0fc828`. It is not a direct file download from Oracle.

The coordinating task independently read 1,853 ordered `USER_SOURCE` rows through the rendered APEX SQL Workshop Results DOM, verified contiguous line numbers per unit, concatenated `TEXT`, normalized CRLF to LF and non-breaking spaces to ordinary spaces, and applied `TrimEnd`. After removing the `CREATE OR REPLACE ` prefix from the Git units (Oracle `USER_SOURCE` omits that prefix), all eight normalized SHA-256 hashes and UTF-8 byte counts matched. This reconstruction independently rechecked all eight supplied hashes and byte counts before writing any files.

Verified live identity reported by the coordinating task: AIDEMODB; `DB_UNIQUE_NAME=tcelkxkd`; workspace and `CURRENT_SCHEMA=GEOSCIENCE`; `SESSION_USER=ORDS_PLSQL_GATEWAY`; APEX user `CODEX`; existing application 105 `Boreholes Demo`. The database identity and source comparison were observed by the coordinating task, not re-queried by the reconstruction task.

The SQL Workshop CSV download was blocked by Chrome with `ERR_BLOCKED_BY_CLIENT`, and CUA `content.export` was unsupported. No bypass was used. The rendered source comparison plus the exact Git baseline is the provenance for these files.

## Source units and comparison

| File | Source at verified commit | Live USER_SOURCE rows | Normalized logical lines | Normalized UTF-8 bytes | Normalized SHA-256 |
| --- | --- | ---: | ---: | ---: | --- |
| [gs_ai_hub_feedback.pks](gs_ai_hub_feedback.pks) | `database/006_create_geoscience_feedback_queue.sql` | 39 | 38 | 996 | `139e832308b1f9078fbfca8cab36297c5c4c420f0b1c24aa4b2cee666ca8a4b1` |
| [gs_ai_hub_feedback.pkb](gs_ai_hub_feedback.pkb) | `database/006_create_geoscience_feedback_queue.sql` | 305 | 304 | 11591 | `aea78ba857af9ba01e5ac5158e6c27c49d0361ea599c2ac26a2bfb13409333ab` |
| [gs_borehole_refresh_api.pks](gs_borehole_refresh_api.pks) | `database/009_create_boreholes_refresh_agent_api.sql` | 25 | 25 | 741 | `f90bc3fd75b4e1dcba3ff1e284da4c72a37202f012430e8edf7711ce536d80fd` |
| [gs_borehole_refresh_api.pkb](gs_borehole_refresh_api.pkb) | `database/009_create_boreholes_refresh_agent_api.sql` | 303 | 303 | 11975 | `300df7abfd6e78e425617b6ecfa2f731ecb72a63850bbad4e9f0ba2a13b95617` |
| [gs_borehole_agent_api.pks](gs_borehole_agent_api.pks) | `database/009_create_boreholes_refresh_agent_api.sql` | 11 | 11 | 496 | `92e4caa31ef322b92c5924647004a543bfed5a205fed1e38fcef5d12a368fb5d` |
| [gs_borehole_agent_api.pkb](gs_borehole_agent_api.pkb) | `database/009_create_boreholes_refresh_agent_api.sql` | 730 | 730 | 40212 | `84bf51916befc2c7acc37490b2523a553fc61095ec43644926e9862fa1e1de50` |
| [gs_borehole_page_api.pks](gs_borehole_page_api.pks) | `database/010_create_boreholes_page_api.sql` | 8 | 8 | 285 | `166a78e7a21f19312de24d5fdc499783ea9606f0ffecf6449d01d33cc30ee8af` |
| [gs_borehole_page_api.pkb](gs_borehole_page_api.pkb) | `database/010_create_boreholes_page_api.sql` | 432 | 432 | 35179 | `a0e81a881247d7db0a25448c11ce070437d33d8420f3c8406289a889f69a8992` |

The feedback specification/body have 39/305 live rows and 38/304 logical lines after trailing whitespace normalization. The supplied normalized byte counts and hashes match exactly; the remaining six logical-line counts equal their live row counts. Thus the live row total is 1,853 and the normalized logical-line total is 1,851.

Each `.pks` or `.pkb` file is UTF-8 without BOM and uses LF line endings. Its exact framing is `CREATE OR REPLACE ` followed by the matching normalized `USER_SOURCE` text, then a newline, `/`, and a final newline. The table hashes and byte counts describe only normalized `USER_SOURCE`, excluding this added executable framing. The feedback units were extracted from the two recognized q-quoted D006 wrappers; their surrounding installer blocks, DDL and DML were not copied. D009 and D010 units were bounded by their named `END` and standalone slash terminator.

The reconstruction verified unique package headers, named endings and wrapper boundaries, all eight hashes and byte counts before writing, expected logical-line counts, and byte-for-byte file readback after writing. A candidate text scan found no private-key markers, recognized literal secret values, or literal authenticated session URLs. No task scratch was created.

## Recovery scope

This is the pre-change source reference for four existing GEOSCIENCE packages, not a full database backup. It contains no table data, grants, workspace credentials, or service definitions. No database or browser action was performed to create this directory, and no package was compiled or installed by the reconstruction task. Commit/push and live verification remain owned by the coordinating task.

Any later restoration must revalidate the target and use the authorized surgical package-unit workflow. Create the relevant specification before its body when both are required; do not replay the original full installers or treat this checkpoint as authority for full APEX application replacement.
