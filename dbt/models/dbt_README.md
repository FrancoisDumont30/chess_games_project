# dbt

## .env
Enable the experimental PostgreSQL adapter for Neon DB:
```env
DBT_ALLOW_EXPERIMENTAL_ADAPTERS=true
```

## models
Raw data is stored in Neon DB as a JSON file containing all games per month.

### Bronze :

bronze_flat_raw : Flattens the JSON structure to extract raw data.

bronze_pgn : Parses the complex string where all data is stored as a space-separated list.

### Silver :
Joins the Bronze tables on the unique identifier (uuid).

### Golds :
**gold_accuracy** : Analyzes the correlation between ELO rating, move precision, and time taken.  
**gold_elo** : Evaluates game results (win, draw, loss) based on the opponent's ELO.  
**gold_opening_group** : Assesses results based on the openings played.  
**gold_result** : Summarizes overall performance by color played (white/black).  
**gold_timed_result** : Tracks the evolution of results over time.  
