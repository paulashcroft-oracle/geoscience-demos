# Boreholes Visual Layout Follow-Up

Date: 2026-06-16

Target:

- Environment: AIDEMODB
- Workspace: GEOSCIENCE
- Application: 105, `Boreholes Demo`
- Branch: `codex/geoscience-boreholes-ai`

Baseline:

- Existing current app export before this follow-up: `exports/apex/f105_boreholes_demo_20260616_prompt_specific_assistant_reports.sql`
- User screenshot showed the Home primary CTA rendering as a blank blue button and the assistant graphical response leaving unused horizontal space / clipping at expanded side-nav width.

Changes replayed surgically:

- `database/009_create_boreholes_refresh_agent_api.sql`
  - Made generated graphical insight CSS intrinsically responsive with `auto-fit` grids.
  - Added width and box-sizing guards to generated visual cards, metrics, maps, and narrative blocks.
- `database/010_configure_boreholes_app_pages.sql`
  - Fixed `.gs-bore` CTA link color specificity so primary buttons render white text on blue.
  - Renamed Home primary CTA from `Explore Boreholes` to `Explore Data` to fit the expanded-nav hero row.
  - Changed assistant grid from fractional columns that could leave unused space to `minmax(18rem,22rem) minmax(0,1fr)`.
  - Added page-level overflow/width guards for assistant graphical output.

Live verification:

- SQL replay:
  - `009_create_boreholes_refresh_agent_api.sql`: package, package body, views, and seed merge processed successfully.
  - `010_configure_boreholes_app_pages.sql`: page API package, package body, and APEX page metadata processed successfully.
- Home page with left nav expanded at `1144x1304`:
  - CTA container width/client width: `440 / 440`.
  - CTA row height: `42`.
  - All CTA buttons share the same row: `Explore Data`, `Reports`, `Refresh Data`, `Ask AI`.
  - Primary CTA computed color/background: `rgb(255,255,255)` on `rgb(29,111,165)`.
- AI Data Assistant with left nav expanded:
  - Shell width: `857`.
  - Grid columns: `352px 489px`.
  - Output width/client/scroll: `489 / 489 / 489`.
- Graphical map prompt: `show a map of loaded boreholes`
  - Ask re-enabled after response and prompt cleared.
  - Thread width/client/scroll: `489 / 472 / 472`.
  - Visual block width/client/scroll: `406 / 406 / 406`.
  - Mini-map width/client/scroll: `372 / 370 / 370`.
  - Overflow probe found no `.gs-bore-viz` descendants with `scrollWidth > clientWidth + 2`.

Post-change export:

- `exports/apex/f105_boreholes_demo_20260616_visual_layout_followup.sql`
