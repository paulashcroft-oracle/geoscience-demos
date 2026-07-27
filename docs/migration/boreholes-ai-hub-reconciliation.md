# Boreholes AI Hub source-to-target reconciliation

## Purpose

This source-only record proves the intended boundary: AIDEMODB application 105
becomes the standalone AI Hub project `boreholes`. It does not copy or rename
the existing ASHCROFT `geoscience` project row, and it does not claim that the
target exists until the AI Hub control plane is deployed and queried.

## Field reconciliation

| Field | ASHCROFT source evidence | Expected AIDEMODB value | Transformation / assertion |
| --- | --- | --- | --- |
| Project name | `Geoscience Demos` | `Boreholes Demo` | Deliberate application-boundary split. |
| Project key | `geoscience` | `boreholes` | Must differ. Assert `PROJECT_KEY = 'boreholes'`. |
| Status | `ACTIVE` | `ACTIVE` after activation | Target is not API-ready until activation and verification pass. |
| Display sequence | Shared-project order was not application-specific | Master-task seed order for `boreholes` | Deliberate target ordering; verify it is unique/intentional, not literal equality. |
| GitHub owner | `paulashcroft-oracle` | `paulashcroft-oracle` | Same repository owner. |
| GitHub repository | `geoscience-demos` | `geoscience-demos` | Shared repo is retained. |
| GitHub URL | `https://github.com/paulashcroft-oracle/geoscience-demos` | Same | Environment-neutral source ownership. |
| GitHub account/status | `Paul Ashcroft Oracle GitHub` / historical `PLANNED` | Current repository/account metadata | Refresh status from Git; do not preserve stale `PLANNED`. |
| Local folder | `C:\Users\pashcrof\Documents\Codex Projects\Geoscience Demos` | Same | Shared local repository, distinct AI Hub project. |
| APEX workspace | `GEOSCIENCE` | `GEOSCIENCE` | Same shared application workspace. |
| APEX schema | `GEOSCIENCE` | `GEOSCIENCE` | Same parsing schema. |
| APEX application ID | Historical shared row was app 104 | `105` | Deliberate correction to Boreholes app. |
| APEX application name | `Geoscience Demos` | `Boreholes Demo` | Deliberate app-specific value. |
| APEX alias | `GEOSCIENCE-DEMOS` | `BOREHOLES-DEMO` | Deliberate app-specific value. |
| APEX builder URL | App 104 builder route | App 105 builder route | Same host, `fb_flow_id=105`; never store a session URL. |
| APEX runtime URL | App 104 route | `/r/geoscience/boreholes-demo/home` | Deliberate app-specific route. |
| Migration target | `AIDEMODB` | `AIDEMODB` | Same lifecycle target. |
| Public domain target | `ashcroftcloud.com` | `ashcroftcloud.com` | Same planned public target. |
| Summary | Geoscience onboarding summary | Boreholes map/report/refresh/AI/feedback summary | Deliberate focused rewrite from source evidence. |
| Notes | Shared workspace/users/apps history | App 105 ownership, source task mapping, control-plane readiness, and split-design link | Keep only Boreholes-relevant notes plus explicit shared dependencies. |
| Design linkage | Legacy task bundles have no usable Boreholes design reference | `boreholes-system-design` | Create idempotently after target design API readiness. |

## Deterministic post-deploy assertions

The AI Hub master task must run these only after the AIDEMODB installer is live:

```sql
select project_key, project_name, status,
       apex_workspace, apex_schema, apex_application_id,
       apex_application_name, apex_application_alias
  from hub_projects
 where project_key = 'boreholes';
```

Expected single row: `boreholes`, `Boreholes Demo`, `ACTIVE`, `GEOSCIENCE`,
`GEOSCIENCE`, `105`, `Boreholes Demo`, `BOREHOLES-DEMO`.

```sql
select actor_key from hub_actors where actor_key = 'codex-boreholes';
select client_key, status from hub_api_clients where client_key = 'codex-boreholes';
select count(*) as normalized_grants
  from hub_current_api_client_grants
 where client_key = 'codex-boreholes';
```

Expected: one actor, one active client, and non-zero normalized grants. Then
use only the guarded `codex-boreholes-aidemodb.local.json` profile to require
`200 OK` from `api-profile`, `api-catalog`, `api-openapi`,
`codex-bootstrap boreholes`, and `task-triage boreholes --status BUILD --limit 5 --no-model`.

Finally assert the four target task keys (`boreholes-001` through
`boreholes-004`) and the `boreholes-system-design` record are readable through
their authenticated API contracts. These are future checks, not live evidence.
