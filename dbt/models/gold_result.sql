-- models/gold_result.sql
{{ config(materialized='table') }}


SELECT 
    ROW_NUMBER() OVER() AS id,
    COUNT(*),
    result,
    color
FROM {{ ref('silver') }}
GROUP BY color, result