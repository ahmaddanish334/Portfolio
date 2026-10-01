USE f1_analytics;

-- constructor wins
SELECT constructor_name, COUNT(*) AS wins
FROM v_result_enriched
WHERE position_order = 1
GROUP BY constructor_name
ORDER BY wins DESC;

-- constructor podiums
SELECT constructor_name, COUNT(*) AS podiums
FROM v_result_enriched
WHERE position_order <= 3
GROUP BY constructor_name
ORDER BY podiums DESC;

-- season win rate
SELECT
    season_year,
    constructor_name,
    races,
    wins,
    ROUND(100.0 * wins / NULLIF(races, 0), 2) AS win_rate_pct
FROM mart_constructor_season
WHERE races >= 10
ORDER BY win_rate_pct DESC, wins DESC;

-- best average finish
SELECT
    season_year,
    constructor_name,
    races,
    ROUND(avg_finish, 2) AS avg_finish
FROM mart_constructor_season
WHERE races >= 10
ORDER BY avg_finish, season_year DESC;

-- constructor champions
WITH last_round AS (
    SELECT season_year, MAX(race_round) AS race_round
    FROM races
    GROUP BY season_year
)
SELECT
    r.season_year,
    c.constructor_name AS champion,
    cs.points,
    cs.wins
FROM last_round f
JOIN races r
  ON r.season_year = f.season_year
 AND r.race_round = f.race_round
JOIN constructor_standings cs
  ON cs.race_id = r.race_id
 AND cs.standing_position = 1
JOIN constructors c ON c.constructor_id = cs.constructor_id
ORDER BY r.season_year;

-- titles by constructor
WITH last_round AS (
    SELECT season_year, MAX(race_round) AS race_round
    FROM races
    GROUP BY season_year
),
champions AS (
    SELECT cs.constructor_id
    FROM last_round f
    JOIN races r
      ON r.season_year = f.season_year
     AND r.race_round = f.race_round
    JOIN constructor_standings cs
      ON cs.race_id = r.race_id
     AND cs.standing_position = 1
)
SELECT
    c.constructor_name,
    COUNT(*) AS titles
FROM champions x
JOIN constructors c ON c.constructor_id = x.constructor_id
GROUP BY c.constructor_id, c.constructor_name
ORDER BY titles DESC;

-- one-two count
SELECT
    c.constructor_name,
    COUNT(*) AS one_two_finishes
FROM (
    SELECT race_id, constructor_id
    FROM results
    WHERE position_order IN (1,2)
    GROUP BY race_id, constructor_id
    HAVING COUNT(*) = 2
) x
JOIN constructors c ON c.constructor_id = x.constructor_id
GROUP BY c.constructor_id, c.constructor_name
ORDER BY one_two_finishes DESC;

-- points by decade
SELECT
    FLOOR(r.season_year / 10) * 10 AS decade,
    c.constructor_name,
    SUM(res.points) AS points
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN constructors c ON c.constructor_id = res.constructor_id
GROUP BY FLOOR(r.season_year / 10) * 10,
         c.constructor_id, c.constructor_name
ORDER BY decade, points DESC;

-- constructor nationality
SELECT
    c.nationality,
    COUNT(DISTINCT c.constructor_id) AS constructors,
    SUM(CASE WHEN res.position_order = 1 THEN 1 ELSE 0 END) AS wins
FROM constructors c
JOIN results res ON res.constructor_id = c.constructor_id
GROUP BY c.nationality
ORDER BY wins DESC, constructors DESC;

-- active seasons
SELECT
    c.constructor_name,
    MIN(r.season_year) AS first_year,
    MAX(r.season_year) AS last_year,
    COUNT(DISTINCT r.season_year) AS active_seasons,
    COUNT(DISTINCT r.race_id) AS races
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN constructors c ON c.constructor_id = res.constructor_id
GROUP BY c.constructor_id, c.constructor_name
ORDER BY active_seasons DESC, races DESC;
