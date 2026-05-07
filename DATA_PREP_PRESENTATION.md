# MTA "Transfer of Stress" — Data Preparation Walkthrough

**Project:** Tableau dashboard for The Data School application
**Question:** When Signal or Track incidents hit lines serving Penn Station, how many thousands of commuters were exposed?
**Prepared:** April 2026

> ⚠ **Historical artifact.** This slide deck documents the *data preparation work* for the v1 walkthrough presentation (April 2026). The data prep approach described here (bridge table, line→complex join, three-way overlap) is still the active pipeline. **The dashboard narrative has since pivoted twice:**
>
> - **v2** (post-April 2026): Penn + WTC corridor narrative — see archived spec in `DASHBOARD_MODEL.md` § "What changed from v2 → v3" and `sample_dashboards/render_9_synthesis.html`.
> - **v3** (current, primary): "Inside Penn — Two Platforms, Two Reliability Stories" — see `CLAUDE.md`, `DASHBOARD_MODEL.md`, `TABLEAU_BUILD_GUIDE.md`, `sample_dashboards/render_11_option3_platforms.html`.
> - **v3 backup:** "What It Costs to Enter NYC Through Penn Station" — `sample_dashboards/render_10_option2_cost.html`.
>
> Slide 14 of this deck describes the v1 dashboard layout/KPIs and is preserved for the historical record. For current dashboard guidance, treat the docs above as the source of truth.

---

## Slide 1 — What We Started With

Five raw CSV files from data.ny.gov, downloaded April 27 2026.

| File | Rows | Grain | Date range |
|------|------|-------|-----------|
| `MTA_Subway_Major_Incidents` | 5,594 | month × line × day_type × category | Jan 2015 – Mar 2026 |
| `MTA_Subway_Trains_Delayed` | 17,895 | month × line × day_type × reporting_category | Jan 2020 – Mar 2026 |
| `MTA_Subway_Stations` | 496 | one row per physical stop | static |
| `MTA_Subway_Hourly_Ridership` | 681,767 | hour × station_complex × fare_class | Jan 2020 – Dec 2024 |
| `MTA_Final_Dataset` | 60 | pre-built monthly Penn Station summary | Jan 2020 – Dec 2024 |

**First decision made:** the ridership file had already been filtered to Penn Station only (complexes 318 and 164) before it was checked in. The 681,767 rows are the result of hourly grain × 12 fare classes × 60 months across two physical complexes. This was verified by confirming the file contains exactly two `station_complex_id` values.

---

## Slide 2 — The Structural Problem: Two Languages, No Translator

After reading all four raw files, one problem stood out above everything else.

**Incidents and Delays speak line language.**  
Their join key is a line code: `"1"`, `"A"`, `"JZ"`.  
They have no concept of which station or complex a line serves.

**Ridership and Stations speak complex language.**  
Their join key is a `station_complex_id` integer: `318`, `164`.  
They have no column for which line serves that complex.

There is no column in either half of the model that naturally joins to the other.

```
INCIDENTS  ──► line = "1"               ╳  no path to station
RIDERSHIP  ──► station_complex_id = 318  ╳  no path to line
```

This is why the bridge table exists. Without it, Tableau has no way to connect incident counts to rider counts. You would be forced to either:
- Hard-code the Penn Station filter directly in Tableau (works for this dashboard, breaks for any other hub), or
- Build the bridge table once and have a reusable, correct join for any hub.

We chose the bridge table.

---

## Slide 3 — Building the Bridge Table

The `Stations` file has a column called `Daytime Routes` that stores space-delimited line tokens:

```
Complex ID 318 → Daytime Routes = "1 2 3"
Complex ID 164 → Daytime Routes = "A C E"
Complex ID 611 → Daytime Routes = "N Q R W 1 2 3 7 A C E S"
```

The bridge table was built by parsing this column — splitting on spaces and emitting one row per `(line, complex_id)` pair.

**Script (10 lines, Python built-ins only):**
```python
import csv

rows = []
with open('datasets/MTA_Subway_Stations_20260427.csv', newline='', encoding='utf-8') as f:
    for r in csv.DictReader(f):
        for line in str(r['Daytime Routes']).split():
            rows.append((line.strip(), int(r['Complex ID'])))

seen = set()
with open('datasets/bridge_line_station.csv', 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['line', 'complex_id'])
    for row in sorted(rows):
        if row not in seen:
            seen.add(row)
            w.writerow(row)
```

**Result:** 767 unique `(line, complex_id)` pairs covering the entire subway network.

**Verified against live data.ny.gov API** — complex IDs 318 (lines 1,2,3) and 164 (lines A,C,E) confirmed correct.

---

## Slide 4 — The Full Join Path (After Bridge Table)

```
INCIDENTS ──[line]──► BRIDGE ──[complex_id]──► STATIONS ──[complex_id = station_complex_id]──► RIDERSHIP
DELAYS    ──[line]──► BRIDGE
```

For Penn Station specifically:

```
INCIDENTS where line IN ('1','2','3','A','C','E')
    JOIN bridge_line_station ON line
    → returns complex_id 318 (for 1,2,3) and 164 (for A,C,E)
    JOIN ridership ON station_complex_id
    → Penn Station rider counts, filterable by month
```

The join works because:
- `INCIDENTS.line` → `BRIDGE.line` : direct string match (`"1"` = `"1"`)
- `BRIDGE.complex_id` → `STATIONS.complex_id` : direct integer match
- `STATIONS.complex_id` → `RIDERSHIP.station_complex_id` : direct integer match (stored as string `"318"` in both, but value is identical)

---

## Slide 5 — Three Traps That Look Like Join Columns But Aren't

### Trap 1: The `division` column

Both sides of the model have a `division` column. It looks like a shared key. It isn't.

