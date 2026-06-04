# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project — "Inside Penn" Tableau Dashboard (v3 FINAL)

A Tableau portfolio dashboard for The Data School application. **Submission-complete as of 2026-06-04** — all four revision rounds applied (R1 2026-05-22 narrative integrity, R2 2026-05-27 build-time iterations + 2026-05-28 second-AI critique, R3 2026-06-02 accessibility/readability, R4 2026-06-04 caption + em-dash polish). Live workbook published as `Inside Penn Station` on Tableau Public.

### Primary narrative — Option 3: "Inside Penn — Two Platforms, A Closing Gap"

**Penn Station looks like one place on a sign. Underneath, it's two platforms — and a closing gap.**
The 1/2/3 platform has been more reliable than the A/C/E every year measured, but A/C/E has been
catching up — peak Wait Assessment rose from ~61% to ~65% (2022→2024) while 1/2/3 held steady near 70%.
The gap narrowed from +8.0 percentage points (pp) to +3.8 pp over two years. For the riders entering Penn each month, the data answers a single practical question — and tracks how the answer's value has changed: *which platform should you trust, and by how much?*

#### Story arc (6 beats)

1. **Orient + scale** — Map first (Sheet 7, **moved to above the KPI strip 2026-06-02** per round-2 reviewer feedback) shows the two platforms share Penn's complex one staircase apart — same building, different services. Then the KPI strip: ~2.9M paid entries/month at Penn across complexes 318 (1/2/3) and 164 (A/C/E), 6 routes converging (1·2·3·A·C·E), months-hit-by-Signal/Track, and the +X pp WA gap. Then the trajectory chart, setting up the closing-gap claim across 2022→2024. Sequence answers in order: *where am I and what are these two platforms* → *how big is this place* → *how has the gap changed over time* — before the centerpiece head-to-head. Map lands before the metrics so every downstream KPI and chart has its "two platforms" referent already established visually.
2. **The punchline first** — 1/2/3 platform leads A/C/E on peak Wait Assessment every year, but the gap is narrowing: +8.0 pp (2022) → +4.3 pp (2023) → +3.8 pp (2024) (Sheet 6 promoted to top of body).
3. **Is the gap real?** — Monthly incidents + ridership split by platform prove it's structural, not a one-month anomaly (Sheets 2 + 3).
4. **Why does it exist?** — Cause Ladder shows Persons on Trackbed, Signals, and Track lead on both platforms. **1/2/3 actually carries *more* incidents than A/C/E in each of the top-3 categories** — a heavier infrastructure load — yet still delivers better reliability. The gap is a service-frequency / recovery-operations story (Sheet 4). Sheet 4a (cause-side trajectory, added 2026-05-28) extends this from category mix to total incident volume across all categories year-over-year, and reveals **both platforms absorbed ~40% more incidents from 2022 to 2024** (1/2/3: 87 → 124; A/C/E: 74 → 101) with 1/2/3 carrying more every year (+13, +6, +23 incident-event gap). So the convergence is unambiguously a recovery-operations story, not a prevention one — A/C/E is getting better at handling a rising load, not avoiding incidents.
5. **Honest qualifier** — the gap is closing because A/C/E is getting better against a rising-incident backdrop on both platforms, not because 1/2/3 is degrading. Best-case operations gain, not a calming system. Quilt (Sheet C) shows the platforms don't fail in lockstep. *(Sheet 7 map moved out of this beat 2026-06-02 — now lives in beat 1 as an orienting visual; the "one staircase apart" punch lands earlier so readers carry the spatial anchor through every analytical beat.)*
6. **When does the choice matter most?** — Tue 8 AM heatmap cell is peak for both platforms (Sheet 8) — exactly when the ~4 pp gap saves the most riders the most time.

#### Mockup reference

`sample_dashboards/render_12_revised.html` — **canonical final mockup**, post round-4 polish. Em-dash-free body text, captions rewritten to 45-50 / 18-25 word bands, new WA trajectory chart between KPI strip and Sheet 6, new Sheet 4a between the Sheet 4+C row and Sheet 8, change-list scaffolding table dropped.

`sample_dashboards/render_11_option3_platforms.html` — preserved for diff comparison (pre-round-4 state). Use only when reviewing what changed between R3 and R4; the v3-final source of truth is render_12_revised.html.

### Backup narrative — Option 2: "What It Costs to Enter NYC Through Penn Station"

Kept as a documented fallback in case the platform-contrast framing weakens after extending to multi-year data (e.g., if the ~4 pp gap narrows or reverses). Cost-angle pivot: same Penn-only scope, same data, different KPIs and centerpiece.

- **KPI strip:** ~2.9M riders · 52-min worst single delay · ~3.4K trains delayed · 3.2× peak-risk multiplier.
- **Centerpiece:** Sheet 8 heatmap (promoted full-width).
- **Demoted/retired:** Sheets 6, 3, C, San (most data still queryable; the framing is what changes).
- **Mockup:** `sample_dashboards/render_10_option2_cost.html`.

