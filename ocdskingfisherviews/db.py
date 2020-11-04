import psycopg2
from psycopg2 import sql
from psycopg2.extras import execute_values

from ocdskingfisherviews.config import get_connection_parameters


class Database:
    def __init__(self):
        """
        Connects to the database.
        """
        self.connection = psycopg2.connect(**get_connection_parameters())
        self.cursor = self.connection.cursor()

    def set_search_path(self, schemas):
        """
        Sets the search path to the given schemas.
        """
        self.cursor.execute(sql.SQL('SET search_path = {schemas}').format(schemas=sql.SQL(', ').join(
            sql.Identifier(schema) for schema in schemas)))

    def schema_exists(self, schema):
        """
        Returns whether a schema exists.
        """
        return self.one('SELECT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = %(schema)s)', {'schema': schema})[0]

    def pluck(self, statement, variables=None):
        """
        Returns the first value from all the results.
        """
        return [row[0] for row in self.all(statement, variables)]

    def schemas(self):
        """
        Returns a list of schema names that start with "view_data_".
        """
        return self.pluck("SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'view_data_%'")

    def all(self, statement, variables=None):
        """
        Executes the SQL statement and fetches all rows.
        """
        self.cursor.execute(statement, variables)
        return self.cursor.fetchall()

    def one(self, statement, variables=None):
        """
        Executes the SQL statement and fetches one row.
        """
        self.cursor.execute(statement, variables)
        return self.cursor.fetchone()

    def execute(self, statement, variables=None):
        """
        Executes the SQL statement.
        """
        self.cursor.execute(statement, variables)

    def execute_values(self, sql, argslist):
        """
        Executes the SQL statement using ``VALUES`` with a sequence of parameters.
        """
        execute_values(self.cursor, sql, argslist)

    def commit(self):
        """
        Commits the transaction.
        """
        self.connection.commit()

    def close(self):
        """
        Close the cursor and connection.
        """
        self.cursor.close()
        self.connection.close()
