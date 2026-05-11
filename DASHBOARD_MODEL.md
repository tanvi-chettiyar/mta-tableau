# Tableau Dashboard Model — Inside Penn (v3)

Sheet-by-sheet specs and design decisions for the v3 Tableau dashboard.

**Canonical layout reference:** `sample_dashboards/render_11_option3_platforms.html` (Option 3 — primary)
**Backup layout reference:** `sample_dashboards/render_10_option2_cost.html` (Option 2 — cost angle, kept as fallback)
*Earlier prototypes — `render_9_synthesis.html`, `render_6.jpeg` — superseded.*

---

## Story — Option 3 (primary): "Inside Penn — Two Platforms, Two Reliability Stories"

> **Penn Station looks like one place on a sign. Underneath, it's two reliability stories.**
> *6 routes converge on one complex; the platform you choose changes your odds.*

The dashboard answers five questions in sequence, each anchored on a chart whose **section title is the question itself**:

1. **Which platform should you trust?** (Sheet 6 — promoted to centerpiece, full width, top of body)
2. **Is the gap real, or just an average that hides bad months?** (Sheets 2 + 3 — incidents + ridership, both split by platform)
3. **Do both platforms see the same kinds of failure?** (Sheet 4 — cause ladder, split by platform)
4. **Do the platforms fail at the same time?** (Sheet C — quilt; September is the honest qualifier)
5. **How close are the two platforms, really?** + **If you had to pick one moment to avoid Penn, when?** (Sheet 7 + Sheet 8)

The sequence: punchline first → stress test → mechanism → qualifier → context. Each section raises a stated question and answers it, then the next section either deepens or qualifies it.

### Why this framing

- **Honest with the data we have.** The earlier "NJ commuter transfer" framing leaned on PATH stations that aren't in the dataset. Penn-only narrows the claim to what the dashboard can defend.
- **Actionable.** "Take 1/2/3 if you can" is a concrete suggestion supported by every chart.
- **Year-agnostic.** Nothing in the framing depends on 2024 specifically — extending to 2020-2024 just deepens the contrast.

---

## Backup story — Option 2: "What It Costs to Enter NYC Through Penn Station"

Documented fallback if the platform-contrast framing weakens with more years of data (e.g., the ~4 pp gap closes or reverses). The cost angle uses the same data with different KPIs and a different centerpiece. See "Option 2 backup variant" section at the end of this doc for the deltas.

---

## Layout — Option 3 (render_11 structure)

```
┌─────────────────────────────────────────────────────────────┐
│ Title + subtitle                       [Year Filter (param)] │
├─────────────────────────────────────────────────────────────┤
│ Journey headline (italic, warm card) — year-aware text      │
├──────────┬──────────┬──────────┬──────────────────────────── │
│  KPI 1   │  KPI 2   │  KPI 3   │  KPI 4   (dark navy tiles) │
│  ~2.9M   │   6      │  N/12    │  +X pp                     │
│  + sub-tag    + sub-tag    + sub-tag    + sub-tag           │
├──────────┴──────────┴──────────┴──────────────────────────── │
│ Sheet 6 — Reliability Comparison (CENTERPIECE, full width)  │
│   "Which platform should you trust?"                        │
│   WA% bars · OTP% bars · system-avg ref line · so-what box  │
├─────────────────────────────────────────────────────────────┤
│ Sheets 2 + 3 — Incidents + Ridership (full width, both split)│
│   "Is the gap real, or just an average?"                    │
│   2×2 grid: 1/2/3 incidents · A/C/E incidents · ditto rider │
│   so-what box                                                │
├────────────────────────┬────────────────────────────────────┤
│ Sheet 4 — Cause Ladder │ Sheet C — Quilt (C-1 above C-2)    │
│   "Same kinds of       │   "Do they fail at the same time?" │
│    failure?"           │   September qualifier callout      │
│   so-what box          │   so-what box                      │
├────────────────────────┼────────────────────────────────────┤
│ Sheet 7 — Map (Penn 318│ Sheet 8 — Day × Hour Heatmap        │
│   + 164 only)          │   "If you had to pick one moment?" │
│   "How close, really?" │   Tue 8 AM annotation              │
│   so-what box          │   so-what box                      │
├────────────────────────┴────────────────────────────────────┤
│ Footer — "The bottom line" + caveats block (dark navy card) │
└─────────────────────────────────────────────────────────────┘
```

