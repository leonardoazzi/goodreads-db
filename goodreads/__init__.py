from flask import Flask, render_template, request
import postgres

goodreads = Flask(__name__, template_folder='templates')

@goodreads.route('/')
def create_database():
    """ Cria o banco de dados e as tabelas necessárias, e renderiza o template index.html """
    try:
        with open('../ddl.sql', 'r') as f:
            ddl_commands = f.read()
            postgres.connect(ddl_commands)
        with open('../instancias.sql', 'r') as f:
            instances = f.read()
            postgres.connect(instances)
    except Exception as e:
        print(f"Error creating database or tables: {e}")

    # Renderiza o template index.html
    return render_template('index.html')

@goodreads.post('/api/v1/POST/query')
def sql():
    """ Executa uma consulta SQL fornecida pelo usuário """
    result = (None, 501)
    content_type = request.headers.get('Content-Type')
    if content_type == 'application/json':
        json = request.json
        try:
            query_result = postgres.connect(json["query"])
            result = (query_result, 200)
        except Exception as e:
            exception_msg = f"Error: {e}"
            result = (exception_msg, 500)
    return result

@goodreads.post('/api/v1/POST/select-author')
def get_author():
    """ Obtém informações de um autor específico """
    result = (None, 501)
    content_type = request.headers.get('Content-Type')
    if content_type == 'application/json':
        json = request.json
        params = json['author_name']
        sql_query = f"SELECT * FROM authors WHERE name = (%s)"
        try:
            query_result = postgres.connect(sql_query, [params])
            result = (query_result, 200)
        except Exception as e:
            result = ({"Error": str(e)}, 500)
    return result

if __name__ == '__main__':
    goodreads.run(debug=True)  # Executa o servidor Flask em modo de depuração