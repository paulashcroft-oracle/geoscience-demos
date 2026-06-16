# Geoscience Demos

Geoscience Demos is the Geoscience project shell under the shared Codex Projects workspace.

This repository will hold replayable source assets for Geoscience APEX demo applications using Oracle Autonomous Database 26ai and APEX in AIDEMODB.

AI Hub project key: `geoscience`

## Live AIDEMODB Workspace

Verified on 2026-06-16:

- AIDEMODB host: `ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com`
- APEX version: `24.2.16`
- Database user/schema: `GEOSCIENCE`
- APEX workspace: `GEOSCIENCE`
- ORDS schema alias: `geoscience`
- Workspace users:
  - `GEOSCIENCE`: workspace administrator and application developer
  - `CODEX`: workspace administrator and application developer
- Workspace Generative AI Services are configured with the same standard OCI GenAI catalog used by AFMA, backed by workspace credential `genai_credentials`. `google.gemini-2.5-pro` is the App Builder service.
- Current App Builder state: 2 generated applications.
- Application 104: `Geoscience Demos`, alias `GEOSCIENCE-DEMOS`, native APEX Feedback enabled, passwordless `DEMO_USER` entry enabled, AI Hub feedback queue enabled for `geoscience-001`.
- Application 105: `Boreholes Demo`, alias `BOREHOLES-DEMO`, native APEX Feedback enabled, passwordless `DEMO_USER` entry enabled, AI Hub feedback queue enabled for `geoscience-003`.
- App Builder entry point: `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/apex/app-builder/apps`
- Geoscience Demos runtime entry point: `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/geoscience/geoscience-demos/home`
- Boreholes Demo runtime entry point: `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/geoscience/boreholes-demo/home`
- Boreholes Reports runtime entry point: `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/geoscience/boreholes-demo/boreholes-reports`
- Demo entry: open either app login page and choose `Continue as Demo User`; normal `CODEX`/administrator login remains available.
- Feedback entry: use the generated APEX Feedback affordance. Submissions are captured by native APEX Feedback and queued in `GS_AI_HUB_FEEDBACK_FORWARDS` with AI Hub source payload, idempotency key, and source task provenance. Live forwarding remains pending endpoint/credential activation; raw API keys are not stored in this repo.

## Replayable Assets

- `database/001_create_geoscience_foundation.sql`: foundation tables and views.
- `database/002_seed_geoscience_demo_data.sql`: deterministic seed data and public-source provenance placeholders.
- `database/003_geoscience_foundation_verification.sql`: verification queries.
- `database/004_register_generated_apex_apps.sql`: live generated app registry and health evidence.
- `database/005_add_demo_user_login.sql`: AFMA-style passwordless `DEMO_USER` entry for app 104 and app 105.
- `database/006_create_geoscience_feedback_queue.sql`: native APEX Feedback to AI Hub source-feedback queue bridge for both apps.
- `database/007_geoscience_feedback_queue_verification.sql`: queue object, page process, and ledger verification query.
- `database/008_configure_geoscience_genai_services.sql`: standard workspace OCI Generative AI Services catalog using existing `genai_credentials`.
- `database/009_create_boreholes_refresh_agent_api.sql`: GA Boreholes WFS refresh API, provenance extensions, summary/status views, and AI assistant API for app 105.
- `database/010_configure_boreholes_app_pages.sql`: app 105 Home, Boreholes Explorer, Data Refresh, and AI Data Assistant pages plus refresh/assistant Ajax processes.
- `exports/apex/f104_geoscience_demos_20260616_post_creation.sql`: post-creation export for app 104.
- `exports/apex/f105_boreholes_demo_20260616_post_creation.sql`: post-creation export for app 105.
- `exports/apex/f104_geoscience_demos_20260616_demo_user_entry.sql`: post-demo-user export for app 104.
- `exports/apex/f105_boreholes_demo_20260616_demo_user_entry.sql`: post-demo-user export for app 105.
- `exports/apex/f104_geoscience_demos_20260616_feedback_queue.sql`: post-feedback-queue export for app 104.
- `exports/apex/f105_boreholes_demo_20260616_feedback_queue.sql`: post-feedback-queue export for app 105.
- `exports/apex/f105_boreholes_demo_20260616_refresh_ai_assistant.sql`: post-refresh/AI-assistant export for app 105.
- `exports/apex/f105_boreholes_demo_20260616_graphical_assistant.sql`: post-graphical-assistant correction export for app 105.
- `exports/apex/f105_boreholes_demo_20260616_assistant_left_panel_enter.sql`: post-left-panel/Enter-key assistant export for app 105.
- `exports/apex/f105_boreholes_demo_20260616_prompt_specific_assistant_reports.sql`: post-prompt-specific-assistant/Reports-page export for app 105.
- `exports/apex/f105_boreholes_demo_20260616_visual_layout_followup.sql`: post-visual-layout follow-up export for app 105.

## Boreholes Demo Data And AI

Verified on 2026-06-16:

- Public source: Geoscience Australia Boreholes WFS at `https://services.ga.gov.au/gis/boreholes/ows`, feature type `bh:Boreholes`.
- Refresh entry: app 105 page 4, `Data Refresh`, Ajax process `GS_BOREHOLES_REFRESH`.
- Assistant entry: app 105 page 5, `AI Data Assistant`, Ajax process `GS_BOREHOLES_AGENT_ASK`.
- Runtime smoke: `Continue as Demo User`, refresh BBOX `129,-24,139,-17`, limit `10`, run `5`, status `SUCCESS`.
- Assistant smoke: selected `cohere.command-latest`, returned `success: true` with mode `APEX_AI` and grounded boreholes-by-state response.
- Verification note: `docs/verification/20260616-boreholes-refresh-ai-assistant.md`.
- Post-change APEX export: `exports/apex/f105_boreholes_demo_20260616_refresh_ai_assistant.sql`.
- Graphical assistant correction: `docs/verification/20260616-boreholes-graphical-assistant.md`.
- Graphical assistant export: `exports/apex/f105_boreholes_demo_20260616_graphical_assistant.sql`.
- Assistant left-panel and Enter-key correction: `docs/verification/20260616-boreholes-assistant-left-panel-enter.md`.
- Assistant left-panel and Enter-key export: `exports/apex/f105_boreholes_demo_20260616_assistant_left_panel_enter.sql`.
- Prompt-specific assistant and Reports page correction: `docs/verification/20260616-boreholes-prompt-specific-assistant-reports.md`.
- Prompt-specific assistant and Reports page export: `exports/apex/f105_boreholes_demo_20260616_prompt_specific_assistant_reports.sql`.
- Visual layout follow-up correction: `docs/verification/20260616-boreholes-visual-layout-followup.md`.
- Visual layout follow-up export: `exports/apex/f105_boreholes_demo_20260616_visual_layout_followup.sql`.
