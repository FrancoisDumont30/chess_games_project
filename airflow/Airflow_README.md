# Airflow

## Important Note 
The variables.json file should be used to import variables into the Airflow UI.      
Avoid hardcoding them.    

## Process
The chess.com API provides a list of game archives, organized as monthly archives.  
Each archive follows the URL format:  
https://api.chess.com/pub/player/{username}/games/yyyy/mm  
Additionally, a checkpoint.json file tracks the download status of each archive.  

exemple : 
{  
    '2026_05':'done',     
    '2026_06':'incomplete'  
    }  

- done: The month has ended, the file is fully downloaded, and no further updates are needed.  
- incomplete: The month is ongoing; the file must be downloaded repeatedly until it reaches the done state.  
 
The process iterates over the archives list and downloads every archive that :  
- Is not listed in checkpoint.json, or  
- Is listed in checkpoint.json with an incomplete status.  


## DAGS

### 1- chess_games tasks

archive_list = get_game_archives() :
- Requests the chess.com API for the list of archives.
- Returns a list in yyyy_mm format (e.g., ['2025_12', '2026_01', '2026_02', ...]).

ddl_list = games_filter(archive_list):  
- Filters the archive_list  

games = get_games(ddl_list) :  
- Requests the chess.com API for the monthly archive data.
- Update the checkpoint.json file.  

trigger_to_neon :   
- Triggers the next dag  


### 2- neon_ingestion tasks

check = get_checkpoint()
- Loads the checkpoint.json file if it exists.

complete_list = get_complete_files()
- Queries the Neon database to retrieve all files marked as complete

neon_insert_task = neon_insert(check, complete_list)
- Performs an UPSERT operation for every file not in the complete_list.