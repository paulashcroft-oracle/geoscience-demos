# 2026-07-15 APEX SQL Source Cleanup Verification

Target:

- AIDEMODB APEX workspace: `GEOSCIENCE`
- Applications: app 104 `Geoscience Demos`, app 105 `Boreholes Demo`
- Branch: `codex/geoscience-boreholes-ai`
- Shared guidance refresh: `2026-07-15.3`, topic `apex-source-control`

## Source Ownership Decision

Numbered SQL now owns only database/data evolution and database program units.
APEX page, region, process, navigation, workspace service, and other component
metadata delivery scripts are historical live-delivery evidence, not canonical
source.

The live GEOSCIENCE SQL Scripts catalog was already empty when this cleanup was
requested, so no live workspace SQL Script deletion was required.

## Retired Numbered SQL

These files were removed from active numbered SQL source because they create or
mutate APEX application/workspace metadata rather than durable database objects:

- `database/005_add_demo_user_login.sql`: page 9999 demo-user region/process
  delivery for apps 104 and 105.
- `database/008_configure_geoscience_genai_services.sql`: workspace Generative
  AI Services delivery using existing `genai_credentials`.
- `database/010_configure_boreholes_app_pages.sql`: app 105 page, region,
  process, and native map component delivery mixed with database package source.
- `database/011_update_boreholes_navigation.sql`: app 105 navigation and page
  card list metadata delivery.

No workspace-user provisioning script was retained as numbered SQL. The live
workspace-user contract remains documented in `AGENTS.md` and `README.md`:
workspace/schema owner `GEOSCIENCE`, routine Codex administrator/developer
`CODEX`, and runtime demo persona `DEMO_USER` through app login components.

## Retained Database Source

- `database/006_create_geoscience_feedback_queue.sql` remains canonical
  database source for `GS_AI_HUB_FEEDBACK_FORWARDS`,
  `GS_AI_HUB_FEEDBACK_CANDIDATES_V`, and `GS_AI_HUB_FEEDBACK`.
- `database/007_geoscience_feedback_queue_verification.sql` remains canonical
  database verification for those queue objects and ledger rows.
- `database/009_create_boreholes_refresh_agent_api.sql` remains canonical
  database source for the WFS refresh, summary/status, and AI assistant API.
- `database/010_create_boreholes_page_api.sql` is the split database package
  source for `GS_BOREHOLE_PAGE_API`. It creates no APEX pages, regions,
  processes, lists, workspace users, or workspace services.

Static scan used:

```text
rg -n -i "wwv_flow|wwv_imp|apex_application_install|apex_application_admin|create_page|create_page_process|create_page_plug|create_remote_server|workspace_user|create_user|set_workspace|apex_workspace|apex_application_page_proc|apex_application_list" database\006_create_geoscience_feedback_queue.sql database\007_geoscience_feedback_queue_verification.sql database\009_create_boreholes_refresh_agent_api.sql database\010_create_boreholes_page_api.sql
```

Result:

- Only read-only references to `apex_workspace_ai_services` remain in app
  support packages.
- No `wwv_flow_imp`, `apex_application_install`, page/list/process creation,
  remote server creation, workspace-user creation, or workspace metadata
  delivery calls remain in retained database scripts.

## Application Export Evidence

App 105 current expanded readable export:

- `exports/apex/f105_boreholes_demo_20260617_reports_native_map_readable/readable/application/pages/p00006.yaml`
  contains page 6 `Reports`, region `Interactive Boreholes Map`, static ID
  `gs-boreholes-reports-map`, and map layer `Boreholes`.
- `exports/apex/f105_boreholes_demo_20260617_reports_native_map_readable/readable/application/shared_components/lists.yaml`
  contains navigation entries `Explore Data`, `Reports`, `Refresh Data`, and
  `Ask AI`.
- `exports/apex/f105_boreholes_demo_20260617_reports_native_map_readable/readable/application/pages/p00004.yaml`
  contains Ajax process `GS_BOREHOLES_REFRESH`.
- `exports/apex/f105_boreholes_demo_20260617_reports_native_map_readable/readable/application/pages/p00005.yaml`
  contains Ajax process `GS_BOREHOLES_AGENT_ASK`.
- `exports/apex/f105_boreholes_demo_20260617_reports_native_map_readable/readable/application/pages/p09999.yaml`
  contains region/process `Demo User Login` and request `DEMO_USER_LOGIN`.
- `exports/apex/f105_boreholes_demo_20260617_reports_native_map_readable/readable/application/pages/p10030.yaml`
  contains process `Queue AI Hub Feedback`.

App 104 and earlier shared hooks are represented by committed SQL application
exports:

- `exports/apex/f104_geoscience_demos_20260616_feedback_queue.sql`
  contains `Demo User Login`, `DEMO_USER_LOGIN`, and `Queue AI Hub Feedback`.
- `exports/apex/f105_boreholes_demo_20260616_feedback_queue.sql`
  contains the same shared login and feedback hook evidence for app 105.

Workspace Generative AI Services are represented by verification evidence:

- `docs/verification/20260616-geoscience-genai-services.md`
  lists the live standard OCI GenAI service catalog and connection-test
  evidence. For APEX 26.1+ promotion, capture workspace metadata through the
  relevant APEXlang/application source export or workspace metadata source path
  rather than reintroducing numbered SQL service creation.
