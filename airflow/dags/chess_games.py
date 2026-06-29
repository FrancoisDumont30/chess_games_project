# Import
import requests
import os
import pendulum
import json
import logging

from airflow.sdk import dag, task
from airflow.sdk import Variable
from airflow.exceptions import AirflowException
from airflow.providers.standard.operators.trigger_dagrun import TriggerDagRunOperator

@dag(dag_id='chess_games',
    schedule='0 9 * * *',
    start_date=pendulum.datetime(2026, 6, 10, tz="UTC"),
    catchup=True,
    tags=["chess", "mine"],
    )


def chess_games():
    """
    Check the data folder and save every games that are not in the folder.
    """

    @task()
    def get_game_archives() -> list :
        """
        Request to chess.com API and get all the game archives.
        return a list in a yyyy_mm format like ['2025_12', '2026_01', '2026_02',...]
        """
        username = Variable.get("USERNAME")
        mail = Variable.get("MAIL")

        header = {
            'User-Agent': f'my-profile-tool/1.2 (username: {username}; contact: {mail})'
            }

        url = f'https://api.chess.com/pub/player/{username}/games/archives'

        response = requests.get(url, headers=header)

        if response.status_code == 200 :
            res = []
            data = response.json().get('archives')

            for ele in data :
                part = ele.rsplit('/', 2)
                # Récupérer yyyy_mm
                date_str = '_'.join(part[-2:])

                res.append(date_str)

            logging.info(f'found {len(data)} files in the archive API')

            return res

        else :
            raise AirflowException(
                f"API request failed with status code {response.get('status_code', 'unknown')}. "
                f"Data: {response.get('data', 'No data')}")


    @task()
    def games_filter(archive_list: list) -> list:
        """
        Read the checkpoint file et determine the files (month) to download
        """

        checkpoint_path = Variable.get("checkpoint_path")

        # Charge le checkpoint
        if os.path.exists(checkpoint_path):
            with open(checkpoint_path, "r") as f:
                check = json.load(f)
        else :
            check = {}

        # Filtre les mois à télécharger
        g_filter = []
        for game in archive_list:
            if check.get(game) != 'done' :
                g_filter.append(game)

        return g_filter


    @task()
    def get_games(ddl_list : list) :
        """
        Send a request to chess.com API
        """
        username = Variable.get("USERNAME")
        mail = Variable.get("MAIL")
        folder = Variable.get('raw_data_path')
        checkpoint_path = Variable.get("checkpoint_path")

        header = {
            'User-Agent': f'my-profile-tool/1.2 (username: {username}; contact: {mail})'
        }
        
        # charger le checkpoint ou dict vide s'il n'existe pas
        if os.path.exists(checkpoint_path) :
            with open(checkpoint_path, "r") as f:
                check = json.load(f)
        else :
            check = {} 
        
        for game in ddl_list :
            game_date = game.replace('_', '/')
            url = f'https://api.chess.com/pub/player/{username}/games/{game_date}'

            response = requests.get(url, headers=header)

            if response.status_code == 200 :
                data = response.json().get('games')

                # save the games data
                os.makedirs(folder, exist_ok=True)
                with open(f'{folder}/{game}.json', 'w') as fp:
                    json.dump(data, fp)

                # checkpoint update
                game_date = pendulum.parse(game.replace('_', '-')).date().replace(day=1)
                actual_date = pendulum.today().date().replace(day=1)
                
                if actual_date >= game_date.add(months=1):
                    check[game] = 'done'
                else:
                    check[game] = 'incomplete'

                with open(checkpoint_path, "w") as f:
                    json.dump(check, f, indent=2)

                logging.info(f'{game} successfully processed with checkpoint status : {check[game]}')

            else :
                logging.error(f'Failed to fetch {game} games with status_code = {response.status_code}')
                

    # --- Déclencher to_neon ---
    trigger_to_neon = TriggerDagRunOperator(
        task_id="trigger_to_neon", 
        trigger_dag_id="neon_ingestion", 
        wait_for_completion=False, 
        )

    
    #-------------
    # task calling
    #-------------

    # Définition des dépendances
    archive_list = get_game_archives()
    ddl_list = games_filter(archive_list)
    games = get_games(ddl_list)

    # Enchaînement des tâches
    archive_list >> ddl_list >> games >> trigger_to_neon

#-----------------
# function calling
#-----------------

chess_games()