USE f1_analytics;

-- Check this first. It should return ON.
SHOW VARIABLES LIKE 'local_infile';

TRUNCATE TABLE raw_circuits;
TRUNCATE TABLE raw_constructor_results;
TRUNCATE TABLE raw_constructor_standings;
TRUNCATE TABLE raw_constructors;
TRUNCATE TABLE raw_driver_standings;
TRUNCATE TABLE raw_drivers;
TRUNCATE TABLE raw_lap_times;
TRUNCATE TABLE raw_pit_stops;
TRUNCATE TABLE raw_qualifying;
TRUNCATE TABLE raw_races;
TRUNCATE TABLE raw_results;
TRUNCATE TABLE raw_seasons;
TRUNCATE TABLE raw_sprint_results;
TRUNCATE TABLE raw_status;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/circuits.csv'
INTO TABLE raw_circuits
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/constructor_results.csv'
INTO TABLE raw_constructor_results
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/constructor_standings.csv'
INTO TABLE raw_constructor_standings
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/constructors.csv'
INTO TABLE raw_constructors
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/driver_standings.csv'
INTO TABLE raw_driver_standings
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/drivers.csv'
INTO TABLE raw_drivers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/lap_times.csv'
INTO TABLE raw_lap_times
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/pit_stops.csv'
INTO TABLE raw_pit_stops
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/qualifying.csv'
INTO TABLE raw_qualifying
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/races.csv'
INTO TABLE raw_races
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/results.csv'
INTO TABLE raw_results
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/seasons.csv'
INTO TABLE raw_seasons
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/sprint_results.csv'
INTO TABLE raw_sprint_results
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/path/to/f1_csv_files/status.csv'
INTO TABLE raw_status
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT 'circuits' AS table_name, COUNT(*) AS rows_loaded FROM raw_circuits
UNION ALL SELECT 'constructor_results', COUNT(*) FROM raw_constructor_results
UNION ALL SELECT 'constructor_standings', COUNT(*) FROM raw_constructor_standings
UNION ALL SELECT 'constructors', COUNT(*) FROM raw_constructors
UNION ALL SELECT 'driver_standings', COUNT(*) FROM raw_driver_standings
UNION ALL SELECT 'drivers', COUNT(*) FROM raw_drivers
UNION ALL SELECT 'lap_times', COUNT(*) FROM raw_lap_times
UNION ALL SELECT 'pit_stops', COUNT(*) FROM raw_pit_stops
UNION ALL SELECT 'qualifying', COUNT(*) FROM raw_qualifying
UNION ALL SELECT 'races', COUNT(*) FROM raw_races
UNION ALL SELECT 'results', COUNT(*) FROM raw_results
UNION ALL SELECT 'seasons', COUNT(*) FROM raw_seasons
UNION ALL SELECT 'sprint_results', COUNT(*) FROM raw_sprint_results
UNION ALL SELECT 'status', COUNT(*) FROM raw_status
ORDER BY table_name;