If pivoting from Option 3 → Option 2, see `TABLEAU_BUILD_GUIDE.md` § "Backup variant — Option 2" for sheet-by-sheet deltas. **The SQL pipeline is identical; only the Tableau workbook changes.**

### Data caveat (read once, applies everywhere)

`monthly_incidents_delays.csv` is built from a `LEFT JOIN` of two facts on `(month, line, day_type)` only — but they have different category systems (`category` vs `reporting_category`), so the export is a Cartesian product. Raw `SUM([Incident Count])` and `SUM([Delay Count])` over-count. Use the `Real Inc` and `Real Delay` dedup calcs from `TABLEAU_BUILD_GUIDE.md` Step 3, and promote `Category`/`Line Group`/`Day Type` filters to **Context** on any sheet that uses them.

### Headline sign — verified 2022-2024 data

**Per-year peak weekday Wait Assessment (verified against rendered dashboards):**

| Year | KPI 1 Riders | KPI 4 WA Gap | 1/2/3 peak WA | A/C/E peak WA |
|------|--------------|--------------|---------------|---------------|
| 2022 | 2.33M        | +8.02 pp     | ~70%          | ~61%          |
| 2023 | 2.71M        | +4.31 pp     | ~70%          | ~65%          |
| 2024 | 2.92M        | +3.84 pp     | 69.6%         | 65.8%         |

**1/2/3 has been the more reliable platform every year measured; A/C/E has been catching up.** 1/2/3 holds steady near 70%; A/C/E has climbed from 61% to 66%. **The gap is narrowing** — the dashboard story is convergence, not a static fact. Terminal OTP gap in 2024 is +4.42 pp same direction.

**Numerical convention:** in narrative prose use 61% / 66% for A/C/E (rounded, no tilde — actuals 61.0 / 65.8 round to integers) and "near 70%" for 1/2/3 (soft framing — the year-to-year wobble of 69.6 / 70.0 / 69.8 doesn't earn precise rounding the way A/C/E's 5-pp climb does). Asymmetry is deliberate. Precise values (`65.8%`, `69.6%`) belong on chart axes and KPI tiles, not in narrative prose.

Also note 1/2/3 carries *more* incidents than A/C/E across the top three Sheet 4 categories — Persons on Trackbed, Signals, and Track. The reliability lead exists *despite* a heavier infrastructure burden, so frame the cause-ladder beat as "same problem, better recovery" rather than "fewer problems." This is chart-verifiable: in the live workbook each top-3 category row should show a visibly longer green bar (1/2/3) than blue bar (A/C/E).

**Cause-side trajectory (Sheet 4a, added 2026-05-28)** sharpens the recovery-operations story further. Total annual incidents (all categories) per platform:

| Year | 1/2/3 | A/C/E | 1/2/3 lead (incidents) |
|------|-------|-------|----------------------|
| 2022 | 87 | 74 | +13 |
| 2023 | 88 | 82 | +6 |
| 2024 | 124 | 101 | +23 |

Both platforms saw ~40% more incidents in 2024 than 2022 (1/2/3: +42%, A/C/E: +37%). 1/2/3 carries more incident events every year measured, with the incident-load gap actually *widening* in 2024 — even as the WA% gap narrowed. So A/C/E's recent improvement isn't fewer disruptions; it's faster recovery from a rising number of disruptions. The closing reliability gap is unambiguously a **recovery-operations story**, chart-verified by Sheet 4a.

### Time scope — year-parameterized

