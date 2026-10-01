USE f1_analytics;

-- career wins
SELECT driver_name, COUNT(*) AS wins
FROM v_result_enriched
WHERE position_order = 1
GROUP BY driver_name
ORDER BY wins DESC, driver_name;

-- career podiums
SELECT driver_name, COUNT(*) AS podiums
FROM v_result_enriched
WHERE position_order <= 3
GROUP BY driver_name
ORDER BY podiums DESC, driver_name;

-- pole conversion
WITH poles AS (
    SELECT race_id, driver_id
    FROM qualifying
    WHERE qualifying_position = 1
)
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS poles,
    SUM(CASE WHEN res.position_order = 1 THEN 1 ELSE 0 END) AS wins_from_pole,
    ROUND(
        100.0 * SUM(CASE WHEN res.position_order = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS conversion_pct
FROM poles p
JOIN results res
  ON res.race_id = p.race_id
 AND res.driver_id = p.driver_id
JOIN drivers d ON d.driver_id = p.driver_id
GROUP BY p.driver_id, d.forename, d.surname
HAVING COUNT(*) >= 5
ORDER BY conversion_pct DESC, poles DESC;

-- average grid gain
SELECT
    driver_name,
    COUNT(*) AS starts,
    ROUND(AVG(grid_position - position_order), 2) AS avg_positions_gained
FROM v_result_enriched
WHERE grid_position > 0
GROUP BY driver_name
HAVING COUNT(*) >= 30
ORDER BY avg_positions_gained DESC;

-- largest race gains
SELECT
    season_year,
    race_name,
    driver_name,
    grid_position,
    position_order,
    grid_position - position_order AS positions_gained
FROM v_result_enriched
WHERE grid_position > 0
ORDER BY positions_gained DESC, season_year DESC
LIMIT 50;

-- front-row win rate
SELECT
    driver_name,
    SUM(CASE WHEN grid_position <= 2 AND grid_position > 0 THEN 1 ELSE 0 END) AS front_row_starts,
    SUM(CASE WHEN grid_position <= 2 AND grid_position > 0 AND position_order = 1 THEN 1 ELSE 0 END) AS wins,
    ROUND(
        100.0 * SUM(CASE WHEN grid_position <= 2 AND grid_position > 0 AND position_order = 1 THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN grid_position <= 2 AND grid_position > 0 THEN 1 ELSE 0 END), 0), 2
    ) AS win_rate_pct
FROM v_result_enriched
GROUP BY driver_name
HAVING front_row_starts >= 10
ORDER BY win_rate_pct DESC;

-- wins outside top three
SELECT driver_name, COUNT(*) AS wins
FROM v_result_enriched
WHERE position_order = 1
  AND grid_position > 3
GROUP BY driver_name
ORDER BY wins DESC;

-- finish consistency
SELECT
    driver_name,
    COUNT(*) AS starts,
    ROUND(AVG(position_order), 2) AS avg_finish,
    ROUND(STDDEV_SAMP(position_order), 2) AS finish_sd
FROM v_result_enriched
GROUP BY driver_name
HAVING COUNT(*) >= 50
ORDER BY finish_sd, avg_finish;

-- points per start
SELECT
    driver_name,
    COUNT(*) AS starts,
    SUM(points) AS points,
    ROUND(SUM(points) / NULLIF(COUNT(*), 0), 2) AS points_per_start
FROM v_result_enriched
GROUP BY driver_name
HAVING COUNT(*) >= 30
ORDER BY points_per_start DESC;

-- season average finish
SELECT
    season_year,
    driver_name,
    starts,
    ROUND(avg_finish, 2) AS avg_finish
FROM mart_driver_season
WHERE starts >= 10
ORDER BY avg_finish, season_year DESC;
