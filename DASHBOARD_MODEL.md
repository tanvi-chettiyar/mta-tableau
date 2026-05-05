# Tableau Dashboard Model — Transfer of Stress (v2)

Sheet-by-sheet specs and design decisions for the v2 Tableau dashboard.

**Canonical layout reference:** `sample_dashboards/render_9_synthesis.html`
(render_6.jpeg is an earlier layout prototype — superseded by render_9)

---

## Story

> **The Jersey-to-NYC Transfer of Stress**
> *How signal & track failures drive delays for NJ commuters · 2024 · Lines 1/2/3 & A/C/E at Penn Station & WTC*

The dashboard answers five questions in sequence:

1. **How many people are at risk?** (Journey headline + KPI strip)
2. **Where does the stress build along the journey?** (Corridor narrative scatter)
3. **What kind of failures, how often, and how bad?** (Cause Ladder + Monthly pattern)
4. **Is one corridor safer?** (Incident timelines + Reliability comparison)
5. **Where and when is peak risk?** (Map + Day×hour heatmap)

Each section raises the question the next one answers — that's what makes it cohesive.

---

## Layout (render_9 structure)

```
┌─────────────────────────────────────────────────────────────┐
│ Title + subtitle                         [Year Q1 Q2 Q3 Q4] │
├─────────────────────────────────────────────────────────────┤
│ Journey headline (italic sentence, warm card)               │
├──────────┬──────────┬──────────┬──────────────────────────── │
│  KPI 1   │  KPI 2   │  KPI 3   │  KPI 4   (dark navy tiles) │
├──────────┴──────────┴──────────┴──────────────────────────── │
│ Stress builds along the trip — corridor narrative           │
│ (scatter: NJ → Penn → 1/2/3 branch ↗ / A/C/E branch → WTC) │
├────────────────────────┬────────────────────────────────────┤
│ Cause Ladder           │ Sankey — Delay Flow                │
│ (Gantt bar + dot)      │ (Category → Line Group)            │
├────────────────────────┴────────────────────────────────────┤
│ Monthly Incident Pattern — Quilt (C-1 above C-2)            │
│  1/2/3 row (red palette) + A/C/E row (purple palette)       │
├─────────────────────────────────────────────────────────────┤
│ Incident Timeline (stacked bar) + Ridership (stacked area)  │
│  Both corridors stacked by Line Group color                  │
├────────────────────────┬────────────────────────────────────┤
│ Reliability Comparison │ Delay Duration Distribution        │
│ (WA% + OTP% bars)      │ (Box plot)                         │
├────────────────────────┼────────────────────────────────────┤
│ Where (Filtered map)   │ When (Day × Hour heatmap)          │
├────────────────────────┴────────────────────────────────────┤
│ Narrative footer (dark navy card, 2-sentence summary)       │
└─────────────────────────────────────────────────────────────┘
```

---

## Color system

| Element | Hex |
|---------|-----|
| Background (warm off-white) | `#faf8f4` |
| KPI tile / footer background (dark navy) | `#0f172a` |
| Card background | `#ffffff` |
| Border / rule | `#e8e4de` |
| Text primary | `#1e293b` |
| Text secondary | `#64748b` |
| 1/2/3 corridor · Signal+Track · "stress" | `#ef4444` |
| A/C/E corridor · "relief" · Ridership | `#a78bfa` |
| Track (delay category accent) | `#f59e0b` |
| Persons / Subway Car / Stations | `#94a3b8` |
| Heatmap sequential scale | `#fef2f2` → `#991b1b` |
| Insight callout (red) | left border `#ef4444`, bg `#fef2f2` |
| Insight callout (purple) | left border `#7c3aed`, bg `#f5f3ff` |

---

## Data sources (Tableau side)

Connect 5 CSVs from `tableau_exports/` using **relationships** (not joins):

```
[monthly_incidents_delays] ── on month + line ──[service_quality]
                           ── on month         ──[monthly_ridership]

[dim_corridor_complexes]   ── on complex_id    ──[monthly_ridership]
                           ── on complex_id    ──[hourly_ridership_corridor]
```