| File | Division values | Meaning |
|------|----------------|---------|
| Incidents | `"A DIVISION"`, `"B DIVISION"` | MTA operational grouping (historical) |
| Delays | `"A DIVISION"`, `"B DIVISION"` | same |
| Stations | `"IRT"`, `"BMT"`, `"IND"`, `"SIR"` | Engineering/historical division names |

`"A DIVISION"` and `"IRT"` describe the same group of trains (numbered lines 1–7) in different vocabularies. A join on `division` across the gap would match zero rows. **Never use `division` to join Incidents/Delays to Stations.**

### Trap 2: The `station_complex` name in Ridership

The `station_complex` column in Ridership looks like a name that could join to `Stop Name` in Stations:

```
Ridership.station_complex  = "34 St-Penn Station (1,2,3)"
Stations.Stop Name         = "34 St-Penn Station"
```

The bracketed route suffix `(1,2,3)` makes these two strings non-equal. A name-based join fails silently — Tableau returns zero matches and shows a blank viz with no error. **Always join on `station_complex_id` (integer), never on the name string.**

### Trap 3: Three date formats across four files

| File | Format | Example |
|------|--------|---------|
| Incidents | `YYYY-MM-DD` | `2020-01-01` |
| Delays | `YYYY-MM-DD` | `2020-01-01` |
| Ridership | `M/D/YYYY H:MM:SS AM` | `04/29/2022 01:00:00 PM` |
| MTA_Final_Dataset | `YYYY-MM-DD HH:MM:SS±TZ` | `2020-01-01 00:00:00-05` |

Tableau will not automatically recognise these as the same type on import. **Manually change each date field's data type to Date in Tableau** (right-click field → Change Data Type → Date). Tableau re-parses on import and normalises all formats to its internal date representation.

In Python (for any rebuild scripts): use `datetime.strptime` with the correct format string per file — do not assume ISO.

---

## Slide 6 — Number Formatting Traps

Two files store numeric columns as comma-formatted strings inside CSV quotes.

| File | Column | Raw value in CSV | What happens if you skip the fix |
|------|--------|-----------------|----------------------------------|
| Delays | `delays` | `"1,836"` | Python: `ValueError: invalid literal for int()`. Tableau: reads as string, treats as dimension not measure, all aggregations silently return 0. |
| Ridership | `ridership` | `"121"` or `"1,204"` | Same — Tableau may import correctly for small values but misparse large ones. |

**Fix in Python:** `.replace(',', '')` before `int()`.  
**Fix in Tableau:** on data source screen, confirm the field type shows as Number (whole). If it shows as String, the comma stripping wasn't applied — reconnect to a cleaned CSV.

---

## Slide 7 — Line Code Quirks

### 7a: Blank line rows in Incidents
Twelve rows in the incidents file have an empty string as their `line` value. These rows have real incident counts but cannot be attributed to any line or station.

**Cause:** likely data entry errors or incidents logged before a line was assigned.  
**Fix:** filter `line != ''` in Tableau (or in a Python pre-processing step). Removing 12 rows from 5,594 has no material effect on the dashboard.

### 7b: W line present in Incidents, absent in Delays
The W train appears in Incidents but has no corresponding rows in Delays.

| File | W line present |
|------|---------------|
| Incidents | Yes — W was suspended 2010–2016, then reinstated 2016 |
| Delays | No |

This is not a data error. The W train does not serve Penn Station, so it has no impact on this dashboard.

### 7c: S shuttles — three distinct codes in Incidents/Delays, one bare `S` in Stations

| Incidents/Delays code | Shuttle route |
|-----------------------|--------------|
| `S 42nd` | Times Square–42nd Street Shuttle |
| `S Fkln` | Franklin Avenue Shuttle |
| `S Rock` | Rockaway Park Shuttle |

The Stations file uses a bare `S` token in `Daytime Routes` for all three. There is no way to programmatically determine from the Stations file which `S` rows belong to which shuttle — the file does not distinguish them.

**Consequence for the bridge table:** `S 42nd`, `S Fkln`, `S Rock` cannot be joined to station complexes through the bridge table. Any shuttle incident analysis would require manually assigning shuttle-to-complex mappings. This is documented as a known gap.

**No impact on this dashboard** — none of the three shuttles serve Penn Station.

---

## Slide 8 — The JZ Fix

### What the problem was

The MTA treats J and Z trains as a combined service in its operational incident reporting. The incidents and delays files use `"JZ"` as a single line code — not separate `"J"` and `"Z"` entries.

The bridge table script parsed `Daytime Routes` from the Stations file, which stores J and Z as **separate tokens** (`"J Z"` in the routes string). This produced separate `J` and `Z` rows in the bridge table — but no `JZ` row.

```
Incidents file: line = "JZ"    → looks up bridge table → NO MATCH → silently dropped
Bridge table:   line = "J"     → never matched by any incident row
Bridge table:   line = "Z"     → never matched by any incident row
```

This was verified against the live data.ny.gov incidents API, which confirmed `JZ` is the only J/Z token used in the source data.

### What the fix does

The fix takes the union of all complex IDs served by `J` or `Z` individually, then writes new `JZ` rows for each of those complexes.

```python
jz_complexes = set()
for r in bridge_rows:
    if r['line'] in ('J', 'Z'):
        jz_complexes.add(r['complex_id'])
# Add one JZ row per complex in the union
for cid in sorted(jz_complexes, key=int):
    new_rows.append({'line': 'JZ', 'complex_id': cid})
```

**Result:** 30 `JZ` rows added. Bridge table grew from 767 → 797 rows.

The union approach is correct because the MTA uses `JZ` to mean "any incident affecting the J/Z service" — not a separate third train. If either J or Z stops at a complex, a `JZ` incident affected that complex.

### Remaining known gap after the fix

