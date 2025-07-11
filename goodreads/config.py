from configparser import ConfigParser
import os

BASE_DIR = os.path.dirname(os.path.abspath('database.ini'))

def config(filename=BASE_DIR+'/goodreads/database.ini', section='postgresql'):
    parser = ConfigParser()
    parser.read(filename)
    print(filename)

    db = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            db[param[0]] = param[1]
    else:
        raise Exception('Section {0} not found in the {1} file'.format(section, filename))
    
    return db