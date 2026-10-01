USE f1_analytics;

-- races by circuit
SELECT
    c.circuit_name,
    c.country,
    COUNT(*) AS races,
    MIN(r.season_year) AS first_year,
    MAX(r.season_year) AS last_year
FROM races r
JOIN circuits c ON c.circuit_id = r.circuit_id
GROUP BY c.circuit_id, c.circuit_name, c.country
ORDER BY races DESC;

-- wins by circuit
WITH x AS (
    SELECT
        c.circuit_id,
        c.circuit_name,
        res.driver_id,
        CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
        COUNT(*) AS wins
    FROM results res
    JOIN races r ON r.race_id = res.race_id
    JOIN circuits c ON c.circuit_id = r.circuit_id
    JOIN drivers d ON d.driver_id = res.driver_id
    WHERE res.position_order = 1
    GROUP BY c.circuit_id, c.circuit_name,
             res.driver_id, d.forename, d.surname
)
SELECT
    circuit_name,
    driver_name,
    wins,
    DENSE_RANK() OVER (
        PARTITION BY circuit_id ORDER BY wins DESC
    ) AS circuit_rank
FROM x
ORDER BY circuit_name, circuit_rank;

-- circuit specialists
WITH x AS (
    SELECT
        r.circuit_id,
        res.driver_id,
        COUNT(*) AS starts,
        AVG(res.position_order) AS avg_finish
    FROM results res
    JOIN races r ON r.race_id = res.race_id
    GROUP BY r.circuit_id, res.driver_id
)
SELECT
    c.circuit_name,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    x.starts,
    ROUND(x.avg_finish, 2) AS avg_finish
FROM x
JOIN circuits c ON c.circuit_id = x.circuit_id
JOIN drivers d ON d.driver_id = x.driver_id
WHERE x.starts >= 5
ORDER BY avg_finish, starts DESC;

-- grid-finish correlation
SELECT
    c.circuit_name,
    COUNT(*) AS entries,
    ROUND(
        (
            COUNT(*) * SUM(res.grid_position * res.position_order)
            - SUM(res.grid_position) * SUM(res.position_order)
        )
        /
        NULLIF(
            SQRT(
                (
                    COUNT(*) * SUM(res.grid_position * res.grid_position)
                    - POW(SUM(res.grid_position), 2)
                )
                *
                (
                    COUNT(*) * SUM(res.position_order * res.position_order)
                    - POW(SUM(res.position_order), 2)
                )
            ),
            0
        ),
        3
    ) AS grid_finish_corr
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN circuits c ON c.circuit_id = r.circuit_id
WHERE res.grid_position > 0
GROUP BY c.circuit_id, c.circuit_name
HAVING COUNT(*) >= 100
ORDER BY grid_finish_corr DESC;

-- position-change proxy
SELECT
    c.circuit_name,
    COUNT(*) AS entries,
    ROUND(AVG(ABS(res.grid_position - res.position_order)), 2) AS avg_abs_position_change
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN circuits c ON c.circuit_id = r.circuit_id
WHERE res.grid_position > 0
GROUP BY c.circuit_id, c.circuit_name
HAVING COUNT(*) >= 100
ORDER BY avg_abs_position_change DESC;

-- circuit attrition
SELECT
    c.circuit_name,
    COUNT(*) AS starts,
    SUM(CASE WHEN res.finish_position IS NULL THEN 1 ELSE 0 END) AS unclassified,
    ROUND(
        100.0 * SUM(CASE WHEN res.finish_position IS NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS attrition_pct
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN circuits c ON c.circuit_id = r.circuit_id
GROUP BY c.circuit_id, c.circuit_name
HAVING COUNT(*) >= 100
ORDER BY attrition_pct DESC;

-- countries hosting races
SELECT
    c.country,
    COUNT(*) AS races,
    COUNT(DISTINCT c.circuit_id) AS circuits
FROM races r
JOIN circuits c ON c.circuit_id = r.circuit_id
GROUP BY c.country
ORDER BY races DESC;

-- pole-to-win by circuit
SELECT
    c.circuit_name,
    COUNT(*) AS poles,
    SUM(CASE WHEN res.position_order = 1 THEN 1 ELSE 0 END) AS pole_wins,
    ROUND(
        100.0 * SUM(CASE WHEN res.position_order = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS conversion_pct
FROM qualifying q
JOIN results res
  ON res.race_id = q.race_id
 AND res.driver_id = q.driver_id
JOIN races r ON r.race_id = q.race_id
JOIN circuits c ON c.circuit_id = r.circuit_id
WHERE q.qualifying_position = 1
GROUP BY c.circuit_id, c.circuit_name
HAVING COUNT(*) >= 5
ORDER BY conversion_pct DESC;

-- average pit stops by circuit
WITH x AS (
    SELECT race_id, driver_id, COUNT(*) AS stops
    FROM pit_stops
    GROUP BY race_id, driver_id
)
SELECT
    c.circuit_name,
    ROUND(AVG(x.stops), 2) AS avg_stops_per_driver
FROM x
JOIN races r ON r.race_id = x.race_id
JOIN circuits c ON c.circuit_id = r.circuit_id
GROUP BY c.circuit_id, c.circuit_name
HAVING COUNT(*) >= 30
ORDER BY avg_stops_per_driver DESC;

-- fastest recorded speed
SELECT
    c.circuit_name,
    MAX(res.fastest_lap_speed) AS max_recorded_speed
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN circuits c ON c.circuit_id = r.circuit_id
WHERE res.fastest_lap_speed IS NOT NULL
GROUP BY c.circuit_id, c.circuit_name
ORDER BY max_recorded_speed DESC;