| Line code in Incidents | Bridge table | Status |
|------------------------|-------------|--------|
| `JZ` | ✓ 30 rows | **Fixed** |
| `S 42nd` | ✗ no rows | Known gap — unfixable from available data |
| `S Fkln` | ✗ no rows | Known gap — unfixable from available data |
| `S Rock` | ✗ no rows | Known gap — unfixable from available data |
| blank `""` | ✗ no rows | Filter these out — 12 rows, not attributable |

---

## Slide 9 — Date Overlap: What Data Is Actually Usable

All three operational datasets were checked for their usable date windows:

| Dataset | Start | End | Months |
|---------|-------|-----|--------|
| Incidents | 2015-01 | 2026-03 | 135 |
| Delays | 2020-01 | 2026-03 | 75 |
| Ridership | 2020-01 | 2024-12 | 60 |
| **Three-way overlap** | **2020-01** | **2024-12** | **60** |

The three-way overlap is exactly 60 months with **no gaps** — every month in the overlap window has data in all three files. This was confirmed programmatically.

**Why this matters for Tableau:** if you build a relationship between all three tables and Tableau shows months with null values, the problem is not a gap in the data — it is a join or filter misconfiguration.

Incidents data from 2015–2019 is present in the file and will appear in Tableau, but will show null ridership (because ridership starts 2020) and null delays (because delays start 2020). This is expected and should be annotated on the dashboard, not treated as an error.

---

## Slide 10 — Ridership by Complex: The Numbers

The ridership file covers Penn Station only. Total across the 60-month window:

| Complex | Station | Lines | Total ridership (Jan 2020–Dec 2024) |
|---------|---------|-------|-------------------------------------|
| 318 | 34 St–Penn Station | 1, 2, 3 | 62,794,521 |
| 164 | 34 St–Penn Station | A, C, E | 68,310,948 |
| **Both** | | **1,2,3,A,C,E** | **131,105,469** |

The A/C/E side (complex 164) carries slightly more riders than the 1/2/3 side (complex 318) over the full period. This is worth surfacing in the dashboard — it means incidents on A/C/E lines affect a marginally larger commuter population.

**Note on MTA_Final_Dataset ridership:** the pre-built summary file shows a total of 80,069,602 — about 39% lower than the raw ridership sum. This reflects a different aggregation method used when the pre-built file was constructed (likely deduplicating transfers or applying a different fare-tap logic). The CLAUDE.md documents this discrepancy. Use `MTA_Final_Dataset.csv` as-is for the dashboard; do not mix its ridership values with a raw sum.

---

## Slide 11 — The SQLite Database

After all raw CSVs were validated, they were loaded into a single SQLite database (`mta.db`) using `load_to_sqlite.py`. This replaced the need to juggle seven CSV files and gave a single place to run SQL queries, explore joins, and export clean data.

### Why SQLite instead of loading CSVs directly into Tableau

Tableau can read CSVs, but it cannot handle the comma-formatted number columns (`delays`, `ridership`) or the three different date formats without manual intervention on every import. Loading into SQLite first let us apply all type coercions once in Python, verify them with SQL queries, and export clean outputs.

### Table inventory

| Table | Rows | Key coercions applied |
|-------|------|-----------------------|
| `stations` | 496 | `CBD` boolean → 0/1 integer; `Line` renamed to `corridor` |
| `incidents` | 5,594 | `month` trimmed to `YYYY-MM-DD` |
| `delays` | 17,895 | `delays` comma-stripped → INTEGER |
| `ridership` | 681,767 | `ridership` comma-stripped → INTEGER; timestamp preserved as-is |
| `ridership_sample` | 500 | same as ridership |
| `bridge` | 797 | includes 30 JZ rows added post-generation |
| `final_dataset` | 60 | `month` timezone offset stripped → plain `YYYY-MM-DD` |

### How to access it

- **WSL path:** `/home/subra/Repo/mta-tableau/mta.db`
- **Windows path (DBeaver):** `C:\Users\subra\Documents\mta.db`
- **DBeaver connection:** New Connection → SQLite → paste Windows path → Test → Finish
- **Rebuild from scratch:** `rm mta.db && python3 load_to_sqlite.py`

### Indexes created

```sql
idx_incidents_month_line, idx_incidents_line
idx_delays_month_line, idx_delays_line
idx_ridership_complex_ts
idx_bridge_line, idx_bridge_complex
idx_stations_complex
```

---

## Slide 12 — The Tableau-Ready Export (Option B)

Rather than loading raw CSVs into Tableau, a single pre-joined CSV was built by running SQL against `mta.db`. This approach handles all the join complexity in one place and gives Tableau a clean flat file.

### What was joined

```
incidents (Penn lines, 2020–2024)
  LEFT JOIN delays (aggregated by line/month/day_type)
  LEFT JOIN ridership (aggregated by complex/month, with date parsed from M/D/YYYY)
  JOIN stations (Penn Station complex only — adds lat/long)
```

### The date parsing problem and fix

The ridership `transit_timestamp` column (`04/29/2022 01:00:00 PM`) had to be parsed into a `YYYY-MM` string to match the `month` column in incidents (`2020-01-01`).

**First attempt — broken:**
```sql
strftime('%Y-%m',
    substr(transit_timestamp, 7, 4) || '-' ||
    printf('%02d', CAST(substr(transit_timestamp, 1, instr(transit_timestamp,'/')-1) AS INT))
) AS month
```
SQLite's `strftime` returns NULL when given a `YYYY-MM` string — it requires a full `YYYY-MM-DD` date. All 644 ridership values came back as 0.

**Fix — direct concatenation:**
```sql
substr(transit_timestamp, 7, 4) || '-' ||
printf('%02d', CAST(substr(transit_timestamp, 1, instr(transit_timestamp,'/')-1) AS INT)) AS month
```
This builds `'2022-04'` directly without calling `strftime`. Verified: 0 rows with ridership = 0 after fix.

### Full working SQL

