USE f1_analytics;

DROP TABLE IF EXISTS raw_circuits;
DROP TABLE IF EXISTS raw_constructor_results;
DROP TABLE IF EXISTS raw_constructor_standings;
DROP TABLE IF EXISTS raw_constructors;
DROP TABLE IF EXISTS raw_driver_standings;
DROP TABLE IF EXISTS raw_drivers;
DROP TABLE IF EXISTS raw_lap_times;
DROP TABLE IF EXISTS raw_pit_stops;
DROP TABLE IF EXISTS raw_qualifying;
DROP TABLE IF EXISTS raw_races;
DROP TABLE IF EXISTS raw_results;
DROP TABLE IF EXISTS raw_seasons;
DROP TABLE IF EXISTS raw_sprint_results;
DROP TABLE IF EXISTS raw_status;

CREATE TABLE raw_circuits (
    circuit_id_txt TEXT,
    circuit_ref_txt TEXT,
    name_txt TEXT,
    location_txt TEXT,
    country_txt TEXT,
    lat_txt TEXT,
    lng_txt TEXT,
    alt_txt TEXT,
    url_txt TEXT
);

CREATE TABLE raw_constructor_results (
    constructor_results_id_txt TEXT,
    race_id_txt TEXT,
    constructor_id_txt TEXT,
    points_txt TEXT,
    status_txt TEXT
);

CREATE TABLE raw_constructor_standings (
    constructor_standings_id_txt TEXT,
    race_id_txt TEXT,
    constructor_id_txt TEXT,
    points_txt TEXT,
    position_txt TEXT,
    position_text_txt TEXT,
    wins_txt TEXT
);

CREATE TABLE raw_constructors (
    constructor_id_txt TEXT,
    constructor_ref_txt TEXT,
    name_txt TEXT,
    nationality_txt TEXT,
    url_txt TEXT
);

CREATE TABLE raw_driver_standings (
    driver_standings_id_txt TEXT,
    race_id_txt TEXT,
    driver_id_txt TEXT,
    points_txt TEXT,
    position_txt TEXT,
    position_text_txt TEXT,
    wins_txt TEXT
);

CREATE TABLE raw_drivers (
    driver_id_txt TEXT,
    driver_ref_txt TEXT,
    number_txt TEXT,
    code_txt TEXT,
    forename_txt TEXT,
    surname_txt TEXT,
    dob_txt TEXT,
    nationality_txt TEXT,
    url_txt TEXT
);

CREATE TABLE raw_lap_times (
    race_id_txt TEXT,
    driver_id_txt TEXT,
    lap_txt TEXT,
    position_txt TEXT,
    time_txt TEXT,
    milliseconds_txt TEXT
);

CREATE TABLE raw_pit_stops (
    race_id_txt TEXT,
    driver_id_txt TEXT,
    stop_txt TEXT,
    lap_txt TEXT,
    time_txt TEXT,
    duration_txt TEXT,
    milliseconds_txt TEXT
);

CREATE TABLE raw_qualifying (
    qualify_id_txt TEXT,
    race_id_txt TEXT,
    driver_id_txt TEXT,
    constructor_id_txt TEXT,
    number_txt TEXT,
    position_txt TEXT,
    q1_txt TEXT,
    q2_txt TEXT,
    q3_txt TEXT
);

CREATE TABLE raw_races (
    race_id_txt TEXT,
    year_txt TEXT,
    round_txt TEXT,
    circuit_id_txt TEXT,
    name_txt TEXT,
    date_txt TEXT,
    time_txt TEXT,
    url_txt TEXT,
    fp1_date_txt TEXT,
    fp1_time_txt TEXT,
    fp2_date_txt TEXT,
    fp2_time_txt TEXT,
    fp3_date_txt TEXT,
    fp3_time_txt TEXT,
    quali_date_txt TEXT,
    quali_time_txt TEXT,
    sprint_date_txt TEXT,
    sprint_time_txt TEXT
);

CREATE TABLE raw_results (
    result_id_txt TEXT,
    race_id_txt TEXT,
    driver_id_txt TEXT,
    constructor_id_txt TEXT,
    number_txt TEXT,
    grid_txt TEXT,
    position_txt TEXT,
    position_text_txt TEXT,
    position_order_txt TEXT,
    points_txt TEXT,
    laps_txt TEXT,
    time_txt TEXT,
    milliseconds_txt TEXT,
    fastest_lap_txt TEXT,
    rank_txt TEXT,
    fastest_lap_time_txt TEXT,
    fastest_lap_speed_txt TEXT,
    status_id_txt TEXT
);

CREATE TABLE raw_seasons (
    year_txt TEXT,
    url_txt TEXT
);

CREATE TABLE raw_sprint_results (
    result_id_txt TEXT,
    race_id_txt TEXT,
    driver_id_txt TEXT,
    constructor_id_txt TEXT,
    number_txt TEXT,
    grid_txt TEXT,
    position_txt TEXT,
    position_text_txt TEXT,
    position_order_txt TEXT,
    points_txt TEXT,
    laps_txt TEXT,
    time_txt TEXT,
    milliseconds_txt TEXT,
    fastest_lap_txt TEXT,
    fastest_lap_time_txt TEXT,
    status_id_txt TEXT
);

CREATE TABLE raw_status (
    status_id_txt TEXT,
    status_txt TEXT
);
