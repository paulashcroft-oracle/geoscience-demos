# Boreholes Graphical Assistant Verification

Date: 2026-06-16

Target:

- AIDEMODB APEX workspace: `GEOSCIENCE`
- APEX application: `105`, `Boreholes Demo`
- Runtime page: `AI Data Assistant`
- Task: `geoscience-003`

## Test Feedback

Paul's runtime test showed that the assistant response was too textual. A prompt asking for the key insights "as graphic as possible" returned escaped prose and chart-like/mermaid syntax rather than an immediately graphical result.

## Correction

`GS_BOREHOLE_AGENT_API` now returns `answerHtml` for every successful assistant call. The visual answer is generated from loaded GEOSCIENCE schema data and includes:

- Metric cards for total boreholes, state count, average length, and maximum length.
- Bar charts for boreholes by state, borehole purpose mix, length profile, and top operators.
- SVG spatial distribution plot of loaded borehole coordinates.
- Recommended next actions grounded in source/data quality.
- Optional AI narrative as supporting commentary only.

The AI prompt was also tightened so models are told not to emit Mermaid, code fences, raw chart syntax, or large tables. The APEX UI renders the charts separately.

## Verification

SQL/API check:

- `GS_BOREHOLE_AGENT_API` package and package body are `VALID`.
- `USER_ERRORS` returned no rows for the package.
- `gs_borehole_agent_api.ask_json(...)` returned:
  - `success: true`
  - `selectedServiceName: google.gemini-2.5-pro`
  - visual markers present: `gs-bore-viz`, `Boreholes by state`, `Spatial distribution`

Runtime check:

- Prompt: `what are the key insights you can show? be as graphic as possible`
- Page produced:
  - visual panel: yes
  - state chart: yes
  - purpose chart: yes
  - length chart: yes
  - SVG map: yes
  - raw Mermaid/chart syntax visible: no

Runtime sample values:

- Boreholes: 30
- States: 5
- Average length: 124.0 m
- Maximum length: 685.0 m
- State chart includes WA, NSW, NT, QLD, and SA.

Replayable script:

- `database/009_create_boreholes_refresh_agent_api.sql`
- `exports/apex/f105_boreholes_demo_20260616_graphical_assistant.sql`
