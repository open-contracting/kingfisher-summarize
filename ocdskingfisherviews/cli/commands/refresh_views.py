import sqlalchemy as sa

import ocdskingfisherviews.cli.commands.base
from ocdskingfisherviews.refresh_views import refresh_views


class RefreshCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'refresh-views'

    def configure_subparser(self, subparser):
        subparser.add_argument("--remove", help="remove all views", action='store_true')
        subparser.add_argument("--start", type=int, default=0,
                               help="Start at script. i.e 4 will start at 004-planning.sql")
        subparser.add_argument("--end", type=int, default=1000,
                               help="End at script i.e 4 will end at 004-planning.sql")
        subparser.add_argument("--sql", help="Just output sql and do not run", action='store_true')
        subparser.add_argument("--sql-timing", help="Add psql timing to sql output", action='store_true')
        subparser.add_argument("--logfile", help="optional output logfile")
        subparser.add_argument("--viewname", help="optional view name")

    def run_logged_command(self, args):

        engine = sa.create_engine(self.config.database_uri)

        refresh_views(engine,
                      remove=args.remove,
                      start=args.start,
                      end=args.end,
                      sql=args.sql,
                      sql_timing=args.sql_timing,
                      viewname=args.viewname)
