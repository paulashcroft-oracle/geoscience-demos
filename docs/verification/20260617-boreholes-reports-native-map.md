# Boreholes Reports Native Map And AI Spatial Handoff Verification

Date: 2026-06-17

Target:

- AIDEMODB APEX workspace: `GEOSCIENCE`
- APEX application: `105`, `Boreholes Demo`
- Runtime pages:
  - `Reports`
  - `AI Data Assistant`
- Task thread: `geoscience-003`

## Defect

Paul reported that the boreholes spatial output still did not look like Australia.

Observed problem:

- The Reports/dashboard experience still depended on a handcrafted SVG spatial card.
- The AI assistant also rendered the same pseudo-map card for Australia/map prompts.
- Even after the spatial prompt logic distinguished Australia-wide vs auto-fit scope, the rendered card still was not a credible Australia map.

## Correction

Two distinct runtime behaviors are now separated:

- `Reports` is now the real spatial surface and uses a native APEX map region with pan, zoom, clustering, and hover details.
- The AI assistant no longer renders the misleading pseudo-map for spatial prompts. Instead, it keeps the assistant answer and grounded companion cards, then hands the user to the interactive Reports map with an explicit call-to-action.

Implemented surgically through live-delivery scripts that are now retired from canonical numbered SQL:

- `database/009_create_boreholes_refresh_agent_api.sql`
  - Removed the SVG mini-map from assistant spatial responses.
  - Kept spatial prompt classification and grounded companion output.
  - Added an explicit `Open Interactive Reports Map` CTA for spatial prompts.
  - Updated the assistant copy so it describes the Reports handoff instead of pretending a live map is embedded in the response.
- `database/010_configure_boreholes_app_pages.sql`
  - Split page 6 into:
    - intro region,
    - native APEX map region,
    - report-card region.
  - Added a native APEX map layer over `GS_BOREHOLES` using `APEX_SPATIAL.POINT(longitude, latitude)`.
  - Removed the temporary prototype page from the final replay.

## Live Verification

Reports page:

- URL: `/ords/r/geoscience/boreholes-demo/boreholes-reports`
- Confirmed the page now renders a native APEX map region above the report cards.
- Confirmed the map is interactive rather than a static SVG card.
- Confirmed the prototype page used during development no longer exists in the application.

AI spatial prompt:

- Prompt used: `can you plot data on a map of australia?`
- Observed result:
  - assistant mode: `APEX_AI`
  - graphical insight hero: yes
  - state distribution card: yes
  - `Open Interactive Reports Map` CTA: yes
  - misleading SVG mini-map: no

Verification evidence:

- `node .local\cdp_eval_page.local.mjs 4275082D35AA6F32C84CFFB1568F7C05 ...`
  - confirmed `hasMiniMap: false`
  - confirmed `buttons: ["Open Interactive Reports Map"]`
- `node .local\cdp_eval_page.local.mjs B8CE9186B0A40007F9B7DFFA23DD6EBB ...`
  - confirmed Reports map region IDs are present in the live DOM
- `reports-map-screenshot.local.png`
  - captured the live Reports page with the native APEX map visible

## Replayable Assets

- `database/009_create_boreholes_refresh_agent_api.sql`
- `database/010_create_boreholes_page_api.sql`
- `exports/apex/f105_boreholes_demo_20260617_reports_native_map.sql`

Source-control note: the former `database/010_configure_boreholes_app_pages.sql` mixed database package source with APEX page, region, process, and navigation metadata delivery. The database package source is retained as `database/010_create_boreholes_page_api.sql`; the app component state is represented by the dated app export above. For APEX 26.1+ targets, the same component state should be captured as APEXlang Standard Export.