```sql
SELECT
    i.month,
    i.line,
    CASE WHEN i.line IN ('1','2','3') THEN '1/2/3'
         WHEN i.line IN ('A','C','E') THEN 'A/C/E' END  AS line_group,
    i.day_type,
    i.category,
    i.count                                              AS incident_count,
    COALESCE(d.delays, 0)                                AS delays,
    COALESCE(r.ridership, 0)                             AS ridership,
    s.complex_id,
    s.stop_name,
    s.latitude,
    s.longitude
FROM incidents i
LEFT JOIN (
    SELECT line, month, day_type, SUM(delays) AS delays
    FROM delays
    GROUP BY line, month, day_type
) d ON i.line = d.line AND i.month = d.month AND i.day_type = d.day_type
LEFT JOIN (
    SELECT
        station_complex_id,
        substr(transit_timestamp, 7, 4) || '-' ||
        printf('%02d', CAST(substr(transit_timestamp, 1, instr(transit_timestamp,'/')-1) AS INT)) AS month,
        SUM(ridership) AS ridership
    FROM ridership
    GROUP BY station_complex_id, month
) r ON r.station_complex_id = CASE WHEN i.line IN ('1','2','3') THEN 318
                                    WHEN i.line IN ('A','C','E') THEN 164 END
   AND r.month = substr(i.month, 1, 7)
JOIN stations s ON s.complex_id = CASE WHEN i.line IN ('1','2','3') THEN 318
                                        WHEN i.line IN ('A','C','E') THEN 164 END
WHERE i.line IN ('1','2','3','A','C','E')
  AND i.month BETWEEN '2020-01-01' AND '2024-12-31'
ORDER BY i.month, i.line, i.day_type, i.category;
```

### Output: `datasets/mta_tableau_joined.csv`

| Column | Type | Notes |
|--------|------|-------|
| `month` | Date string | Change to Date in Tableau |
| `line` | String | 1, 2, 3, A, C, E |
| `line_group` | String | `1/2/3` or `A/C/E` — ready as filter/color |
| `day_type` | Integer | 1 = weekday, 2 = weekend |
| `category` | String | Signals, Track, Other, etc. |
| `incident_count` | Integer | |
| `delays` | Integer | Sum across all reporting categories |
| `ridership` | Integer | Monthly total for whole Penn Station complex |
| `complex_id` | Integer | 318 or 164 |
| `stop_name` | String | "34 St-Penn Station" |
| `latitude` / `longitude` | Real | Penn Station coordinates only (two distinct points) |

**644 rows · 12 columns · zero null ridership values**

### What was intentionally excluded

| Column | Reason excluded |
|--------|----------------|
| `reporting_category` | Collapsed into total delays — add back if you need Infrastructure vs Police breakdown |
| `fare_class_category` | Collapsed into total ridership — add back if you need OMNY vs Metrocard split |
| `division` | Incompatible vocabulary across files — not useful in Tableau |

---

## Slide 13 — Map Data: Station Coordinates

The joined CSV (`mta_tableau_joined.csv`) contains Penn Station coordinates only — two lat/long points, one per complex. This is enough to pin Penn Station on a map, but not enough for a full route map showing every stop on the 1/2/3 and A/C/E lines.

### Why not embed all station stops in the joined file

Joining all station stops would multiply each row by 35–67x (depending on the line — Line 2 has 67 stops, Line E has 35). This would inflate the 644-row joined file to ~34,000 rows and make every non-map chart aggregate incorrectly.

### Solution: separate station coordinates file

`datasets/mta_station_coords.csv` — 321 rows, one per (line, station_stop) for all stops on lines 1, 2, 3, A, C, E.

| Column | What it is |
|--------|-----------|
| `line` | 1, 2, 3, A, C, E — **join key to `mta_tableau_joined.csv`** |
| `line_group` | 1/2/3 or A/C/E |
| `complex_id` | station group ID |
| `stop_name` | station name |
| `borough` | M=Manhattan, BK=Brooklyn, Q=Queens, Bx=Bronx |
| `daytime_routes` | all routes serving that stop |
| `structure` | Subway / Elevated / Open Cut |
| `latitude` / `longitude` | GTFS coordinates |

**How to use in Tableau:**
1. Add `mta_station_coords.csv` as a second data source
2. Create a relationship to `mta_tableau_joined.csv` on `line`
3. On the map sheet: drop `latitude` and `longitude` onto the canvas, size or color dots by `incident_count` or `ridership` from the joined table
4. This shows every stop on both Penn Station corridors with incident data attributed at the line level

### Stop counts by line

| Line | Stops | Route span |
|------|-------|-----------|
| 2 | 67 | Wakefield–241 St (Bronx) → Flatbush Av (Brooklyn) |
| A | 62 | Inwood–207 St → Far Rockaway / Ozone Park |
| C | 59 | 168 St → Euclid Av |
| 3 | 51 | 148 St → New Lots Av |
| 1 | 47 | Van Cortlandt Park–242 St → South Ferry |
| E | 35 | Jamaica Center → World Trade Center |

Line 2 has the longest route (27 unique stops exclusive to it) — this geographic exposure is part of why it has more incidents than Line 3 (11 stops). The `mta_station_map_panel.html` prototype makes this argument visually.

---

## Slide 14 — Dashboard Narrative and Design System

### The story

**Title:** "The Jersey-to-NYC Transfer of Stress — How signal and track failures translate into delays and lost time for NJ commuters (2020–2024)"

**Core question:** When a Signal or Track incident hits a Penn Station gateway line, how many commuters absorb the disruption — and how much time do they lose?

**Structure:** Scale → Pattern → Cause → Timing  
The dashboard opens with the exposure size (1.16M monthly riders), shows when failures cluster (dual-axis time series), explains what drives delays (category breakdown), and closes with when commute risk peaks (hourly scatter). No verdict slide — the numbers make the case.

