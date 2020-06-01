import sqlalchemy as sa

import ocdskingfisherviews.cli.commands.base
from ocdskingfisherviews.refresh_views import refresh_views


class RefreshCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'refresh-views'

    def configure_subparser(self, subparser):
        subparser.add_argument("viewname", help="Name Of View")
        subparser.add_argument("--remove", help="Remove all views", action='store_true')
        subparser.add_argument("--tables-only",
                               help="Do not create database views (use persistent tables only)",
                               action='store_true')

    def run_logged_command(self, args):
        engine = sa.create_engine(self.database_uri)
        refresh_views(engine, args.viewname, remove=args.remove, tables_only=args.tables_only)
