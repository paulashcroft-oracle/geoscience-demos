# Boreholes Prompt-Specific Assistant And Reports Verification

Date: 2026-06-16

Target:

- AIDEMODB APEX workspace: `GEOSCIENCE`
- APEX application: `105`, `Boreholes Demo`
- Runtime pages:
  - `AI Data Assistant`
  - `Boreholes Reports`
- Task thread: `geoscience-003`

## Defect

Paul reported that the AI assistant still returned the exact same response regardless of the prompt.

Root cause:

- The assistant had been wired to return the reusable graphical dashboard for every successful request.
- A previous correction changed the heading and made the model narrative visible, but the body still repeated the same metrics, state, purpose, length, operator, map, and next-action cards.
- The system prompt was also too restrictive: it pushed the model toward a short generic observation style instead of letting it answer the user's specific data question.

## Correction

The assistant and report dashboard responsibilities are now split:

- `GS_BOREHOLE_AGENT_API.ask_json` now returns a model-first assistant answer by default.
- The system prompt now asks the model to answer the user's question directly from supplied borehole data and context.
- Graphical companion output is added only when the prompt asks for or naturally implies a visual, such as chart, map, graph, top, distribution, profile, count, comparison, or spatial wording.
- Graphical companion output is intent-specific:
  - source/refresh questions return a text answer, not a dashboard.
  - operator chart prompts return the top-operator card only.
  - state graph prompts return the state card only.
- The reusable full graphical dashboard is preserved on a new `Boreholes Reports` page.

## Live Verification

Ajax contract check:

`node .local\verify_boreholes_ai_prompt_specific.local.mjs`

Observed assistant payloads:

- Prompt: `what source data is loaded and when was it refreshed?`
  - mode: `APEX_AI`
  - selected service: `google.gemini-2.5-pro`
  - graphical hero: no
  - state/purpose/length/operator/spatial cards: no
  - assistant answer section: yes

- Prompt: `show top operators as a chart`
  - mode: `APEX_AI`
  - selected service: `google.gemini-2.5-pro`
  - graphical hero: yes
  - operator chart: yes
  - state/purpose/spatial cards: no
  - assistant answer section: yes

- Prompt: `show boreholes by state as a graph`
  - mode: `APEX_AI`
  - selected service: `google.gemini-2.5-pro`
  - graphical hero: yes
  - state chart: yes
  - operator/purpose/spatial cards: no
  - assistant answer section: yes

Reports page check:

`https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/geoscience/boreholes-demo/boreholes-reports`

Observed report cards:

- Boreholes reports dashboard: yes.
- Metric cards: yes.
- Boreholes by state: yes.
- Borehole purpose mix: yes.
- Length profile: yes.
- Top operators: yes.
- Spatial distribution: yes.

## Replayable Assets

- `database/009_create_boreholes_refresh_agent_api.sql`
- `database/010_configure_boreholes_app_pages.sql`
- `exports/apex/f105_boreholes_demo_20260616_prompt_specific_assistant_reports.sql`