This framing was chosen deliberately for the Data School application: it shows a complete analytical arc without overfitting to a single routing recommendation.

### Canonical KPI numbers (as shown in Dashboard_Draft.png)

| Metric | Value | Source | Notes |
|--------|-------|--------|-------|
| Avg monthly riders (both complexes) | 1.16M | MTA_Final_Dataset · `AVG([ridership])` | Both Penn Station complexes combined |
| Signal + Track incidents 2020–2024 | 353 | mta_tableau_joined · `SUM(Signal+Track Incidents)` | Penn lines 1,2,3,A,C,E only |
| Months with >1% delay intensity | 28.3% | MTA_Final_Dataset · `COUNTD(IF [delay_intensity] > 0.01 ...)` | 17 of 60 months above threshold |
| Avg time lost per incident month | 5.2 hrs | MTA_Final_Dataset · `AVG(IF [total_incidents] > 0 THEN [total_delays]/60 END)` | Delays column in minutes |
| Peak avg riders per hour | 406 | mta_hourly_avg · 8 AM row | Annotated on hourly scatter |
| Delay intensity — incident months | 3.1% | MTA_Final_Dataset | Supporting context |
| Delay intensity — clean months | 2.1% | MTA_Final_Dataset | Supporting context |
| A/C/E signal advantage over 1/2/3 | −23% | mta_tableau_joined | WTC 377 vs Penn 489 signal incidents |

### Design system (as built in Dashboard_Draft.png)

| Element | Value | Used for |
|---------|-------|---------|
| Canvas background | `#ffffff` (white) | Dashboard background |
| Signal+Track incidents | `#f97316` (orange) | Bars, KPI accent, high-risk |
| Ridership / A/C/E corridor | `#6366f1` (purple) | Trend line, second corridor |
| Text primary | `#1e293b` (dark slate) | Titles, labels |
| Text muted | `#94a3b8` (gray) | Subtitles, axis labels |

Previous dark-theme prototype files (`#0d1117` background, red `#E24B4A`, teal `#2dc98a`) are preserved in `sample_dashboards/` as iteration history but are **superseded** by the light theme in the live Tableau workbook.

### Dashboard layout (4 panels + KPI strip)

```
┌────────────────────────────────────────────────────────────┐
│ "The Jersey-to-NYC Transfer of Stress"  [title + subtitle] │
├──────────┬──────────┬──────────┬──────────────────────────┤
│  1.16M   │   353    │  28.3%   │       5.2 hrs            │
│ avg riders│ S+T inc  │ >1% delay│  time lost/inc month    │
├──────────┴──────────┴──────────┴──────────────────────────┤
│ "How do incidents and ridership drive delays over time?"   │
│   [1/2/3 panel]           [A/C/E panel]                   │
│   orange bars=incidents · purple line=ridership            │
├─────────────────────────────┬──────────────────────────────┤
│ "What causes delays:        │ "When is commute risk        │
│  infrastructure vs          │  highest?"                   │
│  external events?"          │  dot scatter, 8 AM peak=406  │
│  grouped bar by corridor    │                              │
└─────────────────────────────┴──────────────────────────────┘
```

### Prototype and iteration files

| File | What it is | Status |
|------|-----------|--------|
| `Dashboard_Draft.png` | **Current Tableau build** — 4 panels, light theme, confirmed KPIs | **Active — source of truth** |
| `transfer_of_stress_dashboard.html` | HTML prototype with all panels (dark theme) | Reference for panel content |
| `hero_kpi_1_8m_commuters.html` | Early KPI tile prototype | Superseded — numbers changed |
| `penn_station_dow_hour_heatmap.html` | Day × hour heatmap prototype | Superseded — replaced by hourly scatter |
| `mta_station_map_panel.html` | Route map — 496 stations at GTFS coordinates | Not in current Tableau build |
| `nj_commuters_gamble_dashboard.html` | Full assembled layout (dark, NJ routing focus) | Superseded |
| `mta_dashboard_final_v3.html` | 5-section layout prototype | Superseded |
| `mta_dashboard_rebuilt_v2.html` | 4-panel rebuild, Line 2 vs Line 3 head-to-head | Superseded |
| `dashboard_sample.jpeg` | Original target design (Sankey + bubble map) | Reference only — NJ data unavailable |
| `render_1.png` | Day-of-week × hour heatmap prototype | Iteration history |
| `render_2.png` | KPI hero panel (dark) — 1.8M, 55/60, 3.1%, −23% | Iteration history — numbers superseded |
| `render_3.png` | Dashboard v1 — KPI strip + Gateway Line Reliability bar | Iteration history |
| `render_4.png` | Dashboard v2 — Line 2 vs Line 3 head-to-head + scatter | Iteration history |
| `render_5.png` | Dashboard v3 — refined v2 with "Take the 3 train" verdict | Iteration history |
| `render_6.png` | Final HTML render — sidebar nav, Penn→Port Authority→WTC triangle | Iteration history |

### Tableau sheet build order (matching Dashboard_Draft.png)

| # | Sheet name | Data source | Marks / Key fields |
|---|-----------|-------------|-------------------|
| 1 | KPI 1 — Commuters | MTA Penn Lines (MTA_Final_Dataset) | Text · `AVG([ridership])` |
| 2 | KPI 2 — Incidents | MTA Penn Lines (mta_tableau_joined) | Text · `SUM([Signal+Track Incidents])` |
| 3 | KPI 3 — Delay Months | MTA Penn Lines (MTA_Final_Dataset) | Text · `COUNTD(IF [delay_intensity]>0.01...)` |
| 4 | KPI 4 — Time Lost | MTA Penn Lines (MTA_Final_Dataset) | Text · `AVG(IF [total_incidents]>0 THEN [total_delays]/60 END)` |
| 5 | Time Series | MTA Penn Lines (mta_tableau_joined) | Dual axis · `month` on Cols, `line_group` splits panels |
| 6 | Category Bar | MTA Penn Lines (mta_tableau_joined) | Bar · `line_group` + `category` on Cols, `SUM([incident_count])` on Rows |
| 7 | Hourly Scatter | Hourly Avg | Circle · `hour_num` on Cols, `avg_ridership` on Rows, 8 AM annotated |

