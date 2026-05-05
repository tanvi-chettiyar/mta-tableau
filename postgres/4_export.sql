-- =============================================================
-- export.sql — star schema → wide CSVs in C:\temp\exports\
-- Run from repo root: psql mta -f postgres/export.sql
-- Produces 6 CSVs that the Tableau workbook joins via relationships.
-- =============================================================

-- ----------------------------------------------------------------
-- Reusable concept: line_group
--   '1/2/3' = the Penn red corridor
--   'A/C/E' = the Penn blue corridor
--   'Other' = everything else (kept in some exports for context)
-- ----------------------------------------------------------------

\echo '>>> 1/5 monthly_incidents_delays.csv'

\copy (
    SELECT
        i.month,
        i.line,
        m.route_id,
        CASE
            WHEN m.route_id IN ('1','2','3') THEN '1/2/3'
            WHEN m.route_id IN ('A','C','E') THEN 'A/C/E'
            ELSE 'Other'
        END AS line_group,
        i.day_type,
        i.category,
        i.incident_count,
        d.reporting_category,
        d.delay_count
    FROM mta.fact_major_incidents i
    LEFT JOIN mta.dim_line_route_map m ON m.mta_line = i.line
    LEFT JOIN mta.fact_delay_causing_incidents d
           ON d.month = i.month
          AND d.line = i.line
          AND d.day_type = i.day_type
    WHERE m.route_id IN ('1','2','3','A','C','E')   -- Penn corridor only
) TO 'C:\temp\exports\monthly_incidents_delays.csv' WITH (FORMAT csv, HEADER true);


\echo '>>> 2/5 monthly_ridership.csv'

\copy (
    SELECT
        DATE_TRUNC('month', f.transit_timestamp)::DATE AS month,
        f.station_complex_id          AS complex_id,
        c.display_name                AS complex_name,
        CASE
            WHEN f.station_complex_id IN (614,611,318,321,320,319,601,323,324,325,327,328,329,635)  THEN '1/2/3'
            WHEN f.station_complex_id IN (164,165,618,167,168,169,624,628,636)                      THEN 'A/C/E'
            WHEN f.station_complex_id IN (613,610,602,619,337,620,617)                              THEN '4/5/6'
            WHEN f.station_complex_id IN (225,609,607,231,26)                                       THEN 'B/D/F/M'
            ELSE 'Other'
        END AS line_group,
        SUM(f.ridership)::INTEGER AS ridership
    FROM mta.fact_hourly_ridership f
    JOIN mta.dim_complex c ON c.complex_id = f.station_complex_id
    WHERE f.station_complex_id IN (
        -- 1/2/3: Columbus Circle → Times Sq → Penn → 28/23/18 St → 14 St → Christopher → Houston → Canal → Chambers → WTC → Rector → South Ferry
        614, 611, 318, 319, 320, 321, 601, 323, 324, 325, 327, 328, 329, 635,
        -- A/C/E: Penn → 23 St → 14 St-8 Av → W4 St → Spring St → Canal → WTC/Chambers → Fulton → Jay St (Brooklyn)
        164, 165, 618, 167, 168, 169, 624, 628, 636,
        -- 4/5/6: 59 St-Lex → Grand Central → Union Sq → Broadway-Lafayette → Nevins St → Borough Hall → Atlantic Av (Brooklyn)
        613, 610, 602, 619, 337, 620, 617,
        -- B/D/F/M: Rockefeller Ctr → Bryant Pk → Herald Sq → Grand St → DeKalb Av (Brooklyn)
        225, 609, 607, 231, 26
    )
    GROUP BY 1, 2, 3, 4
) TO 'C:\temp\exports\monthly_ridership.csv' WITH (FORMAT csv, HEADER true);


\echo '>>> 3/5 service_quality.csv'

\copy (
    SELECT
        COALESCE(w.month, o.month)              AS month,
        COALESCE(w.line,  o.line)               AS line,
        m.route_id,
        CASE
            WHEN m.route_id IN ('1','2','3') THEN '1/2/3'
            WHEN m.route_id IN ('A','C','E') THEN 'A/C/E'
            ELSE 'Other'
        END                                     AS line_group,
        COALESCE(w.day_type, o.day_type)        AS day_type,
        w.period,
        w.wait_assessment_pct,
        o.terminal_otp_pct
    FROM mta.fact_wait_assessment w
    FULL OUTER JOIN mta.fact_otp o
           ON w.month = o.month
          AND w.line  = o.line
          AND w.day_type = o.day_type
    LEFT JOIN mta.dim_line_route_map m ON m.mta_line = COALESCE(w.line, o.line)
    WHERE m.route_id IN ('1','2','3','A','C','E')
) TO 'C:\temp\exports\service_quality.csv' WITH (FORMAT csv, HEADER true);


