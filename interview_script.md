# Data School Interview — Script & Prep

Target: ~5:00 viz walkthrough + short answers for "Tableau learning" and "about yourself."

---

## Part 1 — Dashboard walkthrough (5 minutes)

### [0:00 – 1:00] Hook + origin story

> This dashboard is called *Inside Penn Station*. It started from something I noticed almost by accident.
>
> Penn Station was actually the hub I knew best to begin with — whenever I travel to NYC, I transfer there — so when I started exploring MTA data, that's where my curiosity went first. I thought of it as one big station: biggest in the system, around 2.9 million paid entries a month.
>
> But when I was matching the data to the official station list, **Penn Station shows up twice**. There's one complex for the 1/2/3 platform, and a separate one for the A/C/E. Same name, listed as two separate places — about a staircase apart.
>
> **I'd been walking through Penn Station for years without realizing I was actually walking between two different stations.** So I dug in: are these actually the same experience? They're not. And the gap between them is closing fast.

### [1:00 – 1:30] Map + KPI strip — *why these first*

> I lead with a map because before we talk about percentages, I want you to *see* what we're comparing. These two dots — same building, two services, one staircase apart.
>
> Then a quick scale read in the KPI strip: **2.9 million** paid entries a month, **six routes** converging, and the headline I'll explain next — a **3.8 percentage point** reliability gap between the two platforms in 2024. I put scale before story because the numbers downstream don't mean much until you know how big this place is.

### [1:30 – 2:15] Wait Assessment — the standout metric

> Before I show you that gap, one quick definition — because the metric this whole dashboard rests on is something called **Wait Assessment**, and it's worth understanding properly.
>
> Wait Assessment is *not* "was the train on time." It measures the **gap between trains**. The MTA sets a target — the scheduled interval plus 25% — and Wait Assessment is the share of waits that came in under that target. So if trains are supposed to come every 4 minutes, the question is: **what fraction of the time was your actual wait 5 minutes or less?**
>
> I chose Wait Assessment over standard on-time performance because it matches what you actually experience as a rider. You don't have the schedule memorized. You just know whether you've been standing there too long. That's what this number captures — and that's why it's the backbone of the dashboard.

### [2:15 – 2:45] Trajectory — the closing gap

> This chart is peak weekday Wait Assessment over time. Green is the 1/2/3 platform; blue is the A/C/E. The 1/2/3 platform has led every year measured — but look at the convergence. In 2022, the gap was **8 points**. By 2024, it's down to **3.8**. The 1/2/3 platform has held steady near 70%; the A/C/E has climbed from 61% to 66%.
>
> I put this chart up front because it's the headline. Everything below is me defending it.

### [2:45 – 3:00] Is the gap real?

> First defense — is this real, or just a noisy average? Monthly Signal+Track incidents show both platforms absorbing stress in consistent patterns all year. The monthly incident quilt adds the per-platform breakdown: bad months hit each platform independently, yet 1/2/3 still carries more events overall. And monthly Wait Assessment shows the 1/2/3 platform winning on reliability **every single month**. Structural difference, not noise.

### [3:00 – 3:50] Why does the gap exist? — the surprise

> Then — *why*? This is the part where the data surprised me, and it's why this question needed two charts working together — one to land the surprise, one to dig into it.
>
> This first one — the cause ladder — breaks incidents into categories: signals, track, people on the trackbed. You'd assume the more-reliable platform has *fewer* incidents. But the 1/2/3 platform has **more** across all three top categories.
>
> I built the second chart specifically to dig into that surprise — total incidents per platform per year, across all categories. Both platforms saw about **40% more incidents** from 2022 to 2024. The 1/2/3 platform went from 87 to 124. A/C/E from 74 to 101.
>
> So the gap isn't closing because A/C/E has fewer problems. It's closing because they're **recovering better from a rising number of problems**. Recovery-operations story, not prevention. That reframed how I thought about the whole comparison.

