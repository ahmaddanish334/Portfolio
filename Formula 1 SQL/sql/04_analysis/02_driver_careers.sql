USE f1_analytics;

-- career span
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    MIN(r.season_year) AS first_season,
    MAX(r.season_year) AS last_season,
    COUNT(DISTINCT r.season_year) AS seasons,
    COUNT(*) AS starts
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN drivers d ON d.driver_id = res.driver_id
GROUP BY res.driver_id, d.forename, d.surname
ORDER BY starts DESC;

-- wins by decade
WITH x AS (
    SELECT
        FLOOR(season_year / 10) * 10 AS decade,
        driver_name,
        COUNT(*) AS wins
    FROM v_result_enriched
    WHERE position_order = 1
    GROUP BY FLOOR(season_year / 10) * 10, driver_name
)
SELECT
    decade,
    driver_name,
    wins,
    DENSE_RANK() OVER (
        PARTITION BY decade ORDER BY wins DESC
    ) AS decade_rank
FROM x
ORDER BY decade, decade_rank, driver_name;

-- youngest winners
SELECT
    x.season_year,
    x.race_name,
    x.driver_name,
    TIMESTAMPDIFF(DAY, d.dob, x.race_date) AS age_days
FROM v_result_enriched x
JOIN drivers d ON d.driver_id = x.driver_id
WHERE x.position_order = 1
  AND d.dob IS NOT NULL
ORDER BY age_days
LIMIT 25;

-- oldest winners
SELECT
    x.season_year,
    x.race_name,
    x.driver_name,
    TIMESTAMPDIFF(DAY, d.dob, x.race_date) AS age_days
FROM v_result_enriched x
JOIN drivers d ON d.driver_id = x.driver_id
WHERE x.position_order = 1
  AND d.dob IS NOT NULL
ORDER BY age_days DESC
LIMIT 25;

-- first win
WITH wins AS (
    SELECT
        driver_id,
        season_year,
        race_round,
        race_name,
        ROW_NUMBER() OVER (
            PARTITION BY driver_id
            ORDER BY season_year, race_round
        ) AS rn
    FROM v_result_enriched
    WHERE position_order = 1
)
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    w.season_year,
    w.race_round,
    w.race_name
FROM wins w
JOIN drivers d ON d.driver_id = w.driver_id
WHERE rn = 1
ORDER BY season_year, race_round;

-- days to first win
WITH debut AS (
    SELECT driver_id, MIN(race_date) AS debut_date
    FROM v_result_enriched
    GROUP BY driver_id
),
first_win AS (
    SELECT driver_id, MIN(race_date) AS first_win_date
    FROM v_result_enriched
    WHERE position_order = 1
    GROUP BY driver_id
)
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    x.debut_date,
    w.first_win_date,
    DATEDIFF(w.first_win_date, x.debut_date) AS days_to_first_win
FROM debut x
JOIN first_win w ON w.driver_id = x.driver_id
JOIN drivers d ON d.driver_id = x.driver_id
ORDER BY days_to_first_win;

-- winning seasons
SELECT
    driver_name,
    COUNT(DISTINCT season_year) AS winning_seasons
FROM v_result_enriched
WHERE position_order = 1
GROUP BY driver_name
ORDER BY winning_seasons DESC;

-- constructors driven for
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(DISTINCT res.constructor_id) AS constructors,
    GROUP_CONCAT(
        DISTINCT c.constructor_name
        ORDER BY c.constructor_name
        SEPARATOR ', '
    ) AS constructor_list
FROM results res
JOIN drivers d ON d.driver_id = res.driver_id
JOIN constructors c ON c.constructor_id = res.constructor_id
GROUP BY res.driver_id, d.forename, d.surname
HAVING COUNT(DISTINCT res.constructor_id) >= 3
ORDER BY constructors DESC, driver_name;

-- nationality performance
SELECT
    d.nationality,
    COUNT(DISTINCT d.driver_id) AS drivers,
    SUM(CASE WHEN res.position_order = 1 THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN res.position_order <= 3 THEN 1 ELSE 0 END) AS podiums
FROM drivers d
JOIN results res ON res.driver_id = d.driver_id
GROUP BY d.nationality
ORDER BY wins DESC, drivers DESC;

-- top ten rate
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS starts,
    ROUND(
        100.0 * SUM(CASE WHEN res.position_order <= 10 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS top_ten_pct
FROM results res
JOIN drivers d ON d.driver_id = res.driver_id
GROUP BY res.driver_id, d.forename, d.surname
HAVING COUNT(*) >= 50
ORDER BY top_ten_pct DESC;
