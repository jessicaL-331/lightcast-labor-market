//////////////////////////////////////////////
// Worksheet 3: Aggregation Layer
//////////////////////////////////////////////

USE WAREHOUSE CHEETAH_WH;
USE DATABASE CHEETAH_DB;
CREATE SCHEMA IF NOT EXISTS LABOR_AGG;
USE SCHEMA LABOR_AGG;

-----------------------------------------------------------
-- Section 1 State-level Education and Unemployment
------------------------------------------------------------
-- 1. Education Completions by State & Award Category

CREATE OR REPLACE VIEW LABOR_AGG.AGG_COMPLETIONS_STATE_AWARD AS
WITH base AS (
    SELECT
        year,
        state_code,
        awards_category,
        SUM(completions_count) AS awards_completions
    FROM LABOR_CUR.CUR_COMPLETION_FINAL
    GROUP BY year, state_code, awards_category
)
SELECT
    year,
    state_code,
    awards_category,
    awards_completions,
    SUM(awards_completions) OVER (PARTITION BY year, state_code) AS state_total,
    ROUND(awards_completions/
    (SUM(awards_completions)OVER (PARTITION BY year, state_code))*100,2) 
    AS award_percent_state
FROM base
ORDER BY year, state_code, award_percent_state DESC;

SELECT * FROM LABOR_AGG.AGG_COMPLETIONS_STATE_AWARD
LIMIT 20;

SELECT 
MAX(state_edu_percent) AS max_state_percent,
MIN(state_edu_percent) AS min_state_percent
FROM LABOR_AGG.AGG_COMPLETIONS_STATE_AWARD;

-- 2. Occupation Unemployment yearly

CREATE OR REPLACE VIEW LABOR_AGG.AGG_STATE_OCC AS
SELECT
    year,
    state_code,
    ROUND(SUM(employment_count),2) AS total_employment,
    ROUND(SUM(unemployment_count),2) AS total_unemployment,
    ROUND(
        SUM(unemployment_count)/
        (SUM(unemployment_count) + SUM(employment_count)) * 100,2)
        AS unemployment_rate
FROM LABOR_CUR.CUR_UNEMP_OCC_FINAL
WHERE occupation_id <> '00-0000'
GROUP BY year, state_code
ORDER BY year, state_code;


SELECT *
FROM LABOR_AGG.AGG_STATE_OCC
WHERE YEAR=2024
ORDER BY total_employment DESC
LIMIT 10;


-- 3. Ocupation Unemployment quaterly

CREATE OR REPLACE VIEW LABOR_AGG.AGG_STATE_OCC_QTR AS
SELECT
    year,
    quarter,
    state_code,
    SUM(employment_count) AS total_employment,
    SUM(unemployment_count) AS total_unemployment,
    ROUND(
        SUM(unemployment_count) /
        NULLIF(SUM(unemployment_count) + SUM(employment_count), 0) * 100,
        2
    ) AS unemployment_rate
FROM LABOR_CUR.CUR_UNEMP_OCC_FINAL
WHERE occupation_id <> '00-0000'
GROUP BY year, quarter, state_code
ORDER BY year, quarter, state_code;

SELECT *
FROM LABOR_AGG.AGG_STATE_OCC
WHERE YEAR=2024
ORDER BY total_employment DESC
LIMIT 10;


-- 4. Industry Unemployment quarterly
CREATE OR REPLACE VIEW LABOR_AGG.AGG_STATE_INDUSTRY AS
SELECT
        year,
        quarter,
        state_code,
        industry,
        ROUND(SUM(unemployment_count),2) AS total_unemployment,
FROM LABOR_CUR.CUR_UNEMP_INDUSTRY_FINAL
WHERE state_code IS NOT NULL
    AND area_type = 'COUNTY'
    AND UPPER(industry) <> 'Total, All Industries'
GROUP BY year,quarter, state_code, industry
ORDER BY year,quarter, state_code, industry;

SELECT *
FROM LABOR_AGG.AGG_STATE_INDUSTRY 
LIMIT 10;

-- 5. Unemployement rate YoY changes
CREATE OR REPLACE VIEW LABOR_AGG.AGG_UNEMP_YOY AS
SELECT
    year,
    state_code,
    unemployment_rate,
    total_unemployment,
    total_employment,
    ROUND(unemployment_rate - LAG(unemployment_rate) 
        OVER (PARTITION BY state_code ORDER BY year),2) AS YoY_unemp_rate,
    ROUND(total_unemployment - LAG(total_unemployment)
        OVER (PARTITION BY state_code ORDER BY year),2) AS YoY_unemp_count,
    ROUND(total_employment - LAG(total_employment)
        OVER (PARTITION BY state_code ORDER BY year),2) AS YoY_emp_count
        
FROM LABOR_AGG.AGG_STATE_OCC
ORDER BY state_code, year;

SELECT *
FROM LABOR_AGG.AGG_UNEMP_YOY
LIMIT 10;

