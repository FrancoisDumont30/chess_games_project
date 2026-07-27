-- models/gold_elo.sql
{{ config(materialized='table') }}

SELECT 
  -- Format texte plus lisible (ex: "1400-1449")
  CONCAT((opponent_rating / 50) * 50, '-', (opponent_rating / 50) * 50 + 49) AS rating_range,
  result, 
  COUNT(*) AS total_games
FROM {{ ref('silver') }}
GROUP BY rating_range, result
ORDER BY rating_range ASC