# Tableau Build Guide — Transfer of Stress (v2)

Step-by-step instructions for building the dashboard from the 5 exported CSVs.
Follow in order — later steps reference sheets created in earlier ones.

Design reference: `sample_dashboards/render_9_synthesis.html`
Design spec: `DASHBOARD_MODEL.md`

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

## Step 3 — Computed fields (create before building sheets)

In the `monthly_incidents_delays` data source, create these fields:

**Signal+Track Incidents**
```
IF [Category] IN ("Signals", "Track") THEN [Incident Count] ELSE 0 END
```

**delay_per_incident**
```
[Delay Count] / NULLIF([Incident Count], 0)
```

**delay_minutes_proxy**
```
[delay_per_incident] * 3
```

**Signal Incident Advantage** (used by KPI 4)
```
(
  SUM(IF [Line Group] = "A/C/E" AND [Category] = "Signals" THEN [Incident Count] END)
  - SUM(IF [Line Group] = "1/2/3" AND [Category] = "Signals" THEN [Incident Count] END)
)
/
SUM(IF [Line Group] = "1/2/3" AND [Category] = "Signals" THEN [Incident Count] END)
```

No additional fields needed in `hourly_ridership_corridor` — `day_num` (ISO 1=Mon–7=Sun) and `hour_of_day` are already exported columns.

---

## Step 4 — KPI tiles (4 Text sheets)

**Goal:** Four dark-background text tiles showing the headline numbers. Build each as a separate sheet and assemble into a horizontal strip on the dashboard.

### Sheet: KPI 1 — Commuters at Risk

**Source:** `monthly_ridership`

#### 4a — Build

1. Set data source to `monthly_ridership`
2. Drag `Ridership` to the **Text** card under Marks
3. Change aggregation to `SUM`
4. Drag `Complex Id` to Filters → select `318` and `164` (Penn Station complexes only)
5. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E`

#### 4b — Format the number

1. Right-click the `SUM(Ridership)` pill on the Text card → **Format**
2. In the Format pane → Numbers → Custom → enter: `"~"#,,"M"`
3. This displays the full-year sum (~8.4M) as `~8.4M`. For a per-month figure (~700K), create a calculated field first: `SUM([Ridership]) / 12` and format as `"~"#,"K"`
4. **Simpler:** use a static Text object on the dashboard with the value `~700K` — only wire up the live calculation if you need the year filter to update it

#### 4c — Styling

1. **Format → Shading** → set worksheet background to `#0f172a`
2. Click the Text card → set font color to `#ffffff`, size 34px, bold
3. Add a subtitle text line below the number: `"commuters/month at Penn Station"` — same card, smaller font, color `#94a3b8`

---

### Sheet: KPI 2 — Incident Months (11/12)

**Source:** `monthly_incidents_delays`

#### 4d — Build

1. Set data source to `monthly_incidents_delays`
2. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E`
3. Drag `Category` to Filters → select `Signals` and `Track`
4. **Simplest approach:** drag a Text object onto the dashboard later and type `11/12` as a static value — skip the calculated field below if you don't need the number to update dynamically

#### 4e — Live calculation (optional)

Create a calculated field:
```
{ FIXED MONTH([Month]) : SUM([Incident Count]) > 0 }
```
This LOD returns TRUE for months with at least one incident. Then `COUNTD` of months where this is TRUE gives 11 (all months except one had Signal or Track incidents on at least one corridor).

#### 4f — Styling

1. Background: `#0f172a`
2. Text color: `#f87171` for the `11`, `#334155` for `/12`
3. To get two colors in one text tile: use a floating text object on the dashboard with HTML-style rich text formatting

---

### Sheet: KPI 3 — Avg Delay per Incident

**Source:** `monthly_incidents_delays`

#### 4g — Build

