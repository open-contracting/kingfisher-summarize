import datetime

import sqlalchemy as sa
from logzero import logger

import ocdskingfisherviews.cli.commands.base
from ocdskingfisherviews.correct_user_permissions import correct_user_permissions
from ocdskingfisherviews.field_counts import FieldCounts
from ocdskingfisherviews.refresh_views import refresh_views


class AddViewCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'add-view'

    def configure_subparser(self, subparser):
        subparser.add_argument("name", help="Name Of View")
        subparser.add_argument("collections", help="Ids of collection, comma separated")
        subparser.add_argument("note", help="A Note")
        subparser.add_argument("--dontbuild", help="Don't Build the View, just create it.", action='store_true')

    def run_command(self, args):

        engine = sa.create_engine(self.config.database_uri)

        logger.info("Creating View " + args.name)
        with engine.begin() as connection:
            # Technically this is SQL injection opportunity,
            # but as operators have access to the DB anyway we don't care.
            connection.execute('CREATE SCHEMA view_data_' + args.name + ';')
            connection.execute('SET search_path = view_data_' + args.name + ';')
            # This could have a foreign key but as extra_collections doesn't, we won't for now.
            connection.execute('CREATE TABLE selected_collections(id INTEGER PRIMARY KEY);')
            for collection_id in args.collections.split(','):
                if collection_id and collection_id.isdigit():
                    connection.execute(sa.sql.text('INSERT INTO selected_collections (id) VALUES (:collection_id)'),
                                       {'collection_id': collection_id})
            connection.execute('CREATE TABLE note(id SERIAL, ' +
                               'note TEXT NOT NULL, created_at TIMESTAMP WITHOUT TIME ZONE);')
            if args.note:
                connection.execute(sa.sql.text('INSERT INTO  note (note, created_at) VALUES (:note, :at)'),
                                   {'note': args.note, 'at': datetime.datetime.utcnow()})

        if not args.dontbuild:

            logger.info("Correcting User Permissions after Creating View " + args.name)
            correct_user_permissions(engine)

            logger.info("Refreshing Views after Creating View " + args.name)
            refresh_views(engine, viewname=args.name)

            logger.info("Updating Field Counts after Creating View " + args.name)
            field_counts = FieldCounts(engine=engine)
            field_counts.run(viewname=args.name)
