# Data model

```text
seasons
   |
races -------- circuits
   |
   +---- results -------- drivers
   |        |
   |        +----------- constructors
   |        |
   |        +----------- status_lookup
   |
   +---- qualifying
   |
   +---- lap_times
   |
   +---- pit_stops
   |
   +---- sprint_results
   |
   +---- driver_standings
   |
   +---- constructor_standings
   |
   +---- constructor_results
```

Important composite keys:

- `lap_times (race_id, driver_id, lap_number)`
- `pit_stops (race_id, driver_id, stop_number)`

The raw tables intentionally keep everything as text. Casting and null handling happen during the core transform.