1. Drag `Line Group` to Filters → `1/2/3` and `A/C/E`
2. Drag `Day Type` to Filters → select `1` (weekday)
3. Drag `Category` to Filters → select `Signals` and `Track`
4. Drag `delay_minutes_proxy` to the **Text** card
5. Change aggregation to `AVG`
6. Right-click the pill → Format → Numbers → Custom → `0" min"` — result should be ~18 min

#### 4h — Styling

1. Background: `#0f172a`, text color: `#fb923c`, size 34px bold
2. Subtitle: `"avg delay per Signal/Track incident"`, color `#94a3b8`

---

### Sheet: KPI 4 — A/C/E Signal Advantage

**Source:** `monthly_incidents_delays`

#### 4i — Build

1. Drag `Signal Incident Advantage` to the **Text** card
2. No filters needed — the field is self-contained (it references both line groups internally)
3. Aggregation: the field already uses SUM internally — leave the outer aggregation as `AGG`

#### 4j — Format and styling

1. Right-click the pill → Format → Numbers → Percentage → 0 decimal places → result should display as `−23%`
2. Background: `#0f172a`, text color: `#c084fc`, size 34px bold
3. Subtitle: `"fewer signal incidents vs 1/2/3"`, color `#94a3b8`

---

## Step 5 — Corridor Narrative scatter (Sheet N)

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
   - `1/2/3` → `#ef4444`
   - `A/C/E` → `#a78bfa`
   - `Other` → `#94a3b8`

### 5d — Labels and annotations

1. Drag `Complex Name` to **Label** → set label visibility to **Selected** only (avoids clutter)
2. For Penn and WTC, force labels always on: right-click the dot → **Mark Label → Always Show**
3. Add static annotations:
   - Right-click the Penn Station dot (complex 318) → **Annotate → Mark** → type e.g. `"~700K riders/month exposed"`
   - Right-click the WTC dot (complex 624) → **Annotate → Mark** → type e.g. `"23% fewer signal incidents via A/C/E"`
   - Update these numbers after verifying KPI 1 and KPI 4 against your actual data

### 5e — Format and axis safeguard

1. Hide gridlines: **Format → Lines** → set all to None
2. Hide axis titles: right-click each axis → Edit Axis → clear the title field
3. **Fix axis ranges** (protects the scatter if geographic roles are restored in Step 11):
   - Right-click x-axis → **Edit Axis → Fixed** → range: `−74.02` to `−73.97`
   - Right-click y-axis → **Edit Axis → Fixed** → range: `40.70` to `40.78`

> Restoring geographic roles in Step 11 does not retroactively change this sheet — Tableau only applies role changes to new drag-and-drop uses. The fixed ranges are an extra safeguard.

---

## Step 6 — Cause Ladder (Sheet B)

**Source:** `monthly_incidents_delays`

**Goal:** Horizontal bars showing incident frequency per category (how often each cause occurs), with a severity dot overlaid (how bad each incident is) — Signals should rank high on both.

### 6a — Filters (apply first)

1. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E`
2. Drag `Day Type` to Filters → select `1` (weekday)

### 6b — Build the bar

1. Drag `Category` to **Rows**
2. Drag `SUM([Incident Count])` to **Columns**
3. Mark type: **Bar**
4. Right-click `Category` on the Rows shelf → **Sort** → sort descending by `SUM([Incident Count])` — most frequent category on top
5. Drag `Category` to **Color** → Edit Colors:
   - Signals → `#ef4444`
   - Track → `#f59e0b`
   - All others → `#94a3b8`

### 6c — Add severity dot (dual axis)

1. Drag `AVG([delay_per_incident])` to **Columns** — it appears as a second pill on the same shelf
2. Right-click the second pill → **Dual Axis**
3. Right-click either axis → **Synchronize Axes**
4. In the Marks card, click the second marks layer (AGG(delay_per_incident)) → change mark type to **Circle**
5. Set the circle color to match the bar color scheme (same Category colors)
6. This gives: bar length = incident frequency, circle position = severity per incident

### 6d — Reference line and format

