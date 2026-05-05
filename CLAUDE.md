# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project — "Transfer of Stress" Tableau Dashboard (v2)

A Tableau portfolio dashboard for The Data School application. Story:
**when a Signal or Track failure hits a Penn Station gateway line, how much
disruption do NJ commuters absorb — and is the WTC alternative actually safer?**

### Story arc

1. **Setup** — ~700K commuters per month rely on Penn Station's gateway lines (1/2/3 + A/C/E).
2. **Problem** — Signal + Track failures cause **77%** of all delay-causing incidents on these lines.
3. **Severity** — Per-incident delay duration (box plot) shows Signal failures hit hardest.
4. **Comparison** — A/C/E vs 1/2/3 via Wait Assessment % and Terminal OTP % — *which line do you trust?*
5. **When** — Tuesday 8 AM is peak risk (peak ridership + peak incident frequency).
6. **Where** — Concentrated at Penn Station; WTC offers an alternate route via PATH.

**Time scope:** 2024 only — all 12 months of hourly ridership loaded; incidents/delays/WA/OTP filtered to 2024 in `transform.sql`. Extend to 2020–2024 by changing `WHERE EXTRACT(YEAR ...) = 2024` predicates in `3_transform.sql` and downloading more years via `mta_hourly_download_new.py`.

---

## Stack

```
[Raw CSVs in datasets/]
    │
    │ 1. psql \copy → staging tables (all TEXT, no type errors)
    ▼
[Postgres schema mta: stg_*]
    │
    │ 2. transform.sql: clean, cast, dedupe, build bridges
    ▼
[Postgres schema mta: dim_*, fact_*, bridge_*]   ← star schema (see 2_schema.sql)
    │
    │ 3. export.sql: aggregate → Tableau-ready wide CSVs
    ▼
[tableau_exports/*.csv]
    │
    ▼
[Tableau Desktop: 5 CSVs joined via relationships]
```

**Postgres schema:** every table lives in the `mta` schema. `2_schema.sql` creates it. All SQL files use fully-qualified `mta.` prefixes. The `/check-data` and `/analyze-hub` slash commands use unqualified names — run `ALTER DATABASE mta SET search_path TO mta, public;` once after `createdb mta`.

