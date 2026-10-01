USE f1_analytics;

EXPLAIN ANALYZE
SELECT *
FROM lap_times
WHERE race_id = 1100
  AND driver_id = 1
ORDER BY lap_number;

EXPLAIN ANALYZE
SELECT
    driver_id,
    AVG(lap_time_ms)
FROM lap_times
WHERE race_id = 1100
GROUP BY driver_id;

EXPLAIN ANALYZE
SELECT
    res.driver_id,
    COUNT(*) AS wins
FROM results res
JOIN races r ON r.race_id = res.race_id
WHERE r.season_year BETWEEN 2010 AND 2024
  AND res.position_order = 1
GROUP BY res.driver_id;

EXPLAIN ANALYZE
SELECT
    q.driver_id,
    AVG(q.qualifying_position)
FROM qualifying q
JOIN races r ON r.race_id = q.race_id
WHERE r.season_year >= 2015
GROUP BY q.driver_id;

EXPLAIN ANALYZE
SELECT
    p.driver_id,
    AVG(p.duration_ms)
FROM pit_stops p
JOIN races r ON r.race_id = p.race_id
WHERE r.season_year >= 2020
GROUP BY p.driver_id;
