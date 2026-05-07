# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project — "Inside Penn" Tableau Dashboard (v3)

A Tableau portfolio dashboard for The Data School application.

### Primary narrative — Option 3: "Inside Penn — Two Platforms, Two Reliability Stories"

**Penn Station looks like one place on a sign. Underneath, it's two reliability stories.**
The 1/2/3 platform and the A/C/E platform serve the same complex but deliver measurably different
peak-hour performance. For the riders entering Penn each month, the data answers a single
practical question: *which platform should you trust?*

#### Story arc (6 beats)

1. **Scale** — ~2.9M paid entries/month at Penn across complexes 318 (1/2/3) and 164 (A/C/E); 6 routes converge here (1·2·3·A·C·E).
2. **The punchline first** — 1/2/3 platform delivers ~4 pp better peak Wait Assessment than A/C/E (Sheet 6 promoted to top of body).
3. **Is the gap real?** — Monthly incidents + ridership split by platform prove it's structural, not a one-month anomaly (Sheets 2 + 3).
4. **Why does it exist?** — Cause Ladder shows Signals + Track dominate both platforms. The 1/2/3 absorbs a comparable infrastructure load yet still delivers — likely a service-frequency / recovery-operations story (Sheet 4).
5. **Honest qualifier** — Quilt (Sheet C) shows the platforms don't fail in lockstep; one month a year flips the picture and is the one month the headline advice would have failed. The map (Sheet 7, refocused to Penn 318 + 164 only) shows the two complexes are one staircase apart.
6. **When does the choice matter most?** — Tue 8 AM heatmap cell is peak for both platforms (Sheet 8) — exactly when the ~4 pp gap saves the most riders the most time.

#### Mockup reference

`sample_dashboards/render_11_option3_platforms.html` — full layout with text-insight stack (headline, KPI sub-tags, section-as-question titles, "so what" boxes, action-oriented closer + caveats block).

### Backup narrative — Option 2: "What It Costs to Enter NYC Through Penn Station"

Kept as a documented fallback in case the platform-contrast framing weakens after extending to multi-year data (e.g., if the ~4 pp gap narrows or reverses). Cost-angle pivot: same Penn-only scope, same data, different KPIs and centerpiece.

- **KPI strip:** ~2.9M riders · 52-min worst single delay · ~3.4K trains delayed · 3.2× peak-risk multiplier.
- **Centerpiece:** Sheet 8 heatmap (promoted full-width).
- **Demoted/retired:** Sheets 6, 3, C, San (most data still queryable; the framing is what changes).
- **Mockup:** `sample_dashboards/render_10_option2_cost.html`.

If pivoting from Option 3 → Option 2, see `TABLEAU_BUILD_GUIDE.md` § "Backup variant — Option 2" for sheet-by-sheet deltas. **The SQL pipeline is identical; only the Tableau workbook changes.**

### Data caveat (read once, applies everywhere)

`monthly_incidents_delays.csv` is built from a `LEFT JOIN` of two facts on `(month, line, day_type)` only — but they have different category systems (`category` vs `reporting_category`), so the export is a Cartesian product. Raw `SUM([Incident Count])` and `SUM([Delay Count])` over-count. Use the `Real Inc` and `Real Delay` dedup calcs from `TABLEAU_BUILD_GUIDE.md` Step 3, and promote `Category`/`Line Group`/`Day Type` filters to **Context** on any sheet that uses them.

### Headline sign — verified 2024 data

For weekday peak Wait Assessment in 2024: **1/2/3 = 69.6%, A/C/E = 65.8%, gap = +3.84 pp in favor of 1/2/3**. Terminal OTP gap is +4.42 pp same direction. The 1/2/3 is the more reliable platform; A/C/E is the worse-performing alternate. Note that 1/2/3 actually carries *more* Signal+Track incidents (52 vs 47 weekdays/year) — the reliability lead exists *despite* a comparable or higher infrastructure-incident burden, so frame the cause-ladder beat as "same problem, better recovery" rather than "fewer problems."

### Time scope — year-parameterized

- **Data layer:** facts are filtered by `WHERE EXTRACT(YEAR FROM month::DATE) BETWEEN <start> AND <end>` in `3_transform.sql`. The current default range is 2024 only, but the file is structured to extend without other downstream changes. To add years: download more raw CSVs via `mta_hourly_download_new.py`, broaden the WHERE-year range in `3_transform.sql`, and re-run the pipeline.
- **Tableau layer:** every date-bearing sheet filters via `[Year Filter]` parameter (created in `TABLEAU_BUILD_GUIDE.md` Step 3 — moved earlier than v2). Headlines, KPI subtitles, and dynamic Mark Labels read `[Year Filter]` so the dashboard is honest about which year is on screen.
- **Never hardcode a year in calcs, captions, titles, or insight text.** The numbers in the docs (`~2.9M`, `+4 pp`, `99`, etc.) are illustrative for the most recent year on file — verify against the current selection before quoting.

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
- Old shuttle codes (`S 42nd`, `S Fkln`, `S Rock`) and GTFS codes (`GS`, `FS`, `H`) both appear in WA/OTP from 2024 onward — `transform.sql` deduplicates by keeping GTFS-named rows.
- `fact_daily_ridership` is isolated — no station or route join possible.

Full join gap analysis: bottom of `postgres/2_schema.sql`.

---

## Dashboard sheets — Option 3 (primary)