**WSL2 note:** Postgres is installed on Windows; `psql` in the slash commands connects from WSL to Windows Postgres via TCP. The `\copy` directives in `1_load.sql` use Windows paths (`C:\temp\`) — if running manually from WSL, update those paths or run the SQL files from a Windows PowerShell session instead.

---

## Running the pipeline

```bash
# One-time setup (Windows PowerShell/cmd)
createdb mta
psql mta -c "ALTER DATABASE mta SET search_path TO mta, public;"

# Full pipeline via slash commands (preferred)
/setup-db        # schema (2_) → load (1_) → transform (3_) — note file numbering is by dependency
/check-data      # validate joins, dim coverage, date gaps
/analyze-hub     # print Penn Station + WTC impact summary
/export-tableau  # write 5 CSVs to tableau_exports/

# Or run SQL files manually (from Windows, in dependency order)
psql mta -f postgres/2_schema.sql
psql mta -f postgres/1_load.sql
psql mta -f postgres/3_transform.sql
psql mta -f postgres/4_export.sql
```

All SQL files are idempotent (start with `DROP TABLE IF EXISTS`) — re-running is safe.

---

## Star schema

| Table | Source | Grain |
|-------|--------|-------|
| `dim_complex` | `MTA_Subway_Stations_and_Complexes` | per-complex location, ADA, daytime routes |
| `dim_route` | GTFS `routes.txt` | one row per GTFS route_id |
| `dim_date` | generated | calendar (date, dow, is_weekend, is_holiday) |
| `dim_line_route_map` | seed | maps source `line` codes (e.g. `S 42nd`, `JZ`) → GTFS `route_id` |
| `bridge_complex_route` | built from GTFS | which lines serve which complex |
| `fact_hourly_ridership` | hourly CSV | timestamp × complex × payment × fare_class |
| `fact_major_incidents` | major incidents CSV | month × line × day_type × category |
| `fact_delay_causing_incidents` | delays CSV | month × line × day_type × reporting_category |
| `fact_wait_assessment` | WA CSV | month × line × day_type × period |
| `fact_otp` | OTP CSV | month × line × day_type |
| `fact_daily_ridership` | daily CSV | date × mode (isolated KPI — no station, no route join) |

Full DDL: `postgres/2_schema.sql` · Detailed model: `DATA_MODEL.md`

---

## Tableau exports (5 CSVs)

KPI tiles on Sheet 1 use Tableau calculated fields on `monthly_incidents_delays.csv` and `monthly_ridership.csv` — there is no `kpi.csv`.

| CSV | Grain | Tableau sheets |
|-----|-------|----------------|
| `monthly_incidents_delays.csv` | month × line × line_group × day_type × category | 1 (KPI), 2, 4, 5, C, San |
| `monthly_ridership.csv` | month × complex_id × line_group | 1 (KPI), 3 |
| `service_quality.csv` | month × line × line_group × day_type × period | 6 |
| `hourly_ridership_corridor.csv` | timestamp × complex_id × line_group | 8 |
| `dim_corridor_complexes.csv` | per complex (corridor only) | 7 |

---

## Hub stations

| Complex ID | Name | Lines | Role |
|-----------|------|-------|------|
| **318** | 34 St-Penn Station | 1, 2, 3 | Penn red corridor |
| **164** | 34 St-Penn Station | A, C, E | Penn purple corridor |
| **328** | Fulton St | 2, 3, 4, 5, A, C, J, Z | WTC-area hub |
| **624** | Chambers St-WTC / Park Pl / Cortlandt | A, C, E, 2, 3, R, W | WTC complex |

Verify these IDs against `dim_complex` with `/check-data` before hardcoding in analysis.

---

## Key joins

```
fact_*_incidents/delays/WA/OTP --[line]--> dim_line_route_map --[route_id]--> dim_route
                                                                               │
dim_route --[route_id]--> bridge_complex_route --[complex_id]--> dim_complex
                                                                       │
fact_hourly_ridership ----------[station_complex_id]---------------> dim_complex
```

Critical points:
- `line` in source facts **does not** match GTFS `route_id` directly — always go through `dim_line_route_map`.
- `JZ` maps to `NULL` route_id (J and Z are inseparable in source data).
- Old shuttle codes (`S 42nd`, `S Fkln`, `S Rock`) and GTFS codes (`GS`, `FS`, `H`) both appear in 2024 WA/OTP — `transform.sql` deduplicates by keeping GTFS-named rows.
- `fact_daily_ridership` is isolated — no station or route join possible.

Full join gap analysis: bottom of `postgres/2_schema.sql`.

---

## Dashboard sheets (~14 Tableau sheets across 9 dashboard sections)

Canonical layout: `sample_dashboards/render_9_synthesis.html`. Sheet-by-sheet specs: `DASHBOARD_MODEL.md`. Step-by-step Tableau build instructions: `TABLEAU_BUILD_GUIDE.md`.

The numbered rows below are dashboard sections; KPI strip is 4 sheets, Quilt is 2 sheets (C-1/C-2). Lettered rows (N, C, San) are additional charts placed alongside the numbered sections.

| # | Sheet | Chart |
|---|-------|-------|
| 1 | KPI strip (4 tiles) | Text (calculated fields) |
| 2 | Incidents over time × line group | Stacked bar (Line Group on Color) |
| 3 | Ridership over time × line group | Stacked area (Line Group on Color) |
| 4 | What Causes Delays? | Cause Ladder — Gantt bar + severity dot (dual axis) |
| 5 | Delay Duration Distribution | Box plot (Month on Detail, Category on Color) |
| 6 | Reliability comparison (WA% + OTP%) | Side-by-side bar (Measure Names + Line Group nested on Columns) |
| 7 | Where Are Delays Concentrated? | Filtered symbol map |
| 8 | When Do Delays Hit Hardest? | Day × hour heatmap |
| N | Corridor Narrative scatter | XY scatter (lat/lon as plain axes — not a map) |
| C | Monthly Incident Pattern quilt | Highlight table (two sheets C-1/C-2 stacked, one per corridor palette) |
| San | Sankey — delay flow by category + corridor | Sankey (Category on Level, Line Group on Level, Delay Count on Link) |

---

## Conventions

- The 2024 time filter lives in `3_transform.sql` only — facts are filtered at staging→fact step.
- Comma-formatted numbers (`"17,864"`) and percent strings (`"78.91%"`) are stripped/cast in `transform.sql`, never in Tableau.
- Three source date formats (`YYYY-MM-DD`, `MM/DD/YYYY`, `YYYY-MM-DDThh:mm:ss`) all normalize to ISO `DATE`/`TIMESTAMP` in fact tables.
- `line_group` is derived in `4_export.sql` (not `3_transform.sql`) per export. **Two definitions in use:**
  - **Route-based** (`monthly_incidents_delays`, `service_quality`, `dim_corridor_complexes`): `'1/2/3'` for routes 1,2,3; `'A/C/E'` for A,C,E; `'Other'` otherwise. The WHERE clause keeps only Penn corridor routes.
  - **Complex-based** (`monthly_ridership`, `hourly_ridership_corridor`): four corridors — `'1/2/3'`, `'A/C/E'`, `'4/5/6'`, `'B/D/F/M'` — derived from `complex_id`. The corridor was expanded to 35 stations across Manhattan + immediate Brooklyn for richer ridership context.
- Color system: red `#ef4444` = 1/2/3 corridor + Signal/Track incidents; purple `#a78bfa` = A/C/E corridor + ridership; background `#faf8f4` (warm off-white per dashboard).
