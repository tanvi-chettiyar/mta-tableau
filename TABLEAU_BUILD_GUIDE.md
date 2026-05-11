# Tableau Build Guide — Inside Penn (v3)

Step-by-step instructions for building the **Option 3 — Inside Penn** dashboard from the 5 exported CSVs. Follow in order — later steps reference sheets created in earlier ones.

**Primary design reference:** `sample_dashboards/render_11_option3_platforms.html`
**Backup design reference:** `sample_dashboards/render_10_option2_cost.html` (Option 2 — cost angle, see § "Backup variant — Option 2" at the end)
**Design spec:** `DASHBOARD_MODEL.md`

> **Year handling.** Every date-bearing sheet must filter via the workbook-level `[Year Filter]` parameter (created in Step 3 below — moved earlier than v2). Don't typo a year into any title, caption, KPI sub-tag, annotation, or so-what box. Year-specific values must come from calc fields that reference `[Year Filter]`.

---

## Pre-flight

1. Run `/export-tableau` to produce the 5 CSVs in `tableau_exports/`:
   - `monthly_incidents_delays.csv`
   - `monthly_ridership.csv`
   - `service_quality.csv`
   - `hourly_ridership_corridor.csv`
   - `dim_corridor_complexes.csv`

2. Open Tableau Desktop. Create a new workbook.

---

## Step 1 — Connect data sources

1. **Connect → Text File** → select `monthly_incidents_delays.csv`
2. In the Data Source tab: confirm columns (`month`, `line`, `line_group`, `day_type`, `category`, `incident_count`, `delay_count`).
3. Click **Sheet 1** to leave the data source tab.
4. **Data menu → New Data Source** → connect `monthly_ridership.csv`
5. Repeat for `service_quality.csv`, `hourly_ridership_corridor.csv`, `dim_corridor_complexes.csv`

You now have 5 data sources. Rename each in the Data pane (right-click → Rename) to match the CSV name without extension.

---

## Step 2 — Workbook formatting