Use relationships so each sheet queries its CSV at the correct grain — no double-counting. The KPI tiles draw from calculated fields on `monthly_incidents_delays` and `monthly_ridership` directly; no separate KPI table exists.

---

## Computed fields (create once in the data source, reuse across sheets)

| Field name | Source | Formula |
|-----------|--------|---------|
| `Signal+Track Incidents` | monthly_incidents_delays | `IF [category] IN ("Signals","Track") THEN [incident_count] ELSE 0 END` |
| `delay_per_incident` | monthly_incidents_delays | `[delay_count] / NULLIF([incident_count], 0)` |
| `delay_minutes_proxy` | monthly_incidents_delays | `[delay_per_incident] * 3` |
| `Signal Incident Advantage` | monthly_incidents_delays | `(SUM(IF [Line Group]="A/C/E" AND [Category]="Signals" THEN [Incident Count] END) - SUM(IF [Line Group]="1/2/3" AND [Category]="Signals" THEN [Incident Count] END)) / SUM(IF [Line Group]="1/2/3" AND [Category]="Signals" THEN [Incident Count] END)` |
| `day_num` | hourly_ridership_corridor | Pre-exported column (`EXTRACT(ISODOW ...)`, 1=Mon–7=Sun) — no calculated field needed |

`line_group` is pre-computed in every export — do not recreate it as a calculated field.

---

## Journey Headline (floating text box — not a sheet)

A warm-background card below the title. Static text, typed directly into a Tableau floating text box:

> *Signal or Track failures hit Penn Station's gateway lines in 11 of 12 months in 2024 — and the A/C/E corridor toward WTC carries 23% fewer signal incidents than the 1/2/3.*

Font: 17px, italic, `#0f172a`. Background: `#ffffff`, border: `#e8e4de`.

---

## KPI Strip (4 dark-tile text sheets)

Background per tile: `#0f172a`. Text colors listed per tile. All use very large font (34px) for the number.

| Tile | Metric | Value (illustrative) | Text color |
|------|--------|---------------------|------------|
| KPI 1 | Commuters in blast radius | ~700K riders/month across complexes 318 + 164 | `#ffffff` |
| KPI 2 | Incident months out of 12 | 11/12 (with waffle dot annotation) | `#f87171` for "11", muted for "/12" |
| KPI 3 | Avg delay per incident | ~18 min (delay_per_incident × 3-min headway) | `#fb923c` |
| KPI 4 | A/C/E signal advantage | −23% fewer signal incidents vs 1/2/3 | `#c084fc` |

**KPI 2 waffle approach in Tableau:** Use a 12-row scaffold (a separate 12-row hand-built CSV: `month_num, is_incident` where 11 rows = 1 and 1 row = 0) as a Shape mark. Set shape to filled square, color to `#ef4444` for 1, `#1e3a5f` for 0. Arrange 12 cells in a grid with `month_num` on columns. Alternatively, simplify to text-only "11/12" if building time is short.

**Build each KPI as a Text sheet:**

| KPI | Data source | Filter |
|-----|-------------|--------|
| KPI 1 (Commuters) | `monthly_ridership` | `Complex Id IN (318, 164)`, `Line Group IN ("1/2/3","A/C/E")` |
| KPI 2 (Incident months) | `monthly_incidents_delays` | `Line Group IN ("1/2/3","A/C/E")`, `Category IN ("Signals","Track")` |
| KPI 3 (Avg delay) | `monthly_incidents_delays` | `Line Group IN ("1/2/3","A/C/E")`, `Day Type = 1`, `Category IN ("Signals","Track")` |
| KPI 4 (Signal advantage) | `monthly_incidents_delays` | **No filter** — the `Signal Incident Advantage` calculated field references both line groups internally; filtering would break the comparison |

Mark type: Text. Place the calculated value on the Text card.

---

## Corridor Narrative — "Stress builds along the trip" (Sheet N)

