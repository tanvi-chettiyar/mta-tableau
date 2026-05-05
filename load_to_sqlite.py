"""
Load all MTA datasets into mta.db (SQLite).
Run from repo root: python3 load_to_sqlite.py
"""

import csv
import sqlite3

DB = "mta.db"
DATASETS = "datasets"

DDL = """
CREATE TABLE IF NOT EXISTS stations (
    gtfs_stop_id          TEXT,
    station_id            INTEGER,
    complex_id            INTEGER,
    division              TEXT,
    corridor              TEXT,        -- named 'Line' in source; renamed to avoid collision with line letters
    stop_name             TEXT,
    borough               TEXT,
    cbd                   INTEGER,     -- 0/1
    daytime_routes        TEXT,
    structure             TEXT,
    latitude              REAL,
    longitude             REAL,
    north_direction_label TEXT,
    south_direction_label TEXT,
    ada                   INTEGER,
    ada_northbound        INTEGER,
    ada_southbound        INTEGER,
    ada_notes             TEXT,
    georeference          TEXT
);

CREATE TABLE IF NOT EXISTS incidents (
    month    TEXT,    -- YYYY-MM-DD
    division TEXT,
    line     TEXT,
    day_type INTEGER, -- 1=weekday, 2=weekend/holiday
    category TEXT,
    count    INTEGER
);

CREATE TABLE IF NOT EXISTS delays (
    month              TEXT,    -- YYYY-MM-DD
    division           TEXT,
    line               TEXT,
    day_type           INTEGER, -- 1=weekday, 2=weekend/holiday
    reporting_category TEXT,
    delays             INTEGER  -- comma-stripped on load
);

CREATE TABLE IF NOT EXISTS ridership (
    transit_timestamp   TEXT,    -- M/D/YYYY H:MM:SS AM (original format preserved)
    transit_mode        TEXT,
    station_complex_id  INTEGER,
    station_complex     TEXT,
    borough             TEXT,
    payment_method      TEXT,
    fare_class_category TEXT,
    ridership           INTEGER, -- comma-stripped on load
    transfers           INTEGER,
    latitude            REAL,
    longitude           REAL,
    georeference        TEXT
);

CREATE TABLE IF NOT EXISTS ridership_sample (
    transit_timestamp   TEXT,
    transit_mode        TEXT,
    station_complex_id  INTEGER,
    station_complex     TEXT,
    borough             TEXT,
    payment_method      TEXT,
    fare_class_category TEXT,
    ridership           INTEGER,
    transfers           INTEGER,
    latitude            REAL,
    longitude           REAL,
    georeference        TEXT
);

CREATE TABLE IF NOT EXISTS bridge (
    line       TEXT,
    complex_id INTEGER
);

CREATE TABLE IF NOT EXISTS final_dataset (
    month           TEXT,    -- YYYY-MM-DD (timezone offset stripped on load)
    station_complex TEXT,
    ridership       INTEGER,
    total_delays    INTEGER,
    total_incidents INTEGER,
    human_impact    INTEGER,
    delay_intensity REAL
);
"""

INDEXES = """
CREATE INDEX IF NOT EXISTS idx_incidents_month_line  ON incidents (month, line);
CREATE INDEX IF NOT EXISTS idx_incidents_line        ON incidents (line);
CREATE INDEX IF NOT EXISTS idx_delays_month_line     ON delays (month, line);
CREATE INDEX IF NOT EXISTS idx_delays_line           ON delays (line);
CREATE INDEX IF NOT EXISTS idx_ridership_complex_ts  ON ridership (station_complex_id, transit_timestamp);
CREATE INDEX IF NOT EXISTS idx_bridge_line           ON bridge (line);
CREATE INDEX IF NOT EXISTS idx_bridge_complex        ON bridge (complex_id);
CREATE INDEX IF NOT EXISTS idx_stations_complex      ON stations (complex_id);
"""


def load(con, table, path, transform):
    with open(path, newline="", encoding="utf-8") as f:
        rows = [transform(r) for r in csv.DictReader(f)]
    if not rows:
        return 0
    placeholders = ", ".join(["?"] * len(rows[0]))
    con.executemany(
        f"INSERT INTO {table} VALUES ({placeholders})",
        [tuple(r.values()) for r in rows],
    )
    return len(rows)


def int_strip(val):
    return int(val.replace(",", "")) if val.strip() else None


