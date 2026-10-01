USE f1_analytics;

-- races per season
SELECT season_year, COUNT(*) AS races
FROM races
GROUP BY season_year
ORDER BY season_year;

-- drivers per season
SELECT
    r.season_year,
    COUNT(DISTINCT res.driver_id) AS drivers
FROM results res
JOIN races r ON r.race_id = res.race_id
GROUP BY r.season_year
ORDER BY r.season_year;

-- constructors per season
SELECT
    r.season_year,
    COUNT(DISTINCT res.constructor_id) AS constructors
FROM results res
JOIN races r ON r.race_id = res.race_id
GROUP BY r.season_year
ORDER BY r.season_year;

-- average grid size
WITH x AS (
    SELECT race_id, COUNT(*) AS starters
    FROM results
    GROUP BY race_id
)
SELECT
    r.season_year,
    ROUND(AVG(x.starters), 2) AS avg_starters
FROM x
JOIN races r ON r.race_id = x.race_id
GROUP BY r.season_year
ORDER BY r.season_year;

-- winner starting position by decade
SELECT
    FLOOR(r.season_year / 10) * 10 AS decade,
    ROUND(AVG(res.grid_position), 2) AS avg_winner_grid,
    COUNT(*) AS races
FROM results res
JOIN races r ON r.race_id = res.race_id
WHERE res.position_order = 1
GROUP BY FLOOR(r.season_year / 10) * 10
ORDER BY decade;

-- podium diversity
SELECT
    r.season_year,
    COUNT(DISTINCT CASE WHEN res.position_order <= 3 THEN res.driver_id END) AS podium_drivers,
    COUNT(DISTINCT CASE WHEN res.position_order <= 3 THEN res.constructor_id END) AS podium_constructors
FROM results res
JOIN races r ON r.race_id = res.race_id
GROUP BY r.season_year
ORDER BY r.season_year;

-- winner diversity
SELECT
    r.season_year,
    COUNT(DISTINCT CASE WHEN res.position_order = 1 THEN res.driver_id END) AS race_winners,
    COUNT(DISTINCT CASE WHEN res.position_order = 1 THEN res.constructor_id END) AS winning_constructors
FROM results res
JOIN races r ON r.race_id = res.race_id
GROUP BY r.season_year
ORDER BY r.season_year;

-- rolling five-race points
SELECT
    r.season_year,
    r.race_round,
    res.driver_id,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    res.points,
    SUM(res.points) OVER (
        PARTITION BY res.driver_id
        ORDER BY r.season_year, r.race_round
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS rolling_5_race_points
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN drivers d ON d.driver_id = res.driver_id
ORDER BY res.driver_id, r.season_year, r.race_round;

-- cumulative season points
SELECT
    r.season_year,
    r.race_round,
    res.driver_id,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    SUM(res.points) OVER (
        PARTITION BY r.season_year, res.driver_id
        ORDER BY r.race_round
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_points
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN drivers d ON d.driver_id = res.driver_id
ORDER BY r.season_year, r.race_round, cumulative_points DESC;

-- season quartiles
WITH x AS (
    SELECT
        r.season_year,
        res.driver_id,
        SUM(res.points) AS points
    FROM results res
    JOIN races r ON r.race_id = res.race_id
    GROUP BY r.season_year, res.driver_id
)
SELECT
    x.*,
    NTILE(4) OVER (
        PARTITION BY season_year
        ORDER BY points DESC
    ) AS points_quartile
FROM x;

-- podium streaks
WITH x AS (
    SELECT
        res.driver_id,
        r.season_year,
        r.race_round,
        CASE WHEN res.position_order <= 3 THEN 1 ELSE 0 END AS podium,
        SUM(
            CASE WHEN res.position_order > 3 THEN 1 ELSE 0 END
        ) OVER (
            PARTITION BY res.driver_id
            ORDER BY r.season_year, r.race_round
        ) AS grp
    FROM results res
    JOIN races r ON r.race_id = res.race_id
),
streaks AS (
    SELECT driver_id, grp, COUNT(*) AS podium_streak
    FROM x
    WHERE podium = 1
    GROUP BY driver_id, grp
)
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    MAX(s.podium_streak) AS longest_podium_streak
FROM streaks s
JOIN drivers d ON d.driver_id = s.driver_id
GROUP BY d.driver_id, d.forename, d.surname
ORDER BY longest_podium_streak DESC;

-- championship rank change
WITH x AS (
    SELECT
        r.season_year,
        r.race_round,
        ds.driver_id,
        ds.standing_position,
        LAG(ds.standing_position) OVER (
            PARTITION BY r.season_year, ds.driver_id
            ORDER BY r.race_round
        ) AS prior_position
    FROM driver_standings ds
    JOIN races r ON r.race_id = ds.race_id
)
SELECT
    season_year,
    race_round,
    driver_id,
    prior_position,
    standing_position,
    prior_position - standing_position AS positions_gained
FROM x
WHERE prior_position IS NOT NULL
ORDER BY ABS(prior_position - standing_position) DESC;

-- team points concentration
WITH x AS (
    SELECT
        r.season_year,
        res.constructor_id,
        res.driver_id,
        SUM(res.points) AS driver_points
    FROM results res
    JOIN races r ON r.race_id = res.race_id
    GROUP BY r.season_year, res.constructor_id, res.driver_id
)
SELECT
    season_year,
    constructor_id,
    MAX(driver_points) AS top_driver_points,
    SUM(driver_points) AS team_points,
    ROUND(
        100.0 * MAX(driver_points) / NULLIF(SUM(driver_points), 0), 2
    ) AS top_driver_share_pct
FROM x
GROUP BY season_year, constructor_id
HAVING SUM(driver_points) > 0
ORDER BY top_driver_share_pct DESC;

-- career best finish progression
SELECT
    r.season_year,
    r.race_round,
    res.driver_id,
    res.position_order,
    MIN(res.position_order) OVER (
        PARTITION BY res.driver_id
        ORDER BY r.season_year, r.race_round
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS career_best_to_date
FROM results res
JOIN races r ON r.race_id = res.race_id
ORDER BY res.driver_id, r.season_year, r.race_round;

-- running constructor wins
SELECT
    r.season_year,
    r.race_round,
    res.constructor_id,
    c.constructor_name,
    SUM(
        CASE WHEN res.position_order = 1 THEN 1 ELSE 0 END
    ) OVER (
        PARTITION BY res.constructor_id
        ORDER BY r.season_year, r.race_round
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_wins
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN constructors c ON c.constructor_id = res.constructor_id
ORDER BY res.constructor_id, r.season_year, r.race_round;
