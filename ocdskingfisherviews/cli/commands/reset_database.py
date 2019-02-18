import ocdskingfisherviews.cli.commands.base
import alembic.config
import os


class ResetDatabaseCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'reset-database'

    def configure_subparser(self, subparser):
        pass

    def run_command(self, args):
        alembicargs = [
            '--config', os.path.abspath(os.path.join(os.path.dirname(__file__), '../../', 'alembic.ini')),
            '--raiseerr',
            'downgrade', 'base',
        ]
        alembic.config.main(argv=alembicargs)
