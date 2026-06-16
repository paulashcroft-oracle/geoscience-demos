# 2026-06-16 Geoscience APEX Bootstrap Verification

Target:

- AIDEMODB host: `ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com`
- APEX workspace: `GEOSCIENCE`
- Schema: `GEOSCIENCE`
- APEX version: `24.2.16`

Applications:

- App 104 `Geoscience Demos`, alias `GEOSCIENCE-DEMOS`
- App 105 `Boreholes Demo`, alias `BOREHOLES-DEMO`

SQL verification after `database/005_add_demo_user_login.sql`:

| Check Type | App | Page | Item | Detail |
| --- | ---: | ---: | --- | --- |
| APP | 104 |  | Geoscience Demos | `GEOSCIENCE-DEMOS`, Feedback enabled, Available with Developer Toolbar |
| APP | 105 |  | Boreholes Demo | `BOREHOLES-DEMO`, Feedback enabled, Available with Developer Toolbar |
| PROCESS | 104 | 9999 | Demo User Login | On Submit, request `DEMO_USER_LOGIN` |
| PROCESS | 105 | 9999 | Demo User Login | On Submit, request `DEMO_USER_LOGIN` |
| REGION | 104 | 9999 | Demo User Login | No Template, display sequence 5 |
| REGION | 105 | 9999 | Demo User Login | No Template, display sequence 5 |

Runtime verification:

| App | Login URL | Result |
| ---: | --- | --- |
| 104 | `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/geoscience/geoscience-demos/login` | `Continue as Demo User` redirects to Home with `apex.env.APP_USER = DEMO_USER` |
| 105 | `https://ge1c42bf10ae843-aidemodb.adb.ap-sydney-1.oraclecloudapps.com/ords/r/geoscience/boreholes-demo/login` | `Continue as Demo User` redirects to Home with `apex.env.APP_USER = DEMO_USER` |

Post-change exports:

- `exports/apex/f104_geoscience_demos_20260616_demo_user_entry.sql`
- `exports/apex/f105_boreholes_demo_20260616_demo_user_entry.sql`
- `exports/apex/f104_geoscience_demos_20260616_feedback_queue.sql`
- `exports/apex/f105_boreholes_demo_20260616_feedback_queue.sql`

The exports were normalized from APEX download archives to plain SQL and checked for `Demo User Login`, `Continue as Demo User`, `DEMO_USER_LOGIN`, and `Queue AI Hub Feedback`.

Shared feedback queue verification:

| Check | Result |
| --- | --- |
| Queue objects | `GS_AI_HUB_FEEDBACK_FORWARDS` table valid, `GS_AI_HUB_FEEDBACK_CANDIDATES_V` view valid, `GS_AI_HUB_FEEDBACK` package/body valid |
| App 104 hook | Page 10030 process `Queue AI Hub Feedback`, sequence 20 |
| App 105 hook | Page 10030 process `Queue AI Hub Feedback`, sequence 20 |
| App 104 smoke | Submitted native APEX Feedback as `DEMO_USER`; ledger row `16555517873203653`, source task `geoscience-001`, status `PENDING`, idempotency key `geoscience-apex-feedback-16555517873203653` |
| App 105 smoke | Submitted native APEX Feedback as `DEMO_USER`; ledger row `16555695455204074`, source task `geoscience-003`, status `PENDING`, idempotency key `geoscience-apex-feedback-16555695455204074` |

Forwarding note: live AI Hub endpoint forwarding is intentionally not activated in the replayable source because it requires a project-scoped API key/credential outside Git. The queue stores the canonical payload and idempotency key so forwarding can be replayed when the approved endpoint credential is present.
