USE f1_analytics;

CREATE OR REPLACE VIEW v_result_enriched AS
SELECT
    r.season_year,
    r.race_round,
    r.race_id,
    r.race_name,
    r.race_date,
    ci.circuit_name,
    ci.country,
    res.result_id,
    res.driver_id,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    res.constructor_id,
    c.constructor_name,
    res.grid_position,
    res.finish_position,
    res.position_order,
    res.points,
    res.laps,
    res.milliseconds,
    res.fastest_lap,
    res.fastest_lap_rank,
    res.fastest_lap_time_ms,
    res.fastest_lap_speed,
    s.status_name
FROM results res
JOIN races r ON r.race_id = res.race_id
JOIN circuits ci ON ci.circuit_id = r.circuit_id
JOIN drivers d ON d.driver_id = res.driver_id
JOIN constructors c ON c.constructor_id = res.constructor_id
JOIN status_lookup s ON s.status_id = res.status_id;

CREATE OR REPLACE VIEW v_qualifying_enriched AS
SELECT
    r.season_year,
    r.race_round,
    q.race_id,
    r.race_name,
    q.driver_id,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    q.constructor_id,
    c.constructor_name,
    q.qualifying_position,
    q.q1_ms,
    q.q2_ms,
    q.q3_ms
FROM qualifying q
JOIN races r ON r.race_id = q.race_id
JOIN drivers d ON d.driver_id = q.driver_id
JOIN constructors c ON c.constructor_id = q.constructor_id;

CREATE OR REPLACE VIEW v_lap_enriched AS
SELECT
    r.season_year,
    r.race_round,
    l.race_id,
    r.race_name,
    l.driver_id,
    CONCAT_WS(' ', d.forename, d.surname) AS driver_name,
    l.lap_number,
    l.track_position,
    l.lap_time_ms
FROM lap_times l
JOIN races r ON r.race_id = l.race_id
JOIN drivers d ON d.driver_id = l.driver_id;
