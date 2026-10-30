import os

import psycopg
from psycopg import ClientCursor, sql


def identifiers(values):
    """Return the values as comma-separated SQL identifiers. A tuple is a dot-separated identifier."""
    return sql.SQL(", ").join(sql.Identifier(*v) if isinstance(v, tuple) else sql.Identifier(v) for v in values)


class Database:
    def __init__(self):
        """Connect to the database."""
        self.connection = psycopg.connect(os.getenv("KINGFISHER_SUMMARIZE_DATABASE_URL"))
        self.cursor = self.connection.cursor()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()

    def close(self):
        """Close the database connection."""
        self.connection.close()

    def set_search_path(self, schemas):
        """Set the search path to the given schemas."""
        self.cursor.execute(t"SET search_path = {identifiers(schemas):q}")

    def schema_exists(self, schema):
        """Return whether a schema exists."""
        statement = "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = %(schema)s)"
        return self.one(statement, {"schema": schema})[0]

    def pluck(self, statement, variables=None):
        """Return the first value from all the results."""
        return [row[0] for row in self.all(statement, variables)]

    def schemas(self):
        """Return a list of schema names that start with "summary_"."""
        return self.pluck("SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'summary_%'")

    def all(self, statement, variables=None):
        """Execute the SQL statement and fetches all rows."""
        self.execute(statement, variables)
        return self.cursor.fetchall()

    def one(self, statement, variables=None):
        """Execute the SQL statement and fetches one row."""
        self.execute(statement, variables)
        return self.cursor.fetchone()

    def execute(self, statement, variables=None):
        """Execute the SQL statement."""
        self.cursor.execute(statement, variables)

    def executemany(self, statement, argslist):
        """Execute the SQL statement once for each sequence of parameters in ``argslist``."""
        self.cursor.executemany(statement, argslist)

    def mogrify(self, statement, variables=None):
        """
        Return the SQL statement with the variables bound, as a string.

        psycopg's default cursor binds parameters server-side and has no ``mogrify()``, so use a
        :class:`~psycopg.ClientCursor` to render the parameters into the statement client-side.
        """
        return ClientCursor(self.connection).mogrify(statement, variables)

    def commit(self):
        """Commit the transaction."""
        self.connection.commit()