1. With the circle axis active, go to **Analytics pane** → drag **Reference Line** onto the view → scope: **Table** → value: `AVG([delay_per_incident])` across all categories → style: dashed gray → label: `"avg severity"`
2. Right-click the top axis (dual axis header) → **Uncheck Show Header** — hides the duplicate axis label
3. Right-click the x-axis → Edit Axis → title: `Incidents (bars) · Avg Delays per Incident (dots)`
4. Format → Lines → remove gridlines

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
5. Color: `SUM([Signal+Track Incidents])` → Edit Colors → Custom Sequential → `#fee2e2` (low) to `#ef4444` (high)
6. Label: `SUM([Signal+Track Incidents])` on each cell, white text for dark cells
7. **Hide column headers** (right-click month axis → Uncheck Show Header) — the bottom sheet will show them
8. Hide axis titles

### Sheet C-2 (A/C/E corridor)

1. Same structure as C-1
2. Filter: `Line Group = "A/C/E"`, `Category IN ("Signals", "Track")`
3. Color: Custom Sequential → `#f5f3ff` (low) to `#7c3aed` (high)
4. **Keep column headers** (months) on this sheet
5. Same label format as C-1

### Dashboard assembly for the quilt

- In a vertical container: place C-1 directly above C-2
- Set both to the same fixed width so month columns align
- Set inter-container padding to 0px so they appear seamless
- The `Line Group` row label on the right side of each sheet acts as the corridor legend
- Add a floating title text box above the container: "Signal + Track Incidents by Month"

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

1. Edit Colors: 1/2/3 = `#ef4444`, A/C/E = `#a78bfa`
2. Stack order: right-click the Color legend → **Sort** → put `1/2/3` at the bottom so red anchors the baseline
3. Format → Lines → remove gridlines
4. Right-click y-axis → Edit Axis → title: `Signal + Track Incidents`

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
5. Edit Colors: 1/2/3 = `#ef4444`, A/C/E = `#a78bfa`
6. Right-click y-axis → Edit Axis → title: `Monthly Ridership`

#### 8f — Dashboard alignment

- Place Sheet 3 directly below Sheet 2 in a vertical container with the same fixed width so month columns align between the two charts

---

## Step 9 — Reliability Comparison (Sheet D)

**Source:** `service_quality`

**Goal:** Four side-by-side bars — Wait Assessment % and Terminal OTP %, each split by corridor — so the A/C/E reliability advantage reads directly from bar height.

### 9a — Filters (apply first)

1. Drag `Period` to the Filters shelf → select `peak`
2. Drag `Day Type` to Filters → select `1` (weekday)
3. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E`

### 9b — Build the view

1. Drag `Measure Names` to **Columns**
2. Drag `Line Group` to **Columns** — drop it to the right of `Measure Names` so it nests inside (gives true side-by-side bars, not stacked)
3. Drag `Measure Values` to **Rows**
4. In the **Measure Values** card on the Marks pane: right-click every unwanted measure → Remove. Keep only:
   - `Wait Assessment Pct`
   - `Terminal Otp Pct`
5. Mark type: **Bar**
6. Drag `Line Group` to **Color**

The view now shows 4 bars: [WA% — 1/2/3] [WA% — A/C/E] | [OTP% — 1/2/3] [OTP% — A/C/E]

### 9c — Colors and labels

1. Set colors manually: 1/2/3 = `#ef4444`, A/C/E = `#a78bfa`
2. Drag `Measure Values` to the **Label** card → format as `0.0"%"` (e.g. "84.2%")
3. Label position: middle center, white text

### 9d — Axis and reference line

1. Right-click the y-axis → **Edit Axis** → Fixed range: `60` to `100` — compresses the scale so the corridor gap is visually prominent
2. **Analytics pane** → drag **Reference Line** onto the chart → scope: **Table** → value: Constant = `81` → label: `"System avg 81%"` → style: dashed gray
3. Right-click the `Measure Names` column header → **Edit Alias**: rename `Wait Assessment Pct` → `Wait Assessment %` and `Terminal Otp Pct` → `Terminal OTP %`

