from flask import Flask, render_template, request
import postgres

goodreads = Flask(__name__, template_folder='templates')

@goodreads.route('/') # Decorador que define qual rota de URL chama a função abaixo
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

@goodreads.post('/sql/POST/query')
def sql():
    """ Executa uma consulta SQL fornecida pelo usuário """
    result = None
    sql_query = request.form.get('sql')
    if sql_query:
        try:
            result = postgres.connect(sql_query)
        except Exception as e:
            result = f"Error: {e}"
    return render_template('index.html', result=result) # TODO: mudar pra jsonfy quando fizer o front.

@goodreads.post('/sql/POST/select-author')
def get_author():
    """ Obtém informações de um autor específico """
    result = None
    author_name = request.form.get('select-author')
    sql_query = f"SELECT * FROM authors WHERE name = '{author_name}'"
    if sql_query:
        try:
            result = postgres.connect(sql_query)
        except Exception as e:
            result = f"Error: {e}"
    return render_template('index.html', result=result) # TODO: mudar pra jsonfy quando fizer o front.

if __name__ == '__main__':
    goodreads.run(debug=True)  # Executa o servidor Flask em modo de depuração