**Source:** `dim_corridor_complexes.csv` joined to `monthly_ridership.csv` on `complex_id`

**Purpose:** Geographical scatter showing the NJ → Penn → fork (1/2/3 uptown, A/C/E → WTC) journey. Penn Station = peak stress. WTC = relief.

**Build:**
- Columns: `longitude` (continuous, sorted ascending left to right = NJ on left, uptown on right)
- Rows: `latitude` (continuous, but suppress or fix scale so it reads as a horizontal flow)
- Size: `SUM([ridership])` from monthly_ridership (bigger dot = more riders exposed)
- Color: `line_group` — red for 1/2/3, purple for A/C/E, gray for PATH-adjacent context
- Label: `display_name` on select stations (Penn, WTC, key stops)
- Annotation: callout box on Penn Station ("700K riders/month exposed"), callout on WTC ("23% fewer signal incidents")
- PATH stations: include but color `#94a3b8` with a note "PATH territory — no MTA data"

**No new export needed** — uses existing `dim_corridor_complexes.csv` + `monthly_ridership.csv`.

**Tableau tip:** This is a Scatter plot (not a Map), so you control the visual flow. Set a fixed x-axis range so Penn Station lands at visual center.

---

## Cause Ladder (Sheet B) — replaces old Sheets 4 + 5 if space is tight

**Source:** `monthly_incidents_delays.csv`

**Purpose:** Shows frequency (bar width) and severity (dot position) in one panel. Replaces two separate charts (sorted bar + box plot) when dashboard real estate is limited.

**Build (Gantt Bar approach):**
- Rows: `[category]` — sorted descending by `SUM([incident_count])`
- Columns: `SUM([incident_count])` as a bar mark (Gantt Bar mark type)
- Dual axis: second axis plots `AVG([delay_per_incident])` as a Circle mark
- Synchronize axes. Hide the second axis label.
- Color: bars by `category` (Signal = `#ef4444`, Track = `#f59e0b`, others = `#94a3b8`); circles same scheme
- Filter: `line_group IN ("1/2/3","A/C/E")` and `day_type = 1`

**Insight callout (static text box on dashboard):**
> Signal + Track = 77% of incidents · Signals are the most frequent AND most severe: highest dot position, 3.2× harder per incident than any other category.

**If keeping Sheets 4 + 5 separate:** use old DASHBOARD_MODEL specs below.
- Sheet 4: sorted horizontal bar (`SUM(incident_count)` on x, `category` on y, same filters)
- Sheet 5: box plot (`delay_per_incident` on x, `category` on y; Circle marks + Box Plot overlay; filter `Incident Count` Range of Values, min = 1 — Tableau filter, not SQL)

---

## Monthly Incident Pattern — "Quilt" (Sheets C-1 + C-2)

**Source:** `monthly_incidents_delays.csv`

**Purpose:** Which months were hit? — corridor-specific pattern visible at a glance. Two sheets stacked because Tableau only allows one sequential palette per measure per sheet.

**Sheet C-1 (1/2/3 corridor):**
- Mark type: Square (highlight table)
- Columns: `MONTH([month])` — discrete, Jan–Dec
- Rows: `Line Group` — discrete
- Color: `SUM([Signal+Track Incidents])` → Custom Sequential palette `#fee2e2` → `#ef4444`
- Filter: `Line Group = "1/2/3"`, `Category IN ("Signals","Track")`
- Hide column headers (will appear on C-2 below)

**Sheet C-2 (A/C/E corridor):**
- Same structure as C-1
- Filter: `Line Group = "A/C/E"`
- Color palette: `#f5f3ff` → `#7c3aed`
- Keep column headers (months) on this sheet

**Dashboard assembly:** stack C-1 directly above C-2 in a vertical container with 0px gap so they read as one chart. Per-corridor palettes need separate sheets — this is a Tableau limitation, not a design choice.

---

## Incident Timeline + Ridership (Sheets 2 + 3)

**Source:** `monthly_incidents_delays.csv` (incidents) + `monthly_ridership.csv` (ridership)

