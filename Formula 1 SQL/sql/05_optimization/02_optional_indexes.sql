USE f1_analytics;

-- Add these only after checking the plans.

CREATE INDEX idx_results_finish_driver
    ON results (position_order, driver_id, race_id);

CREATE INDEX idx_qualifying_position_driver
    ON qualifying (qualifying_position, driver_id, race_id);

CREATE INDEX idx_laps_race_driver_time
    ON lap_times (race_id, driver_id, lap_time_ms);

CREATE INDEX idx_pits_race_duration
    ON pit_stops (race_id, duration_ms);
