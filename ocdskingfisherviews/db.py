import psycopg2

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


def pluck(statement, variables=None):
    """
    Returns the first value from all the results.
    """
    cursor.execute(statement, variables)
    return [row[0] for row in cursor.fetchall()]


def pluckone(statement, variables=None):
    """
    Returns the first value from the first result.
    """
    cursor.execute(statement, variables)
    return cursor.fetchone()[0]


def fetchall(statement, variables=None):
    """
    Returns all the values from all the results.
    """
    cursor.execute(statement, variables)
    return cursor.fetchall()


def schema_exists(schema):
    """
    Returns whether a schema exists.
    """
    return pluckone('SELECT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = %(schema)s)', {'schema': schema})


def commit():
    """
    Commits the transaction.
    """
    connection.commit()
