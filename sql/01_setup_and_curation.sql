//////////////////////////////////////////////
// Lightcast Labor Market Analysis Project
//////////////////////////////////////////////

/////////////////////////////////////////
// Worksheet 0: Initian Setup
/////////////////////////////////////////

USE WAREHOUSE CHEETAH_WH;
USE DATABASE CHEETAH_DB;
CREATE SCHEMA IF NOT EXISTS LABOR_PUBLIC; 
USE SCHEMA LABOR_PUBLIC;
CREATE OR REPLACE TAG CHEETAH_DB.PUBLIC.project_cheetah;

-- Education completions demographics (2010–2025)
CREATE OR REPLACE TABLE COMPLETIONS_DEMOGRAPHICS AS
SELECT *
FROM LIGHTCAST__CORE_LABOR_MARKET_INFORMATION_US.CORELMI_US_SAMPLE.DAT_COMPLETIONS_DEMOGRAPHICS
WHERE YEAR BETWEEN 2010 AND 2025;

-- Unemployment by Occupation
CREATE OR REPLACE TABLE UNEMP_OCCUPATION AS
SELECT *
FROM LIGHTCAST__CORE_LABOR_MARKET_INFORMATION_US.CORELMI_US_SAMPLE.DAT_UNEMP_OCC;

-- Unemployment by Industry
CREATE OR REPLACE TABLE UNEMP_INDUSTRY AS
SELECT *
FROM LIGHTCAST__CORE_LABOR_MARKET_INFORMATION_US.CORELMI_US_SAMPLE.DAT_UNEMP_IND;


-- Uploaded Institution Information data to map univeristy with state. Dataset is from https://nces.ed.gov/ipeds/datacenter.
CREATE OR REPLACE TABLE CHEETAH_DB.LABOR_PUBLIC.INSTITUITION_INFO (
	UNITID NUMBER(38,0),
	INSTNM VARCHAR(16777216),
	CITY VARCHAR(16777216),
	STABBR VARCHAR(16777216),
	ZIP VARCHAR(16777216),
	FIPS NUMBER(38,0),
	OBEREG NUMBER(38,0),
	SECTOR NUMBER(38,0),
	ICLEVEL NUMBER(38,0),
	CONTROL NUMBER(38,0),
	LOCALE NUMBER(38,0),
	INSTSIZE NUMBER(38,0),
	LONGITUD NUMBER(38,6),
	LATITUDE NUMBER(38,6)
);

-- Upload CIP code to categorize the education program from https://nces.ed.gov/ipeds/cipcode
create or replace TABLE CHEETAH_DB.LABOR_PUBLIC.CIP_CODE (
	TITLE VARCHAR(16777216),
	DEFINITION VARCHAR(16777216),
	CIP_CODE NUMBER(38,0),
	ACTION VARCHAR(16777216)
);

/////////////////////////////////////////
// Worksheet 1: Curation
/////////////////////////////////////////

-- Builds curated views in LABOR_CUR for education + labor market.

CREATE SCHEMA IF NOT EXISTS LABOR_CUR; 
USE SCHEMA LABOR_CUR;

----------------------------------------
-- Education Completion layer
----------------------------------------

-- 1. Data Cleannning for Completion Demographic Table, replace "Total" and Zero ID value with Null

CREATE SCHEMA IF NOT EXISTS LABOR_CUR; 
USE SCHEMA LABOR_CUR;

CREATE OR REPLACE VIEW LABOR_CUR.CUR_COMPLETIONS_DEMOGRAPHIC AS
SELECT
    YEAR,
    NULLIF(UNITID, 0) AS UNITID,
    NULLIF(UPPER(TRIM(UNITID_NAME)), 'TOTAL') AS UNITID_NAME,
    NULLIF(PROGRAMID, 99) AS PROGRAMID,
    NULLIF(PROGRAMID_NAME, 'TOTAL') AS PROGRAMID_NAME,
    NULLIF(AWLEVELID, 0) AS AWLEVELID,
    NULLIF(UPPER(TRIM(AWLEVELID_NAME)), 'TOTAL') AS AWLEVELID_NAME,
    NULLIF(RACEID, 0) AS RACEID,
    NULLIF(UPPER(TRIM(RACEID_NAME)), 'TOTAL') AS RACEID_NAME,
    NULLIF(GENDERID, 0) AS GENDERID,
    NULLIF(UPPER(TRIM(GENDERID_NAME)), 'TOTAL, MALES AND FEMALES') AS GENDERID_NAME,
    ROUND(COMPLETIONS) AS COMPLETIONS
