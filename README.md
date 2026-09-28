# Lightcast Labor Market Analysis

A Snowflake SQL data pipeline analyzing the relationship between education completions
and labor market outcomes across U.S. states, built on the Lightcast U.S. Labor Market
Information dataset (BLS, Census, IPEDS).

## What it does

The pipeline ingests raw labor market and education data, cleans and standardizes it,
then aggregates it into analysis-ready views answering questions like:

- Which states have the highest STEM vs. non-STEM completion rates, and how does that
  relate to local unemployment?
- Which occupations had the highest employment/unemployment rates in 2024?
- How have state unemployment rates changed year-over-year?
- Which industries are driving unemployment in a given state and quarter?

## Architecture

Three-layer Snowflake schema design:

```
LABOR_PUBLIC (raw)  →  LABOR_CUR (curated)  →  LABOR_AGG (aggregated)
```

| Schema | Purpose | Naming |
|---|---|---|
| `LABOR_PUBLIC` | Raw marketplace tables + uploaded reference data (IPEDS institution info, NCES CIP codes) | — |
| `LABOR_CUR` | Cleaned/standardized views — nulls handled, categories grouped, join keys unified | `CUR_*` |
| `LABOR_AGG` | Analysis-ready aggregates, YoY trends, top-N rankings, a materialized view | `AGG_*` |

See [`docs/project_summary.md`](docs/project_summary.md) for the full data dictionary and
cleaning logic (award-level grouping, STEM classification, state-code extraction, etc.).

## Repo structure

```
sql/
  01_setup_and_curation.sql   # raw table ingestion + curation layer views
  02_procedures.sql           # stored procedures for education/unemployment curation
  03_aggregation.sql          # state/occupation/industry aggregates + materialized view
  04_function_and_task.sql    # table function + scheduled task
docs/
  project_summary.md          # data dictionary and cleaning logic
```

## Tech stack

- **Snowflake**: schemas, views, stored procedures, UDFs, tasks, materialized views
- **SQL**: window functions, CTEs, `QUALIFY`, `NULLIF`/`CASE` data cleaning

## Key techniques demonstrated

- Data cleaning with `NULLIF` to standardize placeholder values across tables
- Categorical grouping logic (award levels → 4 categories, industries → STEM/non-STEM)
- Window functions for state-level percentages and year-over-year deltas
- Stored procedures to modularize the curation pipeline
- A parameterized table function (`FN_GET_STATE_UNEMP`) for ad-hoc state/year lookups
- A scheduled task to keep curated tables refreshed automatically

## Running it

These scripts assume a Snowflake account with the Lightcast Core LMI marketplace share
installed and a warehouse/database named `CHEETAH_WH` / `CHEETAH_DB` (rename as needed).

> **Data:** The Lightcast dataset comes from the Snowflake Marketplace.
> No source data is included in this repository.

Run the files in order in a Snowflake worksheet:

```
01_setup_and_curation.sql → 02_procedures.sql → 03_aggregation.sql → 04_function_and_task.sql
```
