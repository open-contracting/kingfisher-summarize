import sqlalchemy as sa

import ocdskingfisherviews.cli.commands.base
from ocdskingfisherviews.add_view import add_view


class AddViewCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'add-view'

    def configure_subparser(self, subparser):
        subparser.add_argument("collections", help="Ids of collection, comma separated")
        subparser.add_argument("note", help="A Note")
        subparser.add_argument("--name", help="Name Of View")
        subparser.add_argument("--dontbuild", help="Don't Build the View, just create it.", action='store_true')

    def run_command(self, args):

        engine = sa.create_engine(self.database_uri)

        collections = []
        for collection_id in args.collections.split(','):
            if collection_id and collection_id.isdigit():
                collections.append(collection_id)

        add_view(engine, collections, name=args.name, note=args.note, dontbuild=args.dontbuild)