FROM LABOR_PUBLIC.COMPLETIONS_DEMOGRAPHICS;

SELECT *
FROM LABOR_CUR.CUR_COMPLETIONS_DEMOGRAPHIC
LIMIT 50;

ALTER VIEW LABOR_CUR.CUR_COMPLETIONS_DEMOGRAPHIC 
    SET TAG CHEETAH_DB.PUBLIC.project_cheetah = 'Curation';
    
-- Count Null value for each column and decide if needs to be drop

SELECT 
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(UNITID) AS unitid_nulls,
    ROUND(unitid_nulls * 100.0 / COUNT(*), 2 ) AS unitid_null_percent,
    
    COUNT(*) - COUNT(PROGRAMID) AS programid_nulls,
    ROUND(programid_nulls * 100.0 / COUNT(*), 2 ) AS programid_nulls_percent,
    
    COUNT(*) - COUNT(AWLEVELID) AS awlevelid_nulls,
    ROUND(awlevelid_nulls * 100.0 / COUNT(*), 2 ) AS awlevelid_nulls_percent,
    
    COUNT(*) - COUNT(RACEID) AS raceid_nulls,
    ROUND(raceid_nulls * 100.0 / COUNT(*), 2 ) AS raceid_nulls_percent,
    
    COUNT(*) - COUNT(GENDERID) AS genderid_nulls,
    ROUND(genderid_nulls * 100.0 / COUNT(*), 2 ) AS genderid_nulls_percent
    
FROM LABOR_CUR.CUR_COMPLETIONS_DEMOGRAPHIC;

-- 2. Dropping row with null value in key column (UNITID, UNITID_NAME, PROGRAMID, PROGRAMID_NAME). These columns have low null percentage, so removing it does not significanlly reduce the data size.

CREATE OR REPLACE VIEW LABOR_CUR.CUR_COMPLETIONS_DEMO_DROP AS
SELECT *
FROM LABOR_CUR.CUR_COMPLETIONS_DEMOGRAPHIC
WHERE UNITID IS NOT NULL
  AND PROGRAMID IS NOT NULL;

ALTER VIEW LABOR_CUR.CUR_COMPLETIONS_DEMO_DROP 
    SET TAG CHEETAH_DB.PUBLIC.project_cheetah = 'Curation';
    
-- 3. Grouping all award level into certificate, undergrad, postgrad and post certificate

SELECT DISTINCT AWLEVELID_NAME
FROM CUR_COMPLETIONS_DEMO_DROP
ORDER BY AWLEVELID_NAME;

CREATE OR REPLACE VIEW LABOR_CUR.CUR_COMPLETION_GROUP AS
SELECT *,
CASE
    WHEN AWLEVELID_NAME ILIKE '%less than 1%'
    OR AWLEVELID_NAME ILIKE '%less than 2%'
    OR AWLEVELID_NAME ILIKE 'Certificates'
        THEN 'Certificate'
    
    WHEN AWLEVELID_NAME ILIKE '%at least 2%'
    OR AWLEVELID_NAME ILIKE 'Associates Degree'
    OR AWLEVELID_NAME ILIKE 'Bachelors Degree'
    OR AWLEVELID_NAME ILIKE 'Degrees'
        THEN 'Undergraduate'

    WHEN AWLEVELID_NAME ILIKE 'Doctors Degree'
    OR AWLEVELID_NAME ILIKE 'Masters Degree'
        THEN 'Postgraduate'

    WHEN AWLEVELID_NAME ILIKE 'Post-masters certificate'
    OR AWLEVELID_NAME ILIKE 'Postbaccalaureate certificate'
        THEN 'Post Certificate'
    ELSE NULL
END AS Awards_Category
FROM CUR_COMPLETIONS_DEMO_DROP;

SELECT DISTINCT AWLEVELID_NAME, Awards_Category
FROM LABOR_CUR.CUR_COMPLETION_GROUP
ORDER BY Awards_Category, AWLEVELID_NAME;

ALTER VIEW LABOR_CUR.CUR_COMPLETION_GROUP 
    SET TAG CHEETAH_DB.PUBLIC.project_cheetah = 'Curation';


-- 4. Data cleaning for Institution Info table 

-- Control is a classifactor of whether an institution is Public, Non-Profit Private, Profit private.
-- Locale show the degree of urbanization

