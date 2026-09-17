# Boreholes agent regression fixtures

The assertions.sql file is a PL/SQL declaration fragment for testing the **current package body**, not a copied implementation. It performs no DDL, DML, commits or provider calls. It covers bounded intent routing, rejected/ambiguous filters, current SQL totals, an old record outside a latest-row sampling assumption, deterministic mode, a disallowed-service fallback, safe errors, and complete escaped CLOB rendering.

To validate source before deploying, assemble an anonymous PL/SQL block in memory:

1. Extract only the body of GS_BOREHOLE_AGENT_API from database/009_create_boreholes_refresh_agent_api.sql, replacing its create-package wrapper with a declare section and removing its final package end and slash.
2. Append assertions.sql to that declaration section, then append a begin/end block calling run_agent_regressions.
3. Run it using SQLcl with read-only access to the named Geoscience tables and normal APEX APIs. When testing through CODEX, qualify the three table references as GEOSCIENCE.GS_BOREHOLES, GEOSCIENCE.GS_BOREHOLE_SOURCES and GEOSCIENCE.GS_DATA_REFRESH_RUNS in the in-memory block only, or set the current schema to GEOSCIENCE.
4. If the harness removes the package specification, supply its forward declarations for the five public functions before the body declarations. No package is created or replaced.
5. Keep APEX_AI.CHAT unreachable by using only the fixture calls. For an additional guard, replace its single invocation in memory with a test function that raises an error if reached; count/assert attempted calls at the harness boundary.

These checks do not prove deployed package validity, an active APEX session's map URL, model connectivity, quality, latency or browser behavior. Those remain separate integration checks after the current live baseline is captured and surgical deployment is allowed.

Supported questions include "count boreholes in NT", "chart count by operator", "count by purpose", "top 5 longest boreholes", "length summary", "open map", "data quality", and 'explain ref "REFERENCE"'. A single state and exact operator "NAME", purpose "VALUE" and ref "REFERENCE" filters may be combined. Explain/summarize/interpret requests use the same SQL evidence. Unsupported filters, multi-state comparisons and follow-up pronouns ask for a complete question; they do not invoke AI. Pasted-text interpretation uses an explicit prefix such as "summarize pasted text: ...".

Timing values are server-side elapsed milliseconds at DBMS_UTILITY.GET_TIME resolution (10 ms). contextMs includes routing and evidence construction, providerMs includes service resolution and a single provider attempt when applicable, and renderMs covers final HTML assembly. totalMs is sampled before JSON serialization completes; it is not browser/ORDS end-to-end time. There is no retry or cache and no persisted prompt/record telemetry.
