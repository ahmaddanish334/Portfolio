USE f1_analytics;

-- driver champions
WITH final_round AS (
    SELECT season_year, MAX(race_round) AS race_round
    FROM races
    GROUP BY season_year
)
SELECT
    r.season_year,
    CONCAT_WS(' ', d.forename, d.surname) AS champion,
    ds.points,
    ds.wins
FROM final_round f
JOIN races r
  ON r.season_year = f.season_year
 AND r.race_round = f.race_round
JOIN driver_standings ds
  ON ds.race_id = r.race_id
 AND ds.standing_position = 1
JOIN drivers d ON d.driver_id = ds.driver_id
ORDER BY r.season_year;

-- titles by driver
WITH final_round AS (
    SELECT season_year, MAX(race_round) AS race_round
    FROM races
    GROUP BY season_year
),
champions AS (
    SELECT ds.driver_id
    FROM final_round f
    JOIN races r
      ON r.season_year = f.season_year
     AND r.race_round = f.race_round
    JOIN driver_standings ds
      ON ds.race_id = r.race_id
     AND ds.standing_position = 1
)
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS titles
FROM champions c
JOIN drivers d ON d.driver_id = c.driver_id
GROUP BY d.driver_id, d.forename, d.surname
ORDER BY titles DESC;

-- championship margin
WITH final_round AS (
    SELECT season_year, MAX(race_round) AS race_round
    FROM races
    GROUP BY season_year
),
final AS (
    SELECT
        r.season_year,
        ds.points,
        ds.standing_position
    FROM final_round f
    JOIN races r
      ON r.season_year = f.season_year
     AND r.race_round = f.race_round
    JOIN driver_standings ds ON ds.race_id = r.race_id
    WHERE ds.standing_position IN (1,2)
)
SELECT
    season_year,
    MAX(CASE WHEN standing_position = 1 THEN points END) AS champion_points,
    MAX(CASE WHEN standing_position = 2 THEN points END) AS runner_up_points,
    MAX(CASE WHEN standing_position = 1 THEN points END)
      - MAX(CASE WHEN standing_position = 2 THEN points END) AS margin
FROM final
GROUP BY season_year
ORDER BY margin;

-- lead changes
WITH leaders AS (
    SELECT
        r.season_year,
        r.race_round,
        ds.driver_id,
        LAG(ds.driver_id) OVER (
            PARTITION BY r.season_year
            ORDER BY r.race_round
        ) AS previous_leader
    FROM driver_standings ds
    JOIN races r ON r.race_id = ds.race_id
    WHERE ds.standing_position = 1
)
SELECT
    season_year,
    SUM(
        CASE
            WHEN previous_leader IS NOT NULL
             AND driver_id <> previous_leader
            THEN 1 ELSE 0
        END
    ) AS lead_changes
FROM leaders
GROUP BY season_year
ORDER BY lead_changes DESC, season_year;

-- rounds led
SELECT
    r.season_year,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS rounds_led
FROM driver_standings ds
JOIN races r ON r.race_id = ds.race_id
JOIN drivers d ON d.driver_id = ds.driver_id
WHERE ds.standing_position = 1
GROUP BY r.season_year, d.driver_id, d.forename, d.surname
ORDER BY r.season_year DESC, rounds_led DESC;

-- largest champion deficit
WITH standings AS (
    SELECT
        r.season_year,
        r.race_round,
        ds.driver_id,
        ds.points,
        MAX(ds.points) OVER (
            PARTITION BY r.season_year, r.race_round
        ) - ds.points AS deficit
    FROM driver_standings ds
    JOIN races r ON r.race_id = ds.race_id
),
last_round AS (
    SELECT season_year, MAX(race_round) AS race_round
    FROM races
    GROUP BY season_year
),
champion AS (
    SELECT r.season_year, ds.driver_id
    FROM last_round x
    JOIN races r
      ON r.season_year = x.season_year
     AND r.race_round = x.race_round
    JOIN driver_standings ds
      ON ds.race_id = r.race_id
     AND ds.standing_position = 1
)
SELECT
    s.season_year,
    CONCAT_WS(' ', d.forename, d.surname) AS champion,
    MAX(s.deficit) AS largest_deficit
