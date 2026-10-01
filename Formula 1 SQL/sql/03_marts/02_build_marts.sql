USE f1_analytics;

DROP TABLE IF EXISTS mart_driver_season;
CREATE TABLE mart_driver_season AS
SELECT
    r.season_year,
    res.driver_id,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    COUNT(*) AS starts,
    SUM(CASE WHEN res.position_order = 1 THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN res.position_order <= 3 THEN 1 ELSE 0 END) AS podiums,
    SUM(CASE WHEN res.position_order <= 10 THEN 1 ELSE 0 END) AS top_tens,
    SUM(res.points) AS race_points,
    AVG(res.grid_position) AS avg_grid,
    AVG(res.position_order) AS avg_finish,
    AVG(res.grid_position - res.position_order) AS avg_grid_gain
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN drivers d ON d.driver_id = res.driver_id
GROUP BY
    r.season_year, res.driver_id, d.forename, d.surname;

ALTER TABLE mart_driver_season
    ADD PRIMARY KEY (season_year, driver_id);

DROP TABLE IF EXISTS mart_constructor_season;
CREATE TABLE mart_constructor_season AS
SELECT
    r.season_year,
    res.constructor_id,
    c.constructor_name,
    COUNT(*) AS entries,
    COUNT(DISTINCT res.race_id) AS races,
    SUM(CASE WHEN res.position_order = 1 THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN res.position_order <= 3 THEN 1 ELSE 0 END) AS podiums,
    SUM(res.points) AS race_points,
    AVG(res.position_order) AS avg_finish
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN constructors c ON c.constructor_id = res.constructor_id
GROUP BY
    r.season_year, res.constructor_id, c.constructor_name;

ALTER TABLE mart_constructor_season
    ADD PRIMARY KEY (season_year, constructor_id);

DROP TABLE IF EXISTS mart_driver_race_pace;
CREATE TABLE mart_driver_race_pace AS
SELECT
    race_id,
    driver_id,
    COUNT(*) AS timed_laps,
    AVG(lap_time_ms) AS avg_lap_ms,
    MIN(lap_time_ms) AS best_lap_ms,
    STDDEV_SAMP(lap_time_ms) AS lap_sd_ms
FROM lap_times
GROUP BY race_id, driver_id;

ALTER TABLE mart_driver_race_pace
    ADD PRIMARY KEY (race_id, driver_id);

DROP TABLE IF EXISTS mart_pit_stop_summary;
CREATE TABLE mart_pit_stop_summary AS
SELECT
    race_id,
    driver_id,
    COUNT(*) AS stops,
    AVG(duration_ms) AS avg_stop_ms,
    MIN(duration_ms) AS fastest_stop_ms,
    MAX(duration_ms) AS slowest_stop_ms
FROM pit_stops
GROUP BY race_id, driver_id;

ALTER TABLE mart_pit_stop_summary
    ADD PRIMARY KEY (race_id, driver_id);