**Sheet 2 — Incidents (stacked bar):**
- Columns: `MONTH([month])` — discrete
- Rows: `SUM([Signal+Track Incidents])`
- Mark type: Bar
- `Line Group` on **Color only** (not Columns) — Tableau stacks automatically
- Stack order: 1/2/3 on bottom so red anchors the baseline
- Filter: `line_group IN ("1/2/3","A/C/E")`, `category IN ("Signals","Track")`

**Sheet 3 — Ridership (stacked area):**
- Columns: `MONTH([month])` — discrete
- Rows: `SUM([ridership])`
- Mark type: Area
- `Line Group` on **Color only** — areas stack automatically
- Filter: `line_group IN ("1/2/3","A/C/E")`

Place Sheet 3 directly below Sheet 2 in a vertical container with the same fixed width so month columns align. The stacked view shows combined system stress and the corridor split simultaneously — the red/purple proportions tell the "who absorbs more" story without requiring four separate panels.

---

## Reliability Comparison: A/C/E vs 1/2/3 (Sheet D — NEW)

**Source:** `service_quality.csv`

**Build:**
- Columns: `Measure Names` → then `Line Group` nested inside (creates true side-by-side bars, not stacked)
- Rows: `Measure Values` — keep only `Wait Assessment Pct` and `Terminal Otp Pct`
- `Line Group` also on **Color**
- Mark type: Bar
- Filter: `period = 'peak'`, `day_type = 1`, `line_group IN ("1/2/3","A/C/E")`
- Y-axis: Fixed range 60–100 (amplifies the gap visually)
- Reference line: Constant = 81 (system average), dashed gray
- Result: 4 bars — [WA% 1/2/3] [WA% A/C/E] | [OTP% 1/2/3] [OTP% A/C/E]

**Key:** putting `Line Group` on Columns (nested) rather than Color alone gives side-by-side bars. Color alone gives stacked bars.

**Headline:** "Which line do you trust?" — subtitle fills in "+4 pp better Wait Assessment on A/C/E during peak hours."

This panel didn't exist in v1 — it's why the WA + OTP datasets were added.

---

## Delay Duration Distribution (Sheet E)

**Source:** `monthly_incidents_delays.csv`