Sheet 5 (box plot) and Sheet San (Sankey) are kept as supporting charts but slot into a secondary row if space allows; they aren't load-bearing for the platform-contrast thesis. Sheet N (corridor scatter) is **retired** — it carries the wide-corridor + PATH framing that doesn't fit the Penn-only narrative.

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
| 1/2/3 platform (hero in Option 3) | `#59a14f` (Tableau 10 green) |
| A/C/E platform (alternate) | `#4e79a7` (Tableau 10 blue) |
| Signals (category accent, Sheet 5 spotlight option) | `#ef4444` |
| Track (category accent) | `#f59e0b` |
| Persons / Subway Car / Stations / muted | `#94a3b8` |
| Heatmap sequential scale (rush-hour intensity) | `#fef2f2` → `#991b1b` |
| Insight callout (hero — green, matches 1/2/3) | left border `#59a14f`, bg `#f0fdf4`, text `#14532d` |
| Insight callout (qualifier / secondary — blue, matches A/C/E) | left border `#1d4ed8`, bg `#eff6ff`, text `#1e3a8a` |

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

> **Critical:** `monthly_incidents_delays.csv` is built from a cross-join (see `4_export.sql` lines 31-37 and CLAUDE.md data caveat). Raw `SUM([Incident Count])` and `SUM([Delay Count])` over-count by the cross-product factor. Use the deduplicated `Real Inc` / `Real Delay` calcs below, and promote `Category`, `Line Group`, `Day Type` to **Context filters** on every sheet.

| Field name | Source | Formula |
|-----------|--------|---------|
| `Real Inc` | monthly_incidents_delays | `[Incident Count] / {FIXED [Month],[Line],[Day Type],[Category] : COUNT([Incident Count])}` |
| `Real Delay` | monthly_incidents_delays | `[Delay Count] / {FIXED [Month],[Line],[Day Type],[Reporting Category] : COUNT([Delay Count])}` |
| `Signal+Track Incidents` | monthly_incidents_delays | `IF [Category] IN ("Signals","Track") THEN [Real Inc] ELSE 0 END` |
| `Signal Track Share` (used by KPI 4) | monthly_incidents_delays | `SUM(IIF([Category] IN ("Signals","Track"), [Real Inc], 0)) / NULLIF(SUM([Real Inc]), 0)` |
| `delay_minutes_proxy_v3` (optional, see KPI 3 note) | monthly_incidents_delays | `SUM([Real Delay]) / NULLIF(SUM([Real Inc]), 0) * 3` |
| `day_num` | hourly_ridership_corridor | Pre-exported column (`EXTRACT(ISODOW ...)`, 1=Mon–7=Sun) — no calc needed |
| `Year Filter` (parameter, all sources) | workbook | **DateTime List** parameter; values `1/1/2022`, `1/1/2023`, `1/1/2024` at midnight; display format `yyyy` shows them as `2022`/`2023`/`2024`. Default: most recent year. |
| `Year Match` | each date-bearing source | `YEAR([date column]) = YEAR([Year Filter])` — wrap the parameter in `YEAR()` since it's a timestamp, not an integer. Add to Filters shelf, set to True, promote to Context. Per-sheet; Tableau doesn't auto-apply parameter-driven calc filters across sheets. |

`line_group` is pre-computed in every export — do not recreate it as a calculated field.

**Deprecated calcs (do not recreate):**
- `delay_per_incident = [delay_count] / NULLIF([incident_count], 0)` — row-level division compounds with cross-join duplication; AVG of this gives nonsense.
- `delay_minutes_proxy = delay_per_incident * 3` — depends on the broken calc above; the documented "~18 min" target was an artifact of that bug, not a real measurement.
- `Signal Incident Advantage` — KPI 4 was replaced with `Signal Track Share`; this field has no consumers.

---

## Journey Headline (floating text box — not a sheet)

A warm-background card below the title. The text is fixed copy but every claim is anchored on a year-aware metric (so the body text reads true regardless of year selected):

> *Penn Station looks like one place on a sign. Underneath, it's two reliability stories. Across the selected year, the 1/2/3 platform delivered trains within their target headway more often than the A/C/E platform — even though both absorbed comparable infrastructure incidents. Same name, different odds.*

Font: 17px, italic, `#0f172a`. Background: `#ffffff`, border: `#e8e4de`.

For a fully dynamic version, build it as a Text-mark worksheet that uses calc fields concatenating `STR(YEAR([Year Filter]))` with the live WA% gap. Trade-off: text-mark worksheets don't render formatted prose as cleanly as a static text box. Pick one.

---

## KPI Strip — Option 3 (4 dark-tile text sheets)

Background per tile: `#0f172a`. Text colors listed per tile. Big number 34px bold; sub-tag 10px, top-bordered, in the accent color of the tile.

| Tile | Metric | Display value | Text color | Sub-tag (interpretive) |
|------|--------|---------------|------------|------------------------|
| KPI 1 | Riders entering Penn | `~2.9M` paid entries/month avg across complexes 318 + 164 | `#ffffff` | "More than the population of Chicago, entering one complex every month." |
| KPI 2 | Routes converging | `6` (1·2·3·A·C·E) | `#fbbf24` | "Only Times Sq-42 St beats this count system-wide." |
| KPI 3 | Months hit by Signal/Track | `{N}/12` for active year (year-aware) | numerator `#ef4444`, slash + denom `#334155` | "A clean month at Penn was the year's exception, not the rule." |
| KPI 4 | 1/2/3 platform advantage | `+{X} pp` Wait Assessment % at peak | `#86efac` (light green — matches 1/2/3 hero) | "Compounded over a year of weekday peaks: ~8 extra on-time mornings per rider." |

