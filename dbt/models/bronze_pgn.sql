-- models/silver.sql
{{ config(materialized='table') }}

WITH bronze AS (
    SELECT 
        uuid,
        -- Extrait la valeur entre guillemets après [UTCDate "..."
        (regexp_match(pgn, '\[UTCDate "([^"]+)"\]'))[1] AS raw_utc_date,

        -- Extrait la valeur entre guillemets après [UTCTime "..."
        (regexp_match(pgn, '\[UTCTime "([^"]+)"\]'))[1] AS raw_utc_time,

        -- Nettoyage pgn
        replace(pgn, '%clk ', '') AS raw_moves

    FROM {{ ref('flat_raw') }}
),


cte1 AS (
    SELECT 
        uuid,
        replace(raw_utc_date, '.', '-')::date AS utc_date,
        raw_utc_time::time AS utc_time,
        
        -- Coups et chronos des blancs (ex: "1.")
        ARRAY(
        SELECT (m)[1] 
        FROM regexp_matches(raw_moves, '\d+\.\s+([^\s]+)\s+\{\[([^\]]+)\]\}', 'g') AS m
    ) AS white_moves,
        
        ARRAY(
                SELECT (m)[2] 
                FROM regexp_matches(raw_moves, '\d+\.\s+([^\s]+)\s+\{\[([^\]]+)\]\}', 'g') AS m
            ) AS white_chr,

        -- Coups et chronos des Noirs (ex: "1...")
        ARRAY(
                SELECT (m)[1] 
                FROM regexp_matches(raw_moves, '\d+\.\.\.\s+([^\s]+)\s+\{\[([^\]]+)\]\}', 'g') AS m
            ) AS black_moves,
        
        ARRAY(
                SELECT (m)[2] 
                FROM regexp_matches(raw_moves, '\d+\.\.\.\s+([^\s]+)\s+\{\[([^\]]+)\]\}', 'g') AS m
            ) AS black_chr
    FROM bronze
),

cte2 AS (
SELECT 
    uuid, 
    utc_date, 
    utc_time,
    (utc_date + utc_time) AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Brussels' AS real_timestamp,
    white_moves,
    black_moves,

    -- Temps par coup des Blancs
    ARRAY(
    SELECT ROUND(EXTRACT(EPOCH FROM (
      COALESCE(LAG(t::interval) OVER (ORDER BY idx), '00:10:00'::interval) - t::interval
    ))::numeric, 1)
    FROM unnest(white_chr) WITH ORDINALITY AS u(t, idx)
  ) AS white_times,

  -- Temps par coup des Noirs (en secondes)
  ARRAY(
    SELECT ROUND(EXTRACT(EPOCH FROM (
      COALESCE(LAG(t::interval) OVER (ORDER BY idx), '00:10:00'::interval) - t::interval
    ))::numeric, 1)
    FROM unnest(black_chr) WITH ORDINALITY AS u(t, idx)
  ) AS black_times

FROM cte1)


SELECT 
    uuid,
    real_timestamp,
    white_moves,
    black_moves,
    -- 6 premiers coups
    ARRAY(
        SELECT move 
        FROM (
        SELECT white_moves[i] AS move, (i * 2 - 1) AS step FROM generate_subscripts(white_moves, 1) i WHERE i <= 3
        UNION ALL
        SELECT black_moves[i] AS move, (i * 2)     AS step FROM generate_subscripts(black_moves, 1) i WHERE i <= 3
        ) sub
        WHERE move IS NOT NULL
        ORDER BY step) AS first_moves, 
    white_times,
    black_times

FROM cte2