- **Data layer:** facts are filtered by `WHERE EXTRACT(YEAR FROM month::DATE) BETWEEN 2022 AND 2024` in `3_transform.sql`. The default range is **2022-2024**. To extend: download more raw CSVs via `mta_hourly_download_new.py`, broaden the BETWEEN range on each fact's WHERE clause, and re-run the pipeline. The `fact_hourly_ridership` load is split into 3 INSERTs (one per year) for progress visibility and partial-recovery semantics — when extending, add another INSERT block per new year. The WA/OTP shuttle-code dedup applies only for year ≥ 2024 (pre-2024 data has only the legacy `S 42nd` / `S Fkln` / `S Rock` codes; the dedup must not drop them).
- **Tableau layer:** every date-bearing sheet filters via `[Year Filter]` parameter (created in `TABLEAU_BUILD_GUIDE.md` Step 3 — moved earlier than v2). The parameter is a **DateTime List** (values `1/1/2022`, `1/1/2023`, `1/1/2024` at midnight, displayed as `2022`/`2023`/`2024` via `yyyy` display format). All comparisons must use `YEAR([Year Filter])` — not `[Year Filter]` directly — since the underlying value is a timestamp. Year-aware label calcs use `STR(YEAR([Year Filter]))`. Filter wiring on each sheet uses a `Year Match` boolean calc on the Filters shelf, set to True, promoted to Context — added per-sheet (Tableau does not auto-apply parameter-driven filters across sheets).
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
| 7 | Where are these two platforms? — **MOVED above the KPI strip on 2026-06-02** per round-2 reviewer feedback ("a spatial anchor before diving into the metrics"). Refocused to Penn 318 + 164; Size = per-complex monthly ridership (2026-05-28). Sits between the intro paragraph and the KPI strip — every downstream metric has its "two platforms" referent established first | Filtered symbol map with manual WA% annotations on each dot | Where are these two platforms? *(question-form — was "How close are the two platforms, really?" when slotted as qualifier; reframed for the orienting position)* |
| 1 | KPI strip (4 tiles) | Text (calculated fields) | n/a — 4 numbers + sub-tags |
| Traj | **WA trajectory — between KPI strip and Sheet 6** *(added 2026-05-28)* | Two-line chart, peak weekday WA% per Line Group × year (2022→2024); axis aliases append per-year gap (`2022 (+8.0 pp)` etc.); **does NOT respect `[Year Filter]`** | 1/2/3 holds; A/C/E catches up *(assertion-form — this card delivers the title's promise)* |
| 6 | Reliability comparison (WA% + OTP%) — **CENTERPIECE, full width** | Side-by-side bar | Which platform should you trust? |
| 2 | Incidents over time × platform | Stacked bar (Line Group on Color) | Is the gap real, or just an average that hides bad months? |
| 3 | WA% over time × platform *(post-2026-05-22; was ridership area)* | Line chart (Line Group on Color, peak weekday) | Does the gap hold every month? *(question-form per 2026-05-27 iteration)* |
| 4 | Cause Ladder (split by platform) | Horizontal bar by (category × platform), severity in bar label suffix *(`X · N delays/inc`; circle dropped 2026-05-22; unit revised from `× delay` post-feedback to fit 80–110 magnitude)* | Do both platforms see the same kinds of failure? |
| 4a | **Cause-side trajectory — between Sheet 4 and Sheet 5** *(added 2026-05-28)* | Side-by-side bars, `Real Inc` per Line Group × year, **all categories**; **does NOT respect `[Year Filter]`** | More incidents on both — A/C/E closes the gap anyway *(assertion-form — chart-verifies recovery-operations thesis)* |
| C | Monthly Incident Pattern quilt | Highlight table (C-1/C-2 stacked, per-platform palette) | Do the platforms fail at the same time? |
| 8 | Day × hour heatmap | Heatmap | If you had to pick one moment to avoid Penn, when? |
| 5 | Per-incident severity (optional supporting) | Labeled horizontal bar (one bar per category, top-of-sort in red accent) *(was box plot; replaced 2026-05-22)* | How bad is bad — per-incident severity? |
| ~~San~~ | ~~Sankey — delay flow by category + platform~~ | REMOVED from primary layout *(post-2026-05-22; redundant with Sheet 4 after split-by-platform refactor; kept in workbook as hidden sheet for Option 2 pivot)* | — |
| ~~N~~ | ~~Corridor Narrative scatter~~ | RETIRED — incompatible with Penn-only framing | — |

KPI strip — Option 3:
- KPI 1 — **`~2.9M`** paid entries/month at Penn (year-aware: `SUM([Ridership]) / COUNTD([Month])` filtered by `[Year Filter]`; combined complex 318 + 164)
- KPI 2 — **`6`** routes converging (1·2·3·A·C·E) — derived from `bridge_complex_route` for complexes 318 + 164; effectively static unless service changes
- KPI 3 — **`{N}/12`** months hit by Signal/Track on Penn routes (year-aware: `Months With Incidents` calc)
- KPI 4 — **`+{X} pp`** 1/2/3 vs A/C/E peak Wait Assessment advantage (year-aware: 1/2/3 avg minus A/C/E avg, peak weekday only). Multi-year trajectory: +8.0 (2022) → +4.3 (2023) → +3.8 (2024) — closing gap as A/C/E catches up

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
- Color system: green `#59a14f` = 1/2/3 platform (hero); blue `#4e79a7` = A/C/E platform (alternate); Sheet 5 uses a single red accent (`#dc2626`) on the top-severity category with muted gray (`#94a3b8`) for the rest — no platform encoding on Sheet 5; background `#faf8f4` (warm off-white per dashboard).
- **Text-insight stack:** every chart on the dashboard carries (a) a section title in **question form** (~6–12 words), (b) a subtitle describing **chart mechanics** (encoding, scope, year-aware vs multi-year — 18–25 words, *no* interpretation), and (c) a "so what" interpretation box below the chart (conclusion + qualifier/implication — **45–50 words**). KPI tiles carry an interpretive sub-tag. Footer is "the bottom line" + caveats. Pattern documented in `DASHBOARD_MODEL.md`; word-count bands codified round 4. **Question test for subtitle vs so-what:** if a sentence is still true *before* you've looked at the data, it's subtitle. If it requires seeing the chart, it's so-what.
- **Em-dash convention (round 4):** no em dashes (`—`, U+2014) in user-visible body text. Replace with comma (parenthetical), period (emphasis break), colon (introduction), or parentheses (aside). En dashes (`–`, U+2013) stay for numeric ranges (`3–5 pp`, `2022–2024`).
- **Font sizes (round 4):** titles + intro + conclusion 13pt; subtitles + so-whats + caveats 11pt. Two-tier system — headlines/anchors at 13, supporting prose at 11.
- **Outer dashboard padding:** 150px left + right.
