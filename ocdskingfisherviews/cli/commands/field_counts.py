import sqlalchemy as sa

import ocdskingfisherviews.cli.commands.base
from ocdskingfisherviews.field_counts import FieldCounts


class FieldCountsCommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'field-counts'

    def configure_subparser(self, subparser):
        subparser.add_argument("viewname", help="Name Of View")
        subparser.add_argument("--remove", help="Remove the field_counts table", action='store_true')
        subparser.add_argument("--threads", help="Amount of threads to use", type=int, default=1)
        subparser.add_argument("--logfile", help="Optional output logfile")

    def run_logged_command(self, args):

        engine = sa.create_engine(self.database_uri)

        field_counts = FieldCounts(engine=engine)
        field_counts.run(args.viewname, remove=args.remove, threads=args.threads)
