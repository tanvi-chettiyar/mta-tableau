-- =============================================================
-- load.sql — \copy raw CSVs into staging tables
-- Run from repo root: psql mta -f postgres/load.sql
-- All staging columns are TEXT to avoid type errors during load.
-- transform.sql handles cleaning, casting, and the 2024 filter.
-- =============================================================

\echo '>>> Dropping and recreating staging tables'

DROP TABLE IF EXISTS mta.stg_stations_complexes  CASCADE;
DROP TABLE IF EXISTS mta.stg_major_incidents     CASCADE;
DROP TABLE IF EXISTS mta.stg_delay_incidents     CASCADE;
DROP TABLE IF EXISTS mta.stg_wait_assessment     CASCADE;
DROP TABLE IF EXISTS mta.stg_otp                 CASCADE;
DROP TABLE IF EXISTS mta.stg_daily_ridership     CASCADE;
DROP TABLE IF EXISTS mta.stg_hourly_ridership    CASCADE;
DROP TABLE IF EXISTS mta.stg_gtfs_routes         CASCADE;
DROP TABLE IF EXISTS mta.stg_gtfs_stops          CASCADE;
DROP TABLE IF EXISTS mta.stg_gtfs_trips          CASCADE;
DROP TABLE IF EXISTS mta.stg_gtfs_stop_times     CASCADE;

CREATE TABLE mta.stg_stations_complexes (
    complex_id              TEXT,
    is_complex              TEXT,
    num_stations            TEXT,
    stop_name               TEXT,
    display_name            TEXT,
    constituent_names       TEXT,
    station_ids             TEXT,
    gtfs_stop_ids           TEXT,
    borough                 TEXT,
    cbd                     TEXT,
    daytime_routes          TEXT,
    structure_type          TEXT,
    latitude                TEXT,
    longitude               TEXT,
    ada                     TEXT,
    ada_notes               TEXT
);

CREATE TABLE mta.stg_major_incidents (
    month                   TEXT,
    division                TEXT,
    line                    TEXT,
    day_type                TEXT,
    category                TEXT,
    count                   TEXT
);

CREATE TABLE mta.stg_delay_incidents (
    month                   TEXT,
    division                TEXT,
    line                    TEXT,
    day_type                TEXT,
    reporting_category      TEXT,
    incidents               TEXT
);

-- Source has a buggy column name "num_timepoints_passing_wait _assessment" with an
-- embedded space. Map all columns positionally via HEADER instead of by name.
CREATE TABLE mta.stg_wait_assessment (
    month                   TEXT,
    division                TEXT,
    line                    TEXT,
    day_type                TEXT,
    period                  TEXT,
    num_passing_timepoints  TEXT,
    num_sched_timepoints    TEXT,
    wait_assessment         TEXT
);

CREATE TABLE mta.stg_otp (
    month                   TEXT,
    division                TEXT,
    line                    TEXT,
    day_type                TEXT,
    num_on_time_trips       TEXT,
    num_sched_trips         TEXT,
    terminal_otp            TEXT
);

CREATE TABLE mta.stg_daily_ridership (
    date                    TEXT,
    mode                    TEXT,
    count                   TEXT
);

CREATE TABLE mta.stg_hourly_ridership (
    transit_timestamp       TEXT,
    transit_mode            TEXT,
    station_complex_id      TEXT,
    station_complex         TEXT,
    borough                 TEXT,
    payment_method          TEXT,
    fare_class_category     TEXT,
    ridership               TEXT,
    transfers               TEXT,
    latitude                TEXT,
    longitude               TEXT,
    georeference            TEXT
);

CREATE TABLE mta.stg_gtfs_routes (
    route_id                TEXT,
    agency_id               TEXT,
    route_short_name        TEXT,
    route_long_name         TEXT,
    route_desc              TEXT,
    route_type              TEXT,
    route_url               TEXT,
    route_color             TEXT,
    route_text_color        TEXT,
    route_sort_order        TEXT
);

CREATE TABLE mta.stg_gtfs_stops (
    stop_id                 TEXT,
    stop_name               TEXT,
    stop_lat                TEXT,
    stop_lon                TEXT,
    location_type           TEXT,
    parent_station          TEXT
);

CREATE TABLE mta.stg_gtfs_trips (
    route_id                TEXT,
    trip_id                 TEXT,
    service_id              TEXT,
    trip_headsign           TEXT,
    direction_id            TEXT,
    shape_id                TEXT
);

CREATE TABLE mta.stg_gtfs_stop_times (
    trip_id                 TEXT,
    stop_id                 TEXT,
    arrival_time            TEXT,
    departure_time          TEXT,
    stop_sequence           TEXT
);

\echo '>>> Loading CSVs (relative paths from repo root)'