1. **Format → Workbook** → set default background to `#faf8f4` (warm off-white)
2. **Format → Workbook** → Fonts: set to Segoe UI or -apple-system fallback (pick Tableau's closest: Tableau Regular)
3. Keep borders light: `#e8e4de`

---

## Step 3 — Year filter parameter + computed fields

> **Build the year filter first.** Every sheet from Step 4 onward will reference it. Doing this before the KPIs avoids retrofitting every calc later.

### 3a — Create the `Year Filter` parameter (once, workbook-level)

1. In the Data pane, right-click anywhere → **Create Parameter**
2. Name: `Year Filter`
3. Data type: **Date & Time** (DateTime). Use DateTime — not Integer — so the parameter behaves as a proper date in downstream calcs and feeds continuous-time controls cleanly.
4. Allowable values: **List**. Add one row per year, with Value = year-start timestamp and "Display As" = just the year:

   | Value | Display As |
   |---|---|
   | `1/1/2022 12:00:00 AM` | `2022` |
   | `1/1/2023 12:00:00 AM` | `2023` |
   | `1/1/2024 12:00:00 AM` | `2024` |

   The default range loaded by `3_transform.sql` is **2022-2024**; add rows here as you ingest more years.
5. Display format: **Custom → `yyyy`** so the parameter control and any `STR(YEAR(...))` insertion shows just `2024` (not the full timestamp).
6. Current value: most recent year (e.g. `1/1/2024 12:00:00 AM`). Value when workbook opens: pick `Current value` (workbook saves with the last-selected year) or a fixed timestamp.
7. Click OK
8. Right-click `Year Filter` in the Data pane → **Show Parameter** so the control is available when you assemble the dashboard later.

> **Why DateTime, not Integer.** The DateTime form lets the parameter act as a proper date in calcs (e.g., date-arithmetic, axis controls). The display format trick (`yyyy`) hides the time-of-day component so the user sees a clean year picker. The trade-off: every calc comparing `[Year Filter]` against a date field must wrap with `YEAR(...)` on both sides (see Step 3b).

### 3b — Create a `Year Match` calculated field in each date-bearing data source

Switch data sources using the dropdown at the top of the Data pane and create the same-named field in each.

| Data source | Calc |
|---|---|
| `monthly_incidents_delays` | `YEAR([Month]) = YEAR([Year Filter])` |
| `monthly_ridership` | `YEAR([Month]) = YEAR([Year Filter])` |
| `service_quality` | `YEAR([Month]) = YEAR([Year Filter])` |
| `hourly_ridership_corridor` | `YEAR([Year Date]) = YEAR([Year Filter])` — *post Fix #1 (pre-aggregation); the source no longer carries `Transit Timestamp`* |
| `dim_corridor_complexes` | skip — no date column |

> **Wrap the parameter in `YEAR()` on both sides.** Because `[Year Filter]` is a DateTime (Step 3a), writing `YEAR([Month]) = [Year Filter]` compares an integer to a timestamp and silently returns False for every row. Always `YEAR([Year Filter])`. This same wrapping applies to every other calc that touches the parameter in a date comparison (e.g., KPI 3's "Months in Year" denominator below — Step 4g).

Drag `Year Match` to the Filters shelf on every sheet that uses date-bearing data, set to True, and right-click → **Add to Context**.

> **Parameter-driven filters don't propagate via "Apply to All Worksheets."** Unlike regular dimension filters (where right-click → "Apply to Worksheets → All Using This Data Source" works), a calc-based parameter filter must be added to each sheet's Filters shelf manually. Plan for this when building each sheet. The parameter itself is workbook-global — flipping it on the dashboard updates any sheet that has `Year Match` in its Filters shelf.

### 3c — Computed fields (create before building sheets)

> **Why deduplication matters.** `monthly_incidents_delays.csv` is built from a `LEFT JOIN` between `fact_major_incidents` (per category) and `fact_delay_causing_incidents` (per reporting_category) on `(month, line, day_type)` only — so each (m,l,d) group becomes a Cartesian product. Raw `SUM([Incident Count])` and `SUM([Delay Count])` over-count by the cross-product factor. The `Real Inc` and `Real Delay` calcs below divide each row by its duplication factor so SUM gives the true total.

In the `monthly_incidents_delays` data source, create these fields:

**Real Inc** — deduplicated incident count
```
[Incident Count] / {FIXED [Month], [Line], [Day Type], [Category] : COUNT([Incident Count])}
```

**Real Delay** — deduplicated delay-causing-incident count
```
[Delay Count] / {FIXED [Month], [Line], [Day Type], [Reporting Category] : COUNT([Delay Count])}
```

**Signal+Track Incidents** — row-level mask for Signal/Track only
```
IF [Category] IN ("Signals", "Track") THEN [Real Inc] ELSE 0 END
```
Used by Sheets 2, 7 (Quilt), and the Sankey. Always sum, never average.

**Signal Track Share** (used by KPI 4)
```
SUM(IIF([Category] IN ("Signals", "Track"), [Real Inc], 0))
/ NULLIF(SUM([Real Inc]), 0)
```

**delay_minutes_proxy_v3** (used as severity proxy in box plot and optional Option 2 KPI)
```
SUM([Real Delay]) / NULLIF(SUM([Real Inc]), 0) * 3
```

**WA Gap** (used by KPI 4 in Option 3) — created on `service_quality`:
```
AVG(IF [Line Group] = '1/2/3' THEN [Wait Assessment Pct] END)
- AVG(IF [Line Group] = 'A/C/E' THEN [Wait Assessment Pct] END)
```
Returns the percentage-point advantage of 1/2/3 over A/C/E. Year-aware via `Year Match`. Filter to `Period = 'peak'` and `Day Type = 1` in Context. Multi-year trajectory: **+8.0 pp (2022) → +4.3 pp (2023) → +3.8 pp (2024)** — closing gap as A/C/E catches up to a stable 1/2/3. Verified 2024 detail: 1/2/3 = 69.6%, A/C/E = 65.8%.

**Riders Per Month** (used by KPI 1) — created on `monthly_ridership`:
```
SUM([Ridership]) / NULLIF(COUNTD([Month]), 0)
```
Year-aware: numerator and denominator both shrink with the active year filter.

> **Critical filter discipline:** any sheet that uses `Real Inc`, `Real Delay`, or downstream calcs must promote `Category`, `Line Group`, `Day Type`, and `Year Match` filters to **Context filters** (right-click filter pill → Add to Context, turns gray). Without context promotion, `{FIXED}` LODs ignore those filters and the divisor becomes wrong. This applies to every KPI tile and to Sheets 2, 4, 5, 6, 7, 8, C, San.

No additional fields needed in `hourly_ridership_corridor` — `day_num` (ISO 1=Mon–7=Sun) and `hour_of_day` are already exported columns.

---

## Step 4 — KPI tiles (4 Text sheets) — Option 3

**Goal:** Four dark-background text tiles that read as a 4-beat opening: *scale → concentration → frequency → punchline*. Each KPI previews a chart deeper in the dashboard.

| Tile | Big number | Subtitle | Sub-tag (interpretive, smaller font) |
|---|---|---|---|
| KPI 1 | `~2.9M` | paid entries/month at Penn (318 + 164) | "More than the population of Chicago, entering one complex every month." |
| KPI 2 | `6` | routes converging (1·2·3·A·C·E) | "Only Times Sq-42 St beats this count system-wide." |
| KPI 3 | `{N}/12` (year-aware) | months hit by Signal/Track | "A clean month at Penn was the year's exception, not the rule." |
| KPI 4 | `+{X} pp` (year-aware) | 1/2/3 vs A/C/E peak Wait Assessment | "Compounded over a year of weekday peaks: ~8 extra on-time mornings per rider." |

> **Year-agnostic claim discipline.** Sub-tag copy is editorial and won't auto-update. Keep claims claim-stable across years (the Boston comparison and the Times Sq routes count are stable; "11 of 12 months" is *not* — that's why KPI 3 keeps the year-aware {N}/12 calc). Where a sub-tag must reference a year-specific number, build it via a calc field with `STR(YEAR([Year Filter]))` rather than typing it.

Build each as a separate Text sheet and assemble into a horizontal strip on the dashboard.

### Sheet: KPI 1 — Riders entering Penn

**Source:** `monthly_ridership`
**Big number:** `~2.9M` · **Subtitle:** `paid entries/month at Penn (318 + 164)` · **Sub-tag:** "More than the population of Chicago, entering one complex every month."

#### 4a — Build

1. Set data source to `monthly_ridership`
2. Drag `Year Match` to Filters → True → **Add to Context**
3. Drag `Complex Id` to Filters → select `318` and `164` → **Add to Context**
4. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E` → **Add to Context**
5. Drag the `Riders Per Month` calc field (defined in Step 3c) to the **Text** card. Aggregation: `AGG`.

#### 4b — Format the number

1. Right-click the pill on the Text card → **Format** → Numbers → Custom → enter: `"~"0.0,,"M"` (divides by 1M, one decimal, M suffix — e.g. `~2.9M`)
2. The display rounds dynamically — for 2024 it shows `~2.9M`. If you extend to multi-year and the avg shifts (it shouldn't, since Penn is steady), the tile auto-updates.

#### 4c — Styling, subtitle, and sub-tag

1. **Format → Shading** → set worksheet background to `#0f172a`
2. Click the Text card → big number `#ffffff` 34px bold
3. Below the number, add a subtitle text line: `paid entries/month at Penn (318 + 164)` — same card, 11px, color `#94a3b8`
4. **Sub-tag (interpretive)** — add another text line below the subtitle, 10px, color `#fbbf24`, prefix with a 1px top border (use a horizontal rule character or pad with `Format → Borders` if available): `"More than the population of Chicago, entering one complex every month."`
5. Sheet title (small white text above the number, optional): `Riders Entering Penn`

---

### Sheet: KPI 2 — Routes Converging

**Source:** `dim_corridor_complexes` (or hard-typed text)
**Big number:** `6` · **Subtitle:** `routes converging (1·2·3·A·C·E)` · **Sub-tag:** "Only Times Sq-42 St beats this count system-wide."

#### 4d — Build

This is effectively a constant for any year where service runs as it does today. Two ways:

**Option A (dynamic — preferred for honesty):**
1. Set data source to `dim_corridor_complexes`
2. Drag `Complex Id` to Filters → select `318` and `164`
3. Drag `routes_at_complex` to Filters → keep all rows
4. On the Text card, place a calc:
   ```
   COUNTD(IF [Routes At Complex] LIKE '%1%' OR [Routes At Complex] LIKE '%2%' OR [Routes At Complex] LIKE '%3%'
              OR [Routes At Complex] LIKE '%A%' OR [Routes At Complex] LIKE '%C%' OR [Routes At Complex] LIKE '%E%'
          THEN [Complex Id] END)
   ```
   …or simpler: use `bridge_complex_route` if you joined it in: `COUNTD([route_id])` filtered to `route_id IN ('1','2','3','A','C','E')` and `complex_id IN (318,164)` returns 6.

**Option B (static — typed):** put `6` directly on the Text card as plain text. Acceptable since the count doesn't depend on the year filter. Document this choice in a comment so future-you knows why the tile isn't wired up.

#### 4e — Styling, subtitle, and sub-tag

1. Background: `#0f172a`, big number color `#fbbf24` 34px bold
2. Subtitle: `routes converging (1·2·3·A·C·E)` — 11px `#94a3b8`
3. Sub-tag: `"Only Times Sq-42 St beats this count system-wide."` — 10px `#fbbf24` with 1px top border
4. Sheet title (optional): `Routes Converging`

---

### Sheet: KPI 3 — Months Hit by Signal/Track

**Source:** `monthly_incidents_delays`
**Big number:** `{N}/12` (year-aware) · **Subtitle:** `months hit by Signal/Track on Penn routes` · **Sub-tag:** "A clean month at Penn was the year's exception, not the rule."

#### 4f — Build

1. Set data source to `monthly_incidents_delays`
2. Drag `Year Match` to Filters → True → **Add to Context**
3. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E` → **Add to Context**
4. Drag `Category` to Filters → select `Signals` and `Track` → **Add to Context**
5. Drag `Day Type` to Filters → select `1` → **Add to Context**

#### 4g — Calculation (year-aware)

**Months With Incidents** (numerator, already in Step 3c):
```
COUNTD(IF [Real Inc] > 0 THEN DATETRUNC('month', [Month]) END)
```

**Months in Year** (denominator — handles partial-year safely):
```
IF YEAR([Year Filter]) = YEAR(TODAY()) THEN MONTH(TODAY()) ELSE 12 END
```

#### 4h — Styling, subtitle, and sub-tag

1. Background: `#0f172a`
2. Drag `Months With Incidents` to **Text**. Text format: `<Months With Incidents>/<Months in Year>` (use rich-text on the Text card to get two-tone color)
3. Two-tone color: numerator `#ef4444`, slash + denominator `#334155`
4. Subtitle: `months hit by Signal/Track on Penn routes` — 11px `#94a3b8`
5. Sub-tag: `"A clean month at Penn was the year's exception, not the rule."` — 10px `#fbbf24` with 1px top border
6. Sheet title (optional): `Months Hit by Signal/Track`

---

### Sheet: KPI 4 — 1/2/3 Platform Advantage

**Source:** `service_quality`
**Big number:** `+{X} pp` (year-aware) · **Subtitle:** `1/2/3 vs A/C/E — peak Wait Assessment %` · **Sub-tag:** "Compounded over a year of weekday peaks: ~8 extra on-time mornings per rider."

> **Why this is the punchline KPI.** Of all 4 KPIs, this is the one tied directly to the dashboard's centerpiece chart (Sheet 6). It's the actionable number — promote, don't bury.

#### 4i — Build

1. Set data source to `service_quality`
2. Drag `Year Match` to Filters → True → **Add to Context**
3. Drag `Period` to Filters → select `peak` → **Add to Context**
4. Drag `Day Type` to Filters → select `1` → **Add to Context**
5. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E` → **Add to Context**
6. Drag the `WA Gap` calc field (defined in Step 3c) to the **Text** card. Aggregation: `AGG`.

#### 4j — Format and styling

1. Right-click the pill → Format → Numbers → Custom → `+0.0" pp"` → displays e.g. `+3.8 pp`
2. Background: `#0f172a`, text color: `#86efac` (light green — matches 1/2/3 hero), size 34px bold
3. Subtitle: `1/2/3 vs A/C/E — peak Wait Assessment %` — 11px `#94a3b8`
4. Sub-tag: `"Compounded over a year of weekday peaks: ~8 extra on-time mornings per rider."` — 10px `#86efac` with 1px top border
5. Sheet title (optional): `1/2/3 Platform Advantage`

> **Sign convention:** the `WA Gap` calc returns 1/2/3 minus A/C/E. If the sign flips negative in a future year (A/C/E overtakes 1/2/3), the format shows `-X pp` and the headline thesis weakens — that's your trigger to either re-flip the narrative back to A/C/E-as-hero or pivot to Option 2 backup. See the QA checklist (Step 17) for "annual sign sanity check."

---

## Step 5 — ~~Corridor Narrative scatter (Sheet N)~~ — RETIRED in Option 3

> **This sheet is retired in v3.** Skip to Step 6 unless you're building the v2 archive view.
>
> **Why retired:** Sheet N's wide-corridor + PATH framing is incompatible with the Penn-only platform-contrast narrative. The chart was load-bearing in v2 (the "stress builds along the trip" gradient); in v3, the platform-contrast story (Sheet 6 centerpiece) does that narrative work without the geographic scaffolding.
>
> **If you're pivoting to Option 2 (cost angle):** Sheet N stays retired. The cost framing doesn't gain from this chart either.
>
> **If you're rebuilding the v2 layout for archive:** the original spec is preserved below.

<details>
<summary>Original v2 build spec (kept for archive)</summary>

**Source:** `dim_corridor_complexes` (primary) + relationship to `monthly_ridership` on `complex_id`

**Goal:** A geographic scatter (not a map) showing all corridor stations as circles sized by ridership, colored by line group — Penn Station as the largest dot, WTC as the purple alternate-route anchor.

### 5a — Prevent auto-map

1. Set data source to `dim_corridor_complexes`
2. In the Data pane, right-click `Latitude` → **Geographic Role → None**
3. Repeat for `Longitude` → **Geographic Role → None**
4. This prevents Tableau from auto-generating a map when you drag these fields

### 5b — Build the scatter

1. Drag `Longitude` to **Columns**
2. Drag `Latitude` to **Rows**
3. Tableau renders a plain XY scatter — no map tiles
4. Set Mark type to **Circle**

### 5c — Size and color

1. Drag `SUM([Ridership])` (from the `monthly_ridership` relationship) to **Size**
2. Drag `Line Group` to **Color** → Edit Colors:
   - `1/2/3` → `#59a14f`
   - `A/C/E` → `#4e79a7`
   - `Other` → `#94a3b8`

### 5d — Labels and annotations

1. Drag `Complex Name` to **Label** → set label visibility to **Selected** only (avoids clutter)
2. For Penn and WTC, force labels always on: right-click the dot → **Mark Label → Always Show**
3. Add static annotations:
   - Right-click the Penn Station dot (complex 318) → **Annotate → Mark** → type e.g. `"~2.9M paid entries/month exposed"`
   - Right-click the WTC dot (complex 624) → **Annotate → Mark** → type e.g. `"23% fewer signal incidents via A/C/E"`
   - Update these numbers after verifying KPI 1 and KPI 4 against your actual data

### 5e — Format and axis safeguard

1. Hide gridlines: **Format → Lines** → set all to None
2. Hide axis titles: right-click each axis → Edit Axis → clear the title field
3. **Fix axis ranges** (protects the scatter if geographic roles are restored in Step 11):
   - Right-click x-axis → **Edit Axis → Fixed** → range: `−74.02` to `−73.97`
   - Right-click y-axis → **Edit Axis → Fixed** → range: `40.70` to `40.78`

> Restoring geographic roles in Step 11 does not retroactively change this sheet — Tableau only applies role changes to new drag-and-drop uses. The fixed ranges are an extra safeguard.

### 5f — Title and caption

- **Title** (Worksheet → Show Title → Edit Title): `700K riders, two parallel routes`
- **Caption** (Worksheet → Show Caption → Edit Caption): `Each circle is a corridor station, sized by ridership in the active year. Penn Station anchors both lines; WTC sits at the southern end of the alternate corridor.`

</details>

---

## Step 6 — Cause Ladder (Sheet 4) — split by platform

**Source:** `monthly_incidents_delays`

**Goal:** Horizontal bars showing incident frequency per category, **split by platform**, with a severity dot per (category × platform) — so the chart directly answers whether both platforms see the same kinds of failure. They mostly do; that's the point.

### 6a — Filters (apply first)

1. Drag `Year Match` to Filters → True → **Add to Context**
2. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E` → **Add to Context**
3. Drag `Day Type` to Filters → select `1` (weekday) → **Add to Context**
4. Drag `Category` to Filters → keep all → **Add to Context** (FIXED LODs in `Real Inc`/`Real Delay` need this)

### 6b — Build the split bar (one row per category × platform)

1. Drag `Category` to **Rows**
2. Drag `Line Group` to **Rows** — drop it to the *right* of `Category` so it nests inside (gives one row per category per platform)
3. Drag `SUM([Real Inc])` to **Columns** — use the dedup field, not `Incident Count`
4. Mark type: **Bar**
5. Drag `Line Group` to **Color** → Edit Colors:
   - `1/2/3` → `#59a14f`
   - `A/C/E` → `#4e79a7`
6. Sort categories: right-click `Category` on Rows → **Sort** → field `Real Inc`, aggregation `Sum`, descending — Signals floats to the top across both platforms.

The view now shows N category groups, each with two side-by-side bars (one per platform). Bar length differences within a category = where the platforms diverge in incident volume; same-category dominance = same kinds of failure.

### 6c — Add severity dot (dual axis, per category × platform)

First create a calc field **Severity Ratio** in `monthly_incidents_delays`:
```
SUM([Real Delay]) / NULLIF(SUM([Real Inc]), 0)
```

This computes per-cell because both `Real Delay` and `Real Inc` are aggregates — with `Line Group` nested on Rows, each (category, platform) cell gets its own ratio. That's the desired behavior: the dot now shows whether each platform absorbs the same incident type with different rider-impact.

Then build the dual axis:

1. Drag `Severity Ratio` to **Columns** — it appears as a second pill on the same shelf
2. Right-click the second pill → **Dual Axis**
3. Right-click either axis → **Synchronize Axes**
4. In the Marks card, click the second marks layer (AGG(Severity Ratio)) → change mark type to **Circle**
5. Color the circles by `Line Group` (same scheme as bars) — adds visual consistency
6. Result: bar length = incident frequency for that platform; circle position = trains-delayed per major incident for that platform. If the dots within a category are *not* aligned, that's the "same problem, different absorption" story made visible.

> Make sure Category, Line Group, Day Type filters are all in **Context** — without that, the FIXED LODs inside `Real Inc`/`Real Delay` ignore the category filter and the ratio is wrong.

### 6d — Reference line and format

1. With the circle axis active, go to **Analytics pane** → drag **Reference Line** onto the view → scope: **Table** → value: **Average** of `Severity Ratio` → style: dashed gray → label: `"avg severity"`
2. Right-click the top axis (dual axis header) → **Uncheck Show Header** — hides the duplicate axis label
3. Right-click the x-axis → Edit Axis → title: `Major Incidents (bars) · Trains Delayed per Major Incident (dots)`
4. Format → Lines → remove gridlines

> **Calc note:** the original guide used `AVG([delay_per_incident])` (a row-level ratio) which compounds with the cross-join duplication. Replace it with the Step 3 dedup pattern: build the severity dot from `SUM([Real Delay]) / NULLIF(SUM([Real Inc]), 0)` and keep **Category, Line Group, Day Type in Context** so the FIXED LODs see the right denominators.

### 6e — Title (as question), annotation, and so-what box

- **Title** (Worksheet → Show Title → Edit Title): `Do both platforms see the same kinds of failure?`
- **Caption** (Worksheet → Show Caption): `Bar length = major incidents on that platform; dot position = trains delayed per major incident. Side-by-side within each category, both platforms.`

**Annotation (on chart):**
1. Right-click the Signals row (either platform's bar) → **Annotate → Mark**
2. Type: `"Signals dominate both platforms — same problem, different absorption"` (claim-stable across years)
3. Style the callout: small font, subtle gray border.

**So-what box (floating text on dashboard, below the chart):**
> **So what:** broadly yes — Signals dominate both platforms, Track sits second on both. The reliability gap on Sheet 6 *isn't* explained by a different mix of failures hitting each platform; both platforms see the same problem profile. The gap must be in what happens *after* an incident — a service-frequency and recovery-operations story.

Use the `.insight` style for the **hero (1/2/3) green family**: light fill `#f0fdf4`, 3px left border `#59a14f`, body text `#14532d`, font 11px.

---

## Step 7 — Monthly Incident Pattern / Quilt (Sheets C-1 + C-2)

**Source:** `monthly_incidents_delays`

**Goal:** A 2-row highlight table showing Signal + Track incident counts by month — one row per corridor, each with its own color palette so the corridors read as distinct.

Tableau only allows one sequential palette per measure on a single sheet. Build two sheets and stack them on the dashboard — they'll read as one chart.

### Sheet C-1 (1/2/3 corridor)

1. Mark type: **Square** (highlight table)
2. Columns: `MONTH([Month])` — discrete (right-click → Discrete)
3. Rows: `Line Group` — discrete
4. Filter: `Line Group = "1/2/3"`, `Category IN ("Signals", "Track")`
5. Color: `SUM([Signal+Track Incidents])` → Edit Colors → Custom Sequential → `#dcfce7` (low) to `#16a34a` (high) — 1/2/3 green family
6. Label: `SUM([Signal+Track Incidents])` on each cell, white text for dark cells
7. **Hide column headers** (right-click month axis → Uncheck Show Header) — the bottom sheet will show them
8. Hide axis titles

### Sheet C-2 (A/C/E corridor)

1. Same structure as C-1
2. Filter: `Line Group = "A/C/E"`, `Category IN ("Signals", "Track")`
3. Color: Custom Sequential → `#dbeafe` (low) to `#1e40af` (high) — A/C/E blue family
4. **Keep column headers** (months) on this sheet
5. Same label format as C-1

### Dashboard assembly for the quilt

- In a vertical container: place C-1 directly above C-2
- Set both to the same fixed width so month columns align
- Set inter-container padding to 0px so they appear seamless
- The `Line Group` row label on the right side of each sheet acts as the corridor legend

### Title (as question), qualifier callout, and so-what

Treat the two stacked sheets as one chart. Add a floating text box above the container:

- **Title:** `Do the platforms fail at the same time?`
- **Caption:** `Top row: 1/2/3 platform (red palette). Bottom row: A/C/E platform (purple palette). Darker cell = more Signal+Track incidents that month.`

Hide each constituent sheet's individual title (Worksheet → Hide Title) so only the floating header is visible.

**Honest qualifier callout (small lavender callout above the so-what):**
After identifying the qualifier month from the data (the month where 1/2/3 is heavy while A/C/E is clear — verify in the active year before quoting), add:
> ⚠ **{Month name}:** A/C/E is clear, 1/2/3 is heavy. The one month where the headline advice would have failed.

To make this dynamic, build a calc field that returns the qualifier month name based on the active year filter. If you want the simpler path, type the month manually and update each year (mark it with a comment like `<!-- year-sensitive: verify {Month name} for active year -->`).

**So-what box (insight-blue style — `#eff6ff` fill, `#1d4ed8` left border, `#1e3a8a` text):**
> **So what:** the platforms don't fail in lockstep — they're operationally independent within the same complex. That's *good news* for the routing argument: when one is degraded, the other is usually still on schedule. The {N}-month exception is the honest qualifier on the headline.

---

## Step 8 — Incident Timeline (Sheet 2) + Ridership Timeline (Sheet 3)

### Sheet 2 — Incidents over time (stacked bar)

**Source:** `monthly_incidents_delays`

**Goal:** Stacked bars showing total Signal + Track incidents per month, split by corridor — the combined height shows system-wide stress; the red/purple split shows which corridor absorbs more.

#### 8a — Filters

1. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E`
2. Drag `Category` to Filters → select `Signals` and `Track`

#### 8b — Build

1. Drag `MONTH([Month])` to **Columns** — right-click → **Discrete**
2. Drag `SUM([Signal+Track Incidents])` to **Rows**
3. Mark type: **Bar**
4. Drag `Line Group` to **Color** — Tableau stacks automatically
   - Do NOT put `Line Group` on Columns — that creates side-by-side bars, not stacked

#### 8c — Color and format

1. Edit Colors: 1/2/3 = `#59a14f`, A/C/E = `#4e79a7`
2. Stack order: right-click the Color legend → **Sort** → put `A/C/E` at the bottom so the worse-performing platform anchors the baseline
3. Format → Lines → remove gridlines
4. Right-click y-axis → Edit Axis → title: `Signal + Track Incidents`

#### 8c-title — Title (as question for the paired Sheets 2+3 section) and caption

The pair (Sheets 2 + 3) lives under one section heading on the dashboard:

- **Section title (above both):** `Is the gap real, or just an average that hides bad months?`
- **Sheet 2 caption:** `Stacked monthly Signal + Track major incidents — 1/2/3 in red, A/C/E in purple. Combined height = system-wide stress; the split shows which platform absorbs it.`

---

### Sheet 3 — Ridership over time (stacked area)

**Source:** `monthly_ridership`

**Goal:** Stacked area chart showing monthly ridership by corridor — context for how many commuters experience the incident levels shown in Sheet 2.

#### 8d — Filters

1. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E`

#### 8e — Build

1. Drag `MONTH([Month])` to **Columns** → Discrete
2. Drag `SUM([Ridership])` to **Rows**
3. Mark type: **Area**
4. Drag `Line Group` to **Color** — areas stack automatically
5. Edit Colors: 1/2/3 = `#59a14f`, A/C/E = `#4e79a7`
6. Right-click y-axis → Edit Axis → title: `Monthly Ridership`

#### 8f — Dashboard alignment

- Place Sheet 3 directly below Sheet 2 in a vertical container with the same fixed width so month columns align between the two charts

#### 8g — Title and caption (Sheet 3)

- **Sheet 3 title (hidden — paired with Sheet 2):** `Ridership over time`
- **Sheet 3 caption:** `Monthly station entries by platform. Demand rose on both sides — so the platform-reliability gap is widening, not closing.`

**So-what box for the paired section (place below both charts):**
> **So what:** the incident bars confirm the gap is structural, not a one-month anomaly — both platforms absorb comparable disruption month after month, yet the 1/2/3 keeps trains closer to schedule. Ridership rises on both sides through the year, so the gap is widening, not closing.

---

## Step 9 — Reliability Comparison (Sheet 6a + 6b) — CENTERPIECE

**Source:** `service_quality`

**Goal:** Two side-by-side horizontal-bar sub-panels — Wait Assessment % on the left, Terminal OTP % on the right — each split by platform, so the 1/2/3 reliability advantage reads directly from bar length. **This is the dashboard's centerpiece: full width, top of body, directly below the KPI strip.**

> **Why two sheets, not one (decided 2026-05-09).** The render (`sample_dashboards/render_11_option3_platforms.html:180-216`) uses two independent sub-panels, each with its own sub-title and its own per-metric reference line ("system avg ~68%" on WA, "~77%" on OTP). A single combined sheet cannot honestly carry one shared reference line — WA% and OTP% have different system means, so a Table-scoped average across `Measure Values` is meaningless. Split build matches the render and gives each metric its correct anchor. The two sheets are placed in a Horizontal container on the dashboard, wrapped in an outer Vertical container that holds a shared title above and a shared so-what below; the outer Vertical carries the card border.

### 9a — Filters (apply to both sheets)

1. Drag `Year Match` to Filters → True → **Add to Context**
2. Drag `Period` to Filters → select `peak` → **Add to Context**
3. Drag `Day Type` to Filters → select `1` (weekday) → **Add to Context**
4. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E` → **Add to Context**

### 9b — Build Sheet 6a (Wait Assessment)

1. Mark type: **Bar**
2. Drag `Line Group` to **Rows** (this is what makes the bars horizontal — Line Group on the row axis, measure on the column axis)
3. Drag `Wait Assessment Pct` to **Columns**
4. Drag `Line Group` to **Color**
5. Drag the `Wait Assessment Pct` pill from Columns onto the **Label** card too (or duplicate it via Ctrl+drag)

### 9c — Build Sheet 6b (Terminal OTP)

Duplicate Sheet 6a (right-click sheet tab → Duplicate Sheet). On the copy:
1. Drag `Wait Assessment Pct` off both Columns and Label
2. Drag `Terminal Otp Pct` to **Columns**, then to **Label**
3. Everything else (filters, Line Group on Rows + Color) is inherited from the duplicate

### 9d — Colors and label format (apply to both sheets)

1. Set colors manually: 1/2/3 = `#59a14f`, A/C/E = `#4e79a7`
2. On the Label card → click the measure pill → **Format** → Numbers → Custom → `0.0"%"` (e.g. `69.6%`). Both labels must match — inconsistent decimals (`69.61%` vs `78.9%`) are the most common cosmetic bug here.
3. Label position: middle-center, white text — keeps the data inside the colored mark and reduces clutter on the card

### 9e — Value axis and reference line (per sheet, year-aware)

On **each** sheet:

1. Right-click the value axis (now horizontal — the bottom edge) → **Edit Axis** → Fixed range: `60` to `100`. Both sheets share this scale so the bars are visually comparable side-by-side. At 50–100 the gap looks shallower than it is; at 60–100 the ~4 pp gap reads as the headline.
2. **Analytics pane** → drag **Reference Line** onto the chart → scope: **Table** → value: **Average** of the sheet's own measure (`[Wait Assessment Pct]` on 6a, `[Terminal Otp Pct]` on 6b) → label: `"Penn avg"` (this is the average across Penn-serving routes only, not system-wide — see § Sheet 6 reference line in `project_state.md`) → style: dashed gray
3. Right-click the value axis → Edit Axis → clear the title field (the sub-title text in the dashboard container will carry the metric name)
4. Format → Lines → set Row Dividers and Column Dividers to None

### 9f — Sub-titles, shared title, and so-what (on the dashboard)

Each worksheet's own title can stay hidden (Worksheet → Hide Title). The metric labels live in the dashboard layout, not on the sheets, so the two sheets visually read as one card.

Container structure on the dashboard:

```
Vertical container (outer — border #e2e8f0 1px, background #ffffff)
├── Text: "Which platform should you trust?"          (shared title)
├── Horizontal container
│   ├── Vertical container
│   │   ├── Text: "Wait Assessment %"                 (sub-title 6a)
│   │   └── Sheet 6a
│   └── Vertical container
│       ├── Text: "Terminal On-Time Performance %"    (sub-title 6b)
│       └── Sheet 6b
└── Text: "So what: the 1/2/3 platform leads..."      (shared so-what)
```

Border on the **outer** Vertical only — never on individual sheets, and not on the inner Horizontal (set inner Horizontal background to None so only the outer fill shows). To select the outer Vertical reliably, use Layout pane → **Item hierarchy** at the bottom-left and click the outermost Vertical node directly. There is **no "Add Container Above" menu option** in Tableau — to insert a container, drag from the Objects pane and watch for a thin blue line (sibling drop) vs full-rectangle blue overlay (drops into target as child).

**Annotation (on Sheet 6a only):**
1. Right-click the 1/2/3 bar on Sheet 6a → **Annotate → Mark**
2. Type: `"~1 in 25 more trains on time at peak"` (claim-stable across years)

**Caption (placed as Text inside the outer Vertical, between the Horizontal row and the so-what):**
`Wait Assessment (% trains within 25% of headway) and Terminal OTP (% trips arriving on time). 1/2/3 outperforms A/C/E on both — the platform with more iconic "red lines" is also the more measurably reliable one.`

**So-what (insight-green style: `#f0fdf4` fill, `#59a14f` left border, `#14532d` text — matches 1/2/3 hero color):**
> **So what:** the 1/2/3 platform leads on both metrics, every quarter of the active year. A ~4-percentage-point Wait Assessment gap means roughly **1 in 25 more trains arrive on schedule** — which compounds across thousands of weekday commutes. *If you have both options on your MetroCard, take 1/2/3.*

---

## Step 10 — Delay Duration Box Plot (Sheet E)

**Source:** `monthly_incidents_delays`

**Goal:** One box per incident category showing the spread of `delay_per_incident` across months — Signals should have the widest spread and the highest outlier, making it visually the most severe category.

### 10a — Filters (apply first)

1. Drag `Year Match` to Filters → True → **Add to Context**
2. Drag `Incident Count` to Filters → **Range of Values** → set minimum to `1` → OK (excludes zero-incident months so the ratio is always defined)
3. Drag `Day Type` to Filters → select `1` (weekday) → **Add to Context**
4. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E` → **Add to Context**
5. Drag `Category` to Filters → keep all → **Add to Context** (FIXED LODs need this)

### 10b — Build the view

1. Drag the `Severity Ratio` calc from Step 6c (`SUM([Real Delay]) / NULLIF(SUM([Real Inc]), 0)`) to **Columns** — it's already an aggregate, no AVG wrapper needed.
2. Drag `Category` to **Rows**
3. Mark type: set to **Circle**
4. Drag `Month` to the **Detail** shelf — this is required. Without it Tableau collapses each category to a single value and the box has no spread. With it, each circle = one month's ratio for that category (12 circles per category).
5. Enable box plot: **Analytics pane** → drag **Box Plot** onto the view → drop on **Cell**
   - Alternatively: with Circle marks active, go to **Analysis menu → Box Plot**
   - The circles become the underlying data points; the box plot layer overlays quartiles and whiskers

### 10c — Sort and color (platform encoding) *(updated 2026-05-11)*

1. Right-click `Category` on the Rows shelf → **Sort** → sort descending by the `Severity Ratio` calc. The category at top is whichever has the highest median severity in the active year ("Other" and "Stations and Structure" typically lead — verify in the active year).
2. Drag `Line Group` to **Color** → Edit Colors. Assign the platform palette:
   - `1/2/3` → `#59a14f` (green, hero platform)
   - `A/C/E` → `#4e79a7` (blue, alternate platform)
3. Reduce circle opacity to 70% (Format → Marks → Opacity) so overlapping monthly observations show density without blobbing.
4. Box plot styling: outline `#6b7280` (medium gray), median line `#374151` (darker), whiskers `#9ca3af` (light gray) — colors recede so the platform dots are the focal layer. Set via right-click box → **Format Box Plot** (whisker color, fill = none / transparent).
5. **Optional emphasis on Signals + Track rows:** drag Analytics → Reference Band onto the Y axis → Band From `Signals`, Band To `Track`, Fill `#fef2f2` at ~60% opacity, Label None. Works only if those two rows are adjacent in the sort order; if not, use two single-row reference bands (see `tableau_build_learnings.md` § 25). For bold y-axis labels on those two categories, use the Unicode bold trick (`tableau_calc_patterns.md` § 14).

> **Why green/blue platform encoding (not the earlier red-spotlight palette):** the v3 so-what claims "both platforms show similar severity distributions across categories — A/C/E's improvement is from better routine recovery on the same severity backdrop." That visual claim requires green vs blue dots side-by-side within each category row. A spotlight palette (red accent on the surprise category) made sense under the older "Signals dominate" framing but contradicts the closing-gap narrative. Visual preview: `sample_dashboards/render_12_boxplot_colors.html`.

### 10d — Box plot formatting

1. Right-click any box → **Format Box Plot**:
   - Whiskers: **IQR × 1.5** (default — shows true outliers beyond the whiskers)
   - Fill: checked — if the fill color is stuck on gray, set it to the lightest available option or uncheck Fill entirely and rely on the box border + dot colors
   - Show outliers: checked (outlier dots beyond whiskers are the story)
2. Right-click the x-axis → **Edit Axis** → title: `Delay-Causing Trains per Incident (proxy)`

### 10e — Annotation

1. Identify the Signals outlier dot at the far right (highest delay-per-incident ratio)
2. Right-click it → **Annotate → Mark** → type: `"Worst-month outlier — longest-tail Signal event"` (claim-stable across years)
3. Drag the annotation callout line so it doesn't overlap the Signals box

> **Calc note:** the original `AVG([delay_per_incident])` is broken at row level (cross-join duplication). Replace with the dedup pattern from Step 3: build the box plot off `SUM([Real Delay]) / NULLIF(SUM([Real Inc]), 0)` per (month, category). Promote Category, Line Group, Day Type to Context.

### 10f — Title (as question), so-what

- **Title** (Worksheet → Show Title): `How bad is bad — per-incident severity?`
- **Caption:** `Per-month spread of delay-causing incidents per major incident, by category. Each circle = one month. Signals shows the longest tail and the highest outlier.`

**So-what box (Option 3 framing, canonical 2026-05-11):**
> **So what:** "Other" and "Stations and Structure" deliver the worst per-incident severity — rare but catastrophic days. Signals and Track are mid-severity but frequent, driving most of the total delay minutes despite milder per-event impact. Both platforms show similar severity distributions across categories — A/C/E's recent improvement isn't from getting lucky with milder incidents, it's from better routine recovery on the same severity backdrop.

**Alternative so-what (Option 2 cost framing, if pivoting):**
> **So what:** Signal failures span 4 to 52 minutes — that's the range a Penn rider can't plan around. Track failures cluster tightly: a Track incident is bad but predictable; a Signal incident might cost an entire commute.

---

## Step 11 — Filtered Map (Sheet F)

**Source:** `dim_corridor_complexes` + relationship to `monthly_incidents_delays`

**Goal:** A symbol map showing all corridor stations as circles, sized by incident count, colored by line group — visually concentrating the story at Penn Station and pointing toward WTC as the alternate route.

### 11a — Restore geographic roles

1. In the Data pane, make sure `dim_corridor_complexes` is the selected data source
2. Right-click `Latitude` → **Geographic Role → Latitude**
3. Right-click `Longitude` → **Geographic Role → Longitude**
4. This does not affect Sheet N (corridor scatter) because its axes are fixed ranges

### 11b — Build the symbol map

1. Drag `Latitude` to **Rows**
2. Drag `Longitude` to **Columns**
3. Tableau auto-generates a map — let it render
4. Mark type: **Circle** (symbol map)

### 11c — Size, color, labels (Option 3: focus to Penn only)

1. Drag `Complex Id` to Filters → select `318` and `164` only — **this is the Option 3 refocus**. Wider corridor complexes are hidden so the map shows the two Penn complexes, one staircase apart.
2. Drag `Year Match` (from the `monthly_incidents_delays` relationship) to Filters → True → **Add to Context**
3. Drag `SUM([Real Inc])` (from the `monthly_incidents_delays` relationship) to **Size**
4. Drag `Line Group` to **Color** → Edit Colors:
   - `1/2/3` → `#59a14f`
   - `A/C/E` → `#4e79a7`
5. Drag `Complex Name` to **Label** → always show on both
6. Map zoom: tighten to mid-Manhattan so 318 and 164 dominate the frame

> **For Option 2 backup:** keep this same filter (only 318 + 164) and swap `SUM([Real Inc])` for `SUM([Real Delay])` to size by total trains delayed (the cost unit).

### 11d — Map layers and annotations

1. **Map menu → Map Layers** → uncheck everything except Land and Coastline — gives a clean light gray base
2. **WTC (static annotation)** — right-click the WTC dot → **Annotate → Mark** → `"Alternate route via PATH"`. Geographic fact, no filter dependency.
3. **Penn (dynamic label, year-aware)** — annotations can't read parameters or aggregates, so use a conditional Mark Label instead.
   - Prerequisites: Step 15 complete (so `[Year Filter]` exists) and `monthly_ridership` blended into Sheet F on `complex_id`. If you're building in order, skip this sub-step now and return after Step 15. For a static value, fall back to `Annotate → Mark → "~2.9M paid entries/month"`.
   - In the `monthly_ridership` data source, create a calc field `Penn Label`:
     ```
     IF MIN([Complex Id]) IN (318, 164) THEN
       "Peak stress: "
       + STR(ROUND(SUM([Ridership]) / 1000000.0, 1))
       + "M riders in "
       + STR(YEAR([Year Filter]))
     END
     ```
     `MIN([Complex Id])` is required — Tableau won't mix the row-level `[Complex Id]` with aggregate `SUM([Ridership])` in one `IF`.
   - On Sheet F, click the orange link icon next to `Complex Id` in `monthly_ridership` to activate the blend, then drag `Penn Label` to **Label** on the Marks card.
   - Click **Label → Marks to label → All**. The calc returns NULL for non-Penn complexes, so only 318 and 164 show text.
   - The label updates automatically when the user changes the `[Year Filter]` parameter.
4. Format → remove map border if present (Format → Border → None)

> Annotations are static text in Tableau — they can't read parameters or aggregations. Mark labels respect filters and parameters, so they're the right tool when the headline number depends on the user's selection. Reserve annotations for facts that don't change (e.g., "Alternate route via PATH").

### 11e — Title (as question), so-what

- **Title** (Worksheet → Show Title): `How close are the two platforms, really?`
- **Caption:** `Penn 1/2/3 (complex 318) and Penn A/C/E (complex 164). Two complexes, one chokepoint, one staircase apart. Circle size = total trains delayed.`

**So-what box:**
> **So what:** the A/C/E complex turns each delay-causing incident into more rider-impact than the 1/2/3 complex, despite both drawing comparable infrastructure failures. The cost concentrates on one platform — and switching is a single staircase, not a transfer.

> Specific percentages are year-dependent. To make claims year-aware, build a `Delay Gap %` calc and surface it in the chart's tooltip; the so-what copy itself can stay claim-stable as written above.

---

## Step 12 — Day × Hour Heatmap (Sheet G)

**Source:** `hourly_ridership_corridor`

**Goal:** A 7×24 grid showing ridership intensity by day of week and hour — Tuesday 8 AM should be visibly the darkest cell, confirming peak risk timing.

### 12a — Filters (apply first)

1. Drag `Year Match` to Filters → True → **Add to Context**

1. Drag `Station Complex Id` to Filters → select `318` and `164` (Penn Station complexes only)

### 12b — Build the grid

1. Drag `Hour Of Day` to **Columns** — right-click → **Continuous** (green pill, not blue) — this is required for reference bands to work. *(Post Fix #1: this column is now native in the export; no `HOUR(...)` extraction needed.)*
2. Drag `Day Of Week` to **Rows** — this gives day names (Monday, Tuesday…). *(Post Fix #1: native column; no `DATENAME(...)` wrapper needed.)*
3. Mark type: **Square**
4. Drag `SUM([Ridership])` to **Color**

### 12c — Sort rows by day order

1. Right-click the `DATENAME` pill on Rows → **Sort**
2. Sort by: **Field** → field name: `Day Num` → aggregation: `MIN` → order: **Ascending**
3. This sorts Monday (1) → Sunday (7) top to bottom

### 12d — Color palette

1. Click **Color** on the Marks card → **Edit Colors**
2. Palette: select **Custom Sequential**
3. Set: low end = `#fef2f2`, high end = `#991b1b`
4. Check **Use Full Color Range** → click OK

### 12e — Reference bands (rush hours)

The hour column must be a continuous (green) pill for this to work — confirm from step 12b.

**Morning rush (7–9 AM):**
1. Open the **Analytics** pane (tab next to Data)
2. Drag **Reference Band** onto the view → drop on **Cell**
3. In the Edit Reference Band dialog:
   - Band From: **Constant** → `7`
   - Band To: **Constant** → `9`
   - Fill: click the color swatch → pick `#dbeafe` (light blue — same family as the A/C/E platform `#4e79a7`, distinct from the red heatmap palette)
   - Label: **None**
4. Click OK

**Evening rush (16–19):**
1. Drag another **Reference Band** onto the view → drop on **Cell**
2. Band From: `16`, Band To: `19`, same fill color `#dbeafe`
3. To edit an existing band later: right-click anywhere inside the shaded area → **Edit Reference Band**

### 12f — Annotation and format

1. **Peak label (dynamic, year-aware)** — instead of a static annotation, use a conditional Mark Label that recalculates from the active year filter.
   - Prerequisites: Step 15 complete (so `[Year Filter]` exists and `Year Match` is applied to this sheet). For a static fallback, skip the calcs below and use `Annotate → Mark → "Peak: Tue 8 AM — 3.2× weekday avg"`.
   - In `hourly_ridership_corridor`, create `Weekday Cell Avg`:
     ```
     {FIXED : SUM(IIF([Day Num] BETWEEN 1 AND 5, [Ridership], 0)) / 120.0}
     ```
     120 = 5 weekdays × 24 hours. The LOD strips row context so every cell sees the same workbook-level avg for the filtered year.
   - Create `Peak Label`:
     ```
     IF MIN([Day Num]) = 2 AND MIN([Hour Of Day]) = 8 THEN
       "Peak: Tue 8 AM in " + STR(YEAR([Year Filter])) + " — "
       + STR(ROUND(SUM([Ridership]) / [Weekday Cell Avg], 1))
       + "× weekday avg"
     END
     ```
     Returns NULL for every cell except Tuesday 8 AM (`Day Num = 2`, `Hour Of Day = 8`), so only that cell shows text. `MIN()` wraps the dimensions to avoid the aggregate/non-aggregate `IF` error.
   - Drag `Peak Label` to **Label** on the Marks card. Click **Label → Marks to label → All**.
   - Right-click the Tue 8 AM cell → **Mark Label → Always Show**. Set **Label → Alignment → Direction → Up** so the text floats above the cell instead of overlapping the dark heatmap fill.
2. Format → Cell Size: adjust so all 24 hour columns fit horizontally without a scrollbar
3. Right-click x-axis → Edit Axis → title: `Hour of Day`
4. Right-click y-axis → Edit Axis → clear title

### 12g — Title (as question), so-what

- **Title** (Worksheet → Show Title): `If you had to pick one moment to avoid Penn, when?`
- **Caption:** `7×24 grid of Penn ridership. Rush-hour bands shaded in lavender. Tuesday 8 AM is the densest cell — peak ridership intersects peak incident frequency.`

**So-what box (Option 3 framing):**
> **So what:** Tuesday 8 AM is peak risk on *both* platforms — but it's also the hour with the largest absolute ridership × failure interaction, so the ~4 pp Wait Assessment gap saves the most riders the most time at exactly this cell. *The headline advice has its highest value here.*

**Alternative so-what (Option 2 cost framing, if pivoting):**
> **So what:** Tuesday 8 AM is the single highest-cost cell — 3.2× the weekday average. PM rush (4-6 PM) shows a smaller secondary peak; weekends drop sharply. *If a rider could move one commute by an hour, this is the hour to move out of.*

---

## Step 13 — Sankey Flow (Sheet San)

**Source:** `monthly_incidents_delays`

**Goal:** Show how delay-causing incidents flow from incident category to platform. Signals are the dominant left-side node for both platforms; the wider-of-the-two right-side band is year-dependent — verify in the active year before annotating.

Tableau Public 2026.1.0 has a native Sankey chart type — no extensions needed.

### 13a — Filters (apply first)

1. Drag `Year Match` to Filters → True → **Add to Context**
2. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E` → **Add to Context**
3. Drag `Day Type` to Filters → select `1` (weekday) → **Add to Context**

### 13b — Build the Sankey

1. New sheet → rename "Sankey"
2. In the Marks card, open the chart type dropdown → select **Sankey**
3. The Marks card shows three tabs: **Level**, **Link**, **Detail**
4. Drag `Category` to **Level** — first node dimension (left side)
5. Drag `Line Group` to **Level** — second node dimension (right side)
6. Drag `SUM([Delay Count])` to **Link** — controls the band width (flow volume)

### 13c — Colors

The Sankey marks card has separate color controls per tab — click each tab to set colors independently.

**Level tab (node colors):**
1. Click the **Level** tab in the Marks card
2. Click **Color** → Edit Colors
3. Assign:
   - Signals → `#ef4444` (category accent — alert color)
   - Track → `#f59e0b`
   - All others → `#94a3b8`
   - `1/2/3` → `#59a14f` (platform green)
   - `A/C/E` → `#4e79a7` (platform blue)

**Link tab (band/ribbon colors):**
1. Click the **Link** tab in the Marks card
2. Click **Color** → set to a neutral gray or lower opacity to let node colors dominate

### 13d — Labels and format

1. Enable node labels: click **Label** on the Marks card → check **Show mark labels**
2. Left nodes show `Category`, right nodes show `Line Group` — no additional fields needed
3. Hide the legend if node labels make it redundant (right-click legend → Hide Card)
4. Format → Lines → remove all gridlines and borders

> **Calc note:** Sankey link width should use `SUM([Real Delay])` (the dedup field from Step 3), not raw `SUM([Delay Count])`. Promote `Line Group` and `Day Type` to **Context** so the FIXED LOD divisors compute correctly.

### 13e — Title (as question), so-what

- **Title** (Worksheet → Show Title): `How do delays distribute by category and platform?`
- **Caption:** `Flow width = delay-causing incident count. Signals dominate the left-side flow; the right-side split between platforms varies year to year.`

**Annotation:** right-click whichever Signals→platform band is widest in the active year → **Annotate → Mark** → type a year-stable phrase like `"Widest flow — Signals dominate the disruption mix"`. Don't bake a platform name or number into the annotation since both change year-to-year.

**So-what box (Option 3 framing):**
> **So what:** Signals dominate the flow into both platforms. The band widths track total incidents — the more reliable platform isn't the one with the *narrower* band; it's the one whose service frequency and recovery operations turn the same band into less rider-impact downstream (see Sheet 6).

---

## Step 14 — Assemble the Dashboard

1. **Dashboard → New Dashboard**
2. Set size: Fixed, 1120 × 1600px (or use Automatic and constrain later)
3. Set background: `#faf8f4`

**Drag sheets in this order (top to bottom) — Option 3 layout:**

| Position | Content | Type |
|----------|---------|------|
| Full width, top | Title + Year Filter parameter control | Floating text box + parameter (Compact List) |
| Full width | Journey Headline text (year-aware copy) | Floating text box (`#ffffff` bg) |
| Full width, 4 cols | KPI 1 · KPI 2 · KPI 3 · KPI 4 (each with sub-tag) | Horizontal container, 4 sheets |
| Full width — **CENTERPIECE** | Reliability Comparison (Sheet 6a + 6b side-by-side) + shared title above + so-what below | Outer Vertical container with border, inner Horizontal holding 6a + 6b each with their own metric sub-title — see Step 9f for the structure |
| Full width | Sheets 2 + 3 (Incidents bars + Ridership area, 2×2 grid) + so-what box | Vertical container |
| Half + half | Cause Ladder (Sheet 4) + so-what · Quilt (C-1 above C-2) + qualifier callout + so-what | Horizontal container |
| Half + half | Map (Sheet 7, Penn 318+164 only) + so-what · Heatmap (Sheet 8) + so-what | Horizontal container |
| Full width (optional, supporting) | Box Plot (Sheet 5) · Sankey (San) | Horizontal container — only if space allows |
| Full width | Narrative footer ("The bottom line" + caveats block) | Floating text box (`#0f172a` bg) |

> **Sheet N (corridor scatter) does NOT appear** in the Option 3 layout — it's retired. If you previously built it, hide it (Worksheet → Hide) rather than deleting; preserves the work for an Option 2 or v2 fallback.

**Container tips:**
- Use **Tiled layout** as the base. Add floating text boxes for the headline and footer.
- For the KPI strip: create a horizontal tiled container, drag all 4 KPI sheets in, set each to equal width.
- Match inner padding: 8px on all cards, 10px gap between containers.

---

## Step 15 — Year filter audit (parameter created in Step 3)

The `Year Filter` parameter and `Year Match` calc fields are created in Step 3 — moved earlier than v2 so the KPI tiles can use them. This step is a reconciliation pass to make sure every sheet honors the parameter.

### 15a — Audit every sheet

For each sheet (1, 2, 3, 4, 5, 6a, 6b, 7, 8, C-1, C-2, Sankey, all 4 KPIs), confirm:

1. `Year Match` is on the Filters shelf, set to **True**, and **in Context** (gray pill, not blue).
2. The sheet's title, caption, annotation, and so-what box do not contain a hardcoded year string.

To apply `Year Match` to all sheets in a data source at once:
1. Right-click `Year Match` in the Filters shelf on any sheet → **Apply to Worksheets → All Using This Data Source**
2. Repeat for each of the 4 date-bearing data sources.

### 15b — Show the parameter control on the dashboard

1. Right-click `Year Filter` in the Data pane → **Show Parameter** (already done in Step 3)
2. Drag the control onto the dashboard, top-right corner
3. Right-click the control on the dashboard → **Customize** → set display to **Compact List**

### 15c — KPI tiles: include in filter

For Option 3, **all 4 KPIs honor the year filter** (riders/month, routes converging is naturally year-stable, incident months, WA gap). This is the right default — when the user selects a year, the entire dashboard updates coherently.

If you ever want a tile fixed to a specific year regardless of selection, omit `Year Match` from that sheet (e.g., for a benchmark "2024 baseline" tile). Document the choice in a sheet-level comment so future-you knows why.

### 15d — When extending to multi-year data

When you extend `3_transform.sql` WHERE-year ranges and re-run the pipeline:

1. Add the new years to the `Year Filter` parameter's **List of values** (right-click parameter → Edit → add value)
2. Refresh the data sources in Tableau (Data → Refresh)
3. Validate KPIs against the new year(s) using the QA checklist in Step 17
4. Update the journey headline and footer copy if any year-specific phrasing has crept in (it shouldn't have if you followed the discipline)

---

## Step 16 — Narrative footer text box

1. Dashboard → Objects → Text → drag to bottom
2. Set background: `#0f172a`, padding 20px
3. Type the footer text (see DASHBOARD_MODEL.md for exact wording)
4. Format bold text as `#f1f5f9`, body as `#64748b`, red emphasis as `#f87171`
5. Set fixed height ~80px

---

## Step 17 — Final QA checklist

**Numbers (verify against the raw CSV for the active `Year Filter`):**
- [ ] KPI 1 reads `~2.9M` per-month avg at Penn (complexes 318+164) for active year
- [ ] KPI 2 reads `6` (routes converging — should be stable across years)
- [ ] KPI 3 reads `{N}/12` for active year (months with Signal/Track outages on Penn routes)
- [ ] KPI 4 reads `+{X} pp` (year-aware 1/2/3 – A/C/E peak Wait Assessment gap; 2024 verified value: `+3.8 pp`)
- [ ] All four KPIs use `Real Inc` / `Real Delay` / `WA Gap` / `Riders Per Month` from Step 3 with Context filters on Category, Line Group, Day Type, Year Match — not raw row-level fields

**Year-agnostic discipline:**
- [ ] No sheet title, caption, KPI sub-tag, annotation, or so-what box contains a hardcoded year string. Search the workbook for "2024" — should return zero hits in editorial copy. Calc fields and value pills are fine.
- [ ] **Annual sign sanity check:** if you toggle `Year Filter` between available years, KPI 4 stays positive (1/2/3 ahead). If it flips negative, the platform-contrast headline weakens — either re-flip the narrative back to A/C/E-as-hero or pivot to Option 2 backup.
- [ ] Journey headline copy is claim-stable across years (no specific number that would lie if the year changed).

**Tiles and styling:**
- [ ] KPI strip tiles all have dark `#0f172a` background with white headline, `#94a3b8` subtitle, accent-colored sub-tag with 1px top border
- [ ] 1/2/3 platform = green `#59a14f`; A/C/E platform = blue `#4e79a7`; category accents (Signal red, Track orange on Sheet 5) only on category-encoded charts — no color bleed between platform and category encodings
- [ ] Heatmap rush-hour bands are light blue `#dbeafe` (A/C/E family), not the old lavender or warm tint

**Charts:**
- [ ] Every chart has a Title in **question form** (per Steps 6e, 7, 8c-title, 9f, 10f, 11e, 12g, 13e)
- [ ] Every chart has at least one **annotation on a specific mark** (per Steps 6e, 9f, 10e, 13e)
- [ ] Every chart has a **so-what interpretation box** below it (per the same Steps)
- [ ] Map (Sheet 7) shows only complexes 318 and 164 — no wider corridor stations
- [ ] Box plot Signals row shows the outlier dot at far right (year-dependent — verify exists)
- [ ] Heatmap Tue 8 AM cell is visibly the darkest, with the dynamic Peak label visible
- [ ] Reliability bars (Sheet 6a + 6b centerpiece): 1/2/3 is higher than A/C/E on both WA% (6a) and OTP% (6b); both sheets share Fixed 60–100 axis
- [ ] Monthly quilt: platform-specific months stand out (top red panel ≠ bottom purple panel) and the qualifier callout flags the contradicting month
- [ ] Sankey: band widths reflect each platform's incident totals (visual asymmetry is OK; the reliability story is in Sheet 6, not here)
- [ ] Sheet N (corridor scatter) is hidden or absent from the dashboard layout

**Filtering and parameters:**
- [ ] Year filter parameter (Step 3) drives every date-bearing sheet (verify by changing it and watching all charts update)
- [ ] Year-aware Mark Labels (Sheet 7 Penn label, Sheet 8 Peak label) update when year changes
- [ ] Reference line on Sheet 6a (Penn-avg WA%) and Sheet 6b (Penn-avg OTP%) — each set to **Average** of its own measure scoped Table, not Constant; labels read "Penn avg" since the average is across Penn-serving routes only, not system-wide
- [ ] Footer copy + caveats block do not name a specific year

---

## Export for submission

1. **File → Export Packaged Workbook (.twbx)** — this bundles the 5 CSVs into a self-contained file
2. Rename: `inside_penn_v3.twbx`
3. Test: open the `.twbx` on a machine without the `tableau_exports/` folder — all data should load

The `.twbx` is what The Data School reviewers will open.

---

## Backup variant — Option 2 ("What It Costs to Enter NYC Through Penn Station")

Documented fallback if the Option 3 platform-contrast headline weakens with more years of data (e.g., the ~4 pp WA gap closes or reverses). The pivot is editorial — **the SQL pipeline is identical; only the Tableau workbook changes**.

**Mockup:** `sample_dashboards/render_10_option2_cost.html`.
**Spec:** see `DASHBOARD_MODEL.md` § "Option 2 backup variant" for KPI table, sheet retire/demote, and footer copy.

### When to pivot to Option 2

Trigger conditions (any one):
- Annual sign sanity check (Step 17) shows KPI 4 has flipped negative for the active year — 1/2/3 is no longer ahead, and re-flipping the narrative back to A/C/E doesn't yield a stable headline either.
- The ~4 pp gap has narrowed below ~2 pp for the most recent year — too close to be a confident headline.
- Reviewer feedback indicates the platform-choice framing is misread as "one platform is bad" rather than "one platform is better."

### Pivot steps (estimated ~5 hours total)

**1. Title + headline + footer (~1 hr)**

- Title → `What It Costs to Enter NYC Through Penn Station`
- Subtitle → `Penn 318 + 164 · the operational cost of a Signal or Track failure`
- Headline paragraph → see `render_10_option2_cost.html` for verbatim copy (year-agnostic)
- Footer → use the "Closer (Option 2)" copy from `DASHBOARD_MODEL.md` § Narrative Footer; caveats block adds "Severity proxy treats all delayed trains as equivalent."

**2. KPI swaps (~2 hr) — keep Year Filter / Year Match wiring intact**

| Tile | Replace with | Calc |
|---|---|---|
| KPI 2 (Routes Converging `6`) → | **Worst Single Delay `{X} min`** | `MAX([Severity Ratio]) * 3` (proxy minutes) |
| KPI 3 (Months Hit `{N}/12`) → | **Total Trains Delayed `~{N}K`** | `SUM([Real Delay])` × proxy on Penn-serving routes |
| KPI 4 (WA Gap `+{X} pp`) → | **Peak Risk Multiplier `{X}×`** | Tue 8 AM ridership / weekday cell avg (built from `hourly_ridership_corridor`) |

KPI 1 (`~2.9M`) stays. Sub-tags update — see `render_10_option2_cost.html` for verbatim copy.

**3. Centerpiece swap (~30 min)**

Promote Sheet 8 (Day × Hour Heatmap) to full-width centerpiece directly below the KPI strip. Update its title to `When does it cost the most?` and use the Option 2 so-what variant (already provided in Step 12g).

Demote or remove Sheet 6a + 6b (Reliability) — the WA gap is no longer the punchline. Hide rather than delete (Worksheet → Hide) so they can return if you pivot back.

**4. Sheet retires/demotes (~30 min)**

| Sheet | Action |
|---|---|
| Sheet 6a + 6b (Reliability) | Hide both — no longer load-bearing |
| Sheet 3 (Ridership over time) | Hide — doesn't directly answer the cost question |
| Sheet C-1 / C-2 (Quilt) | Hide — two-platform contrast removed |
| Sheet San (Sankey) | Hide or simplify to a single Category → trains-delayed bar |
| Sheet 7 (Map) | Keep but retitle `Where does the cost concentrate?` and swap size encoding to `SUM([Real Delay])` |

**5. Sheet 2 single-series rebuild (~30 min)**

Drop `Line Group` from the Color shelf on Sheet 2 — the cost framing prefers a single curve over the platform split. Update title to `Which months cost the most?` and use the Option 2 so-what variant.

### Pivoting back to Option 3

Reverse the steps above. Because all the Option 3 sheets were *hidden* not *deleted*, the workbook still contains them — unhide via Worksheet menu and rewire to the dashboard.

### What does NOT change when pivoting

- The 5 CSV exports — same files, same grain
- `3_transform.sql` and `4_export.sql` — unchanged
- The `Year Filter` parameter and `Year Match` calcs — unchanged
- The `Real Inc` / `Real Delay` dedup discipline — unchanged
- The text-insight stack (titles as questions, annotations, so-what boxes, action footer + caveats) — unchanged; only the *content* of those text elements changes

The pipeline is durable; only the editorial layer pivots.
