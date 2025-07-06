import psycopg2
from config import config

# # Connect to the School database
# conn = psycopg2.connect(
#     dbname="prova_antiga",
#     user="postgres",
#     host="localhost",
#     port="5432",
#     password="postgres"
# )

def connect(commands=None):
    """ Conecta com o banco de dados PostgreSQL """
    conn = None
    record = None
    try:
        # Lê os parâmetros de configuração em database.ini
        params = config()

        print('Conectando ao PostgreSQL...')
        conn = psycopg2.connect(**params)

        cur = conn.cursor()

        print('Versão do PortgreSQL:')
        cur.execute("SELECT version();")
        db_version = cur.fetchone()
        print(db_version)

        cur.execute(commands)
        print(f'Executando comando: {commands}')
        record = cur.fetchone()
        print(f'Resultado: {record}')
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.commit()
            print('Transação concluída com sucesso.')
            conn.close()
            print('Conexão com o PostgreSQL fechada.')

    return record

if __name__ == '__main__':
    connect()