### [3:50 – 4:20] Heatmap — when does it matter?

> Last question I wanted to answer: when does this actually matter? This heatmap is day of week against hour of day. The darkest cell for both platforms is **Tuesday at 8 AM** — peak commute. Most riders, highest risk. Which is exactly when even a 4-point reliability difference saves the most people the most time.

### [4:20 – 4:50] Honest qualifier + close

> One caveat I called out: the gap isn't closing because the 1/2/3 platform is degrading — it's closing because A/C/E is recovering against rising incidents on **both** platforms. That's an important nuance for how to read the trend.
>
> So the bottom line: Penn Station is two platforms. The 1/2/3 platform is still more reliable. The gap is shrinking. And the data tells us *why* — it's a recovery story, not a prevention one.

---

## Part 2 — "Tell me about your experience learning Tableau" (~90 seconds)

> My Tableau experience really started with this dashboard. It's the first end-to-end Tableau project I've built.
>
> I started where I think most people start — the Tableau docs, a few YouTube channels, a lot of clicking around. The first thing that surprised me was how *much* of Tableau is calculations. I came in expecting drag-and-drop charts. What I quickly realized is that the interesting decisions live half in SQL — like deduplicating shuttle services that show up under both legacy and GTFS codes — and half in calculated fields, like collapsing a Cartesian join back to the right row count, or comparing two platforms fairly. That was the first mental shift for me: Tableau isn't a chart tool, it's an analytical environment that happens to render visually.
>
> The specific thing I'm most proud of figuring out was performance. The hourly ridership data was about **789,000 rows** — enough that the dashboard felt sluggish on Tableau Public. I pre-aggregated upstream in Postgres down to about **15,000 rows**, and the dashboard went from sluggish to instant. That was the moment my data-engineering instincts and Tableau actually clicked together — the realization that what you choose *not* to load matters as much as what you choose to chart.
>
> The other thing that taught me a lot was iteration. My first version was more of a report than a story — I'd built what I thought a dashboard was supposed to look like, just a grid of charts. I went through **multiple rounds of revision** after that, and almost every round taught me something I couldn't have learned just by reading. Things like — phrasing a chart's title as a question forces the chart to actually answer something. That kind of judgment is hard to absorb from a tutorial; you only really learn it when somebody pushes back.

---

## Part 3 — "Tell me a little about yourself" (~75 seconds)

> I'm a data engineer by background. I've spent years building pipelines — cleaning data, modeling it, serving it to reporting teams. The way I usually describe my job is **making data available**.
>
> What pulled me toward analytics is that for years I'd watch the reporting team turn the same tables I'd built into dashboards that revealed patterns I hadn't seen. I always wondered how they got there. **This MTA dashboard is the first time I've sat in that chair myself.**
>
> About a month in, what surprised me was how much of the analytical work actually happens at the chart-design stage — choosing what question a chart should answer, which gap to surface, which caveat to keep honest. From the engineering side, those calls had been invisible to me.
>
> The Data School is what I'm looking for to learn this properly. The rotation model means **real client work and fast feedback**. The cohort means people to learn alongside, not just from. And honestly, short cycles with real stakes is the closest thing to how I actually learn.
>
> What I think I'd bring is the engineering side of the equation — clean pipelines, end-to-end thinking, the patience for the unglamorous data work — paired with a beginner's curiosity about everything downstream of it.

---

## Part 4 — Likely follow-up questions

**"What was the hardest part of building this?"**
> The narrative pivot. I started with a cost-of-delay angle, but when I saw the two-platforms split in the data, I had a real question to answer instead of a general problem to describe — and that meant rebuilding the dashboard around it. Letting the data redirect the thesis was harder than building the charts. The narrative didn't come from a thesis I picked at the start — it came from each round of feedback exposing a claim the current framing couldn't honestly carry. By the final round, the story was the version the data actually defended, not the version I'd planned.