### Computed fields created in Tableau (MTA Penn Lines source)

| Field | Formula | Used in |
|-------|---------|---------|
| `Signal+Track Incidents` | `IF [category] IN ("Signals","Track") THEN [incident_count] ELSE 0 END` | Time series bars, KPI 2 |
| `Incident Month Label` | `STR(COUNTD(IF [category] IN ("Signals","Track") AND [incident_count]>0 THEN [month] ELSE NULL END)) + " / " + STR(COUNTD([month]))` | KPI 3 alternative |
| `Delay Intensity (Incident)` | `AVG(IF [total_incidents] > 0 THEN [delay_intensity] ELSE NULL END)` | Supporting stat |
| `Delay Intensity (Clean)` | `AVG(IF [total_incidents] = 0 THEN [delay_intensity] ELSE NULL END)` | Supporting stat |

**Note:** `line_group` is already a column in `mta_tableau_joined.csv` — it was not recreated as a calculated field.

---

## Slide 15 — Summary of All Issues Found and Their Status

| Issue | Severity for Penn Station | Status |
|-------|--------------------------|--------|
| Line-side / station-side join gap | Critical | **Resolved** — bridge table built |
| `JZ` not in bridge table | Medium (J/Z don't serve Penn) | **Fixed** — 30 JZ rows added |
| S shuttle codes unresolvable | Low (shuttles don't serve Penn) | **Known gap** — documented |
| `division` column looks joinable but isn't | High (would produce zero rows) | **Documented** — do not use |
| `station_complex` name unresolvable to Stations | High (would produce zero rows) | **Documented** — use integer ID |
| Three different date formats | High (Tableau imports wrong type) | **Documented** — manual type change |
| `delays` comma-formatted | Medium (Tableau treats as string) | **Documented** — manual type change |
| `ridership` comma-formatted | Medium (Tableau treats as string) | **Documented** — manual type change |
| 12 blank `line` rows in Incidents | Low (12 of 5,594 rows) | **Documented** — filter out |
| W line in Incidents but not Delays | Low (W doesn't serve Penn) | **Documented** — expected |
| Incidents 2015–2019 have null ridership | Expected | **Documented** — annotate on dashboard |
| MTA_Final_Dataset ridership 39% lower than raw | Medium | **Documented** — use pre-built file as-is |
| COVID ridership dip Mar–Jun 2020 | Contextual | **Documented** — annotate on dashboard |

---

# Part II — v2 Rebuild (May 2026)

The v1 dashboard documented above shipped, but reviewer feedback flagged three real
problems: the dual-axis time series chart implied a correlation that the data didn't
support, the `MTA_Final_Dataset.csv` numbers couldn't be reproduced from the raw
files (39% gap), and the analysis stopped at "Penn-only" with no comparison hub.
v2 is the response.

---

## Slide 16 — Why we rebuilt

**Three structural complaints from v1:**

1. **Dual-axis chart.** Bars (incidents) and line (ridership) on the same time-series
   panel implies they correlate. They don't — ridership grew steadily through 2024 while
   incidents stayed flat. The visual created a relationship the data didn't.
2. **Opaque pre-built file.** `MTA_Final_Dataset.csv` showed totals 39% below the raw
   sum. Could not be reproduced. Defending it as "different aggregation" is honest but
   weak — a portfolio dashboard should not depend on a black-box input.
3. **No comparison.** The dashboard answered "how bad is Penn Station?" but not "how
   bad is Penn Station *compared to what?*" — leaving the reader without a yardstick.

v2 fixes all three: small-multiples instead of dual-axis, raw data only with all
aggregations done in Postgres, and a Penn-vs-WTC corridor comparison powered by
the new Wait Assessment + OTP datasets.

---

## Slide 17 — Five new datasets, what each unlocks

| Dataset | Source | What v1 was missing |
|---------|--------|---------------------|
| **MTA Subway Wait Assessment** | data.ny.gov | % trains within target headway, by line × month × day_type × period (peak/offpeak). Real service quality metric — lets us say "A/C/E lines have +4 pp better peak Wait Assessment than 1/2/3" with sourced data, not a derived "delay intensity %". |
| **MTA Subway Terminal On-Time Performance** | data.ny.gov | Terminal OTP %, same grain. Pairs with WA for the reliability comparison panel. |
| **MTA Daily Ridership and Traffic** | data.ny.gov `sayj-mze2` | Systemwide ridership by mode (Subway, Bus, LIRR, MNR, SIR, AAR, BT, CBD Entries, CRZ Entries). KPI-tile context — "subway carried 4.5M/day in 2024." |
| **MTA Subway Stations and Complexes** | data.ny.gov `5f5g-n3cz` | Complex-grain dim with `GTFS Stop IDs` column linking to GTFS stops. This is the join key v1 was missing — it's why v1 had to parse `Daytime Routes` strings. |
| **NYC GTFS feed** | mta.info | Authoritative `routes.txt`, `trips.txt`, `stop_times.txt`, `stops.txt`. Lets `bridge_complex_route` be **derived** from real schedule data instead of parsed from a free-text column. |
| **Hourly Ridership (full system)** | data.ny.gov `wujg-7c2s` | Includes every complex, not just Penn. Needed to put WTC, Fulton St, Times Sq, Chambers St on the same heatmap as Penn. v1's hourly file was already pre-filtered to Penn — couldn't extend the analysis. |

Net effect: v2 can ask *comparison* and *severity* questions that v1 couldn't.

---

## Slide 18 — From SQLite + flat CSV to Postgres star schema

v1 stack:
```
raw CSVs → load_to_sqlite.py → mta.db (7 tables, no FKs) → mta_tableau_joined.csv (hand-built) → Tableau
```

v2 stack:
```
raw CSVs → \copy → stg_*  →  transform.sql  →  dim_* + fact_* + bridge_*  →  export.sql  →  6 wide CSVs → Tableau
                  (TEXT)                       (typed star schema, FKs)                    (one per sheet group)
```

**10 tables in the star schema:**

| Layer | Tables |
|-------|--------|
| Dimensions | `dim_complex`, `dim_route`, `dim_date`, `dim_line_route_map` |
| Bridge | `bridge_complex_route` |
| Facts | `fact_hourly_ridership`, `fact_major_incidents`, `fact_delay_causing_incidents`, `fact_wait_assessment`, `fact_otp`, `fact_daily_ridership` |

**Why Postgres over SQLite this time:** v1's join logic was scattered across Python
scripts and Tableau calculated fields. Postgres lets all coercions, dedups, and joins
live in version-controlled SQL. FK constraints catch orphans at load time instead of
during dashboard build. `\copy` handles the 2.1M-row hourly file in seconds.

**Why CSV export and not direct Postgres → Tableau:** The reviewer needs to open the
`.twbx` on their machine without standing up a database. Six packaged CSVs travel
cleanly inside the workbook.

---

## Slide 19 — The bridge table, rebuilt from GTFS

v1 built the bridge by parsing the `Daytime Routes` column of the Stations file —
splitting `"1 2 3"` on spaces. This worked but had three known gaps: JZ wasn't in the
Stations file (had to be hand-patched, +30 rows), the three S shuttles couldn't be
distinguished (all came through as bare `"S"`), and the parsing was brittle to MTA
formatting changes.

v2 derives `bridge_complex_route` from the GTFS feed:

```sql
-- conceptual path
trips.route_id  ──join trip_id──  stop_times.stop_id
                                       │
                                       ├── join to stops.parent_station (platform → station)
                                       │
                                       └── join to dim_complex via gtfs_stop_ids
                                                  │
                                                  └── DISTINCT (complex_id, route_id) → bridge
```

Working SQL (in `postgres/transform.sql`):

```sql
WITH complex_to_gtfs AS (
    SELECT complex_id, TRIM(gtfs_stop_id) AS gtfs_stop_id
    FROM dim_complex,
         LATERAL UNNEST(STRING_TO_ARRAY(gtfs_stop_ids, ',')) AS gtfs_stop_id
),
stop_to_parent AS (
    SELECT stop_id, COALESCE(NULLIF(parent_station, ''), stop_id) AS parent_id
    FROM stg_gtfs_stops
)
INSERT INTO bridge_complex_route (complex_id, route_id)
SELECT DISTINCT ctg.complex_id, t.route_id
FROM stg_gtfs_stop_times st
JOIN stop_to_parent      sp  ON sp.stop_id      = st.stop_id
JOIN complex_to_gtfs     ctg ON ctg.gtfs_stop_id = sp.parent_id
JOIN stg_gtfs_trips      t   ON t.trip_id       = st.trip_id;
```

The result is authoritative — every (complex, route) pair comes from the actual
schedule, not a free-text column. The shuttles (`GS`, `FS`, `H`) get correctly
attributed to their specific shuttle complexes.

---

## Slide 20 — The line ↔ route_id mapping table

v1 made a category error: it tried to use the source `line` codes (`"1"`, `"JZ"`,
`"S 42nd"`) as the dimensional key directly. v2 separates raw line codes (the strings
that appear in incident/delay/WA/OTP files) from canonical GTFS route_ids.

`dim_line_route_map` holds 27 rows:

| Group | mta_line values | route_id |
|-------|----------------|----------|
| Direct match | `1`–`7`, `A`–`G`, `J`, `L`–`Q`, `R`, `W` | same as mta_line |
| GTFS-named shuttles | `GS`, `FS`, `H` | same as mta_line |
| Legacy-named shuttles | `S 42nd`, `S Fkln`, `S Rock` | mapped to `GS`, `FS`, `H` |
| J+Z combined | `JZ` | `NULL` (no GTFS equivalent) |

This isolates a **new gap discovered in v2**: the 2024 Wait Assessment and OTP rows
include shuttles under **both** the legacy text codes (`S 42nd`, `S Fkln`, `S Rock`)
**and** the GTFS codes (`GS`, `FS`, `H`) for the same months. Loading both would
double-count. Fix: `transform.sql` filters out the legacy text codes for those two
fact tables (incidents and delays still use legacy codes, no dedup needed there).

```sql
-- in transform.sql
INSERT INTO fact_wait_assessment (...)
SELECT ... FROM stg_wait_assessment
WHERE EXTRACT(YEAR FROM month::DATE) = 2024
  AND line NOT IN ('S 42nd', 'S Fkln', 'S Rock');   -- keep GTFS codes only
```

---

## Slide 21 — KPI 3: from broken proxy to honest count

The dashboard *originally* shipped a "~18 min avg delay per incident" KPI. We dropped it
and reframed KPI 3 as an absolute count — `99` Signal/Track major outages on the corridor
(2024, weekday). Here's why.

**What I thought the data had:**
- `fact_delay_causing_incidents.delay_count` = number of trains delayed

**What the data actually has:**
- `delay_count` is loaded from `MTA_Subway_Delay-Causing_Incidents.csv` `Incidents` column —
  it's the count of delay-causing **incidents**, not the count of trains delayed. The
  trains-delayed dataset (`MTA_Subway_Trains_Delayed`) is on disk but never loaded.

**Plus a structural bug in the export.** `monthly_incidents_delays.csv` is built from a
`LEFT JOIN` between `fact_major_incidents` (per `category`) and `fact_delay_causing_incidents`
(per `reporting_category`) on `(month, line, day_type)` only. The two facts use different
category systems, so each (m,l,d) becomes a Cartesian product — `incident_count` repeats
M times, `delay_count` repeats N times. A row-level ratio averages noise.

The original `~18 min` figure happened to fall out of `AVG([delay_count] / [incident_count]) × 3`
on the duplicated rows. Once I deduplicated with FIXED LODs (`Real Inc`, `Real Delay`) and
divided correctly, the corridor-weekday ratio came out at **136 secondary delay-causing
incidents per Signal/Track major incident** — which has no minutes interpretation at all.

**The fix:** drop the minutes framing. KPI 3 is now `99` — the count of major Signal/Track
outages, no proxy. The story is unambiguous and the math defends itself.

**What survived:** the box plot (Sheet E) still uses a deduplicated severity ratio per
month per category, but as a relative shape — Signals' tail is longest, regardless of
the units. The thesis (*Signals hit hardest*) doesn't depend on a minute conversion.

**What I'd build differently next time:** load `MTA_Subway_Trains_Delayed.csv` first,
re-derive a real "trains delayed per incident × headway" minute proxy on a clean grain,
and only then put a "minutes" KPI on the strip.

---

## Slide 22 — Dashboard model, evolved

v1 was a 4-panel layout with one KPI strip. v2 is 8 sheets organized around a
deliberate analytical arc, captured in `DASHBOARD_MODEL.md` and prototyped in
`sample_dashboards/render_6.jpeg`.

**Story arc:**

1. **How many people are at risk?** → KPI strip (Sheet 1)
2. **How often does the system fail them, and is ridership growing despite it?** → Time-series small multiples (Sheets 2 + 3)
3. **What kind of failures, and how bad are they?** → Cause bar + duration box plot (Sheets 4 + 5)
4. **Is one corridor more reliable than the other?** → Service quality comparison (Sheet 6 — NEW)
5. **Where and when does disruption concentrate?** → Filtered map + day×hour heatmap (Sheets 7 + 8)

**Key design choices:**

| v1 | v2 | Reason |
|----|----|--------|
| Dual-axis incidents+ridership chart | Stacked bar + stacked area (Line Group on Color) | Eliminates false correlation framing; stacked shows combined burden |
| Severity = `delay_intensity %` (opaque) | Severity = box plot of `delay_count / incident_count` (Month on Detail) | Reproducible from raw data; distribution visible across 12 months |
| No service quality dimension | Sheet D (Wait Assessment + OTP, peak weekday, side-by-side bars) | Lets us say "A/C/E +X pp better than 1/2/3" with sourced data |
| No flow visualization | Sheet San — Sankey (Category → Line Group, delay count on Link) | Signals→1/2/3 widest band is the visual anchor of the thesis |
| Map shows Penn lat/lon only (2 dots) | Filtered corridor map — 35 stations, sized by incident count | Reader sees the geography of the comparison |
| Filtered to Penn-only | Penn (318, 164) + WTC area (328, 624) | Comparison hub gives the reader a yardstick |
| One-palette quilt | Two-sheet quilt (C-1 red palette / C-2 purple palette, stacked) | Per-corridor palettes require separate sheets in Tableau |

Color system unchanged from v1: red for 1/2/3 + Signal/Track high-risk, purple for
A/C/E + ridership, light theme. Render 6 is the canonical layout; renders 7 and 8
are alternative explorations kept in `sample_dashboards/` as iteration history.

---

## Slide 23 — Issue tracker, v2 status

| Issue | v1 status | v2 status |
|-------|----------|----------|
| Line-side / station-side join gap | Resolved via hand-built bridge | **Re-resolved** via GTFS-derived `bridge_complex_route` |
| `JZ` not in bridge table | Patched (+30 manual rows) | **Schema-level** via `dim_line_route_map` (mapped to NULL — J/Z inseparable in source) |
| S shuttles unresolvable | Known gap | **Resolved** — `dim_line_route_map` handles `S 42nd`→`GS`, `S Fkln`→`FS`, `S Rock`→`H` |
| `division` column trap | Documented | Same — still don't use as cross-half join key |
| `station_complex` name unresolvable | Documented | Same — always join on `complex_id` integer |
| Three date formats | Manual cast in Tableau | **Normalized in `transform.sql`** — Tableau gets clean ISO timestamps |
| `delays` comma-formatted | Manual cast in Tableau | **Stripped in `transform.sql`** — `REPLACE(col, ',', '')::INTEGER` |
| `ridership` comma-formatted | Manual cast in Tableau | **Stripped in `transform.sql`** |
| 12 blank `line` rows in Incidents | Filter in Tableau | **Excluded at load** — `WHERE line <> ''` |
| W line absent from Delays | Documented | Same — expected |
| 2015–2019 incidents have null ridership | Annotate on dashboard | **N/A** — v2 starts at 2024 |
| `MTA_Final_Dataset` 39% lower ridership | Use as-is | **Removed from pipeline** — KPI numbers now come from raw data |
| **NEW: 2024 WA/OTP shuttle double-counting** | n/a | **Resolved** — `transform.sql` drops legacy text-named shuttle rows |
| **NEW: 3,343 delay rows have blank `reporting_category`** | n/a | **Excluded at load** — all are zero-count rows, can't fit composite PK |
| **NEW: `fact_daily_ridership` has no station/route** | n/a | **Documented as island** — KPI tile only, no relationships |
| **NEW: hourly ridership only Jan 2024 loaded** | n/a | **Documented** — extends to 2020–2024 when more months are downloaded |

Severity ranking applied to v2: every High issue from v1 is now resolved at the SQL
layer, not at the Tableau layer. That's the meaningful structural improvement —
v1 left a lot of correctness work for the BI tool, v2 hands Tableau pre-cleaned data.
