-- =============================================================
-- transform.sql — staging tables → typed star schema
-- Run AFTER schema.sql (which creates the empty target tables)
-- and load.sql (which fills the stg_* tables).
-- All facts filter to 2022-2024 here. Change the BETWEEN range on each
-- fact's WHERE clause to extend the time window.
-- =============================================================

--\echo '>>> Truncating target tables'

TRUNCATE
    fact_hourly_ridership,
    fact_major_incidents,
    fact_delay_causing_incidents,
    fact_wait_assessment,
    fact_otp,
    fact_daily_ridership,
    bridge_complex_route,
    dim_line_route_map,
    dim_route,
    dim_complex,
    dim_date
CASCADE;


-- ----------------------------------------------------------------
-- DIMENSIONS
-- ----------------------------------------------------------------

--\echo '>>> dim_complex'

INSERT INTO mta.dim_complex (
    complex_id, is_complex, num_stations, stop_name, display_name,
    constituent_names, station_ids, gtfs_stop_ids, borough, cbd,
    daytime_routes, structure_type, latitude, longitude, ada, ada_notes
)
SELECT
    NULLIF(complex_id, '')::INTEGER,
    LOWER(is_complex)::BOOLEAN,
    NULLIF(num_stations, '')::SMALLINT,
    stop_name,
    display_name,
    constituent_names,
    station_ids,
    gtfs_stop_ids,
    borough,
    LOWER(cbd)::BOOLEAN,
    daytime_routes,
    structure_type,
    NULLIF(latitude,  '')::NUMERIC(9,6),
    NULLIF(longitude, '')::NUMERIC(9,6),
    NULLIF(ada, '')::SMALLINT,
    ada_notes
FROM mta.stg_stations_complexes
WHERE complex_id ~ '^\d+$';


--\echo '>>> dim_route'

INSERT INTO mta.dim_route (
    route_id, route_short_name, route_long_name,
    route_color, route_text_color, division
)
SELECT
    route_id,
    route_short_name,
    route_long_name,
    NULLIF(route_color, ''),
    NULLIF(route_text_color, ''),
    -- A division (IRT) = numbered routes; B division (BMT/IND) = lettered
    CASE WHEN route_id ~ '^[1-7]X?$' THEN 'A' ELSE 'B' END
FROM mta.stg_gtfs_routes
WHERE route_id IS NOT NULL;


--\echo '>>> dim_line_route_map'

INSERT INTO mta.dim_line_route_map (mta_line, route_id, notes) VALUES
    ('1','1',NULL),('2','2',NULL),('3','3',NULL),('4','4',NULL),('5','5',NULL),
    ('6','6',NULL),('7','7',NULL),
    ('A','A',NULL),('B','B',NULL),('C','C',NULL),('D','D',NULL),('E','E',NULL),
    ('F','F',NULL),('G','G',NULL),('J','J',NULL),('L','L',NULL),('M','M',NULL),
    ('N','N',NULL),('Q','Q',NULL),('R','R',NULL),('W','W',NULL),
    ('GS','GS','42nd St Shuttle (GTFS naming)'),
    ('FS','FS','Franklin Av Shuttle (GTFS naming)'),
    ('H','H','Rockaway Park Shuttle (GTFS naming)'),
    ('S 42nd','GS','42nd St Shuttle (old MTA naming)'),
    ('S Fkln','FS','Franklin Av Shuttle (old MTA naming)'),
    ('S Rock','H','Rockaway Park Shuttle (old MTA naming)'),
    ('JZ',NULL,'J+Z combined — no 1:1 GTFS route_id');


--\echo '>>> dim_date (2020-01-01 to 2026-12-31)'

INSERT INTO mta.dim_date (date, year, month, quarter, day_of_week, is_weekend, is_holiday)
SELECT
    d::DATE,
    EXTRACT(YEAR    FROM d)::SMALLINT,
    EXTRACT(MONTH   FROM d)::SMALLINT,
    EXTRACT(QUARTER FROM d)::SMALLINT,
    TO_CHAR(d, 'Day'),
    EXTRACT(ISODOW  FROM d) >= 6,
    -- Lightweight holiday flag: just New Year + Independence Day + Christmas
    -- Replace with a holidays table later if needed.
    (TO_CHAR(d, 'MM-DD') IN ('01-01','07-04','12-25'))
FROM generate_series('2020-01-01'::DATE, '2026-12-31'::DATE, '1 day') AS d;


-- ----------------------------------------------------------------
-- BRIDGE: complex × route (built from GTFS)
-- ----------------------------------------------------------------
-- Path: trips → stop_times → stops (parent_station) → dim_complex.gtfs_stop_ids
-- Complication: dim_complex.gtfs_stop_ids is a comma-separated string.
-- We unnest it to one row per (complex, gtfs_stop_id) for clean joining.
-- ----------------------------------------------------------------