> **Why these 4.** This strip reframed away from v2's `99` outages + `72%` infrastructure share. The story arc here is *scale → concentration → frequency → punchline*. Each KPI previews a chart that comes later: KPI 1 ↔ Sheet 8 ridership cell; KPI 2 ↔ Map; KPI 3 ↔ Quilt; KPI 4 ↔ Sheet 6 centerpiece. The strip is the dashboard in miniature.

**Build each KPI as a Text sheet (year-aware where applicable):**

| KPI | Data source | Filter (all in Context where noted) | Field on Text |
|-----|-------------|--------------------------------------|---------------|
| KPI 1 (Riders/month) | `monthly_ridership` | `Complex Id IN (318, 164)` (Context), `Year Match = TRUE` (Context) | `SUM([Ridership]) / NULLIF(COUNTD([Month]), 0)` formatted `~"#,"K"` |
| KPI 2 (Routes converging) | `dim_corridor_complexes` (or hard-typed text) | `Complex Id IN (318, 164)`, `route_id IN ("1","2","3","A","C","E")` | `COUNTD([route_id])` — returns `6`. Stable; can also be a typed `6`. |
| KPI 3 (Incident months) | `monthly_incidents_delays` | `Line Group IN ("1/2/3","A/C/E")` (Context), `Category IN ("Signals","Track")` (Context), `Day Type = 1` (Context), `Year Match = TRUE` (Context) | `Months With Incidents = COUNTD(IF [Real Inc] > 0 THEN DATETRUNC('month', [Month]) END)` displayed as `<value>/12` |
| KPI 4 (Platform WA gap) | `service_quality` | `period = 'peak'` (Context), `Day Type = 1` (Context), `Year Match = TRUE` (Context), `Line Group IN ("1/2/3","A/C/E")` (Context) | `WA Gap = AVG(IF [Line Group]='1/2/3' THEN [Wait Assessment Pct] END) - AVG(IF [Line Group]='A/C/E' THEN [Wait Assessment Pct] END)` formatted `+0.0" pp"` |

Mark type: Text. Place the calculated value on the Text card. Sub-tag is a separate Text line on the same Text card with smaller font, accent color, and a 1px top border.