### 9e — Format

1. Right-click the x-axis → Edit Axis → clear the title field
2. Format → Lines → set Row Dividers and Column Dividers to None (remove gridlines)
3. Set y-axis title: `% of Riders / Trips`

---

## Step 10 — Delay Duration Box Plot (Sheet E)

**Source:** `monthly_incidents_delays`

**Goal:** One box per incident category showing the spread of `delay_per_incident` across months — Signals should have the widest spread and the highest outlier, making it visually the most severe category.

### 10a — Filters (apply first)

1. Drag `Incident Count` to Filters → **Range of Values** → set minimum to `1` → OK (excludes zero-incident months so the ratio is always defined)
2. Drag `Day Type` to Filters → select `1` (weekday)
3. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E`

### 10b — Build the view

1. Drag `delay_per_incident` to **Columns** — aggregation: `AVG` (default is fine)
2. Drag `Category` to **Rows**
3. Mark type: set to **Circle**
4. Drag `Month` to the **Detail** shelf — this is required. Without it Tableau collapses each category to a single value and the box has no spread. With it, each circle = one month's average ratio for that category (12 circles per category).
5. Enable box plot: **Analytics pane** → drag **Box Plot** onto the view → drop on **Cell**
   - Alternatively: with Circle marks active, go to **Analysis menu → Box Plot**
   - The circles become the underlying data points; the box plot layer overlays quartiles and whiskers

### 10c — Sort and color

1. Right-click `Category` on the Rows shelf → **Sort** → sort descending by `AVG([delay_per_incident])` — Signals floats to the top
2. Drag `Category` to **Color** → Edit Colors:
   - Signals → `#ef4444`
   - Track → `#f59e0b`
   - Others → `#94a3b8`
3. Reduce circle opacity to 60% (Format → Marks → Opacity) so box plot lines read clearly over the dots

### 10d — Box plot formatting

1. Right-click any box → **Format Box Plot**:
   - Whiskers: **IQR × 1.5** (default — shows true outliers beyond the whiskers)
   - Fill: checked — if the fill color is stuck on gray, set it to the lightest available option or uncheck Fill entirely and rely on the box border + dot colors
   - Show outliers: checked (outlier dots beyond whiskers are the story)
2. Right-click the x-axis → **Edit Axis** → title: `Delay-Causing Trains per Incident (proxy)`

### 10e — Annotation

1. Identify the Signals outlier dot at the far right (highest `delay_per_incident` value)
2. Right-click it → **Annotate → Mark** → type: `"~52 min proxy — 3.2× avg headway"`
3. Drag the annotation callout line so it doesn't overlap the Signals box

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

### 11c — Size, color, labels

1. Drag `SUM([Incident Count])` (from the `monthly_incidents_delays` relationship) to **Size**
2. Drag `Line Group` to **Color** → Edit Colors:
   - `1/2/3` → `#ef4444`
   - `A/C/E` → `#a78bfa`
   - `Other` → `#94a3b8`
3. Drag `Complex Name` to **Label** → set to show for selected marks only
4. For Penn (318/164) and WTC (624): right-click each dot → **Mark Label → Always Show**
5. No corridor filter needed — all rows in `dim_corridor_complexes.csv` are pre-filtered to corridor complexes by the export SQL

### 11d — Map layers and annotations

1. **Map menu → Map Layers** → uncheck everything except Land and Coastline — gives a clean light gray base
2. Add annotations:
   - Right-click the Penn Station dot → **Annotate → Mark** → `"Peak stress: 700K riders/month"`
   - Right-click the WTC dot → **Annotate → Mark** → `"Alternate route via PATH"`
3. Format → remove map border if present (Format → Border → None)

---

## Step 12 — Day × Hour Heatmap (Sheet G)

**Source:** `hourly_ridership_corridor`

**Goal:** A 7×24 grid showing ridership intensity by day of week and hour — Tuesday 8 AM should be visibly the darkest cell, confirming peak risk timing.

