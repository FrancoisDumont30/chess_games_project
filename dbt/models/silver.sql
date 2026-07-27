-- models/silver.sql
{{ config(materialized='table') }}

WITH cte1 AS(SELECT uuid, opening_full, result_statement, color, my_rating, opponent_rating, my_accuracy, opponent_accuracy, opponent, 
                    ARRAY( SELECT trim(elem) FROM unnest(string_to_array(opening_full, '-')) AS elem) AS parts
            FROM {{ ref('flat_raw') }})

SELECT c.uuid, c.color, c.my_rating, c.opponent_rating, c.my_accuracy, c.opponent_accuracy, c.opponent, c.opening_full, c.result_statement, 
b.real_timestamp, b.white_moves, b.black_moves, b.first_moves, b.white_times, b.black_times,
-- result
    CASE 
        WHEN result_statement IN ('resigned', 'checkmated', 'abandoned', 'timeout') THEN 'loss'
        WHEN result_statement IN ('agreed', 'stalemate', 'repetition', 'insufficient', 'timevsinsufficient') THEN 'draw'
        WHEN result_statement = 'win' THEN 'win'
        ELSE 'unknown'
    END AS result,
-- opening_group
    CASE 
        -- Si la 3e partie existe ET commence par un chiffre (0-9) : on ne prend que les 2 premières
        WHEN array_length(parts, 1) >= 3 AND parts[3] ~ '^[0-9]' THEN
            parts[1] || '-' || parts[2]
        -- Si la 3e partie existe et ne commence PAS par un chiffre : on prend les 3 premières
        WHEN array_length(parts, 1) >= 3 THEN
            parts[1] || '-' || parts[2] || '-' || parts[3]
        ELSE 
            opening_full
    END AS opening_group

FROM cte1 c
LEFT JOIN {{ ref('bronze_pgn') }} b
ON c.uuid = b.uuid