**Build:**
- Rows: `[category]` sorted descending by `AVG([delay_per_incident])`
- Columns: `AVG([delay_per_incident])` — Mark type: Circle first, then add Box Plot from Analytics pane → Cell
- **`Month` on Detail shelf** — required for distribution. Without it Tableau collapses to one point per category and no box renders.
- Filter: `Incident Count` range min = 1 (use Range of Values filter, not NULLIF — that's SQL syntax), `day_type = 1`, `line_group IN ("1/2/3","A/C/E")`
- Color: `category` on Color shelf — Signals `#ef4444`, Track `#f59e0b`, others `#94a3b8`
- Box plot fill: if stuck on gray, uncheck Fill and rely on dot colors + box border
- Outlier annotation: Signals outlier at ~52-min proxy (3.2 trains × 3 min × max headway factor)

---

## Sankey — Delay Flow (Sheet San)

**Source:** `monthly_incidents_delays.csv`

**Purpose:** Shows how delay-causing incidents flow from category to corridor. Signals→1/2/3 is the widest band — the visual anchor of the "Transfer of Stress" thesis.

**Build (Tableau Public 2026.1.0 native Sankey):**
- Mark type: Sankey (from the chart type dropdown)
- The Marks card shows **Level**, **Link**, **Detail** tabs — not "From/To/Size"
- `Category` → **Level** (left nodes)
- `Line Group` → **Level** (right nodes)
- `SUM([delay_count])` → **Link** (band width)
- Filter: `line_group IN ("1/2/3","A/C/E")`, `day_type = 1`
- Colors: set via the Level tab → Color. Node colors follow the Color shelf on the Level marks card. Link tab → Color controls ribbon/band color (set to neutral gray or low opacity).
- **Note:** Sankey color editing is limited in some Tableau versions. If Edit Colors is blocked, use Format → Workbook → Color Palettes to set the workbook palette to your colors in the correct order — Tableau assigns palette colors sequentially to categories.

**Key flow:** Signals→1/2/3 = 7,364 delay-causing incidents (widest band).

---

## Where (Filtered Map — Sheet F)

**Sources:** `dim_corridor_complexes.csv` + `monthly_incidents_delays.csv`

**Build:**
- Geographic roles: `latitude`, `longitude` from `dim_corridor_complexes`
- Size: `SUM([incident_count])` from monthly_incidents_delays
- Color: `line_group`
- No filter needed — all rows in `dim_corridor_complexes.csv` are corridor complexes (filtered in `4_export.sql`)
- Labels: Penn Station complexes (318, 164) and WTC complexes (328, 624) labeled explicitly
- Background map: Tableau automatic (light theme)

---

## When (Day × Hour Heatmap — Sheet G)

**Source:** `hourly_ridership_corridor.csv`

**Build:**
- Columns: `HOUR([transit_timestamp])` — continuous 0–23
- Rows: `DATENAME('weekday', [transit_timestamp])` — sorted by `day_num`
- Color: `SUM([ridership])` — sequential `#fef2f2` → `#991b1b`
- Mark type: Square
- Filter: `complex_id IN (318, 164)` for Penn-only view
- Reference bands: vertical at hours 7–9 (AM Rush) and 16–19 (PM Rush), color `#fff7ed`

**Day sort:** Use `day_num` calculated field to sort Mon → Sun (Tableau sorts weekday names alphabetically by default).

---

## Narrative Footer (floating text box — not a sheet)

Dark navy (`#0f172a`) background card at dashboard bottom:

> A Signal or Track failure at Penn Station is not a rare edge case — it happened in **11 of 12 months in 2024**, and every one of those ~700K monthly riders entered a network where the primary gateway had already failed that month. The A/C/E corridor toward WTC delivers **+4 pp better peak Wait Assessment** and carries **23% fewer signal incidents** than the 1/2/3 lines over the same window. That is the data-backed routing advantage available to any commuter who knows to take it.

Font color: `#64748b` for body, `#f1f5f9` for bold, `#f87171` for red emphasis.

---

## Dashboard-level filters

| Filter | Type | Affects |
|--------|------|---------|
| Year | Single-select pill (`2024`, `Q1`–`Q4`) | All sheets except KPI tiles |
| Day type | Toggle (weekday/weekend) | Cause Ladder, Reliability, Box Plot |

Place as pill buttons (floating containers) top-right. Per render_9: `2024` is default active pill.

---

## Data source footnote (place at dashboard bottom, above footer)

```
Sources: data.ny.gov (incidents, delays, Wait Assessment, OTP, ridership),
MTA GTFS feed (route + station metadata). Time scope: 2024.
Severity proxy: "delay per incident" = delayed-train-count ÷ incident-count
× 3-min avg headway — not a direct delay-duration measurement.
Built by [Your Name] · The Data School application · 2026.
```

---

## What changed from v1

| v1 | v2 (render_9) |
|----|----|
| Penn Station only | Penn Station + WTC corridor |
| Dual-axis incidents+ridership chart | Stacked bar + stacked area (Line Group on Color) |
| No corridor journey visualization | "Stress builds along the trip" scatter (Sheet N) |
| Sheets 4+5 as two separate panels | Cause Ladder consolidates both; box plot kept as Sheet E |
| No service quality dimension | Reliability comparison (WA% + OTP%) — Sheet D |
| No flow visualization | Sankey (Category → Line Group, delay count) — Sheet San |
| One-palette highlight table | Two-sheet quilt (C-1/C-2) for per-corridor palettes |
| Hand-built CSV | Star schema in Postgres + 5 typed CSV exports |
| White background | Warm off-white `#faf8f4` + dark navy KPI tiles |
| No narrative arc | Journey headline + narrative footer frame the story |