### 12a — Filters (apply first)

1. Drag `Station Complex Id` to Filters → select `318` and `164` (Penn Station complexes only)

### 12b — Build the grid

1. Drag `HOUR([Transit Timestamp])` to **Columns** — right-click → **Continuous** (green pill, not blue) — this is required for reference bands to work
2. Drag `DATENAME('weekday', [Transit Timestamp])` to **Rows** — this gives day names (Monday, Tuesday…)
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
   - Fill: click the color swatch → pick `#fff7ed` (light warm tint)
   - Label: **None**
4. Click OK

**Evening rush (16–19):**
1. Drag another **Reference Band** onto the view → drop on **Cell**
2. Band From: `16`, Band To: `19`, same fill color `#fff7ed`
3. To edit an existing band later: right-click anywhere inside the shaded area → **Edit Reference Band**

### 12f — Annotation and format

1. Right-click the cell at Tuesday / hour 8 → **Annotate → Mark** → type: `"Peak: Tue 8 AM — 3.2× weekday avg"`
2. Format → Cell Size: adjust so all 24 hour columns fit horizontally without a scrollbar
3. Right-click x-axis → Edit Axis → title: `Hour of Day`
4. Right-click y-axis → Edit Axis → clear title

---

## Step 13 — Sankey Flow (Sheet San)

**Source:** `monthly_incidents_delays`

**Goal:** Show how delay-causing incidents flow from incident category to corridor — the Signals→1/2/3 band should be the widest, visually anchoring the "Transfer of Stress" thesis.

Tableau Public 2026.1.0 has a native Sankey chart type — no extensions needed.

### 13a — Filters (apply first)

1. Drag `Line Group` to Filters → select `1/2/3` and `A/C/E`
2. Drag `Day Type` to Filters → select `1` (weekday)

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
   - Signals → `#ef4444`
   - Track → `#f59e0b`
   - All others → `#94a3b8`
   - `1/2/3` → `#ef4444`
   - `A/C/E` → `#a78bfa`

**Link tab (band/ribbon colors):**
1. Click the **Link** tab in the Marks card
2. Click **Color** → set to a neutral gray or lower opacity to let node colors dominate

### 13d — Labels and format

1. Enable node labels: click **Label** on the Marks card → check **Show mark labels**
2. Left nodes show `Category`, right nodes show `Line Group` — no additional fields needed
3. Hide the legend if node labels make it redundant (right-click legend → Hide Card)
4. Sheet title: `"Where Do Delays Flow?"`
5. Format → Lines → remove all gridlines and borders

**Key flow to call out:** Signals→1/2/3 is the widest band (7,364 delay-causing incidents). If you want to annotate it: right-click the band → **Annotate → Mark** → type the value.

---

## Step 14 — Assemble the Dashboard

1. **Dashboard → New Dashboard**
2. Set size: Fixed, 1120 × 1600px (or use Automatic and constrain later)
3. Set background: `#faf8f4`

**Drag sheets in this order (top to bottom):**

| Position | Content | Type |
|----------|---------|------|
| Full width, top | Title + year filter pills | Floating text box + button objects |
| Full width | Journey Headline text | Floating text box (`#ffffff` bg) |
| Full width, 4 cols | KPI 1 · KPI 2 · KPI 3 · KPI 4 | Horizontal container, 4 sheets |
| Full width | Corridor Narrative (Sheet N) | Tiled, fixed height 220px |
| Half + half | Cause Ladder (Sheet B) · Sankey — Flow by corridor (Sheet San) | Horizontal container |
| Full width | Monthly Quilt (Sheet C-1 above C-2, 0px gap) | Vertical container |
| Full width | Incidents (Sheet 2) · Ridership (Sheet 3) | Vertical container |
| Half + half | Reliability (Sheet D) · Box Plot (Sheet E) | Horizontal container |
| Half + half | Map (Sheet F) · Heatmap (Sheet G) | Horizontal container |
| Full width | Narrative footer text | Floating text box (`#0f172a` bg) |

