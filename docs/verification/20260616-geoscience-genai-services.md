# Geoscience Generative AI Services Verification

Date: 2026-06-16

Target:

- AIDEMODB APEX workspace: `GEOSCIENCE`
- APEX version: `24.2.16`
- Credential: `genai_credentials`
- Base URL: `https://inference.generativeai.us-chicago-1.oci.oraclecloud.com`
- Compartment: `ocid1.compartment.oc1..aaaaaaaadktw3nngmwhpv6eesplpofqhvgcij6ilcwdciunprkgchekld2dq`

## Pre-Create Test

The APEX `Generative AI Details` page `TestGenAIConn` Ajax process returned status `200` for every standard AFMA/Codex model before service creation:

- `google.gemini-2.5-pro`
- `google.gemini-2.5-flash`
- `google.gemini-2.5-flash-lite`
- `xai.grok-4.20-reasoning`
- `cohere.command-latest`
- `cohere.command-plus-latest`
- `openai.gpt-oss-120b`
- `openai.gpt-oss-20b`
- `xai.grok-4.3`

## Created Services

`APEX_WORKSPACE_AI_SERVICES` and the visible APEX services list show these rows:

| Name | Static ID | Provider | App Builder |
| --- | --- | --- | --- |
| `google.gemini-2.5-pro` | `google_gemini_2_5_pro` | OCI Generative AI Service | Yes |
| `google.gemini-2.5-flash` | `google_gemini_2_5_flash` | OCI Generative AI Service | No |
| `google.gemini-2.5-flash-lite` | `google_gemini_2_5_flash_lite` | OCI Generative AI Service | No |
| `xai.grok-4.20-reasoning` | `xai_grok_4_20_reasoning` | OCI Generative AI Service | No |
| `cohere.command-latest` | `cohere_command_latest` | OCI Generative AI Service | No |
| `cohere.command-plus-latest` | `cohere_command_plus_latest` | OCI Generative AI Service | No |
| `openai.gpt-oss-120b` | `openai_gpt_oss_120b` | OCI Generative AI Service | No |
| `openai.gpt-oss-20b` | `openai_gpt_oss_20b` | OCI Generative AI Service | No |
| `xai.grok-4.3` | `xai_grok_4_3` | OCI Generative AI Service | No |

Replayable setup script:

- `database/008_configure_geoscience_genai_services.sql`

Task evidence:

- AI Hub task thread: `geoscience-003`
- Connection-test update: thread entries `2303` and `2324`
