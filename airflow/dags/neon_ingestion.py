from airflow.sdk import dag, task
from airflow.sdk import Variable
from airflow.providers.standard.sensors.external_task import ExternalTaskSensor
import psycopg2
import json
import pendulum
import os

# ---------- Functions ----------
def neon_connection():
    conn = psycopg2.connect(
        host=Variable.get('neon_host'),
        database="neondb",
        user="neondb_owner",
        password=Variable.get('neon_password')
    )
    return conn

# ---------- DAG ----------
@dag(
    dag_id="neon_ingestion",
    start_date=pendulum.datetime(2026, 6, 10, tz="UTC"),
    catchup=False,
    tags=["chess", "mine"],
)
def to_neon_dag():

    @task()
    def get_checkpoint() -> dict :
        """
        Open the checkpoint file
        """
        checkpoint_path = Variable.get("checkpoint_path")

        # Charge le checkpoint
        if os.path.exists(checkpoint_path):
            with open(checkpoint_path, "r") as f:
                check = json.load(f)
        else :
            check = {}

        return check


    @task()
    def get_complete_files() -> list :
        """
        Request Neon db file_name that don't need to be overwritten.
        """
        with neon_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT file_name FROM chess_raw_data WHERE complete = True")
            resp = cursor.fetchall()
            ans = []

            for ele in resp :
                ans.append(ele[0])

        return ans


    @task()
    def neon_insert(check: dict, complete_list : list) -> list:
        folder = Variable.get('raw_data_path')

        with neon_connection() as conn:
            for key, values in check.items():
                if key not in complete_list :
                    # définir la valeur de la colonne Complete
                    complete_bool = True if values == 'done' else False

                    # récupérer le contenu du json.
                    file_name = f'/{key}.json'
                    file_path = folder + file_name
                    with open(file_path, "r") as f:
                        data = json.load(f)

                    # insérer les valeurs
                    cursor = conn.cursor()
                    cursor.execute(f"""
                                   INSERT INTO chess_raw_data 
                                   (file_name, json_data, complete)
                                   VALUES (%s, %s, %s)
                                   ON CONFLICT (file_name)
                                   DO UPDATE SET
                                        json_data = EXCLUDED.json_data,
                                        complete = EXCLUDED.complete
                                    """,
                                (key, json.dumps(data), complete_bool)
                                )

            conn.commit()


    # Définition des tâches et dépendances
    check = get_checkpoint()
    complete_list = get_complete_files()
    neon_insert_task = neon_insert(check, complete_list)

    # Ordre d'exécution
    check >> complete_list >> neon_insert_task

to_neon_dag()