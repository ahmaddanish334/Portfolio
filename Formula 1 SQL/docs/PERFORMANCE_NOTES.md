# Performance work

Start with the base indexes in `04_constraints_indexes.sql`.

Use:

```sql
EXPLAIN ANALYZE
SELECT ...;
```

Record:

- actual execution time
- estimated rows vs actual rows
- table scan vs index lookup/range scan
- join order
- rows examined
- indexes used

The largest table in this upload is `lap_times`, so it is the best place to demonstrate indexing and plan analysis.

Do not add every optional index automatically. Test a query first, add one index, rerun the plan, and record whether it actually helped.
