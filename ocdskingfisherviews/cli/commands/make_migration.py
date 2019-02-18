import ocdskingfisherviews.cli.commands.base
import alembic.config
import os


class MakeMigrationCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'make-migration'

    def configure_subparser(self, subparser):
        subparser.add_argument("message", help="Migration message. For sql scripts name it to same name as sql script")


    def run_command(self, args):

        alembicargs = [
            '--config', os.path.abspath(os.path.join(os.path.dirname(__file__), '../../', 'alembic.ini')),
            '--raiseerr',
            'revision', '-m', args.message
        ]
        alembic.config.main(argv=alembicargs)

