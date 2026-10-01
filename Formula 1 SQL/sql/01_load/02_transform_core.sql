USE f1_analytics;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE sprint_results;
TRUNCATE TABLE pit_stops;
TRUNCATE TABLE lap_times;
TRUNCATE TABLE qualifying;
TRUNCATE TABLE constructor_results;
TRUNCATE TABLE constructor_standings;
TRUNCATE TABLE driver_standings;
TRUNCATE TABLE results;
TRUNCATE TABLE races;
TRUNCATE TABLE drivers;
TRUNCATE TABLE constructors;
TRUNCATE TABLE circuits;
TRUNCATE TABLE status_lookup;
TRUNCATE TABLE seasons;

INSERT INTO seasons (season_year, url)
SELECT
    CAST(clean_text(year_txt) AS UNSIGNED),
    clean_text(url_txt)
FROM raw_seasons;

INSERT INTO circuits (
    circuit_id, circuit_ref, circuit_name, location, country,
    latitude, longitude, altitude_m, url
)
SELECT
    CAST(clean_text(circuit_id_txt) AS UNSIGNED),
    clean_text(circuit_ref_txt),
    clean_text(name_txt),
    clean_text(location_txt),
    clean_text(country_txt),
    CAST(clean_text(lat_txt) AS DECIMAL(9,6)),
    CAST(clean_text(lng_txt) AS DECIMAL(9,6)),
    CAST(clean_text(alt_txt) AS SIGNED),
    clean_text(url_txt)
FROM raw_circuits;

INSERT INTO drivers (
    driver_id, driver_ref, permanent_number, driver_code,
    forename, surname, dob, nationality, url
)
SELECT
    CAST(clean_text(driver_id_txt) AS UNSIGNED),
    clean_text(driver_ref_txt),
    CAST(clean_text(number_txt) AS UNSIGNED),
    clean_text(code_txt),
    clean_text(forename_txt),
    clean_text(surname_txt),
    STR_TO_DATE(clean_text(dob_txt), '%Y-%m-%d'),
    clean_text(nationality_txt),
    clean_text(url_txt)
FROM raw_drivers;

INSERT INTO constructors (
    constructor_id, constructor_ref, constructor_name, nationality, url
)
SELECT
    CAST(clean_text(constructor_id_txt) AS UNSIGNED),
    clean_text(constructor_ref_txt),
    clean_text(name_txt),
    clean_text(nationality_txt),
    clean_text(url_txt)
FROM raw_constructors;

INSERT INTO status_lookup (status_id, status_name)
SELECT
    CAST(clean_text(status_id_txt) AS UNSIGNED),
    clean_text(status_txt)
FROM raw_status;

INSERT INTO races (
    race_id, season_year, race_round, circuit_id, race_name,
    race_date, race_time, url,
    fp1_date, fp1_time, fp2_date, fp2_time, fp3_date, fp3_time,
    qualifying_date, qualifying_time, sprint_date, sprint_time
)
SELECT
    CAST(clean_text(race_id_txt) AS UNSIGNED),
    CAST(clean_text(year_txt) AS UNSIGNED),
    CAST(clean_text(round_txt) AS UNSIGNED),
    CAST(clean_text(circuit_id_txt) AS UNSIGNED),
    clean_text(name_txt),
    STR_TO_DATE(clean_text(date_txt), '%Y-%m-%d'),
    CAST(clean_text(time_txt) AS TIME),
    clean_text(url_txt),
    STR_TO_DATE(clean_text(fp1_date_txt), '%Y-%m-%d'),
    CAST(clean_text(fp1_time_txt) AS TIME),
    STR_TO_DATE(clean_text(fp2_date_txt), '%Y-%m-%d'),
    CAST(clean_text(fp2_time_txt) AS TIME),
    STR_TO_DATE(clean_text(fp3_date_txt), '%Y-%m-%d'),
    CAST(clean_text(fp3_time_txt) AS TIME),
    STR_TO_DATE(clean_text(quali_date_txt), '%Y-%m-%d'),
    CAST(clean_text(quali_time_txt) AS TIME),
    STR_TO_DATE(clean_text(sprint_date_txt), '%Y-%m-%d'),
    CAST(clean_text(sprint_time_txt) AS TIME)
FROM raw_races;

INSERT INTO results (
    result_id, race_id, driver_id, constructor_id, car_number,
    grid_position, finish_position, position_text, position_order,
    points, laps, result_time, milliseconds, fastest_lap,
    fastest_lap_rank, fastest_lap_time_ms, fastest_lap_speed, status_id
)
SELECT
    CAST(clean_text(result_id_txt) AS UNSIGNED),
    CAST(clean_text(race_id_txt) AS UNSIGNED),
    CAST(clean_text(driver_id_txt) AS UNSIGNED),
    CAST(clean_text(constructor_id_txt) AS UNSIGNED),
    CAST(clean_text(number_txt) AS UNSIGNED),
    CAST(clean_text(grid_txt) AS UNSIGNED),
    CAST(clean_text(position_txt) AS UNSIGNED),
    clean_text(position_text_txt),
    CAST(clean_text(position_order_txt) AS UNSIGNED),
    CAST(clean_text(points_txt) AS DECIMAL(10,2)),
    CAST(clean_text(laps_txt) AS UNSIGNED),
    clean_text(time_txt),
    CAST(clean_text(milliseconds_txt) AS UNSIGNED),
    CAST(clean_text(fastest_lap_txt) AS UNSIGNED),
    CAST(clean_text(rank_txt) AS UNSIGNED),
    f1_time_ms(fastest_lap_time_txt),
    CAST(clean_text(fastest_lap_speed_txt) AS DECIMAL(10,3)),
    CAST(clean_text(status_id_txt) AS UNSIGNED)