FROM standings s
JOIN champion c
  ON c.season_year = s.season_year
 AND c.driver_id = s.driver_id
JOIN drivers d ON d.driver_id = s.driver_id
GROUP BY s.season_year, d.driver_id, d.forename, d.surname
ORDER BY largest_deficit DESC;

-- opening vs final position
WITH ranked AS (
    SELECT
        r.season_year,
        r.race_round,
        ds.driver_id,
        ds.standing_position,
        FIRST_VALUE(ds.standing_position) OVER (
            PARTITION BY r.season_year, ds.driver_id
            ORDER BY r.race_round
        ) AS opening_position,
        LAST_VALUE(ds.standing_position) OVER (
            PARTITION BY r.season_year, ds.driver_id
            ORDER BY r.race_round
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS final_position
    FROM driver_standings ds
    JOIN races r ON r.race_id = ds.race_id
)
SELECT DISTINCT
    x.season_year,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    opening_position,
    final_position,
    opening_position - final_position AS positions_gained
FROM ranked x
JOIN drivers d ON d.driver_id = x.driver_id
ORDER BY positions_gained DESC, x.season_year DESC;

-- final constructor standings
WITH final_round AS (
    SELECT season_year, MAX(race_round) AS race_round
    FROM races
    GROUP BY season_year
)
SELECT
    r.season_year,
    c.constructor_name,
    cs.standing_position,
    cs.points,
    cs.wins
FROM final_round f
JOIN races r
  ON r.season_year = f.season_year
 AND r.race_round = f.race_round
JOIN constructor_standings cs ON cs.race_id = r.race_id
JOIN constructors c ON c.constructor_id = cs.constructor_id
ORDER BY r.season_year DESC, cs.standing_position;

-- champion win share
WITH final_round AS (
    SELECT season_year, MAX(race_round) AS race_round
    FROM races
    GROUP BY season_year
),
champions AS (
    SELECT r.season_year, ds.driver_id
    FROM final_round f
    JOIN races r
      ON r.season_year = f.season_year
     AND r.race_round = f.race_round
    JOIN driver_standings ds
      ON ds.race_id = r.race_id
     AND ds.standing_position = 1
),
wins AS (
    SELECT
        r.season_year,
        res.driver_id,
        COUNT(*) AS wins
    FROM results res
    JOIN races r ON r.race_id = res.race_id
    WHERE res.position_order = 1
    GROUP BY r.season_year, res.driver_id
),
race_count AS (
    SELECT season_year, COUNT(*) AS races
    FROM races
    GROUP BY season_year
)
SELECT
    c.season_year,
    CONCAT_WS(' ', d.forename, d.surname) AS champion,
    COALESCE(w.wins, 0) AS wins,
    rc.races,
    ROUND(100.0 * COALESCE(w.wins, 0) / NULLIF(rc.races, 0), 2) AS win_share_pct
FROM champions c
JOIN drivers d ON d.driver_id = c.driver_id
JOIN race_count rc ON rc.season_year = c.season_year
LEFT JOIN wins w
  ON w.season_year = c.season_year
 AND w.driver_id = c.driver_id
ORDER BY c.season_year;

-- points leader volatility
WITH x AS (
    SELECT
        r.season_year,
        r.race_round,
        ds.driver_id,
        ds.points,
        RANK() OVER (
            PARTITION BY r.season_year, r.race_round
            ORDER BY ds.points DESC
        ) AS points_rank
    FROM driver_standings ds
    JOIN races r ON r.race_id = ds.race_id
)
SELECT
    season_year,
    COUNT(DISTINCT CASE WHEN points_rank = 1 THEN driver_id END) AS different_leaders
FROM x
GROUP BY season_year
ORDER BY different_leaders DESC, season_year;