Canonical layout: `sample_dashboards/render_11_option3_platforms.html`. Sheet-by-sheet specs: `DASHBOARD_MODEL.md`. Step-by-step Tableau build instructions: `TABLEAU_BUILD_GUIDE.md`. Backup variant (Option 2) layout: `sample_dashboards/render_10_option2_cost.html`.

Each sheet's title is phrased as a question; each chart card carries a "so what" interpretation box; KPIs include 1-line interpretive sub-tags. See `DASHBOARD_MODEL.md` § "Text-insight stack" for the full pattern.

| # | Sheet | Chart | Section title (as question) |
|---|-------|-------|------------------------------|
| 1 | KPI strip (4 tiles) | Text (calculated fields) | n/a — 4 numbers + sub-tags |
| 6 | Reliability comparison (WA% + OTP%) — **CENTERPIECE, full width, top of body** | Side-by-side bar | Which platform should you trust? |
| 2 | Incidents over time × platform | Stacked bar (Line Group on Color) | Is the gap real, or just an average that hides bad months? |
| 3 | Ridership over time × platform | Stacked area (Line Group on Color) | (paired with Sheet 2 — same section) |
| 4 | Cause Ladder (split by platform) | Side-by-side bar + severity dot per (category × platform), dual axis | Do both platforms see the same kinds of failure? |
| C | Monthly Incident Pattern quilt | Highlight table (C-1/C-2 stacked, per-platform palette) | Do the platforms fail at the same time? |
| 7 | Where the cost concentrates — **refocused to Penn 318 + 164** | Filtered symbol map | How close are the two platforms, really? |
| 8 | Day × hour heatmap | Heatmap | If you had to pick one moment to avoid Penn, when? |
| 5 | Delay Duration Distribution (optional supporting) | Box plot | How bad is bad — per-incident severity? |
| San | Sankey — delay flow by category + platform | Sankey (Category on Level, Line Group on Level, Real Delay on Link) | How do delays distribute? |
| ~~N~~ | ~~Corridor Narrative scatter~~ | RETIRED — incompatible with Penn-only framing | — |

KPI strip — Option 3:
- KPI 1 — **`~2.9M`** paid entries/month at Penn (year-aware: `SUM([Ridership]) / COUNTD([Month])` filtered by `[Year Filter]`; combined complex 318 + 164)
- KPI 2 — **`6`** routes converging (1·2·3·A·C·E) — derived from `bridge_complex_route` for complexes 318 + 164; effectively static unless service changes
- KPI 3 — **`{N}/12`** months hit by Signal/Track on Penn routes (year-aware: `Months With Incidents` calc)
- KPI 4 — **`+{X} pp`** 1/2/3 vs A/C/E peak Wait Assessment advantage (year-aware: 1/2/3 avg minus A/C/E avg, peak weekday only)

KPI strip — Option 2 backup (cost angle, if pivoting):
- KPI 1 — `~2.9M` paid entries/month (same as Option 3)
- KPI 2 — `{X} min` worst single delay (`MAX([Real Delay]) * 3` — illustrative; verify proxy)
- KPI 3 — `~{N}K` total trains delayed (`SUM([Real Delay])` × proxy on Penn-serving routes for the active year)
- KPI 4 — `{X}×` peak risk multiplier (Tue 8 AM ridership-incidents intersection vs weekday avg)

---

## Conventions

- **Year handling is two-layered:** the year *range* is set in `3_transform.sql` WHERE clauses (one place to extend); within that range, the dashboard year is selected by the `[Year Filter]` Tableau parameter. Never hardcode a year in Tableau calcs, captions, titles, or insight text.
- Comma-formatted numbers (`"17,864"`) and percent strings (`"78.91%"`) are stripped/cast in `transform.sql`, never in Tableau.
- Three source date formats (`YYYY-MM-DD`, `MM/DD/YYYY`, `YYYY-MM-DDThh:mm:ss`) all normalize to ISO `DATE`/`TIMESTAMP` in fact tables.
- `line_group` is derived in `4_export.sql` (not `3_transform.sql`) per export. **Two definitions in use:**
  - **Route-based** (`monthly_incidents_delays`, `service_quality`, `dim_corridor_complexes`): `'1/2/3'` for routes 1,2,3; `'A/C/E'` for A,C,E; `'Other'` otherwise. The WHERE clause keeps only Penn-serving routes. In Option 3 docs and dashboard text, refer to these as **"platforms"** rather than "corridors" — same field, sharper framing.
  - **Complex-based** (`monthly_ridership`, `hourly_ridership_corridor`): four corridors — `'1/2/3'`, `'A/C/E'`, `'4/5/6'`, `'B/D/F/M'` — derived from `complex_id`. Originally built for the v2 wide-corridor narrative (35 stations); for Option 3, only complexes 318 + 164 are used in KPI 1 and Sheet 8 — the rest carry over for context but aren't load-bearing.
- Color system: green `#59a14f` = 1/2/3 platform (hero); blue `#4e79a7` = A/C/E platform (alternate); Signal+Track incidents in `#ef4444` only on category-encoded charts (Sheet 5); background `#faf8f4` (warm off-white per dashboard).
- **Text-insight stack:** every chart on the dashboard carries (a) a section title in **question form**, (b) at least one annotation on a specific mark, and (c) a "so what" interpretation box below the chart. KPI tiles carry an interpretive sub-tag. Footer is "the bottom line" + caveats. Pattern documented in `DASHBOARD_MODEL.md`.
