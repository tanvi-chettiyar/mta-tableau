-- =============================================================
-- MTA Subway Dashboard — PostgreSQL DDL
-- Initial load scope: 2024 (extend to 2020–2024 later)
-- =============================================================

CREATE SCHEMA IF NOT EXISTS mta;

-- ---------------------------------------------------------------
-- DIMENSIONS
-- ---------------------------------------------------------------

CREATE TABLE mta.dim_complex (
    complex_id              INTEGER         PRIMARY KEY,
    is_complex              BOOLEAN,
    num_stations            SMALLINT,
    stop_name               TEXT,
    display_name            TEXT,
    constituent_names       TEXT,           -- comma-separated, informational only
    station_ids             TEXT,           -- raw MTA station IDs
    gtfs_stop_ids           TEXT,           -- parent stop IDs from stops.txt; used to build bridge
    borough                 VARCHAR(5),     -- 'M', 'Bk', 'Bx', 'Q', 'SI'
    cbd                     BOOLEAN,
    daytime_routes          TEXT,           -- e.g. "1 2 3", informational only
    structure_type          TEXT,
    latitude                NUMERIC(9,6),
    longitude               NUMERIC(9,6),
    ada                     SMALLINT,       -- 0=none, 1=full, 2=partial
    ada_notes               TEXT
);

-- Source: GTFS routes.txt
CREATE TABLE mta.dim_route (
    route_id                VARCHAR(10)     PRIMARY KEY,  -- GTFS route_id (e.g. 'A', 'GS', 'FS')
    route_short_name        TEXT,
    route_long_name         TEXT,
    route_color             CHAR(6),
    route_text_color        CHAR(6),
    division                CHAR(1)         -- 'A' or 'B', derived (A=IRT, B=BMT/IND)
);

-- Lookup: maps every "line" value that appears in source CSVs → canonical GTFS route_id.
-- Necessary because MTA uses different naming conventions across datasets and over time.
-- See JOIN GAP NOTES at bottom of this file.
CREATE TABLE mta.dim_line_route_map (
    mta_line                TEXT            PRIMARY KEY,
    route_id                VARCHAR(10)     REFERENCES dim_route(route_id),
    notes                   TEXT
);

CREATE TABLE mta.dim_date (
    date                    DATE            PRIMARY KEY,
    year                    SMALLINT,
    month                   SMALLINT,
    quarter                 SMALLINT,
    day_of_week             TEXT,
    is_weekend              BOOLEAN,
    is_holiday              BOOLEAN
);

-- ---------------------------------------------------------------
-- BRIDGE
-- ---------------------------------------------------------------

-- Built via ETL from GTFS:
--   trips → stop_times → stops (parent_station) → dim_complex (via gtfs_stop_ids)
-- One row per (complex, route) pair; a complex serving 3 lines = 3 rows.
CREATE TABLE mta.bridge_complex_route (
    complex_id              INTEGER         NOT NULL REFERENCES dim_complex(complex_id),
    route_id                VARCHAR(10)     NOT NULL REFERENCES dim_route(route_id),
    PRIMARY KEY (complex_id, route_id)
);

-- ---------------------------------------------------------------
-- FACTS
-- ---------------------------------------------------------------

-- Source: MTA_Subway_Hourly_Ridership_202401.csv (one month for now)
-- Grain: timestamp × complex × payment_method × fare_class
-- Joins to dim_complex directly on station_complex_id.
-- Joins to dim_route via bridge_complex_route.
-- NOTE: filter transit_mode = 'subway' to exclude SIR (Staten Island Railway)
--       which uses complex_ids in the 500s not present in dim_complex subway rows.
CREATE TABLE mta.fact_hourly_ridership (
    transit_timestamp       TIMESTAMP       NOT NULL,
    transit_mode            TEXT            NOT NULL,
    station_complex_id      INTEGER         NOT NULL REFERENCES dim_complex(complex_id),
    payment_method          TEXT            NOT NULL,   -- 'omny' | 'metrocard'
    fare_class_category     TEXT            NOT NULL,
    ridership               NUMERIC(10,1),
    transfers               NUMERIC(10,1),
    latitude                NUMERIC(9,6),
    longitude               NUMERIC(9,6),
    PRIMARY KEY (transit_timestamp, station_complex_id, payment_method, fare_class_category)
);

