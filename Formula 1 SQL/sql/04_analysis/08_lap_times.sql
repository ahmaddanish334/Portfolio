USE f1_analytics;

-- fastest recorded laps
SELECT
    r.season_year,
    r.race_name,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    l.lap_number,
    l.lap_time_ms
FROM lap_times l
JOIN races r ON r.race_id = l.race_id
JOIN drivers d ON d.driver_id = l.driver_id
ORDER BY l.lap_time_ms
LIMIT 100;

-- race pace
SELECT
    r.season_year,
    r.race_name,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    p.timed_laps,
    ROUND(p.avg_lap_ms, 1) AS avg_lap_ms,
    p.best_lap_ms,
    ROUND(p.lap_sd_ms, 1) AS lap_sd_ms
FROM mart_driver_race_pace p
JOIN races r ON r.race_id = p.race_id
JOIN drivers d ON d.driver_id = p.driver_id
WHERE p.timed_laps >= 20
ORDER BY r.season_year DESC, r.race_round, avg_lap_ms;

-- season lap consistency
WITH pace AS (
    SELECT
        r.season_year,
        l.driver_id,
        STDDEV_SAMP(l.lap_time_ms) AS lap_sd,
        COUNT(*) AS laps
    FROM lap_times l
    JOIN races r ON r.race_id = l.race_id
    GROUP BY r.season_year, l.driver_id
)
SELECT
    p.season_year,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    p.laps,
    ROUND(p.lap_sd, 1) AS lap_sd_ms
FROM pace p
JOIN drivers d ON d.driver_id = p.driver_id
WHERE p.laps >= 300
ORDER BY p.season_year DESC, lap_sd_ms;

-- lap-to-lap delta
WITH x AS (
    SELECT
        race_id,
        driver_id,
        lap_number,
        lap_time_ms,
        LAG(lap_time_ms) OVER (
            PARTITION BY race_id, driver_id
            ORDER BY lap_number
        ) AS prior_lap_ms
    FROM lap_times
)
SELECT
    r.season_year,
    r.race_name,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    x.lap_number,
    x.lap_time_ms - x.prior_lap_ms AS delta_ms
FROM x
JOIN races r ON r.race_id = x.race_id
JOIN drivers d ON d.driver_id = x.driver_id
WHERE prior_lap_ms IS NOT NULL
ORDER BY ABS(x.lap_time_ms - x.prior_lap_ms) DESC
LIMIT 100;

-- lap position changes
WITH x AS (
    SELECT
        race_id,
        driver_id,
        lap_number,
        track_position,
        LAG(track_position) OVER (
            PARTITION BY race_id, driver_id
            ORDER BY lap_number
        ) AS prior_position
    FROM lap_times
)
SELECT
    r.season_year,
    r.race_name,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    x.lap_number,
    prior_position,
    track_position,
    prior_position - track_position AS positions_gained
FROM x
JOIN races r ON r.race_id = x.race_id
JOIN drivers d ON d.driver_id = x.driver_id
WHERE prior_position IS NOT NULL
  AND prior_position <> track_position
ORDER BY positions_gained DESC
LIMIT 100;

-- field lap spread
WITH x AS (
    SELECT
        race_id,
        lap_number,
        MAX(lap_time_ms) - MIN(lap_time_ms) AS spread_ms,
        COUNT(*) AS cars
    FROM lap_times
    GROUP BY race_id, lap_number
)
SELECT
    r.season_year,
    r.race_name,
    ROUND(AVG(x.spread_ms), 1) AS avg_lap_spread_ms
FROM x
JOIN races r ON r.race_id = x.race_id
WHERE x.cars >= 10
GROUP BY r.season_year, r.race_round, r.race_name
ORDER BY r.season_year DESC, r.race_round;

-- fastest average pace per race
WITH ranked AS (
    SELECT
        p.*,
        RANK() OVER (
            PARTITION BY p.race_id
            ORDER BY p.avg_lap_ms
        ) AS rn
    FROM mart_driver_race_pace p
    WHERE p.timed_laps >= 20
)
SELECT
    r.season_year,
    r.race_name,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    ROUND(x.avg_lap_ms, 1) AS avg_lap_ms
FROM ranked x
JOIN races r ON r.race_id = x.race_id
JOIN drivers d ON d.driver_id = x.driver_id
WHERE rn = 1
ORDER BY r.season_year DESC, r.race_round;

-- pace vs finish
SELECT
    res.position_order,
    ROUND(AVG(p.avg_lap_ms), 1) AS avg_race_pace_ms,
    COUNT(*) AS driver_races
FROM mart_driver_race_pace p
JOIN results res
  ON res.race_id = p.race_id
 AND res.driver_id = p.driver_id
WHERE p.timed_laps >= 20
GROUP BY res.position_order
ORDER BY res.position_order;

-- laps in P1
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS laps_recorded_in_p1
FROM lap_times l
JOIN drivers d ON d.driver_id = l.driver_id
WHERE l.track_position = 1
GROUP BY d.driver_id, d.forename, d.surname
ORDER BY laps_recorded_in_p1 DESC;

-- pace percentile
SELECT
    p.race_id,
    p.driver_id,
    p.avg_lap_ms,
    PERCENT_RANK() OVER (
        PARTITION BY p.race_id
        ORDER BY p.avg_lap_ms
    ) AS pace_percentile
FROM mart_driver_race_pace p
WHERE p.timed_laps >= 20
ORDER BY p.race_id, pace_percentile;
