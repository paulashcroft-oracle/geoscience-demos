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
- Current App Builder state: 2 generated applications.
- Application 104: `Geoscience Demos`, alias `GEOSCIENCE-DEMOS`, native APEX Feedback enabled, passwordless `DEMO_USER` entry enabled, AI Hub feedback queue enabled for `geoscience-001`.
- Application 105: `Boreholes Demo`, alias `BOREHOLES-DEMO`, native APEX Feedback enabled, passwordless `DEMO_USER` entry enabled, AI Hub feedback queue enabled for `geoscience-003`.
- App Builder entry point: `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/apex/app-builder/apps`
- Geoscience Demos runtime entry point: `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/geoscience/geoscience-demos/home`
- Boreholes Demo runtime entry point: `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/geoscience/boreholes-demo/home`
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
- `exports/apex/f104_geoscience_demos_20260616_post_creation.sql`: post-creation export for app 104.
- `exports/apex/f105_boreholes_demo_20260616_post_creation.sql`: post-creation export for app 105.
- `exports/apex/f104_geoscience_demos_20260616_demo_user_entry.sql`: post-demo-user export for app 104.
- `exports/apex/f105_boreholes_demo_20260616_demo_user_entry.sql`: post-demo-user export for app 105.
- `exports/apex/f104_geoscience_demos_20260616_feedback_queue.sql`: post-feedback-queue export for app 104.
- `exports/apex/f105_boreholes_demo_20260616_feedback_queue.sql`: post-feedback-queue export for app 105.
