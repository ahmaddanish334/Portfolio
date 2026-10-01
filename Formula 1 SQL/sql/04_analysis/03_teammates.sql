USE f1_analytics;

-- race head-to-head
WITH pairs AS (
    SELECT
        a.race_id,
        a.constructor_id,
        a.driver_id AS driver_a,
        b.driver_id AS driver_b,
        a.position_order AS finish_a,
        b.position_order AS finish_b
    FROM results a
    JOIN results b
      ON b.race_id = a.race_id
     AND b.constructor_id = a.constructor_id
     AND b.driver_id > a.driver_id
)
SELECT
    CONCAT_WS(' ', da.forename, da.surname) AS driver_a,
    CONCAT_WS(' ', db.forename, db.surname) AS driver_b,
    COUNT(*) AS races_together,
    SUM(CASE WHEN finish_a < finish_b THEN 1 ELSE 0 END) AS a_ahead,
    SUM(CASE WHEN finish_b < finish_a THEN 1 ELSE 0 END) AS b_ahead
FROM pairs p
JOIN drivers da ON da.driver_id = p.driver_a
JOIN drivers db ON db.driver_id = p.driver_b
GROUP BY p.driver_a, p.driver_b, da.forename, da.surname, db.forename, db.surname
HAVING COUNT(*) >= 10
ORDER BY races_together DESC;

-- qualifying head-to-head
WITH pairs AS (
    SELECT
        a.race_id,
        a.constructor_id,
        a.driver_id AS driver_a,
        b.driver_id AS driver_b,
        a.qualifying_position AS pos_a,
        b.qualifying_position AS pos_b
    FROM qualifying a
    JOIN qualifying b
      ON b.race_id = a.race_id
     AND b.constructor_id = a.constructor_id
     AND b.driver_id > a.driver_id
)
SELECT
    CONCAT_WS(' ', da.forename, da.surname) AS driver_a,
    CONCAT_WS(' ', db.forename, db.surname) AS driver_b,
    COUNT(*) AS sessions,
    SUM(CASE WHEN pos_a < pos_b THEN 1 ELSE 0 END) AS a_ahead,
    SUM(CASE WHEN pos_b < pos_a THEN 1 ELSE 0 END) AS b_ahead
FROM pairs p
JOIN drivers da ON da.driver_id = p.driver_a
JOIN drivers db ON db.driver_id = p.driver_b
GROUP BY p.driver_a, p.driver_b, da.forename, da.surname, db.forename, db.surname
HAVING COUNT(*) >= 10
ORDER BY sessions DESC;

-- grid vs team average
WITH team_avg AS (
    SELECT race_id, constructor_id, AVG(grid_position) AS team_grid
    FROM results
    WHERE grid_position > 0
    GROUP BY race_id, constructor_id
)
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS races,
    ROUND(AVG(res.grid_position - t.team_grid), 2) AS avg_grid_vs_team
FROM results res
JOIN team_avg t
  ON t.race_id = res.race_id
 AND t.constructor_id = res.constructor_id
JOIN drivers d ON d.driver_id = res.driver_id
WHERE res.grid_position > 0
GROUP BY res.driver_id, d.forename, d.surname
HAVING COUNT(*) >= 30
ORDER BY avg_grid_vs_team;

-- finish vs team average
WITH team_avg AS (
    SELECT race_id, constructor_id, AVG(position_order) AS team_finish
    FROM results
    GROUP BY race_id, constructor_id
)
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS races,
    ROUND(AVG(res.position_order - t.team_finish), 2) AS avg_finish_vs_team
FROM results res
JOIN team_avg t
  ON t.race_id = res.race_id
 AND t.constructor_id = res.constructor_id
JOIN drivers d ON d.driver_id = res.driver_id
GROUP BY res.driver_id, d.forename, d.surname
HAVING COUNT(*) >= 30
ORDER BY avg_finish_vs_team;

-- points share
WITH driver_points AS (
    SELECT
        r.season_year,
        res.constructor_id,
        res.driver_id,
        SUM(res.points) AS points
    FROM results res
    JOIN races r ON r.race_id = res.race_id
    GROUP BY r.season_year, res.constructor_id, res.driver_id
),
team_points AS (
    SELECT season_year, constructor_id, SUM(points) AS team_points
    FROM driver_points
    GROUP BY season_year, constructor_id
)
SELECT
    d.season_year,
    c.constructor_name,
    CONCAT_WS(' ', dr.forename, dr.surname) AS driver_name,
    d.points,
    t.team_points,
    ROUND(100.0 * d.points / NULLIF(t.team_points, 0), 2) AS points_share_pct
FROM driver_points d
JOIN team_points t
  ON t.season_year = d.season_year
 AND t.constructor_id = d.constructor_id
JOIN constructors c ON c.constructor_id = d.constructor_id
JOIN drivers dr ON dr.driver_id = d.driver_id
WHERE t.team_points > 0
ORDER BY d.season_year DESC, c.constructor_name, points_share_pct DESC;

-- driver count by team-season
SELECT
    r.season_year,
    c.constructor_name,
    COUNT(DISTINCT res.driver_id) AS drivers_used
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN constructors c ON c.constructor_id = res.constructor_id
GROUP BY r.season_year, res.constructor_id, c.constructor_name
ORDER BY drivers_used DESC, r.season_year DESC;

-- teammate podiums
SELECT
    r.season_year,
    r.race_name,
    c.constructor_name,
    COUNT(*) AS podium_cars
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN constructors c ON c.constructor_id = res.constructor_id
WHERE res.position_order <= 3
GROUP BY r.season_year, r.race_id, r.race_name, c.constructor_id, c.constructor_name
HAVING COUNT(*) >= 2
ORDER BY r.season_year DESC, r.race_round;

-- one-two finishes
SELECT
    r.season_year,
    r.race_name,
    c.constructor_name
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN constructors c ON c.constructor_id = res.constructor_id
WHERE res.position_order IN (1,2)
GROUP BY r.season_year, r.race_round, r.race_id, r.race_name,
         c.constructor_id, c.constructor_name
HAVING COUNT(*) = 2
ORDER BY r.season_year DESC, r.race_round DESC;

-- Q3 teammate gap
WITH q AS (
    SELECT
        race_id,
        constructor_id,
        MAX(q3_ms) - MIN(q3_ms) AS q3_gap_ms,
        COUNT(*) AS cars
    FROM qualifying
    WHERE q3_ms IS NOT NULL
    GROUP BY race_id, constructor_id
)
SELECT
    r.season_year,
    r.race_name,
    c.constructor_name,
    q.q3_gap_ms
FROM q
JOIN races r ON r.race_id = q.race_id
JOIN constructors c ON c.constructor_id = q.constructor_id
WHERE cars >= 2
ORDER BY q3_gap_ms
LIMIT 100;

-- team-season win split
SELECT
    r.season_year,
    c.constructor_name,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    SUM(CASE WHEN res.position_order = 1 THEN 1 ELSE 0 END) AS wins
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN constructors c ON c.constructor_id = res.constructor_id
JOIN drivers d ON d.driver_id = res.driver_id
GROUP BY r.season_year, c.constructor_id, c.constructor_name,
         d.driver_id, d.forename, d.surname
HAVING wins > 0
ORDER BY r.season_year DESC, c.constructor_name, wins DESC;
