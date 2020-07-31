import psycopg2
from psycopg2 import sql

from ocdskingfisherviews.config import get_connection_parameters

global connected
connected = False


def connect():
    """
    Connects to the database.
    """
    global connection
    connection = psycopg2.connect(**get_connection_parameters())

    global cursor
    cursor = connection.cursor()


def get_connection():
    """
    Returns a database connection.
    """
    if not connected:
        connect()

    return connection


def get_cursor():
    """
    Returns a database cursor.
    """
    if not connected:
        connect()

    return cursor


def set_search_path(schemas):
    cursor.execute(sql.SQL('SET search_path = {schemas}').format(schemas=sql.SQL(', ').join(
        sql.Identifier(schema) for schema in schemas)))


def schema_exists(schema):
    """
    Returns whether a schema exists.
    """
    cursor.execute('SELECT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = %(schema)s)', {'schema': schema})
    return cursor.fetchone()[0]


def pluck(statement, variables=None):
    """
    Returns the first value from all the results.
    """
    cursor.execute(statement, variables)
    return [row[0] for row in cursor.fetchall()]


def commit():
    """
    Commits the transaction.
    """
    connection.commit()