**Container tips:**
- Use **Tiled layout** as the base. Add floating text boxes for the headline and footer.
- For the KPI strip: create a horizontal tiled container, drag all 4 KPI sheets in, set each to equal width.
- Match inner padding: 8px on all cards, 10px gap between containers.

---

## Step 15 — Global year filter across all data sources

Parameters in Tableau are workbook-level — one parameter drives filters across all 5 data sources simultaneously.

### 15a — Create the parameter (once)

1. In the Data pane, right-click anywhere → **Create Parameter**
2. Name: `Year Filter`
3. Data type: **Integer**
4. Allowable values: **List** → add `2024` (add `2020`–`2023` when you extend the data)
5. Current value: `2024`
6. Click OK

### 15b — Create a `Year Match` calculated field in each date-bearing data source

Switch data sources using the dropdown at the top of the Data pane and create the same-named field in each.

**In `monthly_incidents_delays`:**
```
YEAR([Month]) = [Year Filter]
```

**In `monthly_ridership`:**
```
YEAR([Month]) = [Year Filter]
```

**In `service_quality`:**
```
YEAR([Month]) = [Year Filter]
```

**In `hourly_ridership_corridor`:**
```
YEAR([Transit Timestamp]) = [Year Filter]
```

**`dim_corridor_complexes` — skip.** No date column; it's a static dimension.

### 15c — Apply to every sheet

For each sheet, drag `Year Match` to the Filters shelf → select **True** → OK.

To apply to all sheets in a data source at once:
1. Add `Year Match` to the Filters shelf on one sheet
2. Right-click `Year Match` in the Filters shelf → **Apply to Worksheets → All Using This Data Source**
3. Repeat for each of the 4 data sources that has a `Year Match` field

### 15d — Show the control on the dashboard

1. Right-click `Year Filter` in the Data pane → **Show Parameter**
2. The control appears — drag it onto the dashboard, top-right corner
3. Right-click the control on the dashboard → **Customize** → set display to **Compact List** (closest to the pill style in render_9)

### 15e — Exclude KPI tiles from the filter (optional)

If you want KPI tiles fixed to 2024 regardless of what the user selects, simply don't add `Year Match` to those sheets. The parameter only affects sheets where the filter is applied.

---

## Step 16 — Narrative footer text box

1. Dashboard → Objects → Text → drag to bottom
2. Set background: `#0f172a`, padding 20px
3. Type the footer text (see DASHBOARD_MODEL.md for exact wording)
4. Format bold text as `#f1f5f9`, body as `#64748b`, red emphasis as `#f87171`
5. Set fixed height ~80px

---

## Step 17 — Final QA checklist

- [ ] All 4 hub complexes (318, 164, 328, 624) appear on the map with correct names
- [ ] KPI strip tiles all have dark `#0f172a` background with white text
- [ ] Signal + Track bars are red; A/C/E elements are purple — no color bleed
- [ ] Box plot Signals row shows the outlier dot at far right
- [ ] Heatmap Tue 8 AM cell is visibly the darkest
- [ ] Reliability bars: A/C/E is higher than 1/2/3 on both WA% and OTP%
- [ ] Monthly quilt: Sep shows clear for 1/2/3, heavy for A/C/E (corridor-specific months)
- [ ] Corridor scatter: Penn Station dot is largest, centered; WTC dot is purple
- [ ] Sankey: Signals→1/2/3 band is visibly the widest
- [ ] Year filter pill applies to all data sheets but not the KPI tiles (which are fixed 2024)
- [ ] Footnote with severity proxy disclaimer is visible at bottom

---

## Export for submission

1. **File → Export Packaged Workbook (.twbx)** — this bundles the 5 CSVs into a self-contained file
2. Rename: `transfer_of_stress_v2.twbx`
3. Test: open the `.twbx` on a machine without the `tableau_exports/` folder — all data should load

The `.twbx` is what The Data School reviewers will open.