def main():
    con = sqlite3.connect(DB)
    con.executescript(DDL)

    print("Loading stations ...", end=" ", flush=True)
    n = load(con, "stations", f"{DATASETS}/MTA_Subway_Stations_20260427.csv", lambda r: {
        "gtfs_stop_id":          r["GTFS Stop ID"],
        "station_id":            int(r["Station ID"]),
        "complex_id":            int(r["Complex ID"]),
        "division":              r["Division"],
        "corridor":              r["Line"],
        "stop_name":             r["Stop Name"],
        "borough":               r["Borough"],
        "cbd":                   1 if r["CBD"].lower() == "true" else 0,
        "daytime_routes":        r["Daytime Routes"],
        "structure":             r["Structure"],
        "latitude":              float(r["GTFS Latitude"]) if r["GTFS Latitude"] else None,
        "longitude":             float(r["GTFS Longitude"]) if r["GTFS Longitude"] else None,
        "north_direction_label": r["North Direction Label"],
        "south_direction_label": r["South Direction Label"],
        "ada":                   int(r["ADA"]) if r["ADA"] else None,
        "ada_northbound":        int(r["ADA Northbound"]) if r["ADA Northbound"] else None,
        "ada_southbound":        int(r["ADA Southbound"]) if r["ADA Southbound"] else None,
        "ada_notes":             r["ADA Notes"],
        "georeference":          r["Georeference"],
    })
    print(f"{n} rows")

    print("Loading incidents ...", end=" ", flush=True)
    n = load(con, "incidents", f"{DATASETS}/MTA_Subway_Major_Incidents__Beginning_2015_20260427.csv", lambda r: {
        "month":    r["month"][:10],
        "division": r["division"],
        "line":     r["line"],
        "day_type": int(r["day_type"]),
        "category": r["category"],
        "count":    int(r["count"]),
    })
    print(f"{n} rows")

    print("Loading delays ...", end=" ", flush=True)
    n = load(con, "delays", f"{DATASETS}/MTA_Subway_Trains_Delayed__Beginning_2020_20260427.csv", lambda r: {
        "month":              r["month"][:10],
        "division":           r["division"],
        "line":               r["line"],
        "day_type":           int(r["day_type"]),
        "reporting_category": r["reporting_category"],
        "delays":             int_strip(r["delays"]),
    })
    print(f"{n} rows")

    print("Loading ridership (681 K rows — takes ~10 s) ...", end=" ", flush=True)
    n = load(con, "ridership", f"{DATASETS}/MTA_Subway_Hourly_Ridership__2020-2024_20260427.csv", lambda r: {
        "transit_timestamp":   r["transit_timestamp"],
        "transit_mode":        r["transit_mode"],
        "station_complex_id":  int(r["station_complex_id"]),
        "station_complex":     r["station_complex"],
        "borough":             r["borough"],
        "payment_method":      r["payment_method"],
        "fare_class_category": r["fare_class_category"],
        "ridership":           int_strip(r["ridership"]),
        "transfers":           int(r["transfers"]),
        "latitude":            float(r["latitude"]) if r["latitude"] else None,
        "longitude":           float(r["longitude"]) if r["longitude"] else None,
        "georeference":        r["Georeference"],
    })
    print(f"{n} rows")

    print("Loading ridership_sample ...", end=" ", flush=True)
    n = load(con, "ridership_sample", f"{DATASETS}/mta_hourly_dataset_sample.csv", lambda r: {
        "transit_timestamp":   r["transit_timestamp"],
        "transit_mode":        r["transit_mode"],
        "station_complex_id":  int(r["station_complex_id"]),
        "station_complex":     r["station_complex"],
        "borough":             r["borough"],
        "payment_method":      r["payment_method"],
        "fare_class_category": r["fare_class_category"],
        "ridership":           int_strip(r["ridership"]),
        "transfers":           int(r["transfers"]),
        "latitude":            float(r["latitude"]) if r["latitude"] else None,
        "longitude":           float(r["longitude"]) if r["longitude"] else None,
        "georeference":        r["georeference"],
    })
    print(f"{n} rows")

    print("Loading bridge ...", end=" ", flush=True)
    n = load(con, "bridge", f"{DATASETS}/bridge_line_station.csv", lambda r: {
        "line":       r["line"],
        "complex_id": int(r["complex_id"]),
    })
    print(f"{n} rows")

    print("Loading final_dataset ...", end=" ", flush=True)
    n = load(con, "final_dataset", f"{DATASETS}/MTA_Final_Dataset.csv", lambda r: {
        "month":           r["month"][:10],   # strip timezone offset
        "station_complex": r["station_complex"],
        "ridership":       int(r["ridership"]),
        "total_delays":    int(r["total_delays"]),
        "total_incidents": int(r["total_incidents"]),
        "human_impact":    int(r["human_impact"]),
        "delay_intensity": float(r["delay_intensity"]),
    })
    print(f"{n} rows")

    print("Building indexes ...", end=" ", flush=True)
    con.executescript(INDEXES)
    print("done")

    con.commit()
    con.close()
    print(f"\nDatabase written to {DB}")


if __name__ == "__main__":
    main()
