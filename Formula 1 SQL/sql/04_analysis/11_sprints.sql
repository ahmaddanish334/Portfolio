USE f1_analytics;

-- sprint wins
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS sprint_wins
FROM sprint_results s
JOIN drivers d ON d.driver_id = s.driver_id
WHERE s.position_order = 1
GROUP BY d.driver_id, d.forename, d.surname
ORDER BY sprint_wins DESC;

-- sprint podiums
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS sprint_podiums
FROM sprint_results s
JOIN drivers d ON d.driver_id = s.driver_id
WHERE s.position_order <= 3
GROUP BY d.driver_id, d.forename, d.surname
ORDER BY sprint_podiums DESC;

-- sprint points
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    SUM(s.points) AS sprint_points
FROM sprint_results s
JOIN drivers d ON d.driver_id = s.driver_id
GROUP BY d.driver_id, d.forename, d.surname
ORDER BY sprint_points DESC;

-- constructor sprint points
SELECT
    c.constructor_name,
    SUM(s.points) AS sprint_points
FROM sprint_results s
JOIN constructors c ON c.constructor_id = s.constructor_id
GROUP BY c.constructor_id, c.constructor_name
ORDER BY sprint_points DESC;

-- sprint grid gain
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS sprints,
    ROUND(AVG(s.grid_position - s.position_order), 2) AS avg_gain
FROM sprint_results s
JOIN drivers d ON d.driver_id = s.driver_id
WHERE s.grid_position > 0
GROUP BY d.driver_id, d.forename, d.surname
HAVING COUNT(*) >= 5
ORDER BY avg_gain DESC;

-- sprint vs race finish
SELECT
    r.season_year,
    r.race_name,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    s.position_order AS sprint_finish,
    res.position_order AS race_finish,
    s.position_order - res.position_order AS race_gain
FROM sprint_results s
JOIN results res
  ON res.race_id = s.race_id
 AND res.driver_id = s.driver_id
JOIN races r ON r.race_id = s.race_id
JOIN drivers d ON d.driver_id = s.driver_id
ORDER BY r.season_year DESC, r.race_round, race_gain DESC;

-- sprint winner conversion
SELECT
    COUNT(*) AS sprint_wins,
    SUM(CASE WHEN res.position_order = 1 THEN 1 ELSE 0 END) AS grand_prix_wins,
    ROUND(
        100.0 * SUM(CASE WHEN res.position_order = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS conversion_pct
FROM sprint_results s
JOIN results res
  ON res.race_id = s.race_id
 AND res.driver_id = s.driver_id
WHERE s.position_order = 1;

-- sprint fastest laps
SELECT
    r.season_year,
    r.race_name,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    s.fastest_lap_time_ms
FROM sprint_results s
JOIN races r ON r.race_id = s.race_id
JOIN drivers d ON d.driver_id = s.driver_id
WHERE s.fastest_lap_time_ms IS NOT NULL
ORDER BY s.fastest_lap_time_ms;

-- sprint points by season
SELECT
    r.season_year,
    SUM(s.points) AS sprint_points_awarded
FROM sprint_results s
JOIN races r ON r.race_id = s.race_id
GROUP BY r.season_year
ORDER BY r.season_year;

-- sprint events by season
SELECT
    r.season_year,
    COUNT(DISTINCT s.race_id) AS sprint_events
FROM sprint_results s
JOIN races r ON r.race_id = s.race_id
GROUP BY r.season_year
ORDER BY r.season_year;
