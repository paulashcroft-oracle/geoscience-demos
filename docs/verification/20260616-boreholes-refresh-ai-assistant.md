# Boreholes Refresh And AI Assistant Verification

Date: 2026-06-16

Target:

- AIDEMODB APEX workspace: `GEOSCIENCE`
- APEX application: `105`, `Boreholes Demo`
- Runtime: `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/geoscience/boreholes-demo/home`
- Data source: `https://services.ga.gov.au/gis/boreholes/ows`
- WFS feature type: `bh:Boreholes`

## Implemented Scope

- Added repeatable GA WFS refresh support in `GS_BOREHOLE_REFRESH_API`.
- Added additional provenance/data fields to `GS_BOREHOLES` for source identifiers, operator, driller, dates, elevation, custodian, metadata/report links, QA status, and refresh run lineage.
- Added refresh run provenance fields to `GS_DATA_REFRESH_RUNS`, including source URL, request URL, feature type, BBOX, requested limit, and response bytes.
- Added `GS_BOREHOLE_SUMMARY_V` and `GS_BOREHOLE_REFRESH_STATUS_V`.
- Added `GS_BOREHOLE_AGENT_API` with dataset summary context, APEX AI chat integration, model selection, and deterministic grounded fallback.
- Added `GS_BOREHOLE_PAGE_API` and configured app pages:
  - Page 1: `Home`
  - Page 2: `Boreholes Explorer`
  - Page 4: `Data Refresh`
  - Page 5: `AI Data Assistant`
- Added page Ajax processes:
  - `GS_BOREHOLES_REFRESH`
  - `GS_BOREHOLES_AGENT_ASK`

## Database Verification

APEX SQL Commands verification returned:

- `GS_BOREHOLE_REFRESH_API`, `GS_BOREHOLE_AGENT_API`, and `GS_BOREHOLE_PAGE_API` package specs and bodies: `VALID`.
- `GS_BOREHOLE_SUMMARY_V` and `GS_BOREHOLE_REFRESH_STATUS_V`: `VALID`.
- `USER_ERRORS`: no rows for the three packages.
- APEX pages 1, 2, 4, and 5 are present with aliases `HOME`, `BOREHOLES-EXPLORER`, `DATA-REFRESH`, and `AI-DATA-ASSISTANT`.
- Ajax processes exist on pages 4 and 5.
- Loaded data after verification: 30 boreholes total, 25 with refresh run lineage.

Latest refresh evidence:

| Run | Status | Rows | BBOX | Limit |
| --- | --- | ---: | --- | ---: |
| 5 | `SUCCESS` | 10 | `129,-24,139,-17` | 10 |
| 4 | `SUCCESS` | 10 | `129,-24,139,-17` | 10 |
| 3 | `SUCCESS` | 10 | `129,-24,139,-17` | 10 |

## Runtime Verification

The app was verified through the runtime login page using `Continue as Demo User`.

Runtime page checks passed:

- Home renders `Australian Boreholes Demo`, refresh status, source contract, and AI-grounding summary.
- Boreholes Explorer renders the map/table view with `OPERATOR`, province, length, and report links.
- Data Refresh renders BBOX inputs, `Run GA WFS Refresh`, recent refresh runs, and the GA WFS source contract.
- AI Data Assistant renders the service/model selector, prompt, pasted screen/context, screenshot/file input, and agent thread.

Runtime Ajax checks passed:

- `GS_BOREHOLES_REFRESH` returned `success: true`, `refreshRunId: 5`, and request URL:
  `https://services.ga.gov.au/gis/boreholes/ows?service=WFS&version=2.0.0&request=GetFeature&typeNames=bh%3ABoreholes&outputFormat=application%2Fjson&count=10&bbox=129,-24,139,-17,EPSG%3A4326`
- `GS_BOREHOLES_AGENT_ASK` returned `success: true`, mode `APEX_AI`, selected service `cohere.command-latest`, and a grounded boreholes-by-state answer.

The assistant accepts screenshot/file input in this slice as attachment metadata plus pasted text context. Binary image interpretation still requires a future multimodal extraction path before claiming screenshot vision.

## Replayable Scripts

- `database/009_create_boreholes_refresh_agent_api.sql`
- `database/010_configure_boreholes_app_pages.sql`
- `exports/apex/f105_boreholes_demo_20260616_refresh_ai_assistant.sql`

Task evidence:

- AI Hub task thread: `geoscience-003`