**"What would you do differently?"**
> I'd start with the question, not the data. I built charts to display the data, not to answer specific questions — and round 1 of feedback was mostly about rebuilding them so each chart delivered an answer instead of just an observation.

**"What chart are you proudest of?"**
> The cause-side trajectory. It's the chart that turned a surprise into a thesis — once I saw the 1/2/3 platform had *more* incidents but better reliability, I needed something that showed total volume over time to prove it was a recovery story, not a prevention one.

**"What chart was hardest to build?"**
> Same one, actually — the cause-side trajectory. Two reasons. First, it was built last, specifically to test a hypothesis the data had raised, so I had to design the encoding — what goes on each axis, what gets colored, how the bars are grouped — around the question, not pick a chart type and force the question to fit. Second, every other chart on the dashboard respects a Year Filter parameter — you can switch between 2022, 2023, and 2024 — but this one has to show all three years at once. Carving out the exception without breaking the filter wiring on every other chart was the fiddly part.

**"What about severity? Is the reliability gap about big incidents or small ones?"**
> It's about frequency, not severity. The per-incident severity chart ranks incident categories by how bad each individual event is. Signals dominate the volume but rank middle on per-incident severity — the worst severity actually sits with rare causes like 'Other' and 'Stations and Structure.' Fewer events, but much heavier when they hit. So the reliability gap rides on how often things happen, not how bad each one is — which fits the recovery-operations story.

**"What's a Tableau feature you want to learn next?"**
> Parameter actions and dashboard actions for interactive drilldowns. Mine is a fairly static narrative dashboard; the next thing I want to build is something a user can navigate.

