import os
from flask import Flask, render_template, request
from . import postgres

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

goodreads = Flask(__name__, template_folder='templates')

@goodreads.route('/')
def create_database():
    """Cria o banco de dados e as tabelas necessária,

    Returns:
        str: Renderiza o template index.html
    """    
    try:
        ddl_path = os.path.join(BASE_DIR, '..', 'ddl.sql')
        with open(ddl_path, 'r') as f:
            ddl_commands = f.read()
            postgres.connect(ddl_commands)
        instancias_path = os.path.join(BASE_DIR, '..', 'instancias.sql')
        with open(instancias_path, 'r') as f:
            instances = f.read()
            postgres.connect(instances)
        visao_path = os.path.join(BASE_DIR, '..', 'consultas', 'view.sql')
        with open(visao_path, 'r') as f:
            visao = f.read()
            try:
                postgres.connect(visao)
            except Exception as e:
                exception_msg = f"Error: {e}"
                result = (exception_msg, 500)
    except Exception as e:
        print(f"Error creating database or tables: {e}")

    # Renderiza o template index.html
    return render_template('index.html')

@goodreads.post('/api/v1/POST/consultas')
def consultas():
    """Executa as consultas da etapa 2

    Returns:
        tuple[str, int]: Retorna uma tupla com uma resposta e um código de retorno HTTP.
    """
    query_id = request.args.get('query_id')

    content_type = request.headers.get('Content-Type')
    if content_type == 'application/json':
        query_params = request.json
    else:
        query_params = None
    
    try:
        print(query_params)
        consulta_path = os.path.join(BASE_DIR, '..', 'consultas', f'{query_id}.sql')
        with open(consulta_path, 'r') as f:
            consultas = f.read()
            try:
                query_result = postgres.connect(consultas, query_params)
                result = (query_result, 200)
            except Exception as e:
                exception_msg = f"Error: {e}"
                result = (exception_msg, 500)
    except Exception as e:
        exception_msg = f"Error: {e}"
        result = (exception_msg, 501)

    return result