USE f1_analytics;

-- poles
SELECT driver_name, COUNT(*) AS poles
FROM v_qualifying_enriched
WHERE qualifying_position = 1
GROUP BY driver_name
ORDER BY poles DESC;

-- front-row starts
SELECT driver_name, COUNT(*) AS front_rows
FROM v_qualifying_enriched
WHERE qualifying_position <= 2
GROUP BY driver_name
ORDER BY front_rows DESC;

-- average qualifying position
SELECT
    driver_name,
    COUNT(*) AS sessions,
    ROUND(AVG(qualifying_position), 2) AS avg_qualifying_position
FROM v_qualifying_enriched
GROUP BY driver_name
HAVING COUNT(*) >= 30
ORDER BY avg_qualifying_position;

-- Q1 to Q3 improvement
SELECT
    driver_name,
    COUNT(*) AS sessions,
    ROUND(AVG(q1_ms - q3_ms), 1) AS avg_improvement_ms
FROM v_qualifying_enriched
WHERE q1_ms IS NOT NULL
  AND q3_ms IS NOT NULL
GROUP BY driver_name
HAVING COUNT(*) >= 20
ORDER BY avg_improvement_ms DESC;

-- pole margin
WITH q3 AS (
    SELECT
        race_id,
        driver_id,
        q3_ms,
        ROW_NUMBER() OVER (
            PARTITION BY race_id
            ORDER BY q3_ms
        ) AS rn
    FROM qualifying
    WHERE q3_ms IS NOT NULL
),
pair AS (
    SELECT
        a.race_id,
        a.driver_id AS pole_driver,
        b.q3_ms - a.q3_ms AS margin_ms
    FROM q3 a
    JOIN q3 b
      ON b.race_id = a.race_id
     AND b.rn = 2
    WHERE a.rn = 1
)
SELECT
    r.season_year,
    r.race_name,
    CONCAT_WS(' ', d.forename, d.surname) AS pole_driver,
    p.margin_ms
FROM pair p
JOIN races r ON r.race_id = p.race_id
JOIN drivers d ON d.driver_id = p.pole_driver
ORDER BY p.margin_ms DESC
LIMIT 50;

-- qualifying vs finish
SELECT
    q.qualifying_position,
    ROUND(AVG(res.position_order), 2) AS avg_finish,
    COUNT(*) AS entries
FROM qualifying q
JOIN results res
  ON res.race_id = q.race_id
 AND res.driver_id = q.driver_id
GROUP BY q.qualifying_position
ORDER BY q.qualifying_position;

-- race-day gain
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS matched_races,
    ROUND(AVG(q.qualifying_position - res.position_order), 2) AS avg_gain
FROM qualifying q
JOIN results res
  ON res.race_id = q.race_id
 AND res.driver_id = q.driver_id
JOIN drivers d ON d.driver_id = q.driver_id
GROUP BY q.driver_id, d.forename, d.surname
HAVING COUNT(*) >= 30
ORDER BY avg_gain DESC;

-- team qualifying strength
SELECT
    r.season_year,
    c.constructor_name,
    ROUND(AVG(q.qualifying_position), 2) AS avg_position,
    COUNT(*) AS entries
FROM qualifying q
JOIN races r ON r.race_id = q.race_id
JOIN constructors c ON c.constructor_id = q.constructor_id
GROUP BY r.season_year, c.constructor_id, c.constructor_name
HAVING COUNT(*) >= 10
ORDER BY r.season_year DESC, avg_position;

-- Q3 appearance rate
SELECT
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS sessions,
    SUM(CASE WHEN q.q3_ms IS NOT NULL THEN 1 ELSE 0 END) AS q3_sessions,
    ROUND(
        100.0 * SUM(CASE WHEN q.q3_ms IS NOT NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS q3_rate_pct
FROM qualifying q
JOIN drivers d ON d.driver_id = q.driver_id
GROUP BY q.driver_id, d.forename, d.surname
HAVING COUNT(*) >= 30
ORDER BY q3_rate_pct DESC;

-- constructor poles
SELECT
    c.constructor_name,
    COUNT(*) AS poles
FROM qualifying q
JOIN constructors c ON c.constructor_id = q.constructor_id
WHERE q.qualifying_position = 1
GROUP BY c.constructor_id, c.constructor_name
ORDER BY poles DESC;
