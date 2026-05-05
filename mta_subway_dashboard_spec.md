# NYC MTA Subway Reporting Dashboard — Data Spec

**Goal:** Build a Tableau dashboard reporting on NYC subway ridership, service quality, and incidents. This document specifies every dataset to download, the target data model, join keys, and an ETL plan in Python.

**Audience:** Claude Code (or any agent) building the ingestion pipeline.

**Stack assumptions:** Python, pandas / DuckDB for processing, Parquet for intermediate storage, Tableau as the BI layer.

---

## 1. Datasets to download

All `data.ny.gov` datasets are Socrata-hosted. The direct CSV export pattern is:

```
https://data.ny.gov/api/views/{dataset_id}/rows.csv?accessType=DOWNLOAD
```

For datasets where the ID is listed below, that pattern can be used directly. Where the ID is marked `verify`, resolve it by visiting the landing page and copying the 4-4 character ID from the URL (`data.ny.gov/d/{id}` or `data.ny.gov/Transportation/.../{id}`).

### 1.1 Ridership (fact tables)

| Dataset | Dataset ID | Landing page | Notes |
|---|---|---|---|
| MTA Subway Hourly Ridership: Beginning February 2022 | `wujg-7c2s` | https://data.ny.gov/d/wujg-7c2s | Covers Feb 2022 through ~end of 2024. Hundreds of millions of rows — use direct CSV download, not Socrata API pagination. |
| MTA Subway Hourly Ridership: Beginning 2025 | verify | search "MTA Subway Hourly Ridership Beginning 2025" on data.ny.gov | Continuation of the above. Same schema. |
| MTA Daily Ridership and Traffic | verify (likely `sayj-mze2`) | https://data.ny.gov/d/sayj-mze2 | Systemwide daily totals across all modes. Small file. Used for KPI tiles. |
| MTA Subway Origin-Destination Ridership Estimate (optional) | `28vm-gjqr` (or current year variant) | https://data.ny.gov/d/28vm-gjqr | Optional. Only pull if dashboard has OD-pair flows. Very large. |

**Schema (Hourly Ridership):** `transit_timestamp`, `transit_mode`, `station_complex_id`, `station_complex`, `borough`, `payment_method` (omny / metrocard), `fare_class_category`, `ridership`, `transfers`, `latitude`, `longitude`, `georeference`.

**Grain:** one row per (station_complex × hour × payment_method × fare_class).

### 1.2 Service quality & incidents (fact tables)

| Dataset | Dataset ID | Landing page | Notes |
|---|---|---|---|
| MTA Subway Major Incidents: Beginning 2020 | `j6d2-s8m2` | https://data.ny.gov/d/j6d2-s8m2 | Incidents that delayed 50+ trains. Monthly grain by line/category. Covers 2020–2024. |
| MTA Subway Major Incidents: Beginning 2025 | `uqnw-2qfk` | https://data.ny.gov/d/uqnw-2qfk | Continuation. Same schema. |
| MTA Subway Major Incidents: 2015–2019 (optional) | verify | search on data.ny.gov | Historical only. Skip unless dashboard needs pre-pandemic baseline. |
| MTA Subway Delay-Causing Incidents: Beginning 2020 | `g937-7k7c` | https://data.ny.gov/d/g937-7k7c | All delay-causing incidents (not just majors), with category + subcategory. Monthly. |
| MTA Subway Delay-Causing Incidents: Beginning 2025 | verify | search on data.ny.gov | Continuation. Same schema. |
| MTA Subway Wait Assessment | verify | search "MTA Subway Wait Assessment" | % trains within target headway, by line. Monthly. |
| MTA Subway On-Time Performance | verify | search "MTA Subway On-Time Performance" | Terminal on-time rate, by line. Monthly. |

**Grain (incidents):** one row per (line × month × day_type × category × subcategory).

### 1.3 Reference / dimension data

| Dataset | Dataset ID | Landing page | Notes |
|---|---|---|---|
| MTA Subway Stations | `39hk-dx4f` | https://data.ny.gov/d/39hk-dx4f | Station-grain dim. One row per station. |
| MTA Subway Stations and Complexes | `5f5g-n3cz` | https://data.ny.gov/d/5f5g-n3cz | **Complex-grain dim. This is the key one** — hourly ridership joins on `station_complex_id`. |

### 1.4 GTFS Static (schedules + geometry + route dim)

| File | Source |
|---|---|
| `google_transit.zip` (NYC Subway) | http://web.mta.info/developers/data/nyct/subway/google_transit.zip |

