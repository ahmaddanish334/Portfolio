# Run order

1. `sql/00_setup/00_create_database.sql`
2. `sql/00_setup/01_raw_tables.sql`
3. `sql/00_setup/02_helpers.sql`
4. `sql/00_setup/03_core_tables.sql`
5. `sql/01_load/01_load_raw_workbench.sql`
6. `sql/01_load/02_transform_core.sql`
7. `sql/00_setup/04_constraints_indexes.sql`
8. `sql/02_quality/01_quality_checks.sql`
9. `sql/03_marts/01_views.sql`
10. `sql/03_marts/02_build_marts.sql`

Then run the files in `sql/04_analysis/`.

Use `sql/05_optimization/` after the core analysis is working.