\copy mta.stg_stations_complexes FROM 'C:\temp\MTA_Subway_Stations_and_Complexes_20260503.csv'         WITH (FORMAT csv, HEADER true);
\copy mta.stg_major_incidents    FROM 'C:\temp\MTA_Subway_Major_Incidents__Beginning_2015_20260503.csv' WITH (FORMAT csv, HEADER true);
\copy mta.stg_delay_incidents    FROM 'C:\temp\MTA_Subway_Delay-Causing_Incidents__Beginning_2020_20260503.csv' WITH (FORMAT csv, HEADER true);
\copy mta.stg_wait_assessment    FROM 'C:\temp\MTA_Subway_Wait_Assessment__Beginning_2015_20260503.csv' WITH (FORMAT csv, HEADER true);
\copy mta.stg_otp                FROM 'C:\temp\MTA_Subway_Terminal_On-Time_Performance__Beginning_2015_20260503.csv' WITH (FORMAT csv, HEADER true);
\copy mta.stg_daily_ridership    FROM 'C:\temp\MTA_Daily_Ridership_and_Traffic__Beginning_2020_20260503.csv' WITH (FORMAT csv, HEADER true);

\copy mta.stg_hourly_ridership   FROM 'C:\temp\MTA_Subway_Hourly_Ridership_202401.csv'                 WITH (FORMAT csv, HEADER true);
\copy mta.stg_hourly_ridership   FROM 'C:\temp\MTA_Subway_Hourly_Ridership_202402.csv'                 WITH (FORMAT csv, HEADER true);
\copy mta.stg_hourly_ridership   FROM 'C:\temp\MTA_Subway_Hourly_Ridership_202403.csv'                 WITH (FORMAT csv, HEADER true);
\copy mta.stg_hourly_ridership   FROM 'C:\temp\MTA_Subway_Hourly_Ridership_202404.csv'                 WITH (FORMAT csv, HEADER true);
\copy mta.stg_hourly_ridership   FROM 'C:\temp\MTA_Subway_Hourly_Ridership_202405.csv'                 WITH (FORMAT csv, HEADER true);
\copy mta.stg_hourly_ridership   FROM 'C:\temp\MTA_Subway_Hourly_Ridership_202406.csv'                 WITH (FORMAT csv, HEADER true);
\copy mta.stg_hourly_ridership   FROM 'C:\temp\MTA_Subway_Hourly_Ridership_202407.csv'                 WITH (FORMAT csv, HEADER true);
\copy mta.stg_hourly_ridership   FROM 'C:\temp\MTA_Subway_Hourly_Ridership_202408.csv'                 WITH (FORMAT csv, HEADER true);
\copy mta.stg_hourly_ridership   FROM 'C:\temp\MTA_Subway_Hourly_Ridership_202409.csv'                 WITH (FORMAT csv, HEADER true);
\copy mta.stg_hourly_ridership   FROM 'C:\temp\MTA_Subway_Hourly_Ridership_202410.csv'                 WITH (FORMAT csv, HEADER true);
\copy mta.stg_hourly_ridership   FROM 'C:\temp\MTA_Subway_Hourly_Ridership_202411.csv'                 WITH (FORMAT csv, HEADER true);
\copy mta.stg_hourly_ridership   FROM 'C:\temp\MTA_Subway_Hourly_Ridership_202412.csv'                 WITH (FORMAT csv, HEADER true);


\copy mta.stg_gtfs_routes        FROM 'C:\temp\routes.txt'      WITH (FORMAT csv, HEADER true);
\copy mta.stg_gtfs_stops         FROM 'C:\temp\stops.txt'       WITH (FORMAT csv, HEADER true);
\copy mta.stg_gtfs_trips         FROM 'C:\temp\trips.txt'       WITH (FORMAT csv, HEADER true);
\copy mta.stg_gtfs_stop_times    FROM 'C:\temp\stop_times.txt'  WITH (FORMAT csv, HEADER true);

\echo '>>> Staging row counts:'
SELECT 'stations_complexes' AS tbl, COUNT(*) FROM mta.stg_stations_complexes UNION ALL
SELECT 'major_incidents',          COUNT(*) FROM mta.stg_major_incidents     UNION ALL
SELECT 'delay_incidents',          COUNT(*) FROM mta.stg_delay_incidents     UNION ALL
SELECT 'wait_assessment',          COUNT(*) FROM mta.stg_wait_assessment     UNION ALL
SELECT 'otp',                      COUNT(*) FROM mta.stg_otp                 UNION ALL
SELECT 'daily_ridership',          COUNT(*) FROM mta.stg_daily_ridership     UNION ALL
SELECT 'hourly_ridership',         COUNT(*) FROM mta.stg_hourly_ridership    UNION ALL
SELECT 'gtfs_routes',              COUNT(*) FROM mta.stg_gtfs_routes         UNION ALL
SELECT 'gtfs_stops',               COUNT(*) FROM mta.stg_gtfs_stops          UNION ALL
SELECT 'gtfs_trips',               COUNT(*) FROM mta.stg_gtfs_trips          UNION ALL
SELECT 'gtfs_stop_times',          COUNT(*) FROM mta.stg_gtfs_stop_times;
