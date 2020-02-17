import datetime

import sqlalchemy as sa
from logzero import logger

from ocdskingfisherviews.correct_user_permissions import correct_user_permissions
from ocdskingfisherviews.field_counts import FieldCounts
from ocdskingfisherviews.refresh_views import refresh_views


def add_view(engine, collections, name=None, note=None, dontbuild=False):

    if not name:
        if len(collections) > 5:
            raise Exception("Please specify name when selecting more than 5 collections")
        name = "collection_{}".format("_".join(str(collection_id) for collection_id in sorted(collections)))

    logger.info("Creating View " + name)
    with engine.begin() as connection:
        # Technically this is SQL injection opportunity,
        # but as operators have access to the DB anyway we don't care.
        connection.execute('CREATE SCHEMA view_data_' + name + ';')
        connection.execute('SET search_path = view_data_' + name + ';')
        # This could have a foreign key but as extra_collections doesn't, we won't for now.
        connection.execute('CREATE TABLE selected_collections(id INTEGER PRIMARY KEY);')

        for collection_id in collections:
            connection.execute(sa.sql.text('INSERT INTO selected_collections (id) VALUES (:collection_id)'),
                               {'collection_id': collection_id})

        connection.execute('CREATE TABLE note(id SERIAL, ' +
                           'note TEXT NOT NULL, created_at TIMESTAMP WITHOUT TIME ZONE);')
        if note:
            connection.execute(sa.sql.text('INSERT INTO  note (note, created_at) VALUES (:note, :at)'),
                               {'note': note, 'at': datetime.datetime.utcnow()})

    if not dontbuild:

        logger.info("Refreshing Views after Creating View " + name)
        refresh_views(engine, name)

        logger.info("Updating Field Counts after Creating View " + name)
        field_counts = FieldCounts(engine=engine)
        field_counts.run(name)

        # This must be done after table creation in refresh_views and FieldCounts
        # as the users are granted access to tables that already exist.
        # So if it's done before, the users won't be able to access some tables!
        logger.info("Correcting User Permissions after Creating View " + name)
        correct_user_permissions(engine)
