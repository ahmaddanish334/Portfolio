USE f1_analytics;

ALTER TABLE races
    ADD CONSTRAINT fk_races_season
        FOREIGN KEY (season_year) REFERENCES seasons(season_year),
    ADD CONSTRAINT fk_races_circuit
        FOREIGN KEY (circuit_id) REFERENCES circuits(circuit_id),
    ADD CONSTRAINT uq_races_season_round
        UNIQUE (season_year, race_round);

ALTER TABLE results
    ADD CONSTRAINT fk_results_race
        FOREIGN KEY (race_id) REFERENCES races(race_id),
    ADD CONSTRAINT fk_results_driver
        FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    ADD CONSTRAINT fk_results_constructor
        FOREIGN KEY (constructor_id) REFERENCES constructors(constructor_id),
    ADD CONSTRAINT fk_results_status
        FOREIGN KEY (status_id) REFERENCES status_lookup(status_id),
    ADD CONSTRAINT uq_results_race_driver
        UNIQUE (race_id, driver_id),
    ADD CONSTRAINT chk_results_grid
        CHECK (grid_position >= 0),
    ADD CONSTRAINT chk_results_order
        CHECK (position_order >= 1);

ALTER TABLE driver_standings
    ADD CONSTRAINT fk_ds_race
        FOREIGN KEY (race_id) REFERENCES races(race_id),
    ADD CONSTRAINT fk_ds_driver
        FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    ADD CONSTRAINT uq_ds_race_driver
        UNIQUE (race_id, driver_id);

ALTER TABLE constructor_standings
    ADD CONSTRAINT fk_cs_race
        FOREIGN KEY (race_id) REFERENCES races(race_id),
    ADD CONSTRAINT fk_cs_constructor
        FOREIGN KEY (constructor_id) REFERENCES constructors(constructor_id),
    ADD CONSTRAINT uq_cs_race_constructor
        UNIQUE (race_id, constructor_id);

ALTER TABLE constructor_results
    ADD CONSTRAINT fk_cr_race
        FOREIGN KEY (race_id) REFERENCES races(race_id),
    ADD CONSTRAINT fk_cr_constructor
        FOREIGN KEY (constructor_id) REFERENCES constructors(constructor_id),
    ADD CONSTRAINT uq_cr_race_constructor
        UNIQUE (race_id, constructor_id);

ALTER TABLE qualifying
    ADD CONSTRAINT fk_qualifying_race
        FOREIGN KEY (race_id) REFERENCES races(race_id),
    ADD CONSTRAINT fk_qualifying_driver
        FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    ADD CONSTRAINT fk_qualifying_constructor
        FOREIGN KEY (constructor_id) REFERENCES constructors(constructor_id),
    ADD CONSTRAINT uq_qualifying_race_driver
        UNIQUE (race_id, driver_id);

ALTER TABLE lap_times
    ADD CONSTRAINT fk_laps_race
        FOREIGN KEY (race_id) REFERENCES races(race_id),
    ADD CONSTRAINT fk_laps_driver
        FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    ADD CONSTRAINT chk_laps_number
        CHECK (lap_number >= 1),
    ADD CONSTRAINT chk_laps_position
        CHECK (track_position >= 1),
    ADD CONSTRAINT chk_laps_time
        CHECK (lap_time_ms > 0);

ALTER TABLE pit_stops
    ADD CONSTRAINT fk_pits_race
        FOREIGN KEY (race_id) REFERENCES races(race_id),
    ADD CONSTRAINT fk_pits_driver
        FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    ADD CONSTRAINT chk_pits_stop
        CHECK (stop_number >= 1),
    ADD CONSTRAINT chk_pits_lap
        CHECK (lap_number >= 1),
    ADD CONSTRAINT chk_pits_duration
        CHECK (duration_ms > 0);

ALTER TABLE sprint_results
    ADD CONSTRAINT fk_sprint_race
        FOREIGN KEY (race_id) REFERENCES races(race_id),
    ADD CONSTRAINT fk_sprint_driver
        FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    ADD CONSTRAINT fk_sprint_constructor
        FOREIGN KEY (constructor_id) REFERENCES constructors(constructor_id),
    ADD CONSTRAINT fk_sprint_status
        FOREIGN KEY (status_id) REFERENCES status_lookup(status_id),
    ADD CONSTRAINT uq_sprint_race_driver
        UNIQUE (race_id, driver_id);

CREATE INDEX idx_races_year_round
    ON races (season_year, race_round);

CREATE INDEX idx_results_driver_race
    ON results (driver_id, race_id);

CREATE INDEX idx_results_constructor_race
    ON results (constructor_id, race_id);

CREATE INDEX idx_results_race_finish
    ON results (race_id, position_order);

CREATE INDEX idx_results_status
    ON results (status_id);

CREATE INDEX idx_qualifying_race_position
    ON qualifying (race_id, qualifying_position);

CREATE INDEX idx_qualifying_driver_race
    ON qualifying (driver_id, race_id);

CREATE INDEX idx_laps_driver_race_lap
    ON lap_times (driver_id, race_id, lap_number);

CREATE INDEX idx_laps_race_lap_position
    ON lap_times (race_id, lap_number, track_position);

CREATE INDEX idx_pits_driver_race
    ON pit_stops (driver_id, race_id);

CREATE INDEX idx_pits_race_lap
    ON pit_stops (race_id, lap_number);

CREATE INDEX idx_ds_driver_race
    ON driver_standings (driver_id, race_id);

CREATE INDEX idx_cs_constructor_race
    ON constructor_standings (constructor_id, race_id);

CREATE INDEX idx_sprint_driver_race
    ON sprint_results (driver_id, race_id);
