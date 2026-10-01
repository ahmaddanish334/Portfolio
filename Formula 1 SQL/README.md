# Formula 1 Performance Analytics

MySQL 8 project built from 14 relational Formula 1 datasets.

The database covers race results, qualifying, standings, lap times, pit stops, sprint results, drivers, constructors, circuits and seasons.

## Dataset scale

- 1,125 races
- 26,759 race results
- 589,081 lap-time records
- 34,863 driver-standing records
- 13,391 constructor-standing records
- 12,625 constructor-result records
- 11,371 pit stops
- 10,494 qualifying records
- 861 drivers
- 212 constructors
- 360 sprint results

Race history covers 1950–2024. Lap-time, qualifying, pit-stop and sprint data start later, so those analyses are separated from full-history race-result analysis.

## Project structure

```text
sql/
  00_setup/
  01_load/
  02_quality/
  03_marts/
  04_analysis/
  05_optimization/

docs/
data/
```

## Database design

The project uses a raw landing layer and a typed relational layer.

The core model links:

- races to circuits and seasons
- results to races, drivers, constructors and status
- qualifying to races, drivers and constructors
- lap times and pit stops to races and drivers
- standings to races and the relevant driver or constructor

## Analysis

The SQL scripts cover:

- race wins, podiums and grid performance
- driver careers
- teammate comparisons
- constructor performance
- qualifying
- championship progression
- reliability
- lap-time analysis
- pit-stop analysis
- circuit characteristics
- sprint races
- rolling, cumulative and ranking metrics

The analysis folder contains more than 100 individual queries using CTEs, window functions, ranking, `LAG`, `FIRST_VALUE`, `LAST_VALUE`, rolling sums and multi-table joins.

## Performance

The project includes composite indexes and `EXPLAIN ANALYZE` examples. The lap-time table is the largest table and is used for most of the indexing work.

## Run

Use MySQL 8 and MySQL Workbench.

Run the files in `RUN_ORDER.md`.

Before loading the data, update the folder path inside:

```text
sql/01_load/01_load_raw_workbench.sql
```

## Data source

Public Formula 1 World Championship dataset available on Kaggle.

The raw CSV files are not included in this repository.
