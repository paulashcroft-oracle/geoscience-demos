# Boreholes Assistant Left Panel And Enter Verification

Date: 2026-06-16

Target:

- AIDEMODB APEX workspace: `GEOSCIENCE`
- APEX application: `105`, `Boreholes Demo`
- Runtime page: `AI Data Assistant`
- Tasks: `geoscience-008`, `geoscience-009`

## Change

The assistant panel was reworked so the prompt is the primary vertical control:

- Removed the separate `Pasted screen/context` textarea.
- Kept pasted text in the main prompt.
- Captured pasted images as prompt markers and attachment metadata.
- Moved file input beside `Ask` and renamed the visible control to `Insert File`.
- Hid the native file input.
- Added Enter-to-ask while preserving Shift+Enter for new lines.
- Clear the prompt and attachment state after each submitted entry.
- Re-enable the Ask button after each successful or failed request using the APEX Ajax `always` lifecycle.

The assistant response now also shows a question-focused visual heading and visible `AI interpretation from selected model` section so the user can see that the selected Generative AI service is contributing to the answer.

## Live Verification

Runtime target:

`https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/geoscience/boreholes-demo/ai-data-assistant`

Automated CDP check:

`node .local\verify_boreholes_ai_left_panel.local.mjs`

Observed results:

- Separate context textarea removed: yes.
- Visible file control text: `Insert File`.
- Native file input hidden: yes.
- Ask and Insert File are on the same row: yes.
- Left panel width ratio: `0.316`.
- Prompt height: `502` px at desktop viewport `1366x900`.
- Pasted image test inserted prompt marker: `map request [pasted image: clipboard-map.png]`.
- Pasted image attachment metadata was visible: `clipboard-map.png image/png 4 bytes`.
- First Ask prompt: `show the state chart`.
- First response mode: `APEX_AI`.
- First response focus title: `State and territory borehole distribution`.
- First response had visible model narrative: yes.
- Prompt cleared after first Ask: yes.
- Ask button re-enabled after first Ask: yes.
- Second Ask used Enter key with prompt: `show top operators`.
- Second response mode: `APEX_AI`.
- Second response focus title: `Borehole operators and data quality`.
- Second response had visible model narrative: yes.
- Prompt cleared after Enter Ask: yes.
- Ask button re-enabled after Enter Ask: yes.
- Mobile viewport `390x844` stacked correctly with both left and right panels at `374` px width.

## Replayable Assets

- `database/009_create_boreholes_refresh_agent_api.sql`
- `database/010_configure_boreholes_app_pages.sql`
- `exports/apex/f105_boreholes_demo_20260616_assistant_left_panel_enter.sql`