\echo '>>> 4/5 hourly_ridership_corridor.csv'

\copy (
    SELECT
        f.transit_timestamp,
        TO_CHAR(f.transit_timestamp, 'Day')      AS day_of_week,
        EXTRACT(ISODOW FROM f.transit_timestamp)::INTEGER AS day_num,
        EXTRACT(HOUR   FROM f.transit_timestamp)::INTEGER AS hour_of_day,
        f.station_complex_id      AS complex_id,
        c.display_name            AS complex_name,
        CASE
            WHEN f.station_complex_id IN (614,611,318,321,320,319,601,323,324,325,327,328,329,635)  THEN '1/2/3'
            WHEN f.station_complex_id IN (164,165,618,167,168,169,624,628,636)                      THEN 'A/C/E'
            WHEN f.station_complex_id IN (613,610,602,619,337,620,617)                              THEN '4/5/6'
            WHEN f.station_complex_id IN (225,609,607,231,26)                                       THEN 'B/D/F/M'
            ELSE 'Other'
        END AS line_group,
        SUM(f.ridership)::INTEGER AS ridership
    FROM mta.fact_hourly_ridership f
    JOIN mta.dim_complex c ON c.complex_id = f.station_complex_id
    WHERE f.station_complex_id IN (
        -- 1/2/3: Columbus Circle → Times Sq → Penn → 28/23/18 St → 14 St → Christopher → Houston → Canal → Chambers → WTC → Rector → South Ferry
        614, 611, 318, 319, 320, 321, 601, 323, 324, 325, 327, 328, 329, 635,
        -- A/C/E: Penn → 23 St → 14 St-8 Av → W4 St → Spring St → Canal → WTC/Chambers → Fulton → Jay St (Brooklyn)
        164, 165, 618, 167, 168, 169, 624, 628, 636,
        -- 4/5/6: 59 St-Lex → Grand Central → Union Sq → Broadway-Lafayette → Nevins St → Borough Hall → Atlantic Av (Brooklyn)
        613, 610, 602, 619, 337, 620, 617,
        -- B/D/F/M: Rockefeller Ctr → Bryant Pk → Herald Sq → Grand St → DeKalb Av (Brooklyn)
        225, 609, 607, 231, 26
    )
    GROUP BY 1, 2, 3, 4, 5, 6, 7
) TO 'C:\temp\exports\hourly_ridership_corridor.csv' WITH (FORMAT csv, HEADER true);


\echo '>>> 5/5 dim_corridor_complexes.csv'

\copy (
    SELECT
        c.complex_id,
        c.display_name AS complex_name,
        c.borough,
        c.latitude,
        c.longitude,
        c.daytime_routes,
        CASE
            WHEN c.complex_id IN (614,611,318,321,320,319,601,323,324,325,327,328,329,635) THEN '1/2/3'
            WHEN c.complex_id IN (164,165,618,167,168,169,624,628,636)                     THEN 'A/C/E'
        END                                                  AS line_group,
        c.complex_id IN (318, 164)                           AS is_penn,
        c.complex_id IN (328, 624)                           AS is_wtc,
        STRING_AGG(b.route_id, ',' ORDER BY b.route_id)     AS routes_at_complex
    FROM mta.dim_complex c
    LEFT JOIN mta.bridge_complex_route b
           ON b.complex_id = c.complex_id
          AND b.route_id IN ('1','2','3','A','C','E')
    WHERE c.complex_id IN (
        -- 1/2/3: Columbus Circle → Times Sq → Penn → 28/23/18 St → 14 St → Christopher → Houston → Canal → Chambers → WTC → Rector → South Ferry
        614, 611, 318, 319, 320, 321, 601, 323, 324, 325, 327, 328, 329, 635,
        -- A/C/E: Penn → 23 St → 14 St-8 Av → W4 St → Spring St → Canal → WTC/Chambers → Fulton St
        164, 165, 618, 167, 168, 169, 624, 628
    )
    GROUP BY 1, 2, 3, 4, 5, 6
) TO 'C:\temp\exports\dim_corridor_complexes.csv' WITH (FORMAT csv, HEADER true);


\echo '>>> Export complete. Files in C:\temp\exports\ (5 CSVs; KPIs are Tableau calculated fields):'
\! dir C:\temp\exports\
