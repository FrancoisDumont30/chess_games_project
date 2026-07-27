-- models/gold_opening_group.sql
{{ config(materialized='table') }}

SELECT 
  opening_group,
  result, 
  COUNT(*) AS total_games
FROM {{ ref('silver') }}
GROUP BY opening_group, result
ORDER BY total_games DESC