-- Source: MTA_Subway_Major_Incidents__Beginning_2015_20260503.csv
-- Grain: month × line × day_type × category
-- `line` is the raw MTA line code; join to dim_route via dim_line_route_map.
-- Exclude rows where line = '' (blank) on load.
CREATE TABLE mta.fact_major_incidents (
    month                   DATE            NOT NULL,   -- first of month (YYYY-MM-01)
    line                    TEXT            NOT NULL,   -- raw MTA line code
    day_type                SMALLINT        NOT NULL,   -- 1=weekday, 2=weekend/holiday
    category                TEXT            NOT NULL,   -- 'Signals','Track','Subway Car', etc.
    incident_count          INTEGER,
    PRIMARY KEY (month, line, day_type, category)
);

-- Source: MTA_Subway_Delay-Causing_Incidents__Beginning_2020_20260503.csv
-- Grain: month × line × day_type × reporting_category
-- 3,343 rows have blank reporting_category (all with 0 incidents); exclude on load.
-- `Incidents` column in source is the delay count (confusingly named).
CREATE TABLE mta.fact_delay_causing_incidents (
    month                   DATE            NOT NULL,
    line                    TEXT            NOT NULL,
    day_type                SMALLINT        NOT NULL,
    reporting_category      TEXT            NOT NULL,
    delay_count             INTEGER,
    PRIMARY KEY (month, line, day_type, reporting_category)
);

-- Source: MTA_Subway_Wait_Assessment__Beginning_2015_20260503.csv
-- Grain: month × line × day_type × period
-- `wait_assessment_pct` stored as decimal (source has trailing '%' — strip it on load).
-- Comma-formatted integers in num_* columns — strip commas on load.
-- WARNING: 2024 data has BOTH old naming (S 42nd, S Fkln, S Rock, JZ) AND
--          new GTFS naming (GS, FS, H, J) for the same months — see gap notes.
CREATE TABLE mta.fact_wait_assessment (
    month                   DATE            NOT NULL,
    line                    TEXT            NOT NULL,
    day_type                SMALLINT        NOT NULL,
    period                  TEXT            NOT NULL,   -- 'peak' | 'offpeak'
    num_passing_timepoints  INTEGER,
    num_sched_timepoints    INTEGER,
    wait_assessment_pct     NUMERIC(8,4),
    PRIMARY KEY (month, line, day_type, period)
);

-- Source: MTA_Subway_Terminal_On-Time_Performance__Beginning_2015_20260503.csv
-- Grain: month × line × day_type (no period column — one row per combination)
-- Comma-formatted integers in num_* columns — strip commas on load.
-- Same line naming inconsistency as fact_wait_assessment.
CREATE TABLE mta.fact_otp (
    month                   DATE            NOT NULL,
    line                    TEXT            NOT NULL,
    day_type                SMALLINT        NOT NULL,
    num_on_time_trips       INTEGER,
    num_sched_trips         INTEGER,
    terminal_otp_pct        NUMERIC(8,4),
    PRIMARY KEY (month, line, day_type)
);

-- Source: MTA_Daily_Ridership_and_Traffic__Beginning_2020_20260503.csv
-- Grain: date × mode  (system-wide; no station breakdown)
-- This table CANNOT join to dim_complex or dim_route — use for KPI tiles only.
-- Source date format: MM/DD/YYYY — cast on load.
-- Comma-formatted Count column — strip commas on load.
CREATE TABLE mta.fact_daily_ridership (
    date                    DATE            NOT NULL REFERENCES dim_date(date),
    mode                    TEXT            NOT NULL,   -- 'Subway','Bus','LIRR','MNR','SIR','AAR','BT','CBD Entries','CRZ Entries'
    ridership               INTEGER,
    PRIMARY KEY (date, mode)
);