--\echo '>>> bridge_complex_route'

WITH complex_to_gtfs AS (
    -- one row per (complex_id, gtfs_stop_id) — unnest the multi-valued column
    SELECT
        complex_id,
        TRIM(gtfs_stop_id) AS gtfs_stop_id
    FROM mta.dim_complex,
         LATERAL UNNEST(STRING_TO_ARRAY(gtfs_stop_ids, ',')) AS gtfs_stop_id
    WHERE gtfs_stop_ids IS NOT NULL
),
stop_to_parent AS (
    -- map every platform stop_id → parent station stop_id
    -- platforms have a parent_station; parent stations are themselves
    SELECT
        stop_id,
        COALESCE(NULLIF(parent_station, ''), stop_id) AS parent_id
    FROM mta.stg_gtfs_stops
)
INSERT INTO mta.bridge_complex_route (complex_id, route_id)
SELECT DISTINCT
    ctg.complex_id,
    t.route_id
FROM mta.stg_gtfs_stop_times st
JOIN stop_to_parent      sp  ON sp.stop_id      = st.stop_id
JOIN complex_to_gtfs     ctg ON ctg.gtfs_stop_id = sp.parent_id
JOIN mta.stg_gtfs_trips      t   ON t.trip_id       = st.trip_id
JOIN mta.dim_route           r   ON r.route_id      = t.route_id
ON CONFLICT DO NOTHING;


-- ----------------------------------------------------------------
-- FACTS — all filtered to 2024
-- ----------------------------------------------------------------

--\echo '>>> fact_major_incidents (2022-2024)'

INSERT INTO mta.fact_major_incidents (month, line, day_type, category, incident_count)
SELECT
    month::DATE,
    line,
    day_type::SMALLINT,
    category,
    NULLIF(count, '')::INTEGER
FROM mta.stg_major_incidents
WHERE EXTRACT(YEAR FROM month::DATE) BETWEEN 2022 AND 2024
  AND line IS NOT NULL AND line <> ''
  AND category IS NOT NULL AND category <> '';


--\echo '>>> fact_delay_causing_incidents (2022-2024)'

INSERT INTO mta.fact_delay_causing_incidents (month, line, day_type, reporting_category, delay_count)
SELECT
    month::DATE,
    line,
    day_type::SMALLINT,
    reporting_category,
    REPLACE(NULLIF(incidents, ''), ',', '')::INTEGER
FROM mta.stg_delay_incidents
WHERE EXTRACT(YEAR FROM month::DATE) BETWEEN 2022 AND 2024
  AND line IS NOT NULL AND line <> ''
  AND reporting_category IS NOT NULL AND reporting_category <> '';


-- WA + OTP have a documented dedup issue: from 2024 onward, both old shuttle codes
-- (S 42nd, S Fkln, S Rock) AND GTFS codes (GS, FS, H) appear for the same months.
-- For 2024+ rows: keep GTFS codes (GS/FS/H), drop the legacy text-named rows.
-- Pre-2024 rows have only old codes — keep them as-is (dim_line_route_map maps them to GTFS).
--\echo '>>> fact_wait_assessment (2022-2024, deduped)'

INSERT INTO mta.fact_wait_assessment (
    month, line, day_type, period,
    num_passing_timepoints, num_sched_timepoints, wait_assessment_pct
)
SELECT
    month::DATE,
    line,
    day_type::SMALLINT,
    period,
    REPLACE(NULLIF(num_passing_timepoints, ''), ',', '')::INTEGER,
    REPLACE(NULLIF(num_sched_timepoints,    ''), ',', '')::INTEGER,
    REPLACE(NULLIF(wait_assessment, ''), '%', '')::NUMERIC(8,4)
FROM mta.stg_wait_assessment
WHERE EXTRACT(YEAR FROM month::DATE) BETWEEN 2022 AND 2024
  AND NOT (EXTRACT(YEAR FROM month::DATE) >= 2024 AND line IN ('S 42nd', 'S Fkln', 'S Rock'));


--\echo '>>> fact_otp (2022-2024, deduped)'

INSERT INTO mta.fact_otp (
    month, line, day_type,
    num_on_time_trips, num_sched_trips, terminal_otp_pct
)
SELECT
    month::DATE,
    line,
    day_type::SMALLINT,
    REPLACE(NULLIF(num_on_time_trips, ''), ',', '')::INTEGER,
    REPLACE(NULLIF(num_sched_trips,   ''), ',', '')::INTEGER,
    REPLACE(NULLIF(terminal_otp, ''), '%', '')::NUMERIC(8,4)
FROM mta.stg_otp
WHERE EXTRACT(YEAR FROM month::DATE) BETWEEN 2022 AND 2024
  AND NOT (EXTRACT(YEAR FROM month::DATE) >= 2024 AND line IN ('S 42nd', 'S Fkln', 'S Rock'));