> **Don't typo `2024` into any tile or sub-tag.** Sub-tag text is editorial and won't auto-update — keep it claim-stable across years (e.g., "More than the population of Boston" doesn't depend on year). Where a sub-tag must reference a year-specific fact, use a calc field with `STR(YEAR([Year Filter]))` rather than a static string.

---

## ~~Corridor Narrative — "Stress builds along the trip" (Sheet N)~~ — RETIRED in Option 3

> **Retired** in v3 because the wide-corridor + PATH framing is incompatible with the Penn-only narrative. Spec preserved below in case you re-enter the v2 framing.
>
> If pivoting to Option 2 (cost angle), Sheet N also stays retired — the cost story doesn't gain from the geographic narrative either.
>
> *Original v2 spec:* geographical scatter showing NJ → Penn → fork (1/2/3 uptown, A/C/E → WTC) journey, with PATH stations greyed out for context. Source: `dim_corridor_complexes.csv` + `monthly_ridership.csv`. Build: `longitude` on Columns, `latitude` on Rows, geographic role None on both, fixed axis ranges, Circle mark, size by `SUM([ridership])`, color by `line_group`. See `TABLEAU_BUILD_GUIDE.md` Step 5 for the original build (kept for archive).

---

## Cause Ladder (Sheet 4) — "Do both platforms see the same kinds of failure?"

**Source:** `monthly_incidents_delays.csv`

**Purpose:** Shows frequency (bar length) and severity (dot position) per **(category × platform)** — one bar and one dot per platform, grouped within each category. The chart directly answers whether the platforms see different *kinds* of failure (mostly, no — same dominant categories), which makes the so-what conclude that the reliability gap is downstream of incident type, not upstream of it.

**Build:**
- Rows: `[category]`, then `[line_group]` nested inside (one row per platform per category)
- Columns: `SUM([Real Inc])` as a Bar mark
- Dual axis: second axis plots `Severity Ratio` (= `SUM([Real Delay]) / NULLIF(SUM([Real Inc]),0)`) as a Circle mark — computes per (category, platform) cell since both terms are aggregates
- Synchronize axes. Hide the second axis label.
- Color: bars and circles both by `[line_group]` (1/2/3 = `#59a14f`, A/C/E = `#4e79a7`)
- Sort: `[category]` by `SUM([Real Inc])` descending — Signals floats to the top
- Filter: `Line Group IN ("1/2/3","A/C/E")` (Context), `Day Type = 1` (Context), `Year Match = TRUE` (Context), `Category` ALL (Context for FIXED LODs)

**Section title (question form):** *Do both platforms see the same kinds of failure?*

**So-what callout (below chart):**
> Broadly yes — Signals dominate both platforms, Track sits second on both. The reliability gap on Sheet 6 *isn't* explained by a different mix of failures hitting each platform; both platforms see the same problem profile. The gap must be in what happens *after* an incident — a service-frequency and recovery-operations story.

**Annotation (on chart):** Right-click the Signals row → *Annotate → Mark* → `"Signals dominate both platforms — same problem, different absorption"`.

> **v2 alternative:** if you keep Sheets 4 and 5 separate (no Gantt dual axis), build Sheet 4 as a sorted horizontal bar of `SUM([Real Inc])` and Sheet 5 as a box plot of `Severity Ratio`. Same filters either way.

---

## Monthly Incident Pattern — "Quilt" (Sheets C-1 + C-2) — "Do the platforms fail at the same time?"

**Source:** `monthly_incidents_delays.csv`

**Purpose:** Show whether the platform-reliability gap holds month-to-month or is driven by a few outliers. Two sheets stacked because Tableau only allows one sequential palette per measure per sheet.

**Sheet C-1 (1/2/3 platform):**
- Mark type: Square (highlight table)
- Columns: `MONTH([month])` — discrete, Jan–Dec
- Rows: `Line Group` — discrete
- Color: `SUM([Signal+Track Incidents])` → Custom Sequential palette `#dcfce7` → `#16a34a` (1/2/3 green family)
- Filter: `Line Group = "1/2/3"`, `Category IN ("Signals","Track")` (Context), `Year Match = TRUE` (Context)
- Hide column headers (will appear on C-2 below)

**Sheet C-2 (A/C/E platform):**
- Same structure as C-1
- Filter: `Line Group = "A/C/E"`, `Category IN ("Signals","Track")` (Context), `Year Match = TRUE` (Context)
- Color palette: `#dbeafe` → `#1e40af` (A/C/E blue family)
- Keep column headers (months) on this sheet

**Section title (question form):** *Do the platforms fail at the same time?*

**Honest qualifier callout (above so-what box):** Identify the month where A/C/E is clear but 1/2/3 is heavy (year-aware — verify in the active year before quoting). Add a small lavender callout:
> ⚠ **{Month name}:** A/C/E is clear, 1/2/3 is heavy. The one month where the headline advice would have failed.

To make this dynamic, identify the qualifier month with a calc field rather than typing the month name:
```
{FIXED [Line Group] :
  IF [Line Group] = '1/2/3'
  THEN MAX(IF SUM([Signal+Track Incidents]) > <threshold> THEN MONTH([Month]) END) END
}
```
…or accept that this is editorial copy and update it manually each year.

**So-what box:**
> The platforms don't fail in lockstep — they're operationally independent within the same complex. That's *good news* for the routing argument: when one is degraded, the other is usually still on schedule. The {N}-month exception is the honest qualifier on the headline.

**Dashboard assembly:** stack C-1 directly above C-2 in a vertical container with 0px gap so they read as one chart. Per-platform palettes need separate sheets — Tableau limitation.

---

## Incident Timeline + Ridership (Sheets 2 + 3) — "Is the gap real?"

**Source:** `monthly_incidents_delays.csv` (incidents) + `monthly_ridership.csv` (ridership)

**Section title (question form):** *Is the gap real, or just an average that hides bad months?*

**Sheet 2 — Incidents (stacked bar):**
- Columns: `MONTH([month])` — discrete
- Rows: `SUM([Signal+Track Incidents])`
- Mark type: Bar
- `Line Group` on **Color only** (not Columns) — Tableau stacks automatically
- Stack order: 1/2/3 on bottom so red anchors the baseline
- Filter: `Line Group IN ("1/2/3","A/C/E")` (Context), `Category IN ("Signals","Track")` (Context), `Year Match = TRUE` (Context)

**Sheet 3 — Ridership (stacked area):**
- Columns: `MONTH([month])` — discrete
- Rows: `SUM([ridership])`
- Mark type: Area
- `Line Group` on **Color only** — areas stack automatically
- Filter: `Line Group IN ("1/2/3","A/C/E")` (Context), `Year Match = TRUE` (Context)

**So-what box (below the 2×2 grid):**
> The incident bars confirm the gap is structural, not a one-month anomaly — both platforms absorb comparable disruption month after month, yet the 1/2/3 keeps trains closer to schedule. Ridership rises on both sides, so the gap is widening, not closing.

Place Sheet 3 directly below Sheet 2 in a vertical container with the same fixed width so month columns align. Combined height = system-wide stress; red/purple split = which platform absorbs more.

---

## Reliability Comparison: 1/2/3 vs A/C/E (Sheet 6a + 6b) — CENTERPIECE

**Source:** `service_quality.csv`

**Section title (question form):** *Which platform should you trust?*

**Structure (decided 2026-05-09):** built as **two worksheets**, not one combined sheet, to match the render's two-sub-panel layout (`render_11_option3_platforms.html:180-216`). Each sub-panel carries its own metric sub-title and its own per-metric reference line, which a single combined sheet cannot do honestly (WA% and OTP% have different system means, so a Table-scoped average across both is meaningless).

- **Sheet 6a** — Wait Assessment %
- **Sheet 6b** — Terminal On-Time Performance %

**Build (each sheet):**
- Mark type: **Bar**
- Rows: `Line Group` (this puts bars on horizontal — matches the render)
- Columns: the sheet's own measure (`Wait Assessment Pct` on 6a, `Terminal Otp Pct` on 6b)
- Color: `Line Group` (1/2/3 = `#59a14f`, A/C/E = `#4e79a7`)
- Label: same measure as on Columns, format `0.0"%"`, middle-center, white text
- Filters (all Context): `Period = 'peak'`, `Day Type = 1`, `Line Group IN ("1/2/3","A/C/E")`, `Year Match = TRUE`
- Value axis (horizontal): Fixed range `60–100`. Both sheets share this scale so the bars are visually comparable side-by-side.
- Reference line: scope **Table**, value **Average** of the sheet's own measure, label `"Penn avg"` (Penn-serving routes only — not system-wide; see `project_state.md` § Sheet 6 reference line), dashed gray

**Why horizontal bars + two sheets, not vertical bars on one sheet:** the render is a two-panel CSS grid with horizontal bars — putting both metrics on one sheet with `Measure Names` + `Line Group` nested on Columns produced 4 vertical bars that were correct numerically but didn't match the render and forced a single shared reference line that was scientifically dishonest. The split matches both the visual and the analytic structure.

**Dashboard placement (this is what makes the two sheets read as one card):**

```
Vertical container (outer — border + background here)
├── Text:        "Which platform should you trust?"           (shared title)
├── Horizontal container
│   ├── Vertical
│   │   ├── Text:  "Wait Assessment %"                        (sub-title 6a)
│   │   └── Sheet 6a
│   └── Vertical
│       ├── Text:  "Terminal On-Time Performance %"           (sub-title 6b)
│       └── Sheet 6b
└── Text:        "So what: the 1/2/3 platform leads..."       (shared so-what)
```

Border (`#e2e8f0` 1px) and background (`#ffffff`) on the **outer Vertical only**. Inner Horizontal background = None (otherwise it competes with the outer fill). Each worksheet's own title is hidden — the metric labels live in the dashboard Text objects.

**Annotation:** on Sheet 6a, right-click the 1/2/3 bar → *Annotate → Mark* → `"~1 in 25 more trains on time at peak"` (claim-stable across years).

**So-what box:**
> The 1/2/3 platform leads on both metrics, every quarter of the active year. A ~4-percentage-point Wait Assessment gap means roughly **1 in 25 more trains arrive on schedule** — which compounds across thousands of weekday commutes. *If you have both options on your MetroCard, take 1/2/3.*

This is the dashboard's centerpiece — promote to top of body, full width.

---

## Delay Duration Distribution (Sheet 5) — supporting "How bad is bad?"

**Source:** `monthly_incidents_delays.csv`

**Section title (question form):** *How bad is bad — per-incident severity?*

**Build:**
- Rows: `[category]` sorted descending by `Severity Ratio`
- Columns: `Severity Ratio` (= `SUM([Real Delay]) / NULLIF(SUM([Real Inc]),0)`) — Mark type: Circle first, then add Box Plot from Analytics pane → Cell
- **`Month` on Detail shelf** — required for distribution. Without it Tableau collapses to one point per category.
- Filter: `Incident Count` range min = 1 (Range of Values filter — Tableau-side, not SQL), `Day Type = 1` (Context), `Line Group IN ("1/2/3","A/C/E")` (Context), `Year Match = TRUE` (Context)
- Color: `category` on Color shelf — **spotlight palette**: surprise category (whichever lands at the top of the severity sort, likely "Other" or "Stations") in `#dc2626` red as the alert color; all other categories muted to `#94a3b8` gray. Don't reuse the platform green/blue here — Sheet 5 isn't a platform-comparison chart, and a different palette signals "different question being asked"
- Box plot fill: if stuck on gray, uncheck Fill and rely on dot colors + box border

**Annotation (on chart):** Right-click the Signals outlier dot at far right → *Annotate → Mark* → `"Worst-month outlier — {X}× the corridor median"`. Use `STR(ROUND(...))` in a calc-field-driven annotation if you want it year-aware; otherwise update the {X} text per year.

**So-what box (Option 3):**
> Severity tracks frequency: Signals are both the most frequent failure type and the longest-tailed in delay. The ~4 pp gap on Sheet 6 isn't driven by *fewer* Signal events on 1/2/3 — both platforms see comparable counts — but by how the 1/2/3 absorbs them with less rider impact.

**So-what box (Option 2 cost angle, if used as backup):**
> Signal failures span 4 to 52 minutes — that's the range a Penn rider can't plan around. Track failures cluster tightly: a Track incident is bad but predictable; a Signal incident might cost an entire commute.

---

## Sankey — Delay Flow (Sheet San)

**Source:** `monthly_incidents_delays.csv`

**Purpose:** Shows how delay-causing incidents flow from category to platform. Signals dominate the left-side flow; the wider right-side band is year-dependent — verify in the active year before annotating.

**Build (Tableau Public 2026.1.0 native Sankey):**
- Mark type: Sankey (from the chart type dropdown)
- The Marks card shows **Level**, **Link**, **Detail** tabs — not "From/To/Size"
- `Category` → **Level** (left nodes)
- `Line Group` → **Level** (right nodes)
- `SUM([delay_count])` → **Link** (band width)
- Filter: `line_group IN ("1/2/3","A/C/E")`, `day_type = 1`
- Colors: set via the Level tab → Color. Node colors follow the Color shelf on the Level marks card. Link tab → Color controls ribbon/band color (set to neutral gray or low opacity).
- **Note:** Sankey color editing is limited in some Tableau versions. If Edit Colors is blocked, use Format → Workbook → Color Palettes to set the workbook palette to your colors in the correct order — Tableau assigns palette colors sequentially to categories.

**Key flow:** Signals dominate the flow into both platforms; the wider band is platform-specific to the active year — verify before annotating.

---

## Where (Filtered Map — Sheet 7) — "How close are the two platforms, really?"

**Sources:** `dim_corridor_complexes.csv` + `monthly_incidents_delays.csv`

**Section title (question form):** *How close are the two platforms, really?*

**Build:**
- Geographic roles: `latitude`, `longitude` from `dim_corridor_complexes`
- Size: `SUM([Real Inc])` (or `SUM([Real Delay])` for cost framing) from monthly_incidents_delays
- Color: `line_group`
- Filter: **`Complex Id IN (318, 164)` only** (Option 3 refocus) — wider corridor complexes hidden
- Year filter: `Year Match = TRUE` (Context) on the joined `monthly_incidents_delays`
- Background map: Tableau automatic (light theme), zoomed to mid-Manhattan so 318 and 164 dominate the frame

**So-what box:**
> The A/C/E complex absorbs more trains-delayed *per rider on schedule* than the 1/2/3 complex, despite drawing similar incident counts. The cost concentrates on one platform — and switching is a single staircase, not a transfer.

If you want a hard percentage on the so-what, build a calc field `Delay Gap %` so it's year-aware (or surface the live ratio in a tooltip rather than typing it).

---

## When (Day × Hour Heatmap — Sheet 8) — "If you had to pick one moment to avoid Penn?"

**Source:** `hourly_ridership_corridor.csv`

**Section title (question form):** *If you had to pick one moment to avoid Penn, when?*

**Build:**
- Columns: `HOUR([transit_timestamp])` — continuous 0–23
- Rows: `DATENAME('weekday', [transit_timestamp])` — sorted by `day_num`
- Color: `SUM([ridership])` — sequential `#fef2f2` → `#991b1b`
- Mark type: Square
- Filter: `Complex Id IN (318, 164)` for Penn-only view (Context), `Year Match = TRUE` (Context)
- Reference bands: vertical at hours 7–9 (AM Rush) and 16–19 (PM Rush), color `#dbeafe` (light blue, A/C/E family — distinct from the red heatmap fill)

**Day sort:** Use `day_num` calculated field to sort Mon → Sun (Tableau sorts weekday names alphabetically by default).

**Annotation (year-aware Mark Label, see TABLEAU_BUILD_GUIDE.md Step 12):** the Tue 8 AM cell carries a dynamic label `"Peak: Tue 8 AM in {year} — {ratio}× weekday avg"`.

**So-what box (Option 3):**
> Tuesday 8 AM is peak risk on *both* platforms — but it's also the hour with the largest absolute ridership × failure interaction, so the ~4 pp Wait Assessment gap saves the most riders the most time at exactly this cell. *The headline advice has its highest value here.*

**So-what box (Option 2 cost angle, if used as backup):**
> Tuesday 8 AM is the single highest-cost cell — 3.2× the weekday average. PM rush (4-6 PM) shows a smaller secondary peak, weekends drop sharply. *If a rider could move one commute by an hour, this is the hour to move out of.*

---

## Narrative Footer — "The bottom line" (floating text box)

Dark navy (`#0f172a`) background card at dashboard bottom. Two parts: action-oriented closer + caveats block.

**Closer (Option 3 primary):**
> **The bottom line.** For the ~2.9M paid entries each month at Penn — riders who often hold both options on their MetroCard — the data answers a single practical question: when both platforms are running, *take 1/2/3*. The A/C/E platform isn't unreliable — it's the second-best choice in a complex where the best choice is one staircase away. That gap holds across most months, narrows in occasional exceptions, and is largest exactly when ridership is highest: *Tuesday 8 AM*.

**Closer (Option 2 backup, if pivoting):**
> **The bottom line.** The cost of a Signal failure at Penn isn't an abstraction — it's *N* trains delayed in the median case, *X* minutes in the worst, and *Y×* more if it happens at 8 AM Tuesday. Multiply that by *11 months* of failures and *~2.9M monthly entries*, and "reliability" stops being a metric and becomes a rider's everyday calculation. The data tells riders *when* to brace and operators *where* to invest.

**Caveats block (below the closer, separated by a 1px top border in `#1e293b`):**
> **Caveats:** active year(s) shown in the parameter at top-right. Wait Assessment measures peak-period headway adherence; it doesn't capture every dimension of "reliability." A handful of stations beyond Penn have their own outage profiles that differ from the platform averages shown here.

Font color: `#64748b` for body, `#f1f5f9` for bold, `#86efac` (Option 3, matches 1/2/3 green) or `#fb923c` (Option 2) for italic emphasis.

---

## Text-insight stack — every chart carries

This is the pattern that distinguishes a portfolio dashboard from a screenshot of charts. Every chart on the dashboard carries:

| Layer | Implementation in Tableau |
|---|---|
| **1. Title + subtitle** | Worksheet → Show Title + Show Caption |
| **2. Headline paragraph** | Floating text box below title, italic, year-aware copy |
| **3. KPI sub-tags** | Second Text line on the KPI tile, smaller font, accent color, 1px top border |
| **4. Section title in question form** | Worksheet → Show Title (plain English question) |
| **5. Annotation on a specific mark** | Right-click mark → Annotate → Mark; one per chart minimum |
| **6. "So what" interpretation box** | Floating text box below chart, light fill + colored left border (`.insight` class in mockups) |
| **7. Action-oriented footer** | Floating text box at the bottom of the dashboard |
| **8. Caveats block** | Bottom of footer, separated by a thin border |

Layers 4-6 are the highest-leverage additions — they convert a chart-of-data into an argument-with-evidence. Layer 5 (annotation on a specific mark) typically scores higher with reviewers than a caption underneath.

---

## Dashboard-level filters

| Filter | Type | Affects |
|--------|------|---------|
| `[Year Filter]` | **DateTime List** parameter; one timestamp row per year (Value `1/1/<yyyy>`, Display As `<yyyy>`); currently 2022/2023/2024. Display format `yyyy`. | All date-bearing sheets via `Year Match` calc — note: must be added to each sheet's Filters shelf manually, won't propagate via "Apply to Worksheets" |
| Day type | Toggle (weekday/weekend) | Cause Ladder, Reliability, Box Plot |

Place the year parameter as a Compact List control (closest to a pill style) top-right of the dashboard. The list values are stored in the Tableau parameter — extending the data via `3_transform.sql` requires adding new years to the parameter list as well.

---

## Data source footnote (place at dashboard bottom, above footer)

```
Sources: data.ny.gov (Major Incidents, Delay-Causing Incidents, Wait Assessment,
Terminal OTP, Hourly Ridership), MTA GTFS feed (route + station metadata).
Time scope: see Year filter at top-right (default = most recent year on file).
Severity is shown as ratios and counts directly — no minutes proxy.
Built by Tanvi Chettiyar · raw CSVs → Postgres star schema → Tableau workbook · The Data School application, 2026.
```

> **Don't typo a year here.** "see Year filter at top-right" is the durable phrasing.

---

## What changed from v2 → v3

| v2 (render_9 — corridor narrative) | v3 (render_11 — platform contrast) |
|----|----|
| Penn Station + WTC wide corridor (35 stations) | Penn Station only (complexes 318 + 164) |
| "NJ commuter transfer" framing with PATH context | "Inside Penn — two platforms" framing, no PATH dependency |
| Sheet N (corridor scatter) full-width centerpiece | Sheet 6 (WA% + OTP%) full-width centerpiece |
| KPI strip: 700K · 11/12 · 99 · 72% | KPI strip: ~2.9M · 6 routes · {N}/12 · +{X} pp |
| Section titles describe ("Where the Stress Falls Each Month") | Section titles ask ("Is the gap real, or just an average?") |
| One insight callout per chart (description) | "So what" boxes per chart (interpretation) + annotations on specific marks |
| Year hardcoded in journey headline + footer copy | Headline + footer year-agnostic; year-specific values via `[Year Filter]` |
| Sheet 7 map shows full Penn corridor (35 stations) | Sheet 7 map zoomed to Penn 318 + 164 only |
| Sheet C labeled as "corridor" rows | Sheet C labeled as "platform" rows (same field, sharper framing) |
| Footer narrates the corridor advantage | Footer "The bottom line" + caveats block (action + honesty) |

## What changed from v1 → v2 (kept for archive)

| v1 | v2 (render_9) |
|----|----|
| Penn Station only | Penn Station + WTC corridor |
| Dual-axis incidents+ridership chart | Stacked bar + stacked area (Line Group on Color) |
| No corridor journey visualization | "Stress builds along the trip" scatter (Sheet N) |
| Sheets 4+5 as two separate panels | Cause Ladder consolidates both; box plot kept as Sheet E |
| No service quality dimension | Reliability comparison (WA% + OTP%) — Sheet D |
| No flow visualization | Sankey (Category → Line Group, Real Delay) — Sheet San |
| One-palette highlight table | Two-sheet quilt (C-1/C-2) for per-corridor palettes |
| Hand-built CSV | Star schema in Postgres + 5 typed CSV exports |
| White background | Warm off-white `#faf8f4` + dark navy KPI tiles |
| No narrative arc | Journey headline + narrative footer frame the story |
| KPI 3 = "Avg Delay per Incident ~18 min" (broken proxy) | KPI 3 = `99` Signal/Track major outages (clean count) |
| KPI 4 = "A/C/E Signal Advantage −23%" (redundant comparison) | KPI 4 = `72%` Signal+Track share (Problem-act thesis) |
| `delay_per_incident` row-level calc | `Real Inc` / `Real Delay` dedup LODs + Context filter discipline |
| Static annotations only | Year-aware Mark Labels on Sheet F (Penn) and Sheet G (Tue 8 AM) |

---

## Option 2 backup variant — "What It Costs to Enter NYC Through Penn Station"

Documented fallback. Pivot here if the platform-contrast headline weakens (e.g., ~4 pp gap closes after extending to multi-year data, or reverses in some years). The pivot is editorial — **the SQL pipeline is identical; only the Tableau workbook changes**.

**Mockup:** `sample_dashboards/render_10_option2_cost.html`.

### Story arc (Option 2)

1. **Scale** — ~2.9M paid entries/month, 11 of 12 months hit by Signal/Track failure (frame as cost exposure).
2. **Per-incident cost** — Sheet 5 box plot promoted to a centerpiece-supporting role; Sheet 4 cause ladder pairs with it (frequency × severity).
3. **Aggregate cost** — Sheet 2 (incidents over time) reframed as a "monthly cost curve."
4. **Peak cost** — Sheet 8 day × hour heatmap PROMOTED to full-width centerpiece. The story becomes "Tuesday 8 AM is the highest-cost cell."
5. **Where it concentrates** — Sheet 7 map (zoomed to Penn 318 + 164) shows the cost split between platforms.

### KPI strip — Option 2 deltas

| Tile | Option 3 (primary) | Option 2 (backup) |
|------|---|---|
| KPI 1 | ~2.9M paid entries/month | ~2.9M paid entries/month *(same)* |
| KPI 2 | 6 routes converging | **{X} min** worst single delay (`MAX(Severity Ratio) * 3` proxy) |
| KPI 3 | {N}/12 incident months | **~{N}K** total trains delayed (`SUM([Real Delay])` × proxy on Penn-serving routes) |
| KPI 4 | +{X} pp WA gap | **{X}×** peak risk multiplier (Tue 8 AM ridership/avg) |

### Sheet retire/demote — Option 2

- **Sheet 6** (Reliability) — *demoted or removed*. The WA gap stops being load-bearing.
- **Sheet 3** (Ridership over time) — *demoted*. Doesn't directly answer the cost question.
- **Sheet C** (Quilt) — *removed*. Two-platform contrast is no longer central.
- **Sheet San** (Sankey) — *retired or simplified* to a single Category → trains-delayed bar.
- **Sheet 7** (Map) — *kept* but title becomes "Where does the cost concentrate?".
- **Sheet 2** (Incidents over time) — *kept* but split removed; single Penn-route series.

### Footer — Option 2

Use the "Closer (Option 2 backup)" copy from the Narrative Footer section above. Caveats block adds: "Severity proxy treats all delayed trains as equivalent; doesn't capture cancelled trains or post-incident schedule recovery."

### Build cost of pivoting

| Change | Effort |
|---|---|
| Title + headline + footer | ~1 hr (text rewrites) |
| KPI 2 + 3 + 4 swaps | ~2 hr (3 new calcs, dashboard tile updates) |
| Sheet 8 promotion to full width | ~30 min (container rearrangement) |
| Sheet 6 / 3 / C / San removal | ~30 min |
| Sheet 2 single-series rebuild | ~30 min |
| **Total** | **~5 hours** |

The SQL pipeline doesn't change. The 5 CSVs work for both options without modification.