-- =============================================================
-- JOIN GAP NOTES
-- =============================================================
--
-- 1. line → dim_route (CRITICAL — affects all 4 service quality fact tables)
--    -----------------------------------------------------------------------
--    The `line` column in fact_major_incidents, fact_delay_causing_incidents,
--    fact_wait_assessment, and fact_otp does NOT directly match GTFS route_id.
--    Use dim_line_route_map as the bridge:
--
--      fact_major_incidents fi
--      JOIN dim_line_route_map m  ON fi.line = m.mta_line
--      JOIN dim_route r           ON m.route_id = r.route_id
--
--    Gaps:
--    a) JZ → NULL route_id. J and Z cannot be separated in these datasets.
--       Affects Penn Station analysis: neither J nor Z serves Penn Station,
--       so this is moot for the core dashboard story.
--    b) Shuttles: old names (S 42nd, S Fkln, S Rock) and GTFS names (GS, FS, H)
--       both appear in the 2024 WA and OTP data for the SAME months.
--       THIS CAUSES DOUBLE-COUNTING. Filter to one convention per time period
--       before aggregating WA/OTP. Recommend: for 2024 keep GTFS names (GS/FS/H),
--       drop the S 42nd / S Fkln / S Rock rows.
--    c) Blank line in fact_major_incidents → excluded on load (no valid join).
--
-- 2. fact_hourly_ridership → dim_route
--    -----------------------------------
--    No direct path. Route reached via:
--      fact_hourly_ridership → dim_complex → bridge_complex_route → dim_route
--    This is by design. One complex serves multiple routes (e.g. complex 318
--    serves lines 1, 2, 3); the bridge is a many-to-many resolver.
--
-- 3. Service quality facts → dim_complex
--    -------------------------------------
--    fact_major_incidents / fact_delay_causing_incidents / fact_wait_assessment
--    / fact_otp have NO complex_id. Path to complex:
--      fact_* → dim_line_route_map → dim_route → bridge_complex_route → dim_complex
--    Three hops. Correct, but means you cannot filter incidents by station without
--    going through the bridge.
--
-- 4. fact_daily_ridership → anything else
--    ----------------------------------------
--    This table is ISOLATED. It has no route_id, no complex_id, and no station.
--    It is system-wide by mode. Use it only for KPI tiles (total subway ridership).
--    It cannot be joined to other facts in the same query without cross-joining.
--
-- 5. bridge_complex_route construction (ETL step, not a load gap)
--    --------------------------------------------------------------
--    Build from GTFS:
--      stop_times → stops (platform → parent_station) → dim_complex (via gtfs_stop_ids)
--      trips → route_id
--    The dim_complex.gtfs_stop_ids column holds the GTFS parent stop IDs.
--    Join path: trips.route_id + trips.trip_id → stop_times.stop_id
--               → stops.parent_station → dim_complex WHERE gtfs_stop_ids LIKE '%' || parent_station || '%'
--    Note: gtfs_stop_ids is multi-valued (comma-separated) — use string matching or
--    split into a separate table before joining.
--
-- 6. Hourly ridership coverage gap
--    --------------------------------
--    fact_hourly_ridership currently contains January 2024 only (one month).
--    All other fact tables cover full 2024 (and beyond for incidents/WA/OTP).
--    Any query joining hourly ridership to service quality will return data
--    only for January 2024. Add remaining 2024 months as files become available.
--
-- 7. SIR (Staten Island Railway) in hourly ridership
--    --------------------------------------------------
--    The hourly ridership CSV includes transit_mode = 'staten_island_railway'
--    with complex_ids in the 500s (e.g. 501). These IDs exist in
--    MTA_Subway_Stations_and_Complexes but represent SIR, not subway.
--    dim_route has route_id = 'SI' for SIR. If you want subway-only analysis,
--    filter: WHERE transit_mode = 'subway'.
