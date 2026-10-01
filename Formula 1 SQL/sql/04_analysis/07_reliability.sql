USE f1_analytics;

-- status frequency
SELECT s.status_name, COUNT(*) AS results
FROM results r
JOIN status_lookup s ON s.status_id = r.status_id
GROUP BY s.status_name
ORDER BY results DESC;

-- driver classified rate
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS starts,
    SUM(CASE WHEN res.finish_position IS NOT NULL THEN 1 ELSE 0 END) AS classified_finishes,
    ROUND(
        100.0 * SUM(CASE WHEN res.finish_position IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS classified_pct
FROM results res
JOIN drivers d ON d.driver_id = res.driver_id
GROUP BY res.driver_id, d.forename, d.surname
HAVING COUNT(*) >= 50
ORDER BY classified_pct DESC;

-- constructor classified rate
SELECT
    c.constructor_name,
    COUNT(*) AS starts,
    SUM(CASE WHEN res.finish_position IS NOT NULL THEN 1 ELSE 0 END) AS classified_finishes,
    ROUND(
        100.0 * SUM(CASE WHEN res.finish_position IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS classified_pct
FROM results res
JOIN constructors c ON c.constructor_id = res.constructor_id
GROUP BY c.constructor_id, c.constructor_name
HAVING COUNT(*) >= 100
ORDER BY classified_pct DESC;

-- unclassified by season
SELECT
    r.season_year,
    SUM(CASE WHEN res.finish_position IS NULL THEN 1 ELSE 0 END) AS unclassified,
    COUNT(*) AS entries,
    ROUND(
        100.0 * SUM(CASE WHEN res.finish_position IS NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS unclassified_pct
FROM results res
JOIN races r ON r.race_id = res.race_id
GROUP BY r.season_year
ORDER BY r.season_year;

-- status by decade
SELECT
    FLOOR(r.season_year / 10) * 10 AS decade,
    s.status_name,
    COUNT(*) AS results
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN status_lookup s ON s.status_id = res.status_id
GROUP BY FLOOR(r.season_year / 10) * 10, s.status_name
ORDER BY decade, results DESC;

-- common non-finish statuses
SELECT
    s.status_name,
    COUNT(*) AS occurrences
FROM results res
JOIN status_lookup s ON s.status_id = res.status_id
WHERE res.finish_position IS NULL
GROUP BY s.status_name
ORDER BY occurrences DESC
LIMIT 30;

-- constructor reliability by season
SELECT
    r.season_year,
    c.constructor_name,
    COUNT(*) AS entries,
    SUM(CASE WHEN res.finish_position IS NOT NULL THEN 1 ELSE 0 END) AS classified,
    ROUND(
        100.0 * SUM(CASE WHEN res.finish_position IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS classified_pct
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN constructors c ON c.constructor_id = res.constructor_id
GROUP BY r.season_year, c.constructor_id, c.constructor_name
HAVING COUNT(*) >= 10
ORDER BY r.season_year DESC, classified_pct DESC;

-- longest classified streak
WITH x AS (
    SELECT
        res.driver_id,
        r.season_year,
        r.race_round,
        CASE WHEN res.finish_position IS NOT NULL THEN 1 ELSE 0 END AS classified,
        SUM(
            CASE WHEN res.finish_position IS NULL THEN 1 ELSE 0 END
        ) OVER (
            PARTITION BY res.driver_id
            ORDER BY r.season_year, r.race_round
        ) AS grp
    FROM results res
    JOIN races r ON r.race_id = res.race_id
),
streaks AS (
    SELECT driver_id, grp, COUNT(*) AS streak
    FROM x
    WHERE classified = 1
    GROUP BY driver_id, grp
)
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    MAX(s.streak) AS longest_streak
FROM streaks s
JOIN drivers d ON d.driver_id = s.driver_id
GROUP BY d.driver_id, d.forename, d.surname
ORDER BY longest_streak DESC;

-- highest attrition races
SELECT
    season_year,
    race_name,
    COUNT(*) AS starters,
    SUM(CASE WHEN finish_position IS NULL THEN 1 ELSE 0 END) AS unclassified,
    ROUND(
        100.0 * SUM(CASE WHEN finish_position IS NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS attrition_pct
FROM v_result_enriched
GROUP BY season_year, race_round, race_name
HAVING COUNT(*) >= 10
ORDER BY attrition_pct DESC
LIMIT 50;

-- reliability by nationality
SELECT
    d.nationality,
    COUNT(*) AS starts,
    ROUND(
        100.0 * SUM(CASE WHEN res.finish_position IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS classified_pct
FROM results res
JOIN drivers d ON d.driver_id = res.driver_id
GROUP BY d.nationality
HAVING COUNT(*) >= 200
ORDER BY classified_pct DESC;
