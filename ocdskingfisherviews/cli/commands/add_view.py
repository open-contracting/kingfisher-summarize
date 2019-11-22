import sqlalchemy as sa
import ocdskingfisherviews.cli.commands.base


class RefreshCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'add-view'

    def configure_subparser(self, subparser):
        subparser.add_argument("name", help="Name Of View")

    def run_command(self, args):

        engine = sa.create_engine(self.config.database_uri)

        with engine.begin() as connection:
            # Technically this is SQL injection opportunity,
            # but as operators have access to the DB anyway we don't care.
            connection.execute('CREATE SCHEMA view_data_' + args.name + ';\n')
            connection.execute('SET search_path = view_data_' + args.name + ';\n')
            # This could have a foreign key but as extra_collections doesn't, we won't for now.
            connection.execute('CREATE TABLE selected_collections(id INTEGER PRIMARY KEY);\n')
