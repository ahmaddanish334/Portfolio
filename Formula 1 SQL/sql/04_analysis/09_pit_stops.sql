USE f1_analytics;

-- fastest stops
SELECT
    r.season_year,
    r.race_name,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    p.stop_number,
    p.lap_number,
    p.duration_ms
FROM pit_stops p
JOIN races r ON r.race_id = p.race_id
JOIN drivers d ON d.driver_id = p.driver_id
ORDER BY p.duration_ms
LIMIT 100;

-- average stop by driver
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS stops,
    ROUND(AVG(p.duration_ms), 1) AS avg_stop_ms,
    MIN(p.duration_ms) AS best_stop_ms
FROM pit_stops p
JOIN drivers d ON d.driver_id = p.driver_id
GROUP BY d.driver_id, d.forename, d.surname
HAVING COUNT(*) >= 30
ORDER BY avg_stop_ms;

-- constructor stop performance
SELECT
    c.constructor_name,
    COUNT(*) AS stops,
    ROUND(AVG(p.duration_ms), 1) AS avg_stop_ms,
    MIN(p.duration_ms) AS best_stop_ms
FROM pit_stops p
JOIN results res
  ON res.race_id = p.race_id
 AND res.driver_id = p.driver_id
JOIN constructors c ON c.constructor_id = res.constructor_id
GROUP BY c.constructor_id, c.constructor_name
HAVING COUNT(*) >= 100
ORDER BY avg_stop_ms;

-- pit performance by season
SELECT
    r.season_year,
    COUNT(*) AS stops,
    ROUND(AVG(p.duration_ms), 1) AS avg_stop_ms,
    MIN(p.duration_ms) AS best_stop_ms
FROM pit_stops p
JOIN races r ON r.race_id = p.race_id
GROUP BY r.season_year
ORDER BY r.season_year;

-- stop count distribution
WITH x AS (
    SELECT race_id, driver_id, COUNT(*) AS stops
    FROM pit_stops
    GROUP BY race_id, driver_id
)
SELECT stops, COUNT(*) AS driver_races
FROM x
GROUP BY stops
ORDER BY stops;

-- average first stop lap
SELECT
    r.season_year,
    ROUND(AVG(p.lap_number), 2) AS avg_first_stop_lap
FROM pit_stops p
JOIN races r ON r.race_id = p.race_id
WHERE p.stop_number = 1
GROUP BY r.season_year
ORDER BY r.season_year;

-- races with most stops
SELECT
    r.season_year,
    r.race_name,
    COUNT(*) AS pit_stops
FROM pit_stops p
JOIN races r ON r.race_id = p.race_id
GROUP BY r.season_year, r.race_round, r.race_name
ORDER BY pit_stops DESC
LIMIT 50;

-- stop rank inside race
SELECT
    p.race_id,
    p.driver_id,
    p.stop_number,
    p.duration_ms,
    DENSE_RANK() OVER (
        PARTITION BY p.race_id
        ORDER BY p.duration_ms
    ) AS stop_rank
FROM pit_stops p
ORDER BY p.race_id, stop_rank;

-- first-stop bucket vs finish
WITH first_stop AS (
    SELECT
        race_id,
        driver_id,
        MIN(lap_number) AS first_stop_lap
    FROM pit_stops
    GROUP BY race_id, driver_id
)
SELECT
    CASE
        WHEN first_stop_lap <= 10 THEN '01. 1-10'
        WHEN first_stop_lap <= 20 THEN '02. 11-20'
        WHEN first_stop_lap <= 30 THEN '03. 21-30'
        WHEN first_stop_lap <= 40 THEN '04. 31-40'
        WHEN first_stop_lap <= 50 THEN '05. 41-50'
        ELSE '06. 51+'
    END AS first_stop_band,
    ROUND(AVG(res.position_order), 2) AS avg_finish,
    COUNT(*) AS driver_races
FROM first_stop f
JOIN results res
  ON res.race_id = f.race_id
 AND res.driver_id = f.driver_id
GROUP BY first_stop_band
ORDER BY first_stop_band;

-- five-lap position change
WITH x AS (
    SELECT
        ps.race_id,
        ps.driver_id,
        ps.stop_number,
        ps.lap_number,
        ps.duration_ms,
        b.track_position AS before_pos,
        a.track_position AS after_pos
    FROM pit_stops ps
    LEFT JOIN lap_times b
      ON b.race_id = ps.race_id
     AND b.driver_id = ps.driver_id
     AND b.lap_number = GREATEST(ps.lap_number - 1, 1)
    LEFT JOIN lap_times a
      ON a.race_id = ps.race_id
     AND a.driver_id = ps.driver_id
     AND a.lap_number = ps.lap_number + 5
)
SELECT
    duration_ms,
    before_pos,
    after_pos,
    before_pos - after_pos AS net_gain
FROM x
WHERE before_pos IS NOT NULL
  AND after_pos IS NOT NULL
ORDER BY duration_ms;
