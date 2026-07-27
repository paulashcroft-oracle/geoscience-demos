# Boreholes Navigation And Functional Pages

Date: 2026-06-16

Target:

- Environment: AIDEMODB
- Workspace: GEOSCIENCE
- Application: 105, `Boreholes Demo`
- Branch: `codex/geoscience-boreholes-ai`

Baseline:

- Existing runtime left navigation still showed only `Home`, `Boreholes`, and `Administration`.
- User feedback called out that the key functional areas were not exposed as pages in the app navigation, specifically `Reports` and `Ask AI`.
- Existing current app export before this follow-up: `exports/apex/f105_boreholes_demo_20260616_visual_layout_followup.sql`

Historical live-delivery changes replayed surgically:

- `database/010_configure_boreholes_app_pages.sql`
  - Renamed page 2 surface and headings from `Boreholes Explorer` to `Explore Data`.
  - Renamed page 4 surface from `Data Refresh` to `Refresh Data`.
  - Renamed page 6 surface from `Boreholes Reports` to `Reports`.
  - Updated in-page CTA labels so cross-links use the same names as the navigation.
- `database/011_update_boreholes_navigation.sql`
  - Updated shared list `Navigation Menu` to expose:
    - `Home`
    - `Explore Data`
    - `Reports`
    - `Refresh Data`
    - `Ask AI`
    - `Administration`
  - Updated shared list `Page Navigation` so the Home cards align to:
    - `Explore Data`
    - `Reports`
    - `Refresh Data`
    - `Ask AI`

Live verification:

- SQL replay:
  - `010_configure_boreholes_app_pages.sql`: package, package body, and APEX page metadata processed successfully.
  - `011_update_boreholes_navigation.sql`: shared list update processed successfully.
- Fresh runtime home load at `/ords/r/geoscience/boreholes-demo/home` with live session:
  - Left navigation labels rendered as `Home`, `Explore Data`, `Reports`, `Refresh Data`, `Ask AI`, `Administration`.
  - Home body also showed the aligned functional card/action labels `Explore Data`, `Reports`, `Refresh Data`, and `Ask AI`.

Post-change export:

- `exports/apex/f105_boreholes_demo_20260616_navigation_pages.sql`

Source-control note: `database/010_configure_boreholes_app_pages.sql` and `database/011_update_boreholes_navigation.sql` were transient APEX metadata delivery scripts. The database package portion now lives in `database/010_create_boreholes_page_api.sql`; the page and navigation components are represented by this dated application export and later app 105 exports.