CREATE OR REPLACE VIEW LABOR_CUR.CUR_INSTITUTION_INFO AS
SELECT
    UNITID,
    INSTNM,
    FIPS,
    CITY,
    STABBR,
    ZIP,
    LOCALE,
    INSTSIZE,
    CONTROL,

    CASE
        WHEN CONTROL = 1 THEN 'Public'
        WHEN CONTROL = 2 THEN 'Private Non-Profit'
        WHEN CONTROL = 3 THEN 'Private For Profit'
        ELSE 'Other'
    END AS INSTITUTION_TYPE,

    CASE
        WHEN LOCALE IN (1,2,3) THEN 'City'
        WHEN LOCALE IN (4,5,6) THEN 'Suburb'
        WHEN LOCALE IN (7,8,9) THEN 'Town'
        WHEN LOCALE IN (10,11,12) THEN 'Rural'
        ELSE 'Other'
    END AS URBAN_TYPE
FROM LABOR_PUBLIC.INSTITUITION_INFO;

SELECT *
FROM LABOR_CUR.CUR_INSTITUTION_INFO
LIMIT 20;

ALTER VIEW LABOR_CUR.CUR_INSTITUTION_INFO 
    SET TAG CHEETAH_DB.PUBLIC.project_cheetah = 'Curation';

-- 5. Join both Completion_Demographic and Institution Info table on UNITID.

CREATE OR REPLACE VIEW LABOR_CUR.CUR_COMPLETION_STATE AS
SELECT
    C.YEAR AS year,
    C.UNITID AS institution_id,
    C.UNITID_NAME AS institution_name,
    C.PROGRAMID AS program_id,
    C.PROGrAMID_NAME AS program_name,
    C.AWLEVELID AS award_id,
    C.Awards_Category AS awards_category,
    C.RACEID_NAME AS race,
    C.GENDERID_NAME AS gender,
    C.COMPLETIONS AS completions_count,
    
    I.CITY as city,
    I.STABBR AS state_code,
    I.ZIP AS zip_code,
    I.URBAN_TYPE AS urban_type,
    I.INSTSIZE AS institution_size,
    I.INSTITUTION_TYPE AS institution_type
    
FROM LABOR_CUR.CUR_COMPLETION_GROUP C
JOIN LABOR_CUR.CUR_INSTITUTION_INFO I
ON C.UNITID = I.UNITID;

SELECT *
FROM LABOR_CUR.CUR_COMPLETION_STATE
LIMIT 20;

ALTER VIEW LABOR_CUR.CUR_COMPLETION_STATE 
    SET TAG CHEETAH_DB.PUBLIC.project_cheetah = 'Curation';


----------------------------------------
-- Labor Market Layer
----------------------------------------

-- 6. Data Cleaning for Unemployment Occupation table

CREATE OR REPLACE VIEW LABOR_CUR.CUR_UNEMP_OCCUPATION AS
SELECT
    YEAR,
    MONTH,
    OCCID AS occupation_id,
    OCCID_NAME AS occupation,
    AREAID AS area_id,
    RIGHT(TRIM(areaid_name), 2) AS state_code,
    EMP AS employment_count,
    UNEMP AS unemployment_count,
    TWELVEMONTHEMPAVERAGE AS twelvemonths_employ_avg,
    TWELVEMONTHUNEMPAVERAGE AS twelvemonths_unemploy_avg
FROM LABOR_PUBLIC.UNEMP_OCCUPATION
WHERE AREAID_TYPE = 'COUNTY';
    
SELECT *
FROM CUR_UNEMP_OCCUPATION
LIMIT 20;

ALTER VIEW LABOR_CUR.CUR_UNEMP_OCCUPATION 
    SET TAG CHEETAH_DB.PUBLIC.project_cheetah = 'Curation';


-- 7. Data Cleaning for Unemployment Industry table

CREATE OR REPLACE VIEW LABOR_CUR.CUR_UNEMP_INDUSTRY AS
SELECT
    YEAR,
    MONTH,
    INDID AS industry_id,
    INDID_NAME AS industry,
    AREAID AS area_id,
    AREAID_TYPE AS area_type,
    TRIM(SPLIT_PART(areaid_name, ',',1)) AS county,
    TRIM(SPLIT_PART(areaid_name, ',',2)) AS state_code,
    UNEMP AS unemployment_count,
    TWELVEMONTHAVERAGE AS twelve_month_avg
        
FROM LABOR_PUBLIC.UNEMP_INDUSTRY
WHERE AREAID_TYPE = 'COUNTY';

SELECT *
FROM CUR_UNEMP_INDUSTRY
WHERE YEAR = 2024
LIMIT 20;

ALTER VIEW LABOR_CUR.CUR_UNEMP_INDUSTRY 
    SET TAG CHEETAH_DB.PUBLIC.project_cheetah = 'Curation';