-- models/gold_timed_result.sql
{{ config(materialized='table') }}


WITH cte AS (SELECT 
            result,
            TO_CHAR(real_timestamp, 'YYYY_MM') AS year_month
            FROM {{ ref('silver') }})
SELECT COUNT(*), result, year_month
FROM cte 
GROUP BY year_month, result
ORDER BY year_month ASC, result DESC
