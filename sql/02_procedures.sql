//////////////////////////////////////////////
// Worksheet 2: Procedures
//////////////////////////////////////////////

USE WAREHOUSE CHEETAH_WH;
USE DATABASE CHEETAH_DB;
USE SCHEMA LABOR_CUR;

---------------------------------------------------
-- PROC_CUR_EDUCATION:
-- Adds program grouping (CIP title) and STEM flag
---------------------------------------------------


CREATE OR REPLACE PROCEDURE LABOR_CUR.PROC_CUR_EDUCATION()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    CREATE OR REPLACE TABLE LABOR_CUR.CUR_COMPLETION_FINAL AS
    SELECT
        c.*,
        CIP.TITLE AS Program_Group,
        CASE 
            WHEN LEFT(c.program_id::STRING, 2) IN 
                ('11','14','15','26','27','40','41')
                THEN 'STEM'
            ELSE 'Non-STEM'
        END AS STEM_FLAG
    FROM LABOR_CUR.CUR_COMPLETION_STATE c
    JOIN LABOR_PUBLIC.CIP_CODE cip
        ON LEFT (c.program_id::STRING, 2)::INT = cip.CIP_CODE;
        
    RETURN 'Program Grouping and STEM Flag complete';
END;
$$;


-----------------------------------------------------------------
-- PROC_CUR_UNEMPLOYMENT:
-- Adds QUARTER field, filters out totals counts and null states
-----------------------------------------------------------------

CREATE OR REPLACE PROCEDURE LABOR_CUR.PROC_CUR_UNEMPLOYMENT()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    CREATE OR REPLACE TABLE LABOR_CUR.CUR_UNEMP_OCC_FINAL AS
    SELECT
        *,
        CASE 
            WHEN MONTH BETWEEN 1 AND 3 THEN 'Q1'
            WHEN MONTH BETWEEN 4 AND 6 THEN 'Q2'
            WHEN MONTH BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4'
        END AS QUARTER
    FROM LABOR_CUR.CUR_UNEMP_OCCUPATION
    WHERE occupation_id <> '00-0000' 
        AND state_code IS NOT NULL;

    
    CREATE OR REPLACE TABLE LABOR_CUR.CUR_UNEMP_INDUSTRY_FINAL AS
    SELECT
        *,
        CASE 
            WHEN MONTH BETWEEN 1 AND 3 THEN 'Q1'
            WHEN MONTH BETWEEN 4 AND 6 THEN 'Q2'
            WHEN MONTH BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4'
        END AS QUARTER
    FROM LABOR_CUR.CUR_UNEMP_INDUSTRY
    WHERE industry_id <> '00-0000' 
        AND state_code IS NOT NULL;
    
    RETURN 'Unemployment Curation Complete';

 END;
 $$;

-- Call Procedure
CALL LABOR_CUR.PROC_CUR_EDUCATION();
CALL LABOR_CUR.PROC_CUR_UNEMPLOYMENT();

SELECT *
FROM LABOR_CUR.CUR_COMPLETION_FINAL
WHERE PROGRAM_ID = 11
LIMIT 20;

SELECT *
FROM LABOR_CUR.CUR_UNEMP_OCC_FINAL
LIMIT 20;