--\echo '>>> fact_daily_ridership (2022-2024)'

INSERT INTO mta.fact_daily_ridership (date, mode, ridership)
SELECT
    TO_DATE(date, 'MM/DD/YYYY'),
    mode,
    REPLACE(NULLIF(count, ''), ',', '')::INTEGER
FROM mta.stg_daily_ridership
WHERE TO_DATE(date, 'MM/DD/YYYY') BETWEEN '2022-01-01' AND '2024-12-31';


-- Loaded year-by-year (3 separate INSERTs) so progress is visible and a
-- failure on one year doesn't roll back the others. Each year is independent.

--\echo '>>> fact_hourly_ridership 1/3 (2022)'

INSERT INTO mta.fact_hourly_ridership (
    transit_timestamp, transit_mode, station_complex_id,
    payment_method, fare_class_category, ridership, transfers,
    latitude, longitude
)
SELECT
    transit_timestamp::TIMESTAMP,
    transit_mode,
    NULLIF(station_complex_id, '')::INTEGER,
    payment_method,
    fare_class_category,
    NULLIF(ridership, '')::NUMERIC(10,1),
    NULLIF(transfers, '')::NUMERIC(10,1),
    NULLIF(latitude,  '')::NUMERIC(9,6),
    NULLIF(longitude, '')::NUMERIC(9,6)
FROM mta.stg_hourly_ridership
WHERE transit_mode = 'subway'                                 -- exclude SIR
  AND EXTRACT(YEAR FROM transit_timestamp::TIMESTAMP) = 2022
  AND NULLIF(station_complex_id, '')::INTEGER IN (
      SELECT complex_id FROM mta.dim_complex                       -- enforce FK
  );


--\echo '>>> fact_hourly_ridership 2/3 (2023)'

INSERT INTO mta.fact_hourly_ridership (
    transit_timestamp, transit_mode, station_complex_id,
    payment_method, fare_class_category, ridership, transfers,
    latitude, longitude
)
SELECT
    transit_timestamp::TIMESTAMP,
    transit_mode,
    NULLIF(station_complex_id, '')::INTEGER,
    payment_method,
    fare_class_category,
    NULLIF(ridership, '')::NUMERIC(10,1),
    NULLIF(transfers, '')::NUMERIC(10,1),
    NULLIF(latitude,  '')::NUMERIC(9,6),
    NULLIF(longitude, '')::NUMERIC(9,6)
FROM mta.stg_hourly_ridership
WHERE transit_mode = 'subway'                                 -- exclude SIR
  AND EXTRACT(YEAR FROM transit_timestamp::TIMESTAMP) = 2023
  AND NULLIF(station_complex_id, '')::INTEGER IN (
      SELECT complex_id FROM mta.dim_complex                       -- enforce FK
  );


--\echo '>>> fact_hourly_ridership 3/3 (2024)'

INSERT INTO mta.fact_hourly_ridership (
    transit_timestamp, transit_mode, station_complex_id,
    payment_method, fare_class_category, ridership, transfers,
    latitude, longitude
)
SELECT
    transit_timestamp::TIMESTAMP,
    transit_mode,
    NULLIF(station_complex_id, '')::INTEGER,
    payment_method,
    fare_class_category,
    NULLIF(ridership, '')::NUMERIC(10,1),
    NULLIF(transfers, '')::NUMERIC(10,1),
    NULLIF(latitude,  '')::NUMERIC(9,6),
    NULLIF(longitude, '')::NUMERIC(9,6)
FROM mta.stg_hourly_ridership
WHERE transit_mode = 'subway'                                 -- exclude SIR
  AND EXTRACT(YEAR FROM transit_timestamp::TIMESTAMP) = 2024
  AND NULLIF(station_complex_id, '')::INTEGER IN (
      SELECT complex_id FROM mta.dim_complex                       -- enforce FK
  );


--\echo '>>> Fact table row counts:'
SELECT 'major_incidents'          AS tbl, COUNT(*) FROM mta.fact_major_incidents          UNION ALL
SELECT 'delay_causing_incidents', COUNT(*) FROM mta.fact_delay_causing_incidents UNION ALL
SELECT 'wait_assessment',         COUNT(*) FROM mta.fact_wait_assessment         UNION ALL
SELECT 'otp',                     COUNT(*) FROM mta.fact_otp                     UNION ALL
SELECT 'daily_ridership',         COUNT(*) FROM mta.fact_daily_ridership         UNION ALL
SELECT 'hourly_ridership',        COUNT(*) FROM mta.fact_hourly_ridership        UNION ALL
SELECT 'bridge_complex_route',    COUNT(*) FROM mta.bridge_complex_route;