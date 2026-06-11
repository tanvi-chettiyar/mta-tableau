# Tableau Dashboard Model — Inside Penn (v3)

Sheet-by-sheet specs and design decisions for the v3 Tableau dashboard.

**Canonical layout reference:** `sample_dashboards/render_11_option3_platforms.html` (Option 3 — primary)
**Backup layout reference:** `sample_dashboards/render_10_option2_cost.html` (Option 2 — cost angle, kept as fallback)
*Earlier prototypes — `render_9_synthesis.html`, `render_6.jpeg` — superseded.*

---

## Round 2 reviewer feedback (2026-06-02) — what changed

Salome's round-2 feedback (7 items, accessibility / readability focused) reshaped several sections of this file. **Application sequence** for the workbook lives in `TABLEAU_BUILD_GUIDE.md` § "Round 2 reviewer feedback — apply in this order"; the specs themselves live where the existing sections are:

| Round-2 item | Where the canonical spec lives in this file |
|---|---|
| 1 — Jargon expansion (`pp`, `WA`, `OTP` first-use definitions) | § "Canonical caption set" → Intro paragraph (lines 15 + 45) |
| 2 — Font size bump (workbook-wide) | § "Typography sizes" (size table below the footer section) |
| 3 — Sheet 2 destack (grouped bars by month) | § "Canonical caption set" → Sheet 2 caption + so-what |
| 4 — Sheet 5 3-swatch legend (red / yellow / gray) | § "Canonical caption set" → Sheet 5 so-what (notes the legend + 3-tier accent) |
| 5 — Magenta retone to platform palette | § "Color treatment (revised 2026-06-02 per round-2 reviewer feedback)" |
| 6 — Line-length break-up (770px width cap) | § "Width cap (added 2026-06-02 per round-2 reviewer feedback)" |
| 7 — Map (Sheet 7) moved above the KPI strip | § "Orient (Filtered Map — Sheet 7)" (dedicated section) + § "Story — Option 3" 5-question structure (slot 0 prelude) |

The intro paragraph, bottom-line, caveats, and Sheet 7 sections were the most rewritten. Everything else — KPI strip definitions, Sheet 6 centerpiece spec, Sheets 2/3/4/4a/C/8 builds, the closing-gap narrative — is unchanged from pre-round-2 (round 2 didn't challenge any of the analysis).

---

## Story — Option 3 (primary): "Inside Penn — Two Platforms, A Closing Gap"

> **Title:** Inside Penn Station: Two Platforms, A Closing Gap
> **Subtitle:** How the platform you choose changes your odds — and why the gap is shrinking ~ Lines 1/2/3 & A/C/E
> **Intro paragraph:** Penn Station looks like one place on a sign. Underneath, it's two platforms — and a closing gap. The 1/2/3 platform has led A/C/E on peak Wait Assessment (the share of peak-hour trains arriving within target headway) every year measured, but the lead has shrunk from +8.0 percentage points (pp) in 2022 to +4.3 pp in 2023 to +3.8 pp in 2024. A/C/E climbed from 61% to 66% while 1/2/3 held steady near 70% — and both platforms absorbed roughly 40% more major incidents along the way. Same name, different odds — narrowing.

*Title changed from "Two Reliability Stories" (2026-05-11) — multi-year comparison revealed the gap is narrowing, not static. A/C/E is catching up to a stable 1/2/3. Intro rewritten 2026-05-28 to include the rising-incidents finding from Sheet 4a (cause-side trajectory): convergence happens against a rising load on both platforms, not a calming system — recovery operations, not prevention. See project_state.md memory § "Closing-gap narrative" + § "Second-AI critique iteration" for the supporting data.*

The dashboard answers five questions in sequence, each anchored on a chart whose **section title is the question itself**, with two orienting cards above the centerpiece: the map (above the KPI strip) and the Trajectory band (between KPIs and Sheet 6):

0. *(Orient — above the KPI strip, immediately after the intro paragraph)* **Where are these two platforms?** (Sheet 7 — moved here on 2026-06-02 per round-2 reviewer feedback, "a spatial anchor before diving into the metrics"). Then the KPI strip (4 tiles). Then the Trajectory band ("1/2/3 holds; A/C/E catches up").
1. **Which platform should you trust?** (Sheet 6 — centerpiece, full width)
2. **Is the gap real, or just an average that hides bad months?** (Sheets 2 + 3 — incidents + Wait Assessment % over time, both split by platform — Sheet 3 was ridership pre-feedback; replaced 2026-05-22 so the chart pair visibly answers the section question)
3. **Do bad months hit both platforms together?** (Sheet C — quilt; broadened to all incident categories 2026-06-11. The qualifier callout was dropped at the same time: once the chart shows independent failure calendars across all categories, the headline *is* the qualifier, and a separate callout no longer adds information.)
4. **Do both platforms see the same kinds of failure?** (Sheet 4 — cause ladder, split by platform; Sheet 4a extends to cause-side trajectory)
5. **If you had to pick one moment to avoid Penn, when?** (Sheet 8 heatmap — closer)

The sequence: orient → punchline first → stress test → mechanism → qualifier → context. Each numbered section raises a stated question and answers it, then the next section either deepens or qualifies it. The orienting cards (slot 0) prime the reader on *what* and *where* before the analytical beats begin.

### Why this framing

- **Honest with the data we have.** The earlier "NJ commuter transfer" framing leaned on PATH stations that aren't in the dataset. Penn-only narrows the claim to what the dashboard can defend.
- **Actionable.** "Take 1/2/3 if you can" is a concrete suggestion supported by every chart.
- **Year-agnostic.** The framing accommodates any year in the data range; the closing-gap trajectory is the multi-year story.

---

## Canonical caption set (2026-05-11 — supersedes earlier inline so-what text)

The so-what / caption / KPI sub-tag text below is the **canonical static text** for the v3 dashboard. It tells the multi-year closing-gap story; valid regardless of which year the `[Year Filter]` parameter is set to. Use this set when writing to text objects or text-only worksheets.

**Title** — `Inside Penn Station: Two Platforms, A Closing Gap`

**Subtitle** — `How the platform you choose changes your odds — and why the gap is shrinking ~ Lines 1/2/3 & A/C/E`

**Intro paragraph** — Penn Station looks like one place on a sign. Underneath, it's two platforms — and a closing gap. The 1/2/3 platform has led A/C/E on peak Wait Assessment (the share of peak-hour trains arriving within target headway) every year measured, but the lead has shrunk from +8.0 percentage points (pp) in 2022 to +4.3 pp in 2023 to +3.8 pp in 2024. A/C/E climbed from 61% to 66% while 1/2/3 held steady near 70% — and both platforms absorbed roughly 40% more major incidents along the way. Same name, different odds — narrowing.

**KPI 4 sub-tag** — `1/2/3 vs A/C/E peak Wait Assessment. Gap narrowing year over year: +8.0 (2022) → +4.3 (2023) → +3.8 (2024) as A/C/E improves toward a stable 1/2/3.`

**Trajectory chart (added 2026-05-28; between KPI strip and Sheet 6) — title (assertion-form):** `1/2/3 holds; A/C/E catches up` · **so what:** 1/2/3 has held near 70% every year measured. A/C/E has climbed from 61% to 66% over two years. The gap is closing because A/C/E is getting better against a rising-incident backdrop, not because 1/2/3 is degrading — a pure operations gain.

**Sheet 6 (Reliability comparison) — so what:** 1/2/3 leads A/C/E on both Wait Assessment and Terminal OTP in every year measured (2022–2024). The lead is now ~4 pp, down from ~8 pp in 2022, but the direction never flips. If both options are on your MetroCard, take 1/2/3.

**Sheet 2 (Monthly Signal+Track incidents — grouped bars by month; destacked 2026-06-02 per round-2 reviewer feedback) — caption:** `Monthly Signal + Track major incidents, grouped by platform — each month shows a green 1/2/3 bar next to a blue A/C/E bar so the per-month comparison reads at a glance.` · **so what (shortened 2026-06-02, ~45 words, pending workbook application):** 1/2/3's green bar is taller than A/C/E's blue bar in most months — the busier platform absorbs more Signal/Track stress month after month, with no single spike that explains the gap. Steady and uneven, not noisy and lopsided. (Total burden has grown year over year — see the cause trajectory below.) · *Previous longer version (85 words, in the workbook as of 2026-06-02) kept on file in case the shorter version doesn't land — see `dashboard_feedback_v3.md` memory § "Pending workbook application — so-what shortenings."*

**Sheet 3 (Monthly WA% by platform — title: "Does the gap hold every month?") — so what:** The 1/2/3 line sits above A/C/E every month measured — not just on annual average. The trajectory chart at the top shows the gap is closing *year-over-year*; this chart shows it never *flips* within a year. Whatever the structural advantage is, it's always-on, not a peak-month artifact.

**Sheet C (Monthly Incident Pattern quilt; broadened from Signal/Track to all categories 2026-06-11) — title (question form):** `Do bad months hit both platforms together?` · **subtitle (mechanics, 22 words, em-dash-free):** `Top row: 1/2/3 platform. Bottom row: A/C/E platform. Darker cell means more major incidents that month, all categories combined.` · **so what (49 words, em-dash-free; revised 2026-06-11):** The bright cells don't line up between rows. Each platform has its own bad months: 1/2/3 spikes when A/C/E is calm, and the reverse. But 1/2/3 carries more events in most cells overall. Independent failure patterns, plus a heavier total load on 1/2/3, yet still the better reliability record. · *Prior so-what (pre-2026-06-11, when Sheet C was filtered to Signals+Track only): "Same calendar shape, different magnitudes. The bright cells line up across both rows — same bad months, same quiet months — but 1/2/3 is the busier platform, carrying more incident events per month in most cells." The "calendar shape lines up" claim was contradicted by the all-categories quilt — verified against rendered Sheet C images for 2022/2023/2024, which show peaks on opposite rows (2023 Oct: 1/2/3=16 vs A/C/E=5; 2023 May: 1/2/3=6 vs A/C/E=12; 2024 Jan: 1/2/3=21 vs A/C/E=7).*

**Sheet 4 (Cause Ladder) — so what (shortened 2026-06-02, ~50 words, pending workbook application):** In every one of the top three categories — Persons on Trackbed, Signals, Track — 1/2/3 carries *more* incidents than A/C/E, yet still wins on reliability. Same problem profile, 1/2/3 sees more of it. The gap must be in what happens *after* an incident — a recovery-operations story. · *Workbook currently carries a longer ~125-word version with the three-pronged negation framing ("isn't explained by mix / severity / counts") and a forward-pointer to the chart below; the long form is preserved in `dashboard_feedback_v3.md` memory § "Pending workbook application — so-what shortenings."* · *(Build-time verification: confirm per-platform claim against active year's bars before shipping; soften if only 2 of 3 categories hold. This is a build note, not dashboard text.)*

**Sheet 4a (Cause-side trajectory; added 2026-05-28; between Sheet 4 and Sheet 5) — title (assertion-form):** `More incidents on both — A/C/E closes the gap anyway` · **caption:** `Total major incidents per year, by platform, 2022–2024 — all categories.` · **so what (shortened 2026-06-02, ~50 words, pending workbook application):** Both platforms absorbed ~40% more incidents in 2024 than in 2022, and 1/2/3 carried more in every year (+13, +6, +23). Yet A/C/E's Wait Assessment climbed and the gap narrowed. The closing gap isn't fewer problems on A/C/E — it's faster recovery from rising ones. An operations story, not a prevention one. · *Long form (~75 words) preserved in `dashboard_feedback_v3.md` memory.*

**Sheet 5 (Per-incident severity bar) — so what (shortened 2026-06-02, ~35 words, pending workbook application):** Signals dominate volume but rank middle on per-event severity. The worst severity sits with rare causes like 'Other' and 'Stations and Structure' — fewer events, much heavier when they hit. The reliability gap rides on frequency, not severity. · *Long form (~60 words) preserved in `dashboard_feedback_v3.md` memory.* · **Build-time notes (NOT dashboard text):** Box plot retired 2026-05-22 per feedback; three-tier accent (red = most severe, yellow = 2nd most severe, gray = all other causes) is year-aware via the `Top Severity Highlight` calc; **3-swatch legend added 2026-06-02 per round-2 reviewer feedback** since red/yellow encoding isn't self-explanatory. See Sheet 5 build section for the formula and Step 10f-legend for the legend spec.

**Sheet 7 (Map; upgraded 2026-05-28 — Size from `Real Inc` → per-complex monthly ridership; MOVED to slot 3 on 2026-06-02 per round-2 reviewer feedback — now an orienting card above the centerpiece, not a closer) — title:** `Where are these two platforms?` *(reframed from `How close are the two platforms, really?` — the original was a qualifier question that landed late; the new title is a setup question that lands early)* · **so what:** Two platforms, one staircase apart. The 1/2/3 platform (green) and the A/C/E platform (blue) share Penn's complex on the surface but run separate operations underneath — different lines, different schedules, different reliability profiles. Circle size marks each platform's monthly ridership; the labels carry the metrics the rest of this dashboard will explain. Same name, different odds — the rest of the dashboard tells you why.

**Sheet 8 (Day × Hour Heatmap) — so what:** Tuesday 8 AM is peak on both platforms — and it's also the hour where the ~4 pp Wait Assessment gap costs the most riders the most time. If the platform choice ever matters, it matters here. The dashboard's practical answer in one cell.

**Bottom-line conclusion (year-dynamic via Route A — calc field on text-only worksheet; rising-incidents framing applied 2026-05-28):**

```
"For the " +
CASE YEAR([Year Filter])
  WHEN 2022 THEN "2.33M"
  WHEN 2023 THEN "2.71M"
  WHEN 2024 THEN "2.92M"
END
+ " paid entries at Penn each month — riders who often hold both options on their MetroCard — the data answers a single practical question: when both platforms are running, take 1/2/3. The A/C/E platform isn't unreliable — it's the second-best choice in a complex where the best choice is one staircase away.

In " + STR(YEAR([Year Filter])) + ", 1/2/3 leads A/C/E by " +
CASE YEAR([Year Filter])
  WHEN 2022 THEN "+8.0 pp"
  WHEN 2023 THEN "+4.3 pp"
  WHEN 2024 THEN "+3.8 pp"
END
+ " on peak Wait Assessment — but that lead has been narrowing. The gap was +8.0 pp in 2022, +4.3 pp in 2023, and +3.8 pp in 2024, even as both platforms absorbed ~40% more major incidents over the period. A/C/E climbed from 61% to 66% while 1/2/3 held steady near 70% — the convergence is recovery operations, not a calmer system.

The 1/2/3 still wins the head-to-head choice — and the choice matters most exactly when ridership peaks: Tuesday 8 AM, on both platforms."
```

The above is a single calculated field (`[Bottom Line Text]`) on the `service_quality` data source, dropped on a text-only worksheet, placed on the dashboard. Update the CASE values when extending data range. Pattern detail: `tableau_calc_patterns.md` § 13 (memory) and `tableau_public_performance.md` for the why.

**Replaced sentence (2026-05-28):** the prior wording — *"Both platforms share the same Signal/Track incident burden; A/C/E is simply getting better at handling it"* — under-claimed the finding from Sheet 4a. Burden is *growing*, not just *shared* (~40% rise on both, 2022→2024). New wording lands the recovery-operations punchline more sharply against a chart-verified backdrop.

**Caveats block (static text object; rising-incidents note added 2026-05-28):**
```
Caveats: Weekday peak-period data, 2022–2024. Wait Assessment measures peak-period headway adherence; it doesn't capture every dimension of "reliability." Major-incident counts rose materially on both platforms across the period — the WA improvements happened against a rising-load backdrop, not a calmer system. Stations beyond Penn on either trunk have their own outage profiles that differ from the platform averages shown here. Use the year filter above to see how the gap evolved.

Built by Tanvi Chettiyar · raw CSVs → Postgres star schema → Tableau workbook · The Data School application, 2026.
```

**Sheet 5 — replaced 2026-05-22, refined post-feedback:** the box plot was retired in favor of a labeled horizontal severity bar (one bar per category, no platform split). Reviewer feedback flagged the box plot's dozens of overlapping monthly dots as analyst-heavy. The labeled bar shows `Severity Ratio` per category with a `"{N} delays/inc"` label suffix, sorted descending. Color: muted gray `#94a3b8` with `#dc2626` accent on top-2 categories via the `Top Severity Highlight = IF RANK_UNIQUE([Severity Ratio], 'desc') <= 2 THEN "Alert" ELSE "Muted" END` calc on Color (Compute Using → Category) — so the accent follows the active year's data automatically. Platform encoding lives on Sheets 6, 2, 3, and 4 — Sheet 5 just shows the cross-cause severity hierarchy. (Earlier green/blue box plot variant kept in `sample_dashboards/render_12_boxplot_colors.html` for archive.)

> **Unit phrasing:** earlier label format used `"× delay"` (multiplier framing) — at the actual magnitude of 80–110, multiplier reads awkwardly. Switched to `delays/inc` (count-ratio framing) which reads correctly at any magnitude. Apply to both Sheet 4 label suffix and Sheet 5 bar label so the unit is consistent across the dashboard. The ratio represents `SUM(Real Delay) / SUM(Real Inc)` where `Real Delay` is the MTA's delay-causing-incident count (not literal trains delayed) and `Real Inc` is the major-incident count.

---

---

## Backup story — Option 2: "What It Costs to Enter NYC Through Penn Station"

Documented fallback if the platform-contrast framing weakens with more years of data (e.g., the ~4 pp gap closes or reverses). The cost angle uses the same data with different KPIs and a different centerpiece. See "Option 2 backup variant" section at the end of this doc for the deltas.

---

## Layout — Option 3 (render_11 structure, updated 2026-05-28)

```
┌─────────────────────────────────────────────────────────────┐
│ Title + subtitle                      [Year Filter (param)] │
├─────────────────────────────────────────────────────────────┤
│ Intro paragraph (italic, warm card) — multi-year framing    │
├─────────────────────────────────────────────────────────────┤
│ Sheet 7 — Map (Penn 318 + 164, size by per-complex monthly  │
│   ridership)                                                │
│   "Where are these two platforms?"                          │
│   Manual WA% annotations on each dot · so-what box          │
├──────────┬──────────┬──────────┬────────────────────────────┤
│  KPI 1   │  KPI 2   │  KPI 3   │  KPI 4   (dark navy tiles) │
│  ~2.9M   │   6      │  N/12    │  +X pp                     │
│ +sub-tag │ +sub-tag │ +sub-tag │ +sub-tag                   │
├──────────┴──────────┴──────────┴────────────────────────────┤
│ Trajectory — WA% by Line Group × year (2022→2024)           │
│   "1/2/3 holds; A/C/E catches up"  (assertion-form)         │
│   Two lines · per-year gap on x-axis aliases · ignores      │
│   [Year Filter] · so-what box                               │
├─────────────────────────────────────────────────────────────┤
│ Sheet 6 — Reliability Comparison (CENTERPIECE)              │
│   "Which platform should you trust?"                        │
│   WA% bars · OTP% bars · Penn-avg ref line · so-what box    │
├─────────────────────────────────────────────────────────────┤
│ Sheet 2 — Monthly Signal+Track Incidents                    │
│   "Is the gap real, or just an average?"                    │
│   Grouped bars per month (green 1/2/3 next to blue A/C/E)   │
│   · so-what box                                             │
├─────────────────────────────────────────────────────────────┤
│ Sheet 3 — Monthly WA% by platform                           │
│   "Does the gap hold every month?"                          │
│   Line chart (Line Group on Color, peak weekday) · so-what  │
├─────────────────────────────────────────────────────────────┤
│ Sheet C — Monthly Incident Pattern Quilt (all categories)   │
│   "Do bad months hit both platforms together?"              │
│   Highlight table (C-1 above C-2, per-platform palette)     │
│   so-what box (qualifier callout removed 2026-06-11)        │
├─────────────────────────────────────────────────────────────┤
│ Sheet 4 — Cause Ladder                                      │
│   "Do both platforms see the same kinds of failure?"        │
│   Horizontal bars by (category × platform) · so-what box    │
├─────────────────────────────────────────────────────────────┤
│ Sheet 4a — Cause-side trajectory                            │
│   "More incidents on both — A/C/E closes the gap anyway"    │
│   Side-by-side bars per year × Line Group · all categories  │
│   · ignores [Year Filter] · so-what box                     │
├─────────────────────────────────────────────────────────────┤
│ Sheet 5 — Per-incident severity (labeled bar)               │
│   "How bad is bad — per-incident severity?"                 │
│   Top-2 red accent (year-aware) · so-what box               │
├─────────────────────────────────────────────────────────────┤
│ Sheet 8 — Day × Hour Heatmap                                │
│   "If you had to pick one moment to avoid Penn, when?"      │
│   Tue 8 AM annotation · so-what box                         │
├─────────────────────────────────────────────────────────────┤
│ Footer — "The bottom line" + caveats block (dark navy card) │
└─────────────────────────────────────────────────────────────┘
```

Sheet 5 sits between Sheet 4a and Sheet 8 — supporting beat (severity), distinct from the volume-trend story Sheet 4a carries. Sheet San (Sankey) is **removed** from the primary layout (kept as hidden sheet in the workbook for Option 2 pivot). Sheet N (corridor scatter) is **retired** — it carries the wide-corridor + PATH framing that doesn't fit the Penn-only narrative.

**Two cards intentionally cross-year (ignore `[Year Filter]`):** the Trajectory card and Sheet 4a. Every other sheet respects the filter. The rule: snapshot questions keep `Year Match`; trajectory questions skip it. Trajectory cards must visually signal "I'm multi-year" via axis aliases (e.g. `2022 (+8.0 pp)`) so a reader doesn't misread them as the active year's data.

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
| KPI 4 | 1/2/3 platform advantage | `+{X} pp` Wait Assessment % at peak | `#86efac` (light green — matches 1/2/3 hero) | "Gap narrowing year over year: +8.0 (2022) → +4.3 (2023) → +3.8 (2024) as A/C/E improves toward a stable 1/2/3." |

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

**Purpose:** Shows incident frequency per **(category × platform)** — one horizontal bar per platform, grouped within each category. The chart directly answers whether the platforms see different *kinds* of failure (mostly, no — same dominant categories), which makes the so-what conclude that the reliability gap is downstream of incident type, not upstream of it. Per-incident severity is shown as a **label on each bar** (`"{N} delays/inc"`) — not a second visual encoding.

> **2026-05-22 — feedback fix:** the earlier build used a dual-axis circle to encode severity on the *same* x-axis as the bar (synchronized, so position read as if it were on the count scale). Reviewer flagged this as double-encoding: one axis was doing two semantic jobs. The fix is to drop the circle entirely and put severity in the bar label. The chart now has one encoding per visual channel (length = count, color = platform, label = severity).

**Build:**
- Rows: `[category]`, then `[line_group]` nested inside (one row per platform per category)
- Columns: `SUM([Real Inc])` as a Bar mark — single axis, no dual
- Color: `[line_group]` (1/2/3 = `#59a14f`, A/C/E = `#4e79a7`)
- Sort: `[category]` by `SUM([Real Inc])` descending — top of sort varies by year (verify; "Persons on Trackbed" has led recently)
- Filter: `Line Group IN ("1/2/3","A/C/E")` (Context), `Day Type = 1` (Context), `Year Match = TRUE` (Context), `Category` ALL (Context for FIXED LODs)
- **Label:** drag `SUM([Real Inc])` to Label first, then add a calc field `Severity Suffix` = `" · " + STR(ROUND([Severity Ratio], 0)) + " delays/inc"` to Label as a second pill. Label format: count in bold, suffix in muted gray (`#64748b`). Final label per bar reads e.g. `38 · 97 delays/inc`.
- `Severity Ratio` calc (create on `monthly_incidents_delays`): `SUM([Real Delay]) / NULLIF(SUM([Real Inc]), 0)` — same calc as before, just no longer plotted on its own axis. **Magnitude lands 80–110 in the actual data** (earlier docs showed `3.2×` as a placeholder); see `tableau_calc_patterns.md` for the magnitude/unit reasoning.

**Section title (question form):** *Do both platforms see the same kinds of failure?*

**So-what callout (below chart):**
> Broadly yes — Persons on Trackbed leads on both platforms, with Signals and Track close behind. The `delays/inc` labels show severity is comparable per-category across platforms. **The bigger surprise: in every one of the top three categories (Trackbed, Signals, Track), 1/2/3 actually carries *more* incidents on average than A/C/E — yet still wins on reliability.** The gap shown above *isn't* explained by a different mix of failures, nor by different severity per incident, nor by lower incident counts on 1/2/3. Both platforms see the same problem profile; 1/2/3 sees *more* of it. The gap must be in what happens *after* an incident — a service-frequency and recovery-operations story.

The bolded sentence is the chart's punchline — render it bold in the dashboard text object. Verify the "1/2/3 sees more" claim against the live render: each of the top 3 category rows should show a visibly longer green bar than blue bar. If only 2 of 3 hold, soften the claim to name the categories that do (e.g. "in Trackbed and Signals, 1/2/3 carries more...").

**Annotation (on chart):** Right-click the **Persons on Trackbed** row → *Annotate → Mark* → `"Trackbed intrusions hit 1/2/3 more often — yet 1/2/3 still leads on reliability. Recovery, not avoidance."` (Verify Persons on Trackbed is the top category by `Real Inc` in the active year; if a different category leads, anchor on that row instead and rephrase.)

---

## Monthly Incident Pattern — "Quilt" (Sheets C-1 + C-2) — "Do bad months hit both platforms together?"

> **2026-06-11 — scope broadened.** Sheet C was originally filtered to `Category IN ("Signals","Track")` to mirror the KPI strip's Signal/Track framing. Verified against rendered Sheet C images for 2022, 2023, and 2024 that the broader, all-categories view tells a *different and stronger* story: peaks land on different months for each platform (2023 Oct: 1/2/3=16 vs A/C/E=5; 2023 May: 1/2/3=6 vs A/C/E=12; 2024 Jan: 1/2/3=21 vs A/C/E=7). The "calendar shape lines up" reading from the Signal/Track quilt didn't survive expansion. Reframed the chart around independent failure calendars + heavier total load on 1/2/3. Category filter removed; Color/Label measure swapped from `Signal+Track Incidents` to `Real Inc`. Qualifier callout removed (see below — once the chart's headline *is* independence, a separate "exception month" callout no longer adds information).

**Source:** `monthly_incidents_delays.csv`

**Purpose:** Show whether the two platforms' monthly disruption rhythms line up or run independently. Two sheets stacked because Tableau only allows one sequential palette per measure per sheet.

**Sheet C-1 (1/2/3 platform):**
- Mark type: Square (highlight table)
- Columns: `MONTH([month])` — discrete, Jan–Dec
- Rows: `Line Group` — discrete
- Color: `SUM([Real Inc])` → Custom Sequential palette `#dcfce7` → `#16a34a` (1/2/3 green family). Set a **manual Start/End range** that spans both C-1 and C-2 maxes so the magnitude comparison between rows is honest.
- Filter: `Line Group = "1/2/3"` (Context), `Year Match = TRUE` (Context), `Day Type = 1` (Context). **No `Category` filter** — all categories are in scope.
- Hide column headers (will appear on C-2 below)

**Sheet C-2 (A/C/E platform):**
- Same structure as C-1
- Filter: `Line Group = "A/C/E"` (Context), `Year Match = TRUE` (Context), `Day Type = 1` (Context). **No `Category` filter.**
- Color palette: `#dbeafe` → `#1e40af` (A/C/E blue family). Use the same manual Start/End range as C-1.
- Keep column headers (months) on this sheet

**Section title (question form):** *Do bad months hit both platforms together?*

**Subtitle (mechanics, 22 words, em-dash-free):** *Top row: 1/2/3 platform. Bottom row: A/C/E platform. Darker cell means more major incidents that month, all categories combined.*

**So-what box (49 words, em-dash-free):**
> The bright cells don't line up between rows. Each platform has its own bad months: 1/2/3 spikes when A/C/E is calm, and the reverse. But 1/2/3 carries more events in most cells overall. Independent failure patterns, plus a heavier total load on 1/2/3, yet still the better reliability record.

**Honest qualifier callout — REMOVED 2026-06-11.** The Signal/Track-only build carried a lavender "⚠ {Month}: A/C/E is clear, 1/2/3 is heavy. The one month where the headline advice would have failed." callout above the so-what. Under the old reading ("same calendar shape"), the callout flagged the one off-pattern month. Under the new reading ("independent failure calendars"), every month is an exception, so the callout's premise no longer holds. Drop the lavender callout from the dashboard layout.

**Dashboard assembly:** stack C-1 directly above C-2 in a vertical container with 0px gap so they read as one chart. Per-platform palettes need separate sheets — Tableau limitation.

**Caption — colors:** do **not** include a "(green palette) / (blue palette)" parenthetical in the subtitle. The row labels (`1/2/3` rendered in green text, `A/C/E` in blue text) already convey the mapping; restating it in prose creates an opportunity to type the wrong color and contradict the rest of the dashboard. *(2026-05-22 fix — reviewer caught the subtitle text reversed: it had read "1/2/3 (blue palette) / A/C/E (green palette)" which inverted the contract held everywhere else on the dashboard. Cleanest fix is to drop the parenthetical entirely; the colors speak for themselves.)*

---

## Incident Timeline + WA% over time (Sheets 2 + 3) — "Is the gap real?"

**Source:** `monthly_incidents_delays.csv` (Sheet 2 incidents) + `service_quality.csv` (Sheet 3 WA%)

> **2026-05-22 — feedback fix.** Sheet 3 was a stacked area chart of ridership over time, which (a) didn't visibly answer the section question (the question is about the **reliability gap**, not ridership), and (b) silently used corridor-wide `line_group` covering all 35 stations along 1/2/3 and A/C/E lines — so the y-axis read 4–9M while KPI 1 read ~2.9M (Penn-only). Both issues are resolved by replacing the ridership chart with a Wait Assessment % by platform over time line chart. Reliability is now drawn directly, month by month — the chart pair answers the section question on first read. Ridership stays surfaced on KPI 1.

**Section title (question form):** *Is the gap real, or just an average that hides bad months?*

**Sheet 2 — Incidents (grouped bars per month):**

> **2026-06-02 — feedback fix (Data School R3).** Original Sheet 2 was a stacked bar (`Line Group` on Color only, automatic stack). Reviewer flagged that stacking the two platforms makes individual platform heights hard to read — you can't compare green vs blue at a glance because they share a baseline that shifts month to month. Replaced with **grouped bars per month**: within each month group, the two platforms render as adjacent bars, so the reader sees green-vs-blue height directly. See `TABLEAU_BUILD_GUIDE.md` Step 4 (line 546) for the full implementation note, including a same-day revision from "two side-by-side panels" to "MONTH-outer / Line-Group-inner" grouping.

- Columns: `MONTH([month])` (discrete, **outer**) → `Line Group` (discrete, **inner**)
- Rows: `SUM([Signal+Track Incidents])`
- Mark type: Bar
- `Line Group` on **Color** (in addition to inner Columns) — green 1/2/3, blue A/C/E
- Inner `Line Group` field labels hidden (Color legend labels both platforms once for the whole chart)
- Filter: `Line Group IN ("1/2/3","A/C/E")` (Context), `Category IN ("Signals","Track")` (Context), `Year Match = TRUE` (Context)
- Sheet title (visible on dashboard): `Monthly Signal + Track incidents by platform`

**Sheet 3 — WA % over time (line chart):**
- Columns: `MONTH([month])` — **continuous** (right-click → Continuous; line charts need continuous x)
- Rows: `AVG([Wait Assessment Pct])`
- Mark type: **Line** (not Area)
- `Line Group` on **Color** — produces two lines, one per platform
- Filter (all in Context): `Period = 'peak'`, `Day Type = 1`, `Line Group IN ("1/2/3","A/C/E")`, `Year Match = TRUE`
- Y-axis: Edit Axis → fixed range `60` to `80`, format as percent with one decimal (`0.0"%"`), title `Wait Assessment % (peak weekday)`
- Sheet title (visible on dashboard, question form): `Does the gap hold every month?`
- Optional reference line: scope Table, value Average of `Wait Assessment Pct`, label `"Penn avg"`, dashed gray — makes the gap quantitatively visible against a neutral baseline.

**So-what box (below the stack):**
> The incident bars confirm the gap is structural, not a one-month anomaly — both platforms absorb comparable disruption month after month. And the WA% lines show the gap holds across nearly every month: 1/2/3 sits ~3–5 pp above A/C/E throughout the year, with A/C/E catching up year-over-year (toggle the year filter to see). The narrowing is structural improvement on A/C/E, not degradation on 1/2/3.

Place Sheet 3 directly below Sheet 2 in a vertical container with the same fixed width so the month axes align. The two charts now share a reading rhythm — incident stress (top) and the resulting reliability gap (bottom) — both anchored on the same time axis.

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

## Per-incident Severity (Sheet 5) — supporting "How bad is bad?"

**Source:** `monthly_incidents_delays.csv`

> **2026-05-22 — feedback fix.** Replaced the earlier box plot with a labeled horizontal bar chart. Reviewer flagged the box plot as analyst-heavy (dozens of overlapping monthly dots, dual visual layer of dots + box), and the chart paid that cognitive cost for an insight a simpler bar carries cleanly. The labeled bar reads in seconds and matches the dashboard's overall readability. Box plot variant archived for reference in `sample_dashboards/render_12_boxplot_colors.html`.

**Section title (question form):** *How bad is bad — per-incident severity?*

**Build:**
- Rows: `[category]` sorted descending by `AVG([Severity Ratio])`
- Columns: `AVG([Severity Ratio])` — Mark type: **Bar**
- Filter: `Incident Count` range min = 1 (Range of Values filter), `Day Type = 1` (Context), `Line Group IN ("1/2/3","A/C/E")` (Context), `Year Match = TRUE` (Context), `Category` ALL (Context for FIXED LODs)
- Color: muted gray `#94a3b8` for all bars, with red `#dc2626` accent on the **top-2 categories** (year-aware). Use calc field `Top Severity Highlight = IF RANK_UNIQUE([Severity Ratio], 'desc') <= 2 THEN "Alert" ELSE "Muted" END` on Color, with **Compute Using → Category** set on the pill (critical — without it the rank computes wrong). Adjust threshold: `= 1` for single-top accent, `<= 2` for top-2 (default), `<= 3` only if top-3 genuinely clusters apart from the rest. Manual coloring breaks when the year filter changes (Tableau stores only one set of color assignments), so calc-driven is the only robust path.
- Label: drag `Severity Ratio` to Label, format as `0" delays/inc"`. Final label per bar reads e.g. `97 delays/inc`. **Unit matches Sheet 4** (was `"× delay"` before — multiplier framing reads awkwardly at the actual magnitude of 80–110; `delays/inc` reads correctly at any magnitude).
- No platform split. The platform contrast lives on Sheets 6, 2, 3, and 4 — Sheet 5 just shows the severity hierarchy across causes.
- X-axis: title `Delay-causing incidents per major incident` (was `Trains delayed per major incident (proxy)` — `Real Delay` counts MTA delay-causing-incident reports, not literal trains).

**Annotation (on chart):** *Recommended: skip the annotation entirely.* Year-aware accent + year-aware labels + question-form title already carry the message; a static annotation creates a year-aware/static mismatch (the annotation doesn't move when the year filter changes). If you keep one, choose static for default year (`"{Category} delivers the worst-day severity — rare but catastrophic"` with `{Category}` typed in for the default year) or dynamic via a Mark Label calc that returns text only for the rank-1 bar.

**So-what box (Option 3):**
> "Other" and "Stations and Structure" deliver the worst per-incident severity — rare but catastrophic days. Signals and Track are mid-severity but frequent, driving most of the total delay minutes despite milder per-event impact. Severity dominates total delay; frequency dominates the daily rider experience.

**So-what box (Option 2 cost angle, if used as backup):**
> Signal failures span the widest range — that's the slice a Penn rider can't plan around. Track failures cluster tightly: a Track incident is bad but predictable; a Signal incident might cost an entire commute.

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

## Orient (Filtered Map — Sheet 7) — "Where are these two platforms?"

**MOVED above the KPI strip on 2026-06-02** per round-2 reviewer feedback (Salome): *"a spatial anchor before diving into the metrics."* The map sits immediately after the intro paragraph and **before** the KPI strip — every downstream metric (the +X pp WA gap KPI, the Trajectory's two lines, the Sheet 6 head-to-head) meets its "two platforms" referent first. See TABLEAU_BUILD_GUIDE.md Step 14 dashboard assembly table for the exact row order.

**Sources:** `dim_corridor_complexes.csv` + `monthly_ridership.csv` (post-2026-05-28 size encoding); fall back to `monthly_incidents_delays.csv` for the older `Real Inc` size if you haven't applied the May-28 upgrade.

**Section title (question form, reframed 2026-06-02):** *Where are these two platforms?* *(was `How close are the two platforms, really?` when slotted as qualifier — that question makes sense as a finale but lands flat as a setup; the new title is a literal setup question that the chart visibly answers in a glance)*

**Build:**
- Geographic roles: `latitude`, `longitude` from `dim_corridor_complexes`
- Size: `AVG(Ridership) / COUNTD(Month)` per complex (blend `dim_corridor_complexes` + `monthly_ridership` on `Complex Id`) — post-2026-05-28; the circle now scales with how many riders pass through, which is what matters when the map is the orienting card
- Color: `line_group` → green `#59a14f` for 1/2/3, blue `#4e79a7` for A/C/E
- Filter: **`Complex Id IN (318, 164)` only** (Option 3 refocus) — wider corridor complexes hidden
- Year filter: **NOT applied** (post-2026-05-28 recommendation; multi-year synthesis at the physical level reads consistently across year-views, and as an orientation card the map should not change with year selection)
- Background map: Tableau automatic (light theme), zoomed to mid-Manhattan so 318 and 164 dominate the frame; consider zooming closer post-move since the map is no longer at the bottom (more room to play with)

**Manual annotations on each dot** (added 2026-05-28; updated phrasing 2026-06-02 for orienting role):
- 1/2/3 dot: `1/2/3 platform · ~70% Wait Assessment · ~1.4M riders/mo`
- A/C/E dot: `A/C/E platform · ~66% Wait Assessment · ~1.4M riders/mo`

**So-what box (orienting frame, 2026-06-02):**
> Two platforms, one staircase apart. The 1/2/3 platform (green) and the A/C/E platform (blue) share Penn's complex on the surface but run separate operations underneath — different lines, different schedules, different reliability profiles. Circle size marks each platform's monthly ridership; the labels carry the metrics the rest of this dashboard will explain. **Same name, different odds — the rest of the dashboard tells you why.**

The so-what shifts the chart's *purpose* without changing its data: as the closer it asserted a finding ("the choice is worth ~4 pp"); as the orienter it teases what's coming ("the rest of the dashboard tells you why"). Each role earns the chart a place — but in different beats.

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

**Closer (Option 3 primary) — rendered text** *(year-dynamic; the live source is the `[Bottom Line Text]` calc field at the top of this file § "Canonical caption set" → "Bottom-line conclusion". This is what the calc renders for 2024; `pp` is defined on first use in the intro paragraph above the dashboard so the bottom-line keeps the abbreviation.)*:
> **The bottom line.** For the 2.92M paid entries at Penn each month — riders who often hold both options on their MetroCard — the data answers a single practical question: when both platforms are running, *take 1/2/3*. The A/C/E platform isn't unreliable — it's the second-best choice in a complex where the best choice is one staircase away.
>
> In 2024, 1/2/3 leads A/C/E by +3.8 pp on peak Wait Assessment — but that lead has been narrowing. The gap was +8.0 pp in 2022, +4.3 pp in 2023, and +3.8 pp in 2024, even as both platforms absorbed ~40% more major incidents over the period. A/C/E climbed from 61% to 66% while 1/2/3 held steady near 70% — the convergence is recovery operations, not a calmer system.
>
> The 1/2/3 still wins the head-to-head choice — and the choice matters most exactly when ridership peaks: *Tuesday 8 AM*, on both platforms.

**Closer (Option 2 backup, if pivoting):**
> **The bottom line.** The cost of a Signal failure at Penn isn't an abstraction — it's *N* trains delayed in the median case, *X* minutes in the worst, and *Y×* more if it happens at 8 AM Tuesday. Multiply that by *11 months* of failures and *~2.9M monthly entries*, and "reliability" stops being a metric and becomes a rider's everyday calculation. The data tells riders *when* to brace and operators *where* to invest.

**Caveats block (below the closer, separated by a 1px top border in `#1e293b`) — superseded 2026-05-28 by the rising-incidents caveats at top of this file § "Canonical caption set" → "Caveats block". Rendered text:**
> **Caveats:** Weekday peak-period data, 2022–2024. Wait Assessment measures peak-period headway adherence; it doesn't capture every dimension of "reliability." Major-incident counts rose materially on both platforms across the period — the WA improvements happened against a rising-load backdrop, not a calmer system. Stations beyond Penn on either trunk have their own outage profiles that differ from the platform averages shown here. Use the year filter above to see how the gap evolved.

### Color treatment (revised 2026-06-02 per round-2 reviewer feedback — replaces block-level magenta)

The intro paragraph, bottom-line closer, and caveats block previously rendered as all-magenta text — flagged as design-accent-not-semantic-signal. New treatment uses the platform palette for phrase-level emphasis instead, so color does the same semantic work it does in the charts.

**Intro paragraph (light `#faf8f4` background):**
- Body text: dark slate `#0f172a`
- `1/2/3` mentions → green `#59a14f` bold
- `A/C/E` mentions → blue `#4e79a7` bold
- Numbers (`+8.0 pp`, `~2.9M`, `61% to 66%`, `near 70%`, `40% more`) → bold dark slate (no color)
- Closing line `Same name, different odds — narrowing.` → italic, body color

**Bottom-line closer (dark `#0f172a` background):**
- Body text: light gray `#cbd5e1`
- `take 1/2/3` → light green `#86efac` bold italic (the only italic call-out — single call to action)
- Other `1/2/3` mentions → light green `#86efac` bold (no italic)
- `A/C/E` mentions → light blue `#93c5fd` bold
- Numbers → near-white `#f1f5f9` bold

**Caveats block (dark `#0f172a` background, smaller font):**
- Body text: muted gray `#94a3b8` — deliberately de-emphasized
- `Caveats:` label and key terms (`Wait Assessment`, `rising-load backdrop`) → near-white `#f1f5f9` bold

### Typography sizes (revised 2026-06-02 per round-2 reviewer feedback — text-size bump for readability)

Round-2 feedback flagged that the dashboard's body text and chart annotations sit around ≤ 12pt — a strain to read and easy to skim past. The bump moves the body up one tier across the board while leaving section titles where they already are (they were never the problem). At 14pt body inside a 770px width cap (item 6), each line settles at ~70–80 chars — the comfortable newspaper-column zone.

| Element | Previous | New | Notes |
|---|---|---|---|
| Section title (`card-title`) | 14pt | **16pt** | Was on the edge of "small chart title"; bumps to a confident size. Above-chart shared titles (Sheet 6 centerpiece title) can go to 18pt for emphasis. |
| Body / so-what (`.insight`) | 11–12pt | **13–14pt** | The biggest leverage — this is the prose the reviewer actually reads. |
| Chart caption / sub-title (`card-subtitle`) | 11pt | **12pt** + darker color (`#475569` vs `#94a3b8`) | Color bump matters as much as size — `#94a3b8` was the size-equivalent of greyed-out. |
| KPI tile body (`kpi-desc`) | 11pt | **12pt** + color bump to `#94a3b8` (was `#475569` — invisible on dark tile) | Note: KPI tile body color was *darker* than the dark tile background, so it read as no contrast. Both size and color need to bump. |
| KPI tile label (`kpi-label`) | 9pt | **10pt** + color `#94a3b8` | Tiny label sat on the dark tile. |
| Intro paragraph body (`hl-text`) | 17pt | **18pt** | Already prominent; small bump for headline weight. |
| Footer body | 13pt | **14pt** (already applied in Group A) | Group A touched this; listed here for completeness. |
| Caveats | 11pt | **12pt** (already applied in Group A) | Same. |
| Chart axis tick labels (SVG) | 9pt | **11pt** | Bump in Tableau via Format → Worksheet → Axes. |
| Chart annotations (manual marks) | 10pt | **12pt** | Bump in Tableau via Format → Annotations. |
| Sheet 6 axis sub-titles | 11pt | **12pt** (already applied in Group A) | Same. |

**Sweep approach in Tableau:** Format → Workbook (top menu) → set the default font size for **Worksheet > Worksheet Title** to 16pt, **Tooltip** to 12pt, and rely on per-sheet overrides for the few chart-specific cases. Per-sheet axis ticks and annotations: set per sheet (Tableau doesn't have a workbook-level "axis font" toggle).

### Width cap (added 2026-06-02 per round-2 reviewer feedback — line-length break-up; SCOPE CORRECTED to so-what insight boxes only)

Salome's round-2 item 6 flagged *"annotation/analysis text sections"* spanning the full dashboard width — meaning the **so-what insight callout boxes under each chart**, not the intro paragraph, bottom-line, or caveats (those are headline/footer blocks, not analysis text). Initial application of the 770px cap to all three prose blocks was a misread; corrected 2026-06-02 same day.

**Width-capped at 770px (left-aligned):**
- So-what insight boxes under **full-width** chart cards: Sheet 6 (centerpiece), Sheet 7 (map), Sheet 2+3 shared so-what, Sheet 4a, Sheet 8, Sheet 5 supporting. These previously ran 100+ chars/line at small font — hard to read.
- Manual chart annotations (the `Annotate → Mark` callouts) if they hold prose-length text.

**NOT width-capped (stay full-width):**
- Intro paragraph — headline-style; its job is to span the top.
- Bottom-line — dark-card footer with its own design context; the 3 short paragraphs are visually framed by the card.
- Caveats — small footer text; one paragraph; already short.
- So-what boxes on **half-width** chart cards (e.g. Sheet 4 + Sheet C side-by-side) — already width-bounded by their parent card (~600px each at the dashboard's 1280px); no extra cap needed.

In Tableau: for each full-width chart's so-what text object, set Floating Width 770px and left-align inside the parent container. At the post-Group-B body size of 14pt this gives ~70–80 chars per line — the comfortable newspaper-column zone Salome's referenced reader (Otto Richardson, "Tips for Building Dashboards that Reduce Cognitive Load") recommends.

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
