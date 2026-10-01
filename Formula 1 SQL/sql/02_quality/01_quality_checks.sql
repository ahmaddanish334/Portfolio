USE f1_analytics;

-- counts
SELECT 'races' AS table_name, COUNT(*) AS row_count FROM races
UNION ALL SELECT 'results', COUNT(*) FROM results
UNION ALL SELECT 'lap_times', COUNT(*) FROM lap_times
UNION ALL SELECT 'pit_stops', COUNT(*) FROM pit_stops
UNION ALL SELECT 'qualifying', COUNT(*) FROM qualifying
UNION ALL SELECT 'drivers', COUNT(*) FROM drivers
UNION ALL SELECT 'constructors', COUNT(*) FROM constructors
UNION ALL SELECT 'sprint_results', COUNT(*) FROM sprint_results;

-- duplicate race/driver
SELECT race_id, driver_id, COUNT(*) AS n
FROM results
GROUP BY race_id, driver_id
HAVING COUNT(*) > 1;

-- duplicate lap key
SELECT race_id, driver_id, lap_number, COUNT(*) AS n
FROM lap_times
GROUP BY race_id, driver_id, lap_number
HAVING COUNT(*) > 1;

-- missing race link
SELECT COUNT(*) AS result_without_race
FROM results x
LEFT JOIN races r ON r.race_id = x.race_id
WHERE r.race_id IS NULL;

-- missing driver link
SELECT COUNT(*) AS result_without_driver
FROM results x
LEFT JOIN drivers d ON d.driver_id = x.driver_id
WHERE d.driver_id IS NULL;

-- missing constructor link
SELECT COUNT(*) AS result_without_constructor
FROM results x
LEFT JOIN constructors c ON c.constructor_id = x.constructor_id
WHERE c.constructor_id IS NULL;

-- lap rows without race result
SELECT COUNT(*) AS lap_without_result
FROM lap_times l
LEFT JOIN results r
  ON r.race_id = l.race_id
 AND r.driver_id = l.driver_id
WHERE r.result_id IS NULL;

-- race date/year mismatch
SELECT *
FROM races
WHERE YEAR(race_date) <> season_year;

-- invalid result values
SELECT *
FROM results
WHERE grid_position < 0
   OR position_order < 1
   OR laps < 0
   OR points < 0;

-- invalid lap values
SELECT *
FROM lap_times
WHERE lap_number < 1
   OR track_position < 1
   OR lap_time_ms <= 0;

-- invalid pit values
SELECT *
FROM pit_stops
WHERE stop_number < 1
   OR lap_number < 1
   OR duration_ms <= 0;

-- source coverage
SELECT
    MIN(r.season_year) AS first_year,
    MAX(r.season_year) AS last_year,
    COUNT(*) AS rows_found
FROM lap_times l
JOIN races r ON r.race_id = l.race_id;

SELECT
    MIN(r.season_year) AS first_year,
    MAX(r.season_year) AS last_year,
    COUNT(*) AS rows_found
FROM pit_stops p
JOIN races r ON r.race_id = p.race_id;

SELECT
    MIN(r.season_year) AS first_year,
    MAX(r.season_year) AS last_year,
    COUNT(*) AS rows_found
FROM qualifying q
JOIN races r ON r.race_id = q.race_id;

SELECT
    MIN(r.season_year) AS first_year,
    MAX(r.season_year) AS last_year,
    COUNT(*) AS rows_found
FROM sprint_results s
JOIN races r ON r.race_id = s.race_id;
