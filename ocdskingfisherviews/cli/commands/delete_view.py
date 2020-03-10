
import sqlalchemy as sa
from logzero import logger

import ocdskingfisherviews.cli.commands.base


class DeleteViewCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'delete-view'

    def configure_subparser(self, subparser):
        subparser.add_argument("name", help="Name Of View")

    def run_command(self, args):

        engine = sa.create_engine(self.database_uri)

        logger.info("Deleting View " + args.name)
        with engine.begin() as connection:
            # Technically this is SQL injection opportunity,
            # but as operators have access to the DB anyway we don't care.
            connection.execute('DROP SCHEMA view_data_' + args.name + ' CASCADE;')
