import os

import psycopg2
from psycopg2 import sql
from psycopg2.extras import execute_values


class Database:
    def __init__(self):
        """
        Connects to the database.
        """
        self.connection = psycopg2.connect(os.getenv('KINGFISHER_SUMMARIZE_DATABASE_URL'))
        self.cursor = self.connection.cursor()

    def set_search_path(self, schemas):
        """
        Sets the search path to the given schemas.
        """
        self.cursor.execute(self.format('SET search_path = {schemas}', schemas=schemas))

    def schema_exists(self, schema):
        """
        Returns whether a schema exists.
        """
        return self.one('SELECT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = %(schema)s)', {'schema': schema})[0]

    def pluck(self, statement, variables=None, **kwargs):
        """
        Returns the first value from all the results.
        """
        return [row[0] for row in self.all(statement, variables, **kwargs)]

    def schemas(self):
        """
        Returns a list of schema names that start with "view_data_".
        """
        return self.pluck("SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'view_data_%'")

    def all(self, statement, variables=None, **kwargs):
        """
        Executes the SQL statement and fetches all rows.
        """
        self.execute(statement, variables, **kwargs)
        return self.cursor.fetchall()

    def one(self, statement, variables=None, **kwargs):
        """
        Executes the SQL statement and fetches one row.
        """
        self.execute(statement, variables, **kwargs)
        return self.cursor.fetchone()

    def format(self, statement, **kwargs):
        """
        Formats the SQL statement, expressed as a format string with keyword arguments. A keyword argument's value is
        converted to a SQL identifier, or a list of SQL identifiers, unless it's already a ``sql`` object.
        """
        objects = {}
        for key, value in kwargs.items():
            if isinstance(value, sql.Composable):
                objects[key] = value
            elif isinstance(value, list):
                objects[key] = sql.SQL(', ').join(self.identify(entry) for entry in value)
            else:
                objects[key] = self.identify(value)
        return sql.SQL(statement).format(**objects)

    def identify(self, value):
        """
        Returns the value as a SQL identifier. If the value is a tuple, the SQL identifier will be dot-separated.
        """
        if not isinstance(value, tuple):
            value = (value,)
        return sql.Identifier(*value)

    def execute(self, statement, variables=None, **kwargs):
        """
        Executes the SQL statement.
        """
        if kwargs:
            statement = self.format(statement, **kwargs)
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