Unzip to get:
- `routes.txt` → `dim_route` (route_id, route_short_name, route_long_name, route_color)
- `stops.txt` → has `parent_station` field; rolls stops up to complex
- `trips.txt` + `stop_times.txt` → join to build `complex_route` bridge (which lines serve which complex)
- `shapes.txt` → polylines for the Tableau map
- `calendar.txt` / `calendar_dates.txt` → optional, only if modeling service patterns

### 1.5 Optional geographic layer

| Dataset | Source | Notes |
|---|---|---|
| NYC Neighborhood Tabulation Areas (NTAs) | https://data.cityofnewyork.us → search "NTA" | GeoJSON or shapefile. Only needed for neighborhood choropleths. |

---

## 2. Target data model (star schema)

```
                     ┌──────────────────┐
                     │   dim_complex    │
                     │ complex_id (PK)  │
                     │ name, lat, lon   │
                     │ borough, ada     │
                     └────────┬─────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼─────────┐   ┌───────▼──────────┐  ┌───────▼─────────┐
│ fact_hourly_    │   │ bridge_complex_  │  │ fact_od_        │
│   ridership     │   │     route        │  │   ridership     │
│ complex_id      │   │ complex_id (FK)  │  │ (optional)      │
│ ts              │   │ route_id   (FK)  │  └─────────────────┘
│ payment_method  │   └───────┬──────────┘
│ fare_class      │           │
│ ridership       │           │
└─────────────────┘           │
                              │
                     ┌────────▼─────────┐
                     │   dim_route      │
                     │ route_id (PK)    │
                     │ short_name       │
                     │ long_name, color │
                     │ division (A/B)   │
                     └────────┬─────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼─────────┐   ┌───────▼──────────┐  ┌───────▼──────────┐
│ fact_major_     │   │ fact_delay_      │  │ fact_wait_       │
│   incidents     │   │   causing_       │  │   assessment     │
│ route_id        │   │   incidents      │  │ route_id         │
│ month           │   │ route_id         │  │ month            │
│ category        │   │ month            │  │ wa_pct           │
│ count           │   │ category         │  └──────────────────┘
└─────────────────┘   │ subcategory      │
                      │ day_type         │  ┌──────────────────┐
                      │ count            │  │ fact_otp         │
                      └──────────────────┘  │ route_id         │
                                            │ month            │
┌──────────────────┐                        │ otp_pct          │
│ fact_daily_      │                        └──────────────────┘
│   ridership      │
│ (KPI tiles only) │   ┌──────────────────┐
│ date, mode       │   │   dim_date       │
│ count            │   │ date (PK)        │
└──────────────────┘   │ dow, is_holiday  │
                       │ is_weekday       │
                       │ year, month, fyq │
                       └──────────────────┘
```

### Tables to materialize as Parquet

```
dim_complex
dim_route
dim_date
bridge_complex_route

fact_hourly_ridership
fact_major_incidents
fact_delay_causing_incidents
fact_wait_assessment
fact_otp
fact_daily_ridership
```

---

## 3. Join keys & known gotchas

| Join | Key | Gotcha |
|---|---|---|
| ridership → dim_complex | `station_complex_id` | The hourly ridership file has `station_complex_id` already; just match it to `complex_id` in `MTA Subway Stations and Complexes`. |
| ridership → dim_route | `complex_id` → bridge → `route_id` | One complex serves multiple routes. Use bridge table. Don't try to parse the comma-separated `Daytime Routes` string in the stations file. |
| GTFS stops → complex | `stops.parent_station` | In NYC GTFS, `parent_station` IDs map (with prefix stripping) to MTA station IDs. Some stops have no parent — those are themselves stations. |
| incidents → dim_route | `line` (e.g. "1", "A", "L") → `route_short_name` | Direct match. Watch for: Shuttles ("S" used for multiple shuttles — Franklin, Rockaway, 42nd St), and "SIR" for Staten Island Railway. |
| any fact → dim_date | `date` | Monthly facts: cast month to first-of-month. Hourly: floor timestamp to date. |

---

## 4. ETL plan

### 4.1 Project layout

```
mta_dashboard/
├── data/
│   ├── raw/              # downloaded CSVs and GTFS zip (gitignored)
│   ├── interim/          # cleaned, partitioned Parquet
│   └── marts/            # final star-schema Parquet for Tableau
├── src/
│   ├── download.py       # fetch all datasets
│   ├── gtfs.py           # parse GTFS zip → dim_route + bridge
│   ├── dims.py           # build dim_complex, dim_date
│   ├── facts.py          # clean and partition each fact
│   └── publish.py        # write final marts/ Parquet
├── pyproject.toml
└── README.md
```

