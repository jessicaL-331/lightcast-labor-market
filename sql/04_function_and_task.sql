//////////////////////////////////////////////
// Worksheet 4: Create a Function
//////////////////////////////////////////////

USE WAREHOUSE CHEETAH_WH;
USE DATABASE CHEETAH_DB;
CREATE SCHEMA IF NOT EXISTS LABOR_AGG; 
USE SCHEMA LABOR_AGG;

CREATE OR REPLACE FUNCTION LABOR_AGG.FN_GET_STATE_UNEMP(
state VARCHAR(2),
select_year INT
)
RETURNS TABLE (
    year INT,
    quarter VARCHAR(2),
    state_code VARCHAR(2),
    total_employment FLOAT,
    total_unemployment FLOAT,
    unemployment_rate FLOAT
)
AS
$$
    SELECT
        year,
        quarter,
        state_code,
        total_employment,
        total_unemployment,
        unemployment_rate
    FROM LABOR_AGG.AGG_STATE_OCC_QTR
    WHERE state_code = state
        AND year = select_year
$$;

SELECT *
FROM TABLE(LABOR_AGG.FN_GET_STATE_UNEMP('GA',2024));


//////////////////////////////////////////////
// Worksheet 6: Task
//////////////////////////////////////////////

USE WAREHOUSE CHEETAH_WH;
USE DATABASE CHEETAH_DB;
USE SCHEMA LABOR_CUR;

CREATE OR REPLACE TASK LABOR_CUR.TASK_CUR_EDU_SCHEDULED
    WAREHOUSE = CHEETAH_WH
    SCHEDULE = 'USING CRON 0 4 * * SUN America/Chicago'
    COMMENT = 'Runs weekly education completion table curation procedure Every Sunday at 4 AM'
AS
    CALL LABOR_CUR.PROC_CUR_EDUCATION();

ALTER TASK LABOR_CUR.TASK_CUR_EDU_SCHEDULED RESUME;

EXECUTE TASK LABOR_CUR.TASK_CUR_EDU_SCHEDULED;

ALTER TASK LABOR_CUR.TASK_CUR_EDU_SCHEDULED SUSPEND;
