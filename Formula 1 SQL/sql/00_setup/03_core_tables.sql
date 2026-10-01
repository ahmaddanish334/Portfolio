USE f1_analytics;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS sprint_results;
DROP TABLE IF EXISTS pit_stops;
DROP TABLE IF EXISTS lap_times;
DROP TABLE IF EXISTS qualifying;
DROP TABLE IF EXISTS constructor_results;
DROP TABLE IF EXISTS constructor_standings;
DROP TABLE IF EXISTS driver_standings;
DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS races;
DROP TABLE IF EXISTS drivers;
DROP TABLE IF EXISTS constructors;
DROP TABLE IF EXISTS circuits;
DROP TABLE IF EXISTS status_lookup;
DROP TABLE IF EXISTS seasons;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE seasons (
    season_year INT PRIMARY KEY,
    url TEXT
);

CREATE TABLE circuits (
    circuit_id INT PRIMARY KEY,
    circuit_ref VARCHAR(100) NOT NULL,
    circuit_name VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    country VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    altitude_m INT,
    url TEXT
);

CREATE TABLE drivers (
    driver_id INT PRIMARY KEY,
    driver_ref VARCHAR(100) NOT NULL,
    permanent_number INT,
    driver_code VARCHAR(10),
    forename VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    dob DATE,
    nationality VARCHAR(100),
    url TEXT
);

CREATE TABLE constructors (
    constructor_id INT PRIMARY KEY,
    constructor_ref VARCHAR(100) NOT NULL,
    constructor_name VARCHAR(255) NOT NULL,
    nationality VARCHAR(100),
    url TEXT
);

CREATE TABLE status_lookup (
    status_id INT PRIMARY KEY,
    status_name VARCHAR(255) NOT NULL
);

CREATE TABLE races (
    race_id INT PRIMARY KEY,
    season_year INT NOT NULL,
    race_round INT NOT NULL,
    circuit_id INT NOT NULL,
    race_name VARCHAR(255) NOT NULL,
    race_date DATE NOT NULL,
    race_time TIME NULL,
    url TEXT,
    fp1_date DATE,
    fp1_time TIME,
    fp2_date DATE,
    fp2_time TIME,
    fp3_date DATE,
    fp3_time TIME,
    qualifying_date DATE,
    qualifying_time TIME,
    sprint_date DATE,
    sprint_time TIME
);

CREATE TABLE results (
    result_id INT PRIMARY KEY,
    race_id INT NOT NULL,
    driver_id INT NOT NULL,
    constructor_id INT NOT NULL,
    car_number INT,
    grid_position INT NOT NULL,
    finish_position INT,
    position_text VARCHAR(20),
    position_order INT NOT NULL,
    points DECIMAL(10,2) NOT NULL,
    laps INT NOT NULL,
    result_time VARCHAR(100),
    milliseconds BIGINT,
    fastest_lap INT,
    fastest_lap_rank INT,
    fastest_lap_time_ms BIGINT,
    fastest_lap_speed DECIMAL(10,3),
    status_id INT NOT NULL
);

CREATE TABLE driver_standings (
    driver_standings_id INT PRIMARY KEY,
    race_id INT NOT NULL,
    driver_id INT NOT NULL,
    points DECIMAL(10,2) NOT NULL,
    standing_position INT NOT NULL,
    position_text VARCHAR(20),
    wins INT NOT NULL
);

CREATE TABLE constructor_standings (
    constructor_standings_id INT PRIMARY KEY,
    race_id INT NOT NULL,
    constructor_id INT NOT NULL,
    points DECIMAL(10,2) NOT NULL,
    standing_position INT NOT NULL,
    position_text VARCHAR(20),
    wins INT NOT NULL
);

CREATE TABLE constructor_results (
    constructor_results_id INT PRIMARY KEY,
    race_id INT NOT NULL,
    constructor_id INT NOT NULL,
    points DECIMAL(10,2) NOT NULL,
    source_status VARCHAR(100)
);

CREATE TABLE qualifying (
    qualify_id INT PRIMARY KEY,
    race_id INT NOT NULL,
    driver_id INT NOT NULL,
    constructor_id INT NOT NULL,
    car_number INT,
    qualifying_position INT NOT NULL,
    q1_ms BIGINT,
    q2_ms BIGINT,
    q3_ms BIGINT
);

CREATE TABLE lap_times (
    race_id INT NOT NULL,
    driver_id INT NOT NULL,
    lap_number INT NOT NULL,
    track_position INT NOT NULL,
    lap_time_ms INT NOT NULL,
    PRIMARY KEY (race_id, driver_id, lap_number)
);

CREATE TABLE pit_stops (
    race_id INT NOT NULL,
    driver_id INT NOT NULL,
    stop_number INT NOT NULL,
    lap_number INT NOT NULL,
    stop_time TIME,
    duration_ms INT NOT NULL,
    PRIMARY KEY (race_id, driver_id, stop_number)
);

CREATE TABLE sprint_results (
    sprint_result_id INT PRIMARY KEY,
    race_id INT NOT NULL,
    driver_id INT NOT NULL,
    constructor_id INT NOT NULL,
    car_number INT,
    grid_position INT NOT NULL,
    finish_position INT,
    position_text VARCHAR(20),
    position_order INT NOT NULL,
    points DECIMAL(10,2) NOT NULL,
    laps INT NOT NULL,
    result_time VARCHAR(100),
    milliseconds BIGINT,
    fastest_lap INT,
    fastest_lap_time_ms BIGINT,
    status_id INT NOT NULL
);