### 4.2 Dependencies

```
pandas>=2.2
pyarrow>=15
duckdb>=1.0
requests
holidays         # for dim_date
sodapy           # optional, only for Socrata API access
```

For the hourly ridership file (very large), prefer DuckDB:

```python
import duckdb
duckdb.sql("""
    CREATE TABLE hourly_ridership AS
    SELECT * FROM read_csv_auto('data/raw/hourly_ridership_*.csv')
""")
```

### 4.3 Download script outline

```python
DATASETS = {
    "hourly_ridership_2022_2024": "wujg-7c2s",
    "stations":                   "39hk-dx4f",
    "stations_and_complexes":     "5f5g-n3cz",
    "major_incidents_2020":       "j6d2-s8m2",
    "major_incidents_2025":       "uqnw-2qfk",
    "delay_causing_2020":         "g937-7k7c",
    # add the rest after verifying IDs
}

URL = "https://data.ny.gov/api/views/{id}/rows.csv?accessType=DOWNLOAD"
GTFS_URL = "http://web.mta.info/developers/data/nyct/subway/google_transit.zip"
```

### 4.4 GTFS → dim_route + bridge_complex_route

Critical step. Approach:

1. Read `routes.txt` → `dim_route`.
2. Read `stops.txt`. Stops with `location_type = 1` are parent stations; stops with a `parent_station` are platforms.
3. Map stops to MTA `complex_id` using the `MTA Subway Stations and Complexes` reference (join on `gtfs_stop_id` → strip platform suffix → match `parent_station`).
4. Join `trips.txt` ↔ `stop_times.txt` ↔ stops ↔ complexes to get all (route_id, complex_id) pairs.
5. Distinct → `bridge_complex_route`.

### 4.5 dim_date

```python
import pandas as pd, holidays
us_holidays = holidays.US(years=range(2020, 2031))
dates = pd.date_range("2020-01-01", "2030-12-31", freq="D")
dim_date = pd.DataFrame({"date": dates})
dim_date["dow"]        = dim_date.date.dt.day_name()
dim_date["is_weekend"] = dim_date.date.dt.weekday >= 5
dim_date["is_holiday"] = dim_date.date.isin(us_holidays)
dim_date["year"]       = dim_date.date.dt.year
dim_date["month"]      = dim_date.date.dt.month
dim_date["quarter"]    = dim_date.date.dt.quarter
```

### 4.6 Tableau handoff

Two viable paths:

1. **Parquet + Tableau Desktop** — point Tableau at the `marts/` folder. Set up relationships (NOT joins) on the keys above so the line filter cascades correctly across all four facts.
2. **Hyper extracts** — use `tableauhyperapi` to write `.hyper` files directly. Faster dashboard performance, more setup.

For most use cases, start with Parquet + relationships.

---

## 5. Build order (suggested)

1. `download.py` — pull all CSVs + GTFS zip into `data/raw/`.
2. `dims.py` — build `dim_complex`, `dim_date`.
3. `gtfs.py` — build `dim_route`, `bridge_complex_route`.
4. `facts.py` — clean each fact, validate join keys against dims, partition.
5. `publish.py` — write final marts.
6. Wire into Tableau, build dashboard.

---

## 6. Verification checklist before building dashboard

- [ ] Every `station_complex_id` in `fact_hourly_ridership` exists in `dim_complex`.
- [ ] Every `route_id` in `fact_major_incidents` and `fact_delay_causing_incidents` exists in `dim_route`.
- [ ] `bridge_complex_route` has no orphan keys on either side.
- [ ] `dim_date` covers full ridership date range plus 1 year forward.
- [ ] Hourly ridership row counts roughly match published MTA totals (sanity check against Daily Ridership dataset, aggregated up).
- [ ] GTFS shapes render in Tableau as expected (sometimes coordinate order needs reversal).

---

## 7. Datasets explicitly NOT included (and why)

- **Turnstile Usage Data** — retired/archival. Hourly Ridership supersedes it.
- **GTFS-Realtime feeds** — not needed for historical reporting; only for live dashboards.
- **Mean Distance Between Failures** — useful for ops reporting, but rarely fits a rider-facing dashboard.
- **Customer Feedback** — useful as a separate page, but adds a different grain (free-text categorized) and complicates the model.

If the dashboard scope expands, revisit these.
