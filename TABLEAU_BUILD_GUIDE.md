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

**Goal:** Horizontal bars showing incident frequency per category, **split by platform** (one bar per platform per category) — so the chart directly answers whether both platforms see the same kinds of failure. They mostly do; that's the point.

> **2026-05-22 — feedback fix.** Previous build used a dual-axis circle to encode `Severity Ratio` on the *same* x-axis as the count bar (synchronized, so the circle's position visually competed with the bar's length). That's a double-encoding trap: one axis was doing two semantic jobs and a casual reader couldn't tell which value the position was reporting. The fix is to drop the circle entirely and put severity in the **bar label** instead, so each visual channel encodes exactly one thing: length = count, color = platform, label suffix = severity.

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

### 6c — Add severity as a label on each bar (replaces dual-axis circle)

First create a calc field **Severity Ratio** in `monthly_incidents_delays` (this is the same calc the retired dual-axis used — we're just plotting it differently):
```
SUM([Real Delay]) / NULLIF(SUM([Real Inc]), 0)
```

It computes per-cell because both `Real Delay` and `Real Inc` are aggregates — with `Line Group` nested on Rows, each (category, platform) cell gets its own ratio. Now build the label:

1. Drag `SUM([Real Inc])` to the **Label** shelf — this puts the count on each bar
2. Create a calc field **Severity Suffix** on `monthly_incidents_delays`:
   ```
   " · " + STR(ROUND([Severity Ratio], 0)) + " delays/inc"
   ```
3. Drag `Severity Suffix` to the **Label** shelf as a second pill (drop it next to the count)
4. Open the Label card → Edit Label → format the count in bold default color, the suffix in `#64748b` (muted gray) so the eye reads count-first
5. Final label on each bar reads e.g. `38 · 97 delays/inc`

> **Magnitude note:** the ratio is `SUM(Real Delay) / SUM(Real Inc)`, where `Real Inc` counts *major incidents* and `Real Delay` counts *delay-causing incident reports* (a more granular MTA metric). One major incident typically generates ~80–110 downstream delay-causing-incident records, so values land in the 80–110 range, not 1–10. Earlier docs showed `3.2×` as a placeholder — that was illustrative, not data. Hence the `ROUND(..., 0)` (no decimal needed at this magnitude) and `delays/inc` (the multiplier framing `"× delay"` reads awkwardly when the value is 97).

> Make sure Category, Line Group, Day Type filters are all in **Context** — without that, the FIXED LODs inside `Real Inc`/`Real Delay` ignore the category filter and the ratio is wrong.

### 6d — Format

1. Right-click the x-axis → Edit Axis → title: `Major incidents per platform (severity shown in label)`
2. Format → Lines → remove gridlines
3. Sort already applied in 6b — verify Signals lands at the top
4. **Do NOT add a dual axis or a circle layer.** That's the encoding the 2026-05-22 fix removed. If you want a per-category benchmark, use a Reference Line on `Severity Ratio` — but be aware it competes with the label text. Default to no reference line; the labels carry the comparison.

> **Calc note:** the original guide used `AVG([delay_per_incident])` (a row-level ratio) which compounds with the cross-join duplication. Replace it with the Step 3 dedup pattern: build the severity calc from `SUM([Real Delay]) / NULLIF(SUM([Real Inc]), 0)` and keep **Category, Line Group, Day Type in Context** so the FIXED LODs see the right denominators.

### 6e — Title (as question), annotation, and so-what box

- **Title** (Worksheet → Show Title → Edit Title): `Do both platforms see the same kinds of failure?`
- **Caption** (Worksheet → Show Caption): `Bar length = major incidents on that platform. Label suffix = delay-causing incident reports per major incident (severity). Side-by-side within each category, both platforms.`

**Annotation (on chart):**
1. Right-click the **Persons on Trackbed** row (either platform's bar) → **Annotate → Mark** — *verify this is the top category by `Real Inc` in the active year; if a different category leads, anchor on that row instead*
2. Type: `"Trackbed intrusions hit 1/2/3 more often — yet 1/2/3 still leads on reliability. Recovery, not avoidance."` (the "more often" half is directly visible in the side-by-side green/blue bar lengths on that row)
3. Style the callout: small font, subtle gray border.

**So-what box (floating text on dashboard, below the chart):**
> **So what:** broadly yes — Persons on Trackbed leads on both platforms, with Signals and Track close behind. The "delays/inc" labels show severity is comparable per-category across platforms. **The bigger surprise: in every one of the top three categories (Trackbed, Signals, Track), 1/2/3 actually carries *more* incidents on average than A/C/E — yet still wins on reliability.** The gap shown above *isn't* explained by a different mix of failures, nor by different severity per incident, nor by lower incident counts on 1/2/3. Both platforms see the same problem profile; 1/2/3 sees *more* of it. The gap must be in what happens *after* an incident — a service-frequency and recovery-operations story.

> The bolded sentence is the chart's punchline — bold it visually in the dashboard text object so the eye lands on it.

> **Verify per-platform claim before shipping.** The "1/2/3 sees more" claim is chart-verifiable: for each of the top 3 category rows, the green bar should be visibly longer than the blue bar. If only 2 of 3 hold (or the rank order is different), soften to name only the categories that hold ("...in two of the top three categories — Trackbed and Signals — 1/2/3 carries more..."). Don't claim more than the bars show.

Use the `.insight` style for the **hero (1/2/3) green family**: light fill `#f0fdf4`, 3px left border `#59a14f`, body text `#14532d`, font 11px.

### 6f — Sheet 4a (Cause-side trajectory) — added 2026-05-28

**Source:** `monthly_incidents_delays` (same as Sheet 4)

**Goal:** Volume-trend partner to Sheet 4. Side-by-side bars showing total annual `Real Inc` per Line Group across 2022 / 2023 / 2024, all categories. Answers *"is A/C/E having fewer incidents (prevention story) or recovering better from a rising load (operations story)?"* — chart-verifies CLAUDE.md narrative beat 5.

> **Cross-year by design.** Do **not** add `Year Match` to this sheet's filter shelf. Sheet 4a is intentionally the one cross-year card in the cause-side block.

**Filters:** `Day Type` = `1` (Add to Context), `Line Group` ∈ `{1/2/3, A/C/E}` (Add to Context), `Category` = all (Add to Context — FIXED LODs need it).

**Marks:**
- Columns: `YEAR(Month)` discrete (blue pill), then `Line Group` to the right of it (groups bars side-by-side per year)
- Rows: `SUM([Real Inc])` (the dedup calc; not raw `Incident Count`)
- Color: `Line Group` → `#59a14f` / `#4e79a7`
- Mark type: Bar
- Label: `SUM([Real Inc])` integer-formatted, shown on each bar

**Polish:**
- Hide y-axis title (Edit Axis → blank Title field)
- X-axis aliases: append the per-year incident-load gap to each year tick — `2022 (+13)`, `2023 (+6)`, `2024 (+23)`
- Tooltip: `<Line Group> · <YEAR(Month)> · <Real Inc>` only

**Title (assertion-form):** `More incidents on both — A/C/E closes the gap anyway`
**Caption:** `Total major incidents per year, by platform, 2022–2024 — all categories.`
**So-what:** see `DASHBOARD_MODEL.md` § canonical caption set.

**Place on dashboard:** full content width, ~260 px tall, between Sheet 4 and Sheet 5.

**Verify-before-shipping check:** the 87/88/124 (1/2/3) and 74/82/101 (A/C/E) values were verified against the live render 2026-05-28. If your numbers differ materially after a data refresh, check that all filters are in Context (otherwise the FIXED LODs ignore the Line Group filter and bar magnitudes inflate).

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
- **Caption:** `Top row: 1/2/3 platform. Bottom row: A/C/E platform. Darker cell = more Signal+Track incidents that month.`

> **2026-05-22 — feedback fix.** Earlier caption named the palettes in parentheses ("(green palette) / (blue palette)") — and earlier still, under v2, used "(red palette) / (purple palette)" before the platform colors flipped to green/blue. Reviewer caught that the workbook's live caption had typed the parentheticals **reversed** (1/2/3 labelled with the blue palette, A/C/E with green), which contradicted the contract held everywhere else on the dashboard. Cleanest fix: drop the palette parentheticals entirely. The row labels (1/2/3 in green text, A/C/E in blue text) already convey the mapping; restating it in prose only creates an opportunity to flip it.

Hide each constituent sheet's individual title (Worksheet → Hide Title) so only the floating header is visible.

**Honest qualifier callout (small lavender callout above the so-what):**
After identifying the qualifier month from the data (the month where 1/2/3 is heavy while A/C/E is clear — verify in the active year before quoting), add:
> ⚠ **{Month name}:** A/C/E is clear, 1/2/3 is heavy. The one month where the headline advice would have failed.

To make this dynamic, build a calc field that returns the qualifier month name based on the active year filter. If you want the simpler path, type the month manually and update each year (mark it with a comment like `<!-- year-sensitive: verify {Month name} for active year -->`).

**So-what box (insight-blue style — `#eff6ff` fill, `#1d4ed8` left border, `#1e3a8a` text):**
> **So what:** the platforms don't fail in lockstep — they're operationally independent within the same complex. That's *good news* for the routing argument: when one is degraded, the other is usually still on schedule. The {N}-month exception is the honest qualifier on the headline.

---

## Step 8 — Incident Timeline (Sheet 2) + WA% Timeline (Sheet 3)

> **2026-05-22 — feedback fix.** Sheet 3 was a stacked area chart of ridership over time. Two problems: (1) it didn't visibly answer the section question ("Is the gap real?" — the question is about the reliability gap, which the chart didn't draw), and (2) it silently used `monthly_ridership.csv` filtered by complex-based `line_group`, which covers all 35 stations along 1/2/3 and A/C/E lines — so the y-axis read 4–9M total while KPI 1 read ~2.9M (Penn-only complexes 318 + 164). The reviewer correctly flagged both: chart didn't answer its own header, and numbers didn't reconcile with the KPI. Replaced Sheet 3 with a Wait Assessment % by platform over time line chart, sourced from `service_quality.csv` (which already filters cleanly by platform and is what Sheet 6 uses). Ridership stays surfaced on KPI 1.

### Sheet 2 — Incidents over time (stacked bar) — *unchanged*

**Source:** `monthly_incidents_delays`

**Goal:** Stacked bars showing total Signal + Track incidents per month, split by platform — the combined height shows system-wide stress; the green/blue split shows which platform absorbs more.

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
- **Sheet 2 caption:** `Stacked monthly Signal + Track major incidents — 1/2/3 in green, A/C/E in blue. Combined height = system-wide stress; the split shows which platform absorbs it.`

---

### Sheet 3 — Wait Assessment % over time (line chart) — *2026-05-22 rebuild*

**Source:** `service_quality`

**Goal:** Two-line chart of monthly Wait Assessment % at peak weekday — one line per platform. Directly draws the reliability gap month by month, which is exactly what the section question ("Is the gap real, or just an average that hides bad months?") promises. The chart pair (Sheet 2 incidents + Sheet 3 WA%) now reads as: "here's the stress on both platforms, and here's the resulting reliability gap, drawn at the same time grain."

#### 8d — Filters (all → Add to Context)

1. Drag `Year Match` to Filters → True → **Add to Context**
2. Drag `Period` to Filters → select `peak` → **Add to Context**
3. Drag `Day Type` to Filters → select `1` (weekday) → **Add to Context**
4. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E` → **Add to Context**

#### 8e — Build

1. Drag `MONTH([Month])` to **Columns** — right-click → **Continuous** (line charts need a continuous x-axis; this is the one place Step 8 differs from Sheet 2's discrete months)
2. Drag `Wait Assessment Pct` to **Rows** — aggregate as **AVG** (right-click pill if it lands as SUM)
3. Mark type: **Line**
4. Drag `Line Group` to **Color** — produces two lines, one per platform
5. Edit Colors: 1/2/3 = `#59a14f`, A/C/E = `#4e79a7`
6. Line size: drag `Line Group` to Size if you want both lines the same weight; default is fine. Avoid dashed/dotted styles — both platforms get solid lines.

#### 8f — Y-axis format

1. Right-click y-axis → Edit Axis → **Fixed** range `60` to `80`
2. Tick format: percent with one decimal (`0.0"%"`)
3. Title: `Wait Assessment % (peak weekday)`

The fixed 60–80 range is the same band the Sheet 6 centerpiece uses for WA — keeps the visual scale consistent across the dashboard. If WA% drops below 60 in any year/month, widen to 55–80 rather than letting it auto-fit (auto-fit makes inter-year visual comparison misleading).

#### 8g — Reference line (optional, recommended)

1. Analytics pane → Reference Line → drop on the view → scope **Table**, value **Average** of `Wait Assessment Pct`, label `"Penn avg"`, style dashed gray (`#94a3b8`)
2. This gives the eye a neutral middle line; the 1/2/3 line sits above it, the A/C/E line below — the gap is visible without arithmetic.

#### 8h — Dashboard alignment

- Place Sheet 3 directly below Sheet 2 in a vertical container with the same fixed width so the month axes align. Sheet 2 uses discrete months and Sheet 3 uses continuous — they should still align if both have all 12 months in the active year. If they don't, set both to start at January and end at December via axis edits.

#### 8i — Title and caption (Sheet 3)

- **Sheet 3 title (visible — paired with Sheet 2, question form):** `Does the gap hold every month?`
- **Sheet 3 caption:** `Monthly Wait Assessment % at peak weekday, split by platform. The gap between the green and blue lines is the reliability advantage of 1/2/3 — drawn month by month so a "bad month" can't hide an average.`

> **Title pattern:** the original descriptive label (`Wait Assessment % by platform, monthly`) didn't match the rest of the dashboard's question-form titles (`Which platform should you trust?`, `Do both platforms see the same kinds of failure?`, etc.). The revised title is narrower than the section header above (`Is the gap real, or just an average that hides bad months?`) — the section asks whether the gap exists; Sheet 3 specifically answers whether it appears month-by-month.

**So-what box for the paired section (place below both charts):**
> **So what:** the incident bars confirm the stress is structural, not a one-month anomaly — both platforms absorb comparable disruption month after month. The WA% lines confirm the *reliability* gap is also structural: 1/2/3 sits ~3–5 pp above A/C/E nearly every month, and toggling the year filter shows the gap narrowing year over year (A/C/E rising toward a stable 1/2/3). Same data, drawn directly.

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

### 9g — Trajectory chart (cross-year WA %) — added 2026-05-28

**Source:** `service_quality` (same as Sheets 6a/6b)

**Goal:** Two-line chart showing peak weekday Wait Assessment % per Line Group across 2022 → 2024, so the closing-gap arc carries from the headline into the body. **Sits directly between the KPI strip and Sheet 6 on the dashboard** — same data family as Sheet 6, just rolled up across all three years instead of a single-year snapshot.

> **Cross-year by design.** Do **not** add `Year Match` to this sheet's filter shelf. The Trajectory and Sheet 4a are the only two cards on the dashboard that intentionally ignore `[Year Filter]`.

**Filters:** `Day Type` = `1` (Add to Context), `Period` = `peak` (Add to Context), `Line Group` ∈ `{1/2/3, A/C/E}` (Add to Context).

**Marks:**
- Columns: `YEAR(Month)` — discrete (blue pill)
- Rows: `AVG([Wait Assessment Pct])` (or whatever measure Sheet 6a uses — match exactly)
- Color: `Line Group` → `#59a14f` / `#4e79a7`
- Detail: `Line Group` (so each line draws across years)
- Mark type: Line
- Label: WA value as percent, 1 decimal

**Polish:**
- Hide y-axis title (Edit Axis → blank Title)
- Y-axis fixed range: `58%` to `75%` — covers full range with breathing room
- X-axis aliases: append per-year gap to each tick — `2022 (+8.0 pp)`, `2023 (+4.3 pp)`, `2024 (+3.8 pp)`. Right-click `YEAR(Month)` pill → Aliases…
- Tooltip: `<Line Group> · <YEAR(Month)> · <WA %>` only

**Title (assertion-form, because this card delivers the dashboard title's promise):** `1/2/3 holds; A/C/E catches up`
**Caption:** `Peak weekday Wait Assessment %, 2022 → 2024.`
**So-what:** see `DASHBOARD_MODEL.md` § canonical caption set.

**Place on dashboard:** full content width, ~160–200 px tall (smaller than Sheet 6 — it's a setup card, not the centerpiece), between the KPI strip and Sheet 6.

**Belt-and-suspenders check:** dashboard → click the Year Filter parameter card → drop-down → "Apply to Worksheets…" → "Selected Worksheets…" → confirm this trajectory sheet is unchecked. Flip the year filter through 2022/2023/2024; every other sheet should change, the trajectory card should not.

---

## Step 10 — Per-incident Severity Bar (Sheet 5) — *2026-05-22 rebuild*

**Source:** `monthly_incidents_delays`

**Goal:** One horizontal bar per incident category showing `AVG([Severity Ratio])` (trains delayed per major incident), sorted descending, with the value labeled on each bar. The chart answers "how bad is bad?" in one sweep: longest bar at top, severity value labeled, no interpretation required.

> **2026-05-22 — feedback fix.** Earlier build was a box plot with circles for each month and overlaid quartile boxes — dozens of overlapping marks per category, colored by platform. Reviewer flagged it as analyst-heavy: the chart paid a lot of cognitive load for an insight a simpler bar carries cleanly. Replaced with a labeled bar (one bar per category, no platform split). Box plot variant archived in `sample_dashboards/render_12_boxplot_colors.html` for reference.

### 10a — Filters (apply first, all → Add to Context)

1. Drag `Year Match` to Filters → True → **Add to Context**
2. Drag `Incident Count` to Filters → **Range of Values** → set minimum to `1` → OK (excludes zero-incident months so the ratio is always defined)
3. Drag `Day Type` to Filters → select `1` (weekday) → **Add to Context**
4. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E` → **Add to Context**
5. Drag `Category` to Filters → keep all → **Add to Context** (FIXED LODs in `Real Inc`/`Real Delay` need this)

### 10b — Build the view

1. Drag `Category` to **Rows**
2. Drag the `Severity Ratio` calc (`SUM([Real Delay]) / NULLIF(SUM([Real Inc]), 0)`) to **Columns** — already aggregate, no AVG wrapper needed
3. Mark type: **Bar**
4. **Do NOT add Month to Detail.** That was required for the retired box plot (to get per-month dots). For the bar chart we want one aggregate value per category — leave Detail empty.
5. Right-click `Category` on Rows → Sort → field `Severity Ratio`, aggregation `Avg` (or whatever Tableau exposes — the calc is already aggregate), descending. Top category is the most-severe (typically "Other" or "Stations and Structure" — verify per year).

### 10c — Color (calc-driven top-N accent, not platform split)

Sheet 5 isn't a platform-comparison chart — the platform contrast lives on Sheets 6, 2, 3, and 4. Sheet 5 just shows the severity hierarchy across causes, so use a top-N accent that follows the active year's data (manual coloring breaks when the year filter changes, because Tableau stores only one set of color assignments).

1. Create calc field **Top Severity Highlight** on `monthly_incidents_delays`:
   ```
   IF RANK_UNIQUE([Severity Ratio], 'desc') <= 2 
   THEN "Alert" 
   ELSE "Muted" 
   END
   ```
   Adjust the threshold: `= 1` for a single top-of-sort accent, `<= 2` for top-2 (current default — keeps the spotlight effect while flagging both extreme categories), `<= 3` only if your data genuinely has a top-3 cluster that pulls away from the rest.
2. Drag `Top Severity Highlight` to **Color** on the Marks card.
3. **Critical:** right-click the pill on Color → **Compute Using → Category** (not Table Across, not Pane). Without this the rank computes in the wrong direction and miscolors everything.
4. Edit Colors:
   - `Alert` → `#dc2626` (red)
   - `Muted` → `#94a3b8` (gray)
5. Verify: toggle `[Year Filter]` through 2022 → 2023 → 2024 — the red accent should *jump* to whichever categories are top-N by Severity Ratio in each year. If it doesn't move, re-check **Compute Using → Category** in step 3.

> **Two-tier accent variant.** If you want top-1 and top-2 visually distinguishable (rank-2 in a lighter red), return three categorical values instead of two:
> ```
> IF RANK_UNIQUE([Severity Ratio], 'desc') = 1 THEN "Alert 1"
> ELSEIF RANK_UNIQUE([Severity Ratio], 'desc') = 2 THEN "Alert 2"
> ELSE "Muted"
> END
> ```
> Colors: `Alert 1` → `#dc2626`, `Alert 2` → `#f87171` (lighter red), `Muted` → `#94a3b8`. Reads as "two bad ones, one *especially* bad." Default to flat top-N coloring unless you specifically want the rank visible.

> **Filter context dependency.** `RANK_UNIQUE` against `Severity Ratio` only works if all of these are in **Context** (Year Match = True, Day Type = 1, Line Group in 1/2/3+A/C/E, Category ALL). Without context promotion, the FIXED LODs inside `Real Inc`/`Real Delay` ignore the year filter, the ratio stays stuck at the multi-year average, and the rank never recomputes.

> **Ties:** `RANK_UNIQUE` arbitrarily breaks ties — if two categories have effectively identical severity, the accent lands on the alphabetically-first one. Hover both bars to confirm if you suspect a near-tie.

The accent is a deliberate signal that this chart asks a *different* question than the rest of the dashboard. Resist the temptation to color by platform — the platform information isn't in the bar; adding it would double-encode.

### 10d — Label

1. Drag `Severity Ratio` to the **Label** shelf
2. Open Label card → Edit Label → format `0" delays/inc"` (so each bar reads e.g. `97 delays/inc`)
3. Alignment: middle-right of bar; font 11px, color: white for the red accent bars, `#1e293b` for the muted gray bars

> **Unit phrasing matches Sheet 4.** Earlier docs used `"× delay"` (multiplier framing) — at the actual magnitude of 80–110 the multiplier framing reads awkwardly. `delays/inc` reads correctly at any magnitude and matches the Sheet 4 label suffix unit. Keep the two sheets consistent so the reader sees one unit across the dashboard.

### 10e — Format

1. Right-click the x-axis → **Edit Axis** → title: `Delay-causing incidents per major incident`
2. Format → Lines → remove gridlines
3. Worksheet → Show Title → Edit Title: `How bad is bad — per-incident severity?`

> **X-axis title clarification.** Earlier title was `Trains delayed per major incident (proxy)` — but `Real Delay` counts MTA delay-causing-incident reports (a granular MTA metric), not literal trains. Updated phrasing is semantically accurate; the `delays/inc` label is the shorthand.

### 10f — Annotation (recommended: skip)

**Recommended path: drop the annotation entirely.** The calc-driven red accent + the year-aware `delays/inc` labels + the question-form sheet title already carry the message. Adding a static annotation creates a year-aware/static mismatch — the colors move with the year filter, but a typed annotation doesn't.

If you want an annotation anyway, two options:

- **Static (default-year only):** right-click the top bar → Annotate → Mark → `"{Category} delivers the worst-day severity — rare but catastrophic"` with `{Category}` replaced with the default year's top category. Technically wrong for the other years.
- **Dynamic via Mark Label trick:** create a calc field that returns callout text only for the top-ranked bar(s):
  ```
  IF RANK_UNIQUE([Severity Ratio], 'desc') = 1 
  THEN MIN([Category]) + " — worst-day severity, rare but catastrophic"
  END
  ```
  Drag to **Label**, set Compute Using → Category. Returns NULL on every bar except rank-1, where it renders alongside the regular `delays/inc` label. Slightly cluttered; reserve for when the annotation is genuinely load-bearing.

### 10g — So-what

**So-what box (Option 3 framing):**
> **So what:** the top-2 categories deliver the worst per-incident severity — rare but catastrophic days. Signals and Track are mid-severity but far more frequent, driving most of the total delay despite milder per-event impact. Severity dominates the worst single days; frequency dominates the average rider's experience.

> **Verify the named categories in the active year before shipping.** Earlier doc text named "Other" and "Stations and Structure" as the top-2; with the multi-year extension, the ranking may differ. Glance at the top-2 red bars on your render and replace the generic "the top-2 categories" wording with the actual category names if you want the so-what to be more concrete. The "(per-platform severity on Cause Ladder labels)" parenthetical from earlier docs has been dropped — it forced a workbook-internal sheet reference and the Sheet-5-as-cross-cause-hierarchy framing doesn't need to cross-reference Sheet 4.

**Alternative so-what (Option 2 cost framing, if pivoting):**
> **So what:** Signal failures span the widest range — that's the slice a Penn rider can't plan around. Track failures cluster tightly: a Track incident is bad but predictable; a Signal incident might cost an entire commute.

---

## Step 11 — Filtered Map (Sheet F)

**Source:** `dim_corridor_complexes` + relationship to `monthly_incidents_delays` + relationship/blend to `monthly_ridership` *(blend added 2026-05-28 for the ridership-size upgrade)*

**Goal:** A symbol map showing the two Penn complexes (318 + 164) as circles, colored by line group, **sized by per-complex avg monthly ridership** *(switched from Real Inc 2026-05-28)* — visually carrying the "two complexes, one staircase, two reliability profiles" beat with rider-weight as a new dimension.

> **2026-05-28 — Size encoding switched from `Real Inc` to ridership.** Reasoning: Sheet 4a now forcefully makes the "1/2/3 carries more incidents" point with three years of bars; the map re-stating it as Size encoding became redundant. Ridership size adds a new dimension nothing else on the dashboard carries explicitly (KPI 1 collapses both complexes; the heatmap uses ridership as time-of-day signal, not per-complex). The map's job becomes synthesis: *"two complexes physically adjacent, roughly equal rider weight, persistent reliability gap."* See `v3_narrative_decisions.md` § 14 for the decision rationale.

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

### 11c — Size, color, labels (Option 3: focus to Penn only; updated 2026-05-28)

1. Drag `Complex Id` to Filters → select `318` and `164` only — **this is the Option 3 refocus**. Wider corridor complexes are hidden so the map shows the two Penn complexes, one staircase apart.
2. **Year filter — decide before building.** Recommended (2026-05-28): **do NOT add Year Match** to this sheet. The map's job is now multi-year synthesis at the physical level; year-to-year size fluctuation adds noise without adding meaning. If you keep `Year Match`, the dot sizes will shift slightly between years.
3. **Activate ridership blend.** In the Data pane, click `monthly_ridership` to make it active as a secondary on this sheet. Verify the orange chain icon on `Complex Id` linking primary→secondary; click if it's broken.
4. **Create the size calc on `monthly_ridership`** if it doesn't exist:
   ```
   Monthly Ridership Avg = SUM([Ridership]) / COUNTD([Month])
   ```
5. Drag `Monthly Ridership Avg` (from the `monthly_ridership` secondary) to **Size**
6. Drag `Line Group` to **Color** → Edit Colors:
   - `1/2/3` → `#59a14f`
   - `A/C/E` → `#4e79a7`
7. Drag `Complex Name` to **Label** → always show on both
8. **Adjust size scale manually.** Click **Size** → **Edit Sizes…** → set a non-zero minimum (~40 px) and large maximum (~120 px) — Tableau's default is too small for a 2-dot map and the size difference will be invisible.
9. Map zoom: tighten to mid-Manhattan so 318 and 164 dominate the frame

> **Previous Size encoding (`SUM([Real Inc])`) — retired 2026-05-28.** Kept as note for archival: was sized by major-incident count from the `monthly_incidents_delays` relationship. Switched because Sheet 4a now carries the "1/2/3 carries more incidents" claim with three years of bars; the map re-stating it visually was redundant.

> **For Option 2 backup:** keep this same filter (only 318 + 164) and use `SUM([Real Delay])` from `monthly_incidents_delays` for Size — the cost-angle backup wants total trains delayed as the size dimension, not ridership.

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

### 11e — Title (as question), annotations, so-what (updated 2026-05-28)

- **Title** (Worksheet → Show Title): `How close are the two platforms, really?`
- **Caption** (post-2026-05-28): `Penn 1/2/3 (complex 318) and Penn A/C/E (complex 164). Two complexes, one chokepoint, one staircase apart. Circle size = avg monthly ridership.`

**Annotations on each dot (manual, static text — multi-year framing since the sheet ignores Year Filter):**
- 1/2/3 dot → right-click → Annotate → Mark → `"1/2/3 platform · ~70% WA · ~1.4M riders/mo"`
- A/C/E dot → right-click → Annotate → Mark → `"A/C/E platform · ~66% WA · ~1.4M riders/mo"`
- Format the annotation boxes quiet: ~10pt, low-opacity background fill (`#faf8f4`), no border. Position below-right of each dot.

**So-what box (multi-year framing):**
> **So what:** one staircase between them. The larger circle marks the busier platform by monthly ridership; the labels carry the reliability gap. Same complex on the sign, two different services underneath — and the choice is worth ~4 pp at peak Wait Assessment, every weekday, across roughly the same rider weight on each side.

> The old map so-what (*"the A/C/E complex turns each delay-causing incident into more rider-impact…"*) was a Real-Inc-Size-era framing; replaced 2026-05-28 with the ridership-size framing above.

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

## Step 13 — Sankey Flow (Sheet San) — REMOVED from primary layout (2026-05-22+)

> **Sheet status (2026-05-28):** Sankey is **removed from the v3 primary dashboard layout**. Build instructions below preserved for the Option 2 (cost angle) backup pivot — flow visualizations land harder when the framing is cost/volume rather than reliability/recovery. For Option 3, the Sankey was found redundant with Sheet 4 (after the split-by-platform refactor) and the band-width encoding reinforces a count dimension the Option 3 narrative explicitly de-emphasizes. Keep the worksheet in the workbook (Worksheet → Hide), don't delete — it stays available for the Option 2 layout.

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

**Drag sheets in this order (top to bottom) — Option 3 layout (updated 2026-05-28 to include Trajectory + Sheet 4a):**

| Position | Content | Type |
|----------|---------|------|
| Full width, top | Title + Year Filter parameter control | Floating text box + parameter (Compact List) |
| Full width | Intro paragraph (multi-year, no hardcoded year) | Floating text box (`#ffffff` bg) |
| Full width, 4 cols | KPI 1 · KPI 2 · KPI 3 · KPI 4 (each with sub-tag) | Horizontal container, 4 sheets |
| Full width | **Trajectory (Step 9g, added 2026-05-28)** — `1/2/3 holds; A/C/E catches up` + so-what; **ignores Year Filter** | Vertical container, ~160–200 px tall |
| Full width — **CENTERPIECE** | Reliability Comparison (Sheet 6a + 6b side-by-side) + shared title above + so-what below | Outer Vertical container with border, inner Horizontal holding 6a + 6b each with their own metric sub-title — see Step 9f for the structure |
| Full width | Sheets 2 + 3 (Incidents bars on top + WA% line below) + so-what box per sheet | Vertical container |
| Half + half | Cause Ladder (Sheet 4) + so-what (with handshake → 4a) · Quilt (C-1 above C-2) + qualifier callout + so-what | Horizontal container |
| Full width | **Sheet 4a (Step 6f, added 2026-05-28)** — `More incidents on both — A/C/E closes the gap anyway` + so-what; **ignores Year Filter** | Vertical container, ~260 px tall |
| Full width (supporting) | Severity Bar (Sheet 5) + so-what | Vertical container |
| Half + half | Map (Sheet 7, Penn 318+164, **size by ridership** post-2026-05-28) + so-what · Heatmap (Sheet 8) + so-what | Horizontal container |
| Full width | Narrative footer ("The bottom line" + caveats block) | Floating text box (`#0f172a` bg) |

> **Sheet San (Sankey) does NOT appear** in the Option 3 layout — removed 2026-05-22+. If built, Hide rather than delete (kept for Option 2 backup pivot).
> **Sheet N (corridor scatter) does NOT appear** — retired. Same Hide-don't-delete rule applies.

> **Two cards intentionally cross-year** (Trajectory + Sheet 4a). When assembling, do **not** apply the Year Filter parameter to these two sheets — the dashboard would silently filter them otherwise via the parameter's "Apply to Worksheets" setting. Verify via the Apply to Worksheets dialog: both should be unchecked.

**Container tips:**
- Use **Tiled layout** as the base. Add floating text boxes for the headline and footer.
- For the KPI strip: create a horizontal tiled container, drag all 4 KPI sheets in, set each to equal width.
- Match inner padding: 8px on all cards, 10px gap between containers.

---

## Step 15 — Year filter audit (parameter created in Step 3)

The `Year Filter` parameter and `Year Match` calc fields are created in Step 3 — moved earlier than v2 so the KPI tiles can use them. This step is a reconciliation pass to make sure every sheet honors the parameter.

### 15a — Audit every sheet

For each sheet (1, 2, 3, 4, 5, 6a, 6b, 7, 8, C-1, C-2, all 4 KPIs), confirm:

1. `Year Match` is on the Filters shelf, set to **True**, and **in Context** (gray pill, not blue).
2. The sheet's title, caption, annotation, and so-what box do not contain a hardcoded year string.

**Exceptions — sheets that intentionally ignore `[Year Filter]` (added 2026-05-28):**

- **Trajectory** (Step 9g) — cross-year WA% by year × Line Group; must not have `Year Match`. Verify in the Filters shelf — empty for this sheet.
- **Sheet 4a** (Step 6f) — cross-year `Real Inc` by year × Line Group; must not have `Year Match`. Verify in the Filters shelf — empty for this sheet.
- **Sheet 7 Map** (recommended post-2026-05-28) — multi-year synthesis; recommended without `Year Match` so the map reads consistently across year-views.

To apply `Year Match` to all sheets in a data source at once:
1. Right-click `Year Match` in the Filters shelf on any sheet → **Apply to Worksheets → All Using This Data Source**
2. Repeat for each of the 4 date-bearing data sources.
3. **After applying:** remove `Year Match` from the Trajectory and Sheet 4a filter shelves (the "Apply to All" pulled it in).

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
- [ ] 1/2/3 platform = green `#59a14f`; A/C/E platform = blue `#4e79a7`; Sheet 5 uses a single red accent (`#dc2626`) on the top-severity category with muted gray for the rest — no platform encoding on Sheet 5 (no color bleed between platform and category encodings)
- [ ] Heatmap rush-hour bands are light blue `#dbeafe` (A/C/E family), not the old lavender or warm tint

**Charts:**
- [ ] Every chart has a Title in **question form** (per Steps 6e, 7, 8c-title + 8i, 9f, 10e, 11e, 12g, 13e)
- [ ] Every chart has at least one **annotation on a specific mark** (per Steps 6e, 9f, 10f, 13e)
- [ ] Every chart has a **so-what interpretation box** below it (per the same Steps)
- [ ] Map (Sheet 7) shows only complexes 318 and 164 — no wider corridor stations
- [ ] Sheet 5 severity bar: top-of-sort category (highest avg severity) is rendered in the red accent with `"{X.X}× delay"` label; all other bars muted gray with the same label format
- [ ] Cause Ladder (Sheet 4): bars are single-axis (no dual axis, no circles); each bar's label reads `<count> · <X.X>× delay`
- [ ] Heatmap Tue 8 AM cell is visibly the darkest, with the dynamic Peak label visible
- [ ] Reliability bars (Sheet 6a + 6b centerpiece): 1/2/3 is higher than A/C/E on both WA% (6a) and OTP% (6b); both sheets share Fixed 60–100 axis
- [ ] Monthly quilt: platform-specific months stand out (top green panel ≠ bottom blue panel) and the qualifier callout flags the contradicting month. **Caption does not name palettes in parentheses** (the row labels carry the colors — restating them in prose is the bug the 2026-05-22 fix removed)
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
| Sheet 3 (WA% over time, post-2026-05-22) | Hide — the cost framing doesn't lead with the reliability gap |
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
