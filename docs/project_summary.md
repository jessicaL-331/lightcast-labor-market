# Project Summary

## Dataset

**Lightcast U.S. Labor Market Information (Education & Unemployment)**

This project uses the Lightcast U.S. Labor Market Information datasets to analyze the
relationship between education completions and labor market outcomes across U.S. states.
The dataset combines several government data sources (BLS, Census, IPEDS, etc.) to provide
a unified view of the U.S. labor market.

The full Core LMI product includes 31 views with billions of rows. For this project, three
views were selected: education completions, industry unemployment, and occupation
unemployment across U.S. regions.

Three primary marketplace tables plus two external reference tables are used:

| Table | Description |
|---|---|
| `COMPLETIONS_DEMOGRAPHICS` | Education completions by institution, program, award level, race, gender, and year. |
| `UNEMP_OCCUPATION` | Unemployment and employment by occupation and geography (county, state). |
| `UNEMP_INDUSTRY` | Unemployment by industry and geography (county, state). |
| `INSTITUITION_INFO` (external upload – IPEDS) | Maps `UNITID` to state, city, locale, and institution type. |
| `CIP_CODE` (external upload – NCES) | Categorizes programs and supports STEM vs. Non-STEM classification. |

## Schemas and Naming Conventions

- **`LABOR_PUBLIC`** — Raw marketplace tables and uploaded reference files.
- **`LABOR_CUR`** — Curated and cleaned views/tables; all objects start with `CUR_`.
- **`LABOR_AGG`** — Aggregated analytic views and tables; all objects start with `AGG_`.

## Custom Fields and Logic (Mini Data Catalog)

### Curation Layer (`LABOR_CUR`)

1. **Award Category Grouping** — IPEDS award levels are grouped into four categories:
   - *Certificate*: "less than 1 year", "less than 2 years", "Certificates"
   - *Undergraduate*: "at least 2 years", "Associate's Degree", "Bachelor's Degree", "Degrees"
   - *Postgraduate*: "Master's Degree", "Doctor's Degree"
   - *Post Certificate*: "Post-masters certificate", "Postbaccalaureate certificate"

2. **Institution Classification Fields** — Derived from IPEDS values to categorize
   institutions as Public/Private and Urban/Suburban/Town/Rural.
   - `CONTROL` classifies an institution as Public, Non-Profit Private, or For-Profit Private.
   - `LOCALE` indicates the degree of urbanization.

3. **State Code Extraction** — For both unemployment tables, state codes are derived from
   the county-level `AREAID_NAME`.

4. **Quarterly Bucketing** — Month is converted into Q1–Q4 for both occupation and industry
   unemployment tables.

5. **STEM Flag** — Based on the first two digits of the CIP program code:
   STEM = (11, 14, 15, 26, 27, 40, 41).

6. **Placeholder Cleaning** — Placeholder values (e.g., `0`, `99`, "TOTAL" labels) are
   converted to `NULL` using `NULLIF` to remove invalid data from the completions dataset.

### Field Reference

| Field Name | Description |
|---|---|
| `awards_category` | Certificate, Undergraduate, Postgraduate, Post Certificate |
| `state_code` | 2-letter state code derived from `AREAID_NAME` |
| `institution_type` | 1 = Public, 2 = Private Non-Profit, 3 = Private For-Profit |
| `urban_type` | City, Suburb, Town, Rural |
| `institution_id` | Renamed from `UNITID` |
| `institution_name` | Renamed from `UNITID_NAME` |
| `program_id` | Renamed from `PROGRAMID` |
| `program_name` | Renamed from `PROGRAMID_NAME` |
| `award_id` | Renamed from `AWLEVELID` |
| `occupation_id` | Renamed from `OCCID` |
| `occupation` | Renamed from `OCCID_NAME` |
| `industry_id` | Renamed from `INDID` |
| `industry` | Renamed from `INDID_NAME` |
| `county` | Text before the comma in `AREAID_NAME` |