-- 6. Top 10 occupations with highest unemployment and employment in 2024

CREATE OR REPLACE VIEW LABOR_AGG.AGG_TOP_OCC_EMP AS
SELECT
    year,
    occupation,
    ROUND(SUM(employment_count) / 
    (SUM(unemployment_count) + SUM(employment_count)) * 100, 2) 
    AS employment_rate,
    ROW_NUMBER() OVER (ORDER BY SUM(employment_count)/
    (SUM(unemployment_count) + SUM(employment_count)) * 100 DESC) AS rnk
FROM LABOR_CUR.CUR_UNEMP_OCC_FINAL
WHERE year = 2024
  AND occupation_id <> '00-0000'
GROUP BY year, occupation
QUALIFY rnk <= 10
ORDER BY rnk;

SELECT *
FROM LABOR_AGG.AGG_TOP_OCC_EMP;

        -- occupations with highest unemployment in 2024

CREATE OR REPLACE VIEW LABOR_AGG.AGG_TOP_OCC_UNEMP  AS
SELECT
    year,
    occupation,
     ROUND(
        SUM(unemployment_count)/
        (SUM(unemployment_count) + SUM(employment_count)) * 100,2)
        AS unemployment_rate
FROM LABOR_CUR.CUR_UNEMP_OCC_FINAL
WHERE year = 2024
  AND occupation_id <> '00-0000'
GROUP BY year, occupation
ORDER BY unemployment_rate DESC
LIMIT 10;

SELECT *
FROM LABOR_AGG.AGG_TOP_OCC_UNEMP ;

 -- 7. State with higest unemployement rate in past 5 years
CREATE OR REPLACE VIEW LABOR_AGG.AGG_TOP_STATE_UNEMP_5YR AS
SELECT 
    state_code,
    ROUND((SUM(unemployment_count)/ (SUM(unemployment_count)+ SUM(employment_count)))*100,2) AS unemp_rate_5yr
FROM LABOR_CUR.CUR_UNEMP_OCC_FINAL
WHERE year BETWEEN 2020 AND 2024
GROUP BY state_code
ORDER BY unemp_rate_5yr DESC
LIMIT 10;

SELECT * FROM LABOR_AGG.AGG_TOP_STATE_UNEMP_5YR;


-----------------------------------------------------------
-- Section 2 Program - level Education and Unemployment
------------------------------------------------------------

-- 8. STEM VS Non-STEM and Unemployment by State Yearly

CREATE OR REPLACE TABLE LABOR_AGG.AGG_STEM_EDU_STATE AS
WITH stem_base AS (
    SELECT
        year,
        state_code,
        stem_flag,
        SUM(completions_count) as total_completions
    FROM LABOR_CUR.CUR_COMPLETION_FINAL
    WHERE stem_flag IN ('STEM', 'Non-STEM')
    GROUP BY year, state_code, stem_flag 
    )
SELECT
    b.year,
    b.state_code,
    b.stem_flag,
    b.total_completions,
    ROUND(b.total_completions*100 / SUM(b.total_completions) OVER (PARTITION BY b.year, b.state_code),2)
    AS stem_completion_percent,
    oc.unemployment_rate
FROM stem_base b
JOIN LABOR_AGG.AGG_STATE_OCC oc
    ON b.year = oc.year
    AND b.state_code = oc.state_code
ORDER BY b.year, b.state_code, b.stem_flag;

SELECT * 
FROM LABOR_AGG.AGG_STEM_EDU_STATE
LIMIT 20;

-- 9.Industry unemployment by STEM category

CREATE OR REPLACE VIEW LABOR_AGG.AGG_STEM_INDUSTRY AS
SELECT
    year,
    state_code,

    CASE
        WHEN UPPER(industry) IN (
            'INFORMATION',
            'PROFESSIONAL, SCIENTIFIC, AND TECHNICAL SERVICES',
            'MANUFACTURING',
            'MINING, QUARRYING, AND OIL AND GAS EXTRACTION',
            'UTILITIES'
        )
        THEN 'STEM Industry'
        ELSE 'Non-STEM Industry'
    END AS industry_stem_flag,

    ROUND(SUM(unemployment_count),2) AS total_unemployment

FROM LABOR_CUR.CUR_UNEMP_INDUSTRY_FINAL
WHERE area_type = 'COUNTY'
  AND UPPER(industry) <> 'TOTAL, ALL INDUSTRIES'

GROUP BY year, state_code, industry_stem_flag
ORDER BY year, state_code, industry_stem_flag;

SELECT *
FROM LABOR_AGG.AGG_STEM_INDUSTRY
LIMIT 20;

/////////////////////////////////////////////////////////////
//MATERIALIZED VIEW 
//Combines STEM completion with unemployment rate
/////////////////////////////////////////////////////////////

CREATE OR REPLACE MATERIALIZED VIEW AGG_MV_STEM_PIPELINE AS
SELECT *
FROM AGG_STEM_EDU_STATE;