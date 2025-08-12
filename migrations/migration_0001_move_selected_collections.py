"""
Migrate from selected_collections inside the schema, to a global one in its own summaries schema.

Run this with `python -m migrations.migration_0001_move_selected_collections` in the parent directory.
"""

# https://github.com/open-contracting/kingfisher-summarize/issues/197
from psycopg2.errors import UndefinedTable

from ocdskingfishersummarize.db import Database


def migrate():
    db = Database()

    db.execute("CREATE SCHEMA IF NOT EXISTS summaries")
    db.set_search_path(["summaries"])
    db.execute("""CREATE TABLE IF NOT EXISTS selected_collections
                  (schema TEXT NOT NULL, collection_id INTEGER NOT NULL)""")
    db.execute("""CREATE UNIQUE INDEX IF NOT EXISTS selected_collections_schema_collection_id
                  ON selected_collections (schema, collection_id)""")
    db.commit()

    for schema in db.schemas():
        db.set_search_path([schema])
        try:
            collections = db.pluck("SELECT id FROM selected_collections")
        except UndefinedTable:
            db.connection.rollback()
        else:
            db.execute_values(
                "INSERT INTO summaries.selected_collections (schema, collection_id) VALUES %s",
                [(schema, _id) for _id in collections],
            )
            db.commit()


if __name__ == "__main__":
    migrate()
