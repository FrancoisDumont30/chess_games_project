-- models/flat_raw.sql
{{ config(materialized='table') }}

WITH raw_data AS (
    SELECT 
        -- aplatir le json
        json_data::jsonb AS games
    FROM {{ source('neon_raw', 'chess_raw_data') }})

SELECT
    game_element ->> 'uuid' AS uuid,

-- My color
    CASE 
        WHEN (game_element -> 'white') ->> 'username' = 'Moby1981' THEN 'white'
        ELSE 'black'
    END AS color,

-- my rating
    (CASE 
        WHEN (game_element -> 'white') ->> 'username' = 'Moby1981' THEN (game_element -> 'white') ->> 'rating'
        ELSE (game_element -> 'black') ->> 'rating'
    END)::smallint AS my_rating,

-- opponent_rating
    (CASE 
        WHEN (game_element -> 'white') ->> 'username' != 'Moby1981' THEN (game_element -> 'white') ->> 'rating'
        ELSE (game_element -> 'black') ->> 'rating'
    END)::smallint AS opponent_rating,

-- my_accuracy
    (CASE
        WHEN (game_element -> 'white') ->> 'username' = 'Moby1981' THEN (game_element -> 'accuracies') ->> 'white'
        ELSE (game_element -> 'accuracies') ->> 'black'
    END)::numeric AS my_accuracy,

-- opponent_accuracy
    (CASE
        WHEN (game_element -> 'white') ->> 'username' != 'Moby1981' THEN (game_element -> 'accuracies') ->> 'white'
        ELSE (game_element -> 'accuracies') ->> 'black'
    END)::numeric AS opponent_accuracy,

-- opponent
    CASE
        WHEN (game_element -> 'white') ->> 'username' != 'Moby1981' THEN (game_element -> 'white') ->> 'username'
        ELSE (game_element -> 'black') ->> 'username'
    END AS opponent,

-- result_statement
    CASE
        WHEN (game_element -> 'white') ->> 'username' = 'Moby1981' THEN (game_element -> 'white') ->> 'result'
        ELSE (game_element -> 'black') ->> 'result'
    END AS result_statement,

    game_element ->> 'pgn' AS pgn,

-- eco
    replace((game_element) ->> 'eco', 'https://www.chess.com/openings/', '' ) AS opening_full

FROM raw_data,

LATERAL jsonb_array_elements(games) AS game_element

WHERE game_element ->> 'rated' = 'true' 
AND game_element ->> 'time_class' = 'rapid'
AND game_element ->> 'time_control' = '600'
AND game_element ->> 'rules' = 'chess'