**"So how often do you transfer at Penn Station?"**
> Warm-conversation question, not technical. Give the honest answer ("a few times a year" or whatever's true). The fact that you *have* a real answer is the whole point.

---

## Part 5 — Chart reference (data sources & what each measures)

Quick reference for if an interviewer drills into any single chart. The pipeline is the same for every chart: **raw CSVs from data.ny.gov → Postgres star schema (cleaned, modeled, deduplicated) → pre-aggregated Tableau CSVs → Tableau workbook.**

| Chart | What it measures | Source dataset (data.ny.gov) |
|---|---|---|
| **Map** | Physical location of Penn Station's two complexes (318 = 1/2/3, 164 = A/C/E), sized by monthly ridership, with WA% annotations | MTA Subway Stations and Complexes |
| **KPI strip** | 4 metrics: paid entries/month, routes converging, months hit by Signal/Track, peak WA gap | Hourly Ridership + Major Incidents + Wait Assessment |
| **WA Trajectory chart** | Peak weekday Wait Assessment % per platform across 2022–2024 (multi-year — does *not* respect the Year Filter) | MTA Subway Wait Assessment |
| **Reliability head-to-head** | Peak weekday Wait Assessment % and Terminal On-Time Performance % per platform, side-by-side bars | Wait Assessment + Terminal On-Time Performance |
| **Incidents over time** | Monthly incident counts per platform, grouped bar chart (1/2/3 vs A/C/E shown side-by-side per month) | MTA Subway Major Incidents |
| **WA over time** | Monthly peak weekday WA% per platform, line chart | MTA Subway Wait Assessment |
| **Monthly Incident Pattern quilt** | Monthly incident pattern as a highlight table, per-platform color palette, all categories | MTA Subway Major Incidents |
| **Cause Ladder** | Incident count by category (Signals, Track, Persons on Trackbed, etc.), split by platform | Major Incidents + Delay-Causing Incidents |
| **Cause-side trajectory** | Total annual incidents per platform per year, all categories combined (multi-year — does *not* respect the Year Filter) | MTA Subway Major Incidents |
| **Per-incident severity** (supporting) | Per-incident severity (delays caused per incident) by category | Major Incidents + Delay-Causing Incidents |
| **Day × hour heatmap** | Ridership at Penn Station complexes by day of week × hour of day | MTA Subway Hourly Ridership |

### If they ask broader data questions

**"Where does the raw data come from?"**
> All from **data.ny.gov** — New York State's open data portal. The MTA publishes incident counts, delay counts, Wait Assessment, on-time performance, hourly ridership, and the station/complex reference all there.

**"How fresh is the data? What time range?"**
> The dashboard covers **2022–2024**. The MTA updates these datasets monthly, so the pipeline could be re-run to extend the range whenever new data is released.

**"Did you clean the data yourself?"**
> Yes — that was about half the project. The hourly ridership came in at ~789,000 rows with mixed date formats. The Wait Assessment dataset had shuttle codes that appeared under both their legacy names (`S 42nd`, `S Fkln`, `S Rock`) and the GTFS codes (`GS`, `FS`, `H`) from 2024 onward — loading both would have double-counted. All of that got handled in Postgres before anything reached Tableau.

**"How did you tie the incident data to specific stations?"**
> That was the join problem at the heart of the data model. Incidents are reported by **line** (1, 2, A, C, etc.), not by station. So I had to use a GTFS routes table to map line codes to route IDs, then a bridge table to map route IDs to the complexes they serve. Once that was wired up, I could ask "which incidents happened on routes that serve Penn Station?" — which is what every chart on the dashboard ultimately answers.

### If they ask about design choices

**"Why is the map at the top instead of the KPI strip?"** *(breaking the KPI-first convention)*
> Convention says KPI first, but I moved the map up because a reviewer flagged that readers needed the spatial anchor before the metrics made sense. The dashboard's whole premise is that Penn Station is actually two platforms — so I wanted readers to *see* that physically before any KPI references "the platform gap." The intro paragraph plants the idea verbally, the map reinforces it visually, and by the time the reader reaches the KPI strip the two-platform framing is already concrete. It breaks convention on purpose, in service of narrative clarity.

**"Why are all the chart titles phrased as questions?"** *(question-form titles)*
> Forcing the title to be a question forces the chart to answer one. If the title is a noun phrase like "Monthly incidents by platform," the chart can be informational without delivering a point. If the title is "Is the gap real?", the chart has to land an answer or it fails its own headline. The judgment came out of my second round of feedback — and it's the single biggest shift in how I think about charts now.

**"Why do some charts show all three years and others just the active year?"** *(trajectory charts ignore the Year Filter)*
> Most of the dashboard responds to a Year Filter — you can switch between 2022, 2023, and 2024 to see what each year looked like. But two charts deliberately ignore the filter: the Wait Assessment trajectory chart and the cause-side trajectory chart. Their entire purpose is the multi-year change — if either only showed one year, it'd be a single snapshot, and the closing-gap story would disappear. The rule I settled on: snapshot questions respect the filter; trajectory questions skip it. Mild inconsistency for the sake of letting both reads coexist.

**"Why green and blue for the platforms?"** *(color encodes the comparison)*
> Color tracks the thing you're being asked to compare. The central comparison of the dashboard is between platforms, so color encodes platform — green for 1/2/3, blue for A/C/E. Incident categories like Signals and Track stay grayscale on most charts because they're not the central comparison, they're just sorted ranks. The one exception is the per-incident severity chart, which uses a red accent on the top-severity category — because that chart's question is "which cause is worst?", not "which platform is better?"

**"Why did you replace the box plot on the severity chart with a labeled bar?"** *(iteration on chart type)*
> The per-incident severity chart was originally a box plot showing severity per category, with one dot per month. A reviewer flagged that it was analyst-heavy — dozens of overlapping monthly dots forced the reader to do statistical work just to read the chart. I replaced it with a labeled horizontal bar: one bar per category, severity ratio printed as a label, red accent on the top-two highest-severity categories. Same severity hierarchy, readable at a glance. The lesson I took: if a chart requires the reader to be an analyst, the chart isn't doing its job.

**"Why only Penn Station — why not a wider geography?"** *(scope choice)*
> An earlier version of this dashboard covered 35 stations across a wider corridor. I narrowed it to Penn Station because the closing-gap story only holds at the platform level — averaged across many stations, the gap dissolves into noise. Penn is also the biggest hub in the system, which gives the dashboard a concrete "where" rather than an abstract corridor average. Smaller scope, sharper claim.

---

## Part 6 — Prep frameworks (internal notes, not scripted)

Two questions you should have a clean answer to but probably won't be asked verbatim: *"how did you make your chart choices?"* and *"how did the narrative take shape?"* These are prep frameworks, not lines to memorize — internalize the logic so you can speak fluently when an interviewer probes either angle.

### Chart choices — "question → chart type, not chart type → question"

The strongest answer demonstrates each chart exists *because* a specific question demanded a specific encoding, not because it was on a Tableau catalog. You already seeded this in Part 4 ("design the encoding around the question"). To extend it, walk the interviewer through 1-2 charts where the choice was non-obvious.

**Language patterns:**
- *"The question was X, and that ruled out [chart type]. I needed [encoding] because [reason]."*
- *"That chart's job is to answer one specific question — [Q]. So I picked the encoding that delivers the answer in the fewest seconds."*
- *"I tried [first attempt] and it didn't land because [problem]. The version I shipped reads in one glance because [encoding choice]."*

**Strongest concrete example to keep loaded:**
- **Cause Ladder.** Question: "do both platforms see the same kinds of failure?" Originally dual-axis (bar = count + circle = severity, sharing one x-axis). Reviewer flagged that one axis was doing two semantic jobs. Replaced with single-axis bars where severity lives in the bar's label suffix (`38 · 3.2× delay`). One encoding per visual channel. Reads in seconds. *This is the example to lead with because it has a clear before/after with a documented reason — editorial judgment is visible, not just claimed.*

**Backup examples** (pull only if pressed for more):
- **Reliability head-to-head:** split into two side-by-side panels (WA + OTP) so the eye reads them as parallel verdicts rather than competing on one axis.
- **Day × hour heatmap:** the only chart type that surfaces a single peak across two categorical dimensions without forcing a mental crosstab.
- **Monthly Incident Pattern quilt:** two stacked rows put both platforms' calendar rhythms on one grid; a small-multiple alternative would force the reader to compare two separate charts.

### Narrative shape — "what I started with → what the data taught me → what I shipped"

This question is really asking: *can you let the data redirect you, and can you tell that story honestly?* You've nailed a piece of this in Part 4's "narrative pivot" answer. To extend it, talk about *iteration*, not eureka.

**Language patterns:**
- *"I started with [framing X]. When I looked at the data, [observation Y] changed what the dashboard could honestly claim — so I rebuilt around [framing Z]."*
- *"The thesis didn't arrive all at once. It went through multiple versions, and each round of feedback exposed something the current framing couldn't carry."*
- *"The narrative shape is downstream of two things: what the data actually supports, and what question a reader would naturally ask next."*

**The arc, in beats you can pace yourself through:**
1. **v2 cost-of-delay framing — rejected.** *"Started here because I thought the story was NYC commuter cost, but the wide corridor leaned on stations that weren't in the dataset, so I couldn't honestly defend it."*
2. **Pivot moment.** *"Saw 1/2/3 = 69.6% WA vs A/C/E = 65.8% at the same complex. That's when I realized I had a real comparison to draw — same building, two services, measurably different reliability."*
3. **First v3 round.** *"A reviewer pointed out the closing-gap claim lived only in the title — every chart was single-year. Added two trajectory cards so the headline gets chart-verified inside the dashboard, not just claimed."*
4. **Round-2 honest reframe.** *"Discovered 1/2/3 actually carries more incidents than A/C/E. That broke the original cause-ladder framing — rewrote it as 'same problem, faster recovery,' which turned out to be the more interesting story anyway."*

**The meta-line that ties it all together (potential closer for the "hardest part" or "what would you do differently" answer):**
> *"The narrative didn't come from a thesis I picked at the start — it came from each round of feedback exposing a claim the current framing couldn't honestly carry. By the final round, the story was the version the data actually defended, not the version I'd planned."*

### How to deploy this in the room
- If asked literally *"how did you make your chart choices?"* — lead with the cause-ladder before/after, then surface the underlying rule ("one encoding per visual channel; question first, chart type second").
- If asked *"how did the narrative take shape?"* — don't recite the four beats. Pick one pivot moment (the v2 → Option 3 flip, or the recovery-not-prevention reframe) and tell *that* story; the four-beat structure is for *you* to organize the answer, not for them to hear.
- If asked something adjacent (*"what surprised you?"*, *"what did you change?"*) — the same content works, just lead with the surprise instead of the framework.

### Major Incidents vs Delay-Causing Incidents — "earthquakes vs aftershocks"

You're using **two** MTA incident datasets that look similar but measure different things. Be ready for *"why two? which one is the 'real' incident count?"* — it's a credible data-fluency probe.

**The frame to hold in your head:**

| | Major Incidents | Delay-Causing Incidents |
|---|---|---|
| **Counts** | Service-affecting events meeting MTA's "major" bar | Every event that delayed any train, no matter how small |
| **Magnitude** | One major incident ≈ **80–110** downstream delay-causing reports | ~100× higher row counts than majors |
| **Category system** | 6 **physical / infrastructure** buckets: Signals · Track · Subway Car · Stations and Structure · Persons on Trackbed/Police/Medical · Other | 6 **operational / cause** buckets: Crew Availability · External Factors · Infrastructure & Equipment · Operating Conditions · Planned ROW Work · Police & Medical |
| **Time scope** | 2015+ | 2020+ |
| **Where it shows up** | KPI 3, Sheet 2, Cause Ladder, Cause-side trajectory, the quilt | Cause Ladder severity suffix, Per-incident severity chart |

**The memorable one-line framing:**
> *"Major Incidents are the earthquake count — rare, big, named by physical cause. Delay-Causing Incidents are the aftershock log — frequent, granular, named by operational cause. Each answers a different question, so I use both."*

**Why this matters technically (have this loaded for SQL questions):**
> *"The two datasets don't share a category system, so the LEFT JOIN on `(month, line, day_type)` creates a Cartesian product — every major-incident category pairs with every delay-causing-category in the export. Raw `SUM` over-counts. I built `Real Inc` and `Real Delay` as `{FIXED}` LOD dedup calcs to collapse the cross-product back to true row counts, and promoted Category / Line Group / Day Type to Context filters so the LODs see the right scope."*

That second paragraph is the technically heaviest answer in the script. Only land it if the interviewer is technical and pushing for SQL/Tableau internals — for a non-technical interviewer, stop at the earthquakes-vs-aftershocks line.

### Data lineage — raw CSV → Postgres → Tableau export → chart

Likely interviewer probes: *"walk me through your data pipeline,"* *"how does the raw data get into Tableau?"* *"why did you pre-aggregate?"* This table is the answer to all three at a glance.

**The frame to lead with:**
> *"Raw CSVs from data.ny.gov get loaded into Postgres staging, transformed into a star schema with facts and dimensions, then aggregated out into five flat CSVs that Tableau reads. Two layers of normalization upstream means Tableau is a presentation layer, not a data-prep layer — which is what made the 789K → 15K performance win possible."*

**Lineage at a glance:**

| Raw CSV (`datasets/`) | → Postgres fact/dim (`mta` schema) | → Tableau export (`tableau_exports/`) | Consumed by |
|---|---|---|---|
| **Major Incidents** (2015+) | `fact_major_incidents` | `monthly_incidents_delays.csv` *(joined with delays; Cartesian-product trap; deduped via `Real Inc`)* | KPI 3 · Incidents over time · Cause Ladder · Cause-side trajectory · Monthly Incident Pattern quilt · Per-incident severity |
| **Delay-Causing Incidents** (2020+) | `fact_delay_causing_incidents` | same CSV as above | same set; supplies the delay-side severity ratio |
| **Wait Assessment** (2015+) | `fact_wait_assessment` | `service_quality.csv` *(joined with OTP)* | KPI 4 · WA Trajectory · Reliability head-to-head · WA over time |
| **Terminal OTP** (2015+) | `fact_otp` | same CSV as above | Reliability head-to-head |
| **Hourly Ridership** (2024+) | `fact_hourly_ridership` | `hourly_ridership_corridor.csv` + `monthly_ridership.csv` *(pre-aggregated from ~789K → ~15K rows for Tableau Public)* | KPI 1 · Map (size) · Day × hour heatmap |
| **Stations and Complexes** | `dim_complex` | `dim_corridor_complexes.csv` | Map |
| **GTFS `routes.txt`** | `dim_route` + `bridge_complex_route` | *(not exported; powers SQL joins between facts and complexes)* | every chart indirectly |
| **Daily Ridership** (2020+) | `fact_daily_ridership` | *(not exported; isolated — no station or route join possible)* | — |
| **Trains Delayed** (2020+) | *(not loaded)* | — | — |

**Three things this table lets you say confidently:**

1. **"Tableau is a presentation layer, not a data-prep layer."** Everything heavy — joins, dedup, type casts, pre-aggregation — happens in SQL before Tableau ever sees the data. That's the data-engineering instinct the dashboard is built on.
2. **"Pre-aggregation is the reason Public performs."** The hourly ridership row goes from ~789K rows in the raw CSV down to ~15K rows in the Tableau export, because the grain you actually visualize is hour × complex × line_group, not transaction-level. The ~50× reduction is what made Tableau Public render instantly instead of sluggishly.
3. **"The Cartesian-product trap was the trickiest design challenge in the export layer."** Major Incidents and Delay-Causing Incidents have different category systems but you need both for the cause-and-severity story — so the export LEFT JOINs them on `(month, line, day_type)` and produces a cross-product CSV that the `Real Inc` / `Real Delay` LOD calcs dedup inside Tableau. The trade-off: one wide CSV is simpler to ship and maintain than two narrow ones, at the cost of needing dedup discipline on every consuming sheet.

---

## Delivery notes

### Pacing
- Target ~150 words/min — that's conversational. The script is tight to 5:00, so if you tend to speed up under nerves, target 4:30 in practice for a buffer.
- The walkthrough has natural pause breaks at every section heading. Use them.

### Numbers that must land cleanly
- **"8 points down to 3.8"** — the closing gap
- **"40% more incidents on both platforms"** — the recovery insight
- **"789K to 15K rows"** — the technical anchor in the Tableau learning answer

If a non-data listener remembers three things, those are the three.

### Where to slow down
- **Wait Assessment definition (1:30 – 2:15).** This is the metric the whole dashboard rests on. Don't rush it.
- **Cause-ladder surprise (3:00 – 3:50).** "More incidents but still more reliable" is counterintuitive — give the listener a beat to absorb it.

### Where to cut if you're over time
- The "Is the gap real?" section (2:45 – 3:00) is already trimmed to one sentence. You can skip it entirely if needed and the story still holds.
- The honest qualifier (4:20 – 4:50) can compress to: *"One caveat — the gap is closing because A/C/E is recovering, not because the 1/2/3 platform is degrading. It's a best-case operations gain."*

### The single best line
> "I'd been walking through Penn Station for years without realizing I was actually walking between two different stations."

Land this one cleanly. It compresses the entire premise of the dashboard into one sentence the interviewer will remember.

### "Practice with a non-data person" hint
When you rehearse, ask them at the end: *"What's the gap, and why is it closing?"* If they can't answer in their own words, the section that lost them needs simplifying — not more detail.

### One last thing
You don't need to deliver this perfectly. You need to deliver it like someone who actually built it and actually cares about the answer. The interviewer is listening for that, not for polish.
