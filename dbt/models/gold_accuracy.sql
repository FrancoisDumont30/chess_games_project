-- models/gold_accuracy.sql
{{ config(materialized='table') }}


WITH cte AS (
    SELECT 
        my_rating,
        my_accuracy,
        TO_CHAR(real_timestamp, 'YYYY_MM') AS year_month
    FROM {{ ref('silver') }}
    WHERE my_accuracy IS NOT NULL)
  
SELECT 
    ROUND(AVG(my_rating), 2) AS classement_moyen,
    ROUND(AVG(my_accuracy)::numeric, 2) AS precision_moyenne,
    year_month
FROM cte 
GROUP BY year_month
ORDER BY year_month ASC