FROM raw_results;

INSERT INTO driver_standings (
    driver_standings_id, race_id, driver_id, points,
    standing_position, position_text, wins
)
SELECT
    CAST(clean_text(driver_standings_id_txt) AS UNSIGNED),
    CAST(clean_text(race_id_txt) AS UNSIGNED),
    CAST(clean_text(driver_id_txt) AS UNSIGNED),
    CAST(clean_text(points_txt) AS DECIMAL(10,2)),
    CAST(clean_text(position_txt) AS UNSIGNED),
    clean_text(position_text_txt),
    CAST(clean_text(wins_txt) AS UNSIGNED)
FROM raw_driver_standings;

INSERT INTO constructor_standings (
    constructor_standings_id, race_id, constructor_id, points,
    standing_position, position_text, wins
)
SELECT
    CAST(clean_text(constructor_standings_id_txt) AS UNSIGNED),
    CAST(clean_text(race_id_txt) AS UNSIGNED),
    CAST(clean_text(constructor_id_txt) AS UNSIGNED),
    CAST(clean_text(points_txt) AS DECIMAL(10,2)),
    CAST(clean_text(position_txt) AS UNSIGNED),
    clean_text(position_text_txt),
    CAST(clean_text(wins_txt) AS UNSIGNED)
FROM raw_constructor_standings;

INSERT INTO constructor_results (
    constructor_results_id, race_id, constructor_id, points, source_status
)
SELECT
    CAST(clean_text(constructor_results_id_txt) AS UNSIGNED),
    CAST(clean_text(race_id_txt) AS UNSIGNED),
    CAST(clean_text(constructor_id_txt) AS UNSIGNED),
    CAST(clean_text(points_txt) AS DECIMAL(10,2)),
    clean_text(status_txt)
FROM raw_constructor_results;

INSERT INTO qualifying (
    qualify_id, race_id, driver_id, constructor_id, car_number,
    qualifying_position, q1_ms, q2_ms, q3_ms
)
SELECT
    CAST(clean_text(qualify_id_txt) AS UNSIGNED),
    CAST(clean_text(race_id_txt) AS UNSIGNED),
    CAST(clean_text(driver_id_txt) AS UNSIGNED),
    CAST(clean_text(constructor_id_txt) AS UNSIGNED),
    CAST(clean_text(number_txt) AS UNSIGNED),
    CAST(clean_text(position_txt) AS UNSIGNED),
    f1_time_ms(q1_txt),
    f1_time_ms(q2_txt),
    f1_time_ms(q3_txt)
FROM raw_qualifying;

INSERT INTO lap_times (
    race_id, driver_id, lap_number, track_position, lap_time_ms
)
SELECT
    CAST(clean_text(race_id_txt) AS UNSIGNED),
    CAST(clean_text(driver_id_txt) AS UNSIGNED),
    CAST(clean_text(lap_txt) AS UNSIGNED),
    CAST(clean_text(position_txt) AS UNSIGNED),
    CAST(clean_text(milliseconds_txt) AS UNSIGNED)
FROM raw_lap_times;

INSERT INTO pit_stops (
    race_id, driver_id, stop_number, lap_number, stop_time, duration_ms
)
SELECT
    CAST(clean_text(race_id_txt) AS UNSIGNED),
    CAST(clean_text(driver_id_txt) AS UNSIGNED),
    CAST(clean_text(stop_txt) AS UNSIGNED),
    CAST(clean_text(lap_txt) AS UNSIGNED),
    CAST(clean_text(time_txt) AS TIME),
    CAST(clean_text(milliseconds_txt) AS UNSIGNED)
FROM raw_pit_stops;

INSERT INTO sprint_results (
    sprint_result_id, race_id, driver_id, constructor_id, car_number,
    grid_position, finish_position, position_text, position_order,
    points, laps, result_time, milliseconds, fastest_lap,
    fastest_lap_time_ms, status_id
)
SELECT
    CAST(clean_text(result_id_txt) AS UNSIGNED),
    CAST(clean_text(race_id_txt) AS UNSIGNED),
    CAST(clean_text(driver_id_txt) AS UNSIGNED),
    CAST(clean_text(constructor_id_txt) AS UNSIGNED),
    CAST(clean_text(number_txt) AS UNSIGNED),
    CAST(clean_text(grid_txt) AS UNSIGNED),
    CAST(clean_text(position_txt) AS UNSIGNED),
    clean_text(position_text_txt),
    CAST(clean_text(position_order_txt) AS UNSIGNED),
    CAST(clean_text(points_txt) AS DECIMAL(10,2)),
    CAST(clean_text(laps_txt) AS UNSIGNED),
    clean_text(time_txt),
    CAST(clean_text(milliseconds_txt) AS UNSIGNED),
    CAST(clean_text(fastest_lap_txt) AS UNSIGNED),
    f1_time_ms(fastest_lap_time_txt),
    CAST(clean_text(status_id_txt) AS UNSIGNED)
FROM raw_sprint_results;

SET FOREIGN_KEY_CHECKS = 1;
