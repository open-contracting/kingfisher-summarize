import sqlalchemy as sa

import ocdskingfisherviews.cli.commands.base
from ocdskingfisherviews.field_counts import FieldCounts


class FieldCountsCommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'field-counts'

    def configure_subparser(self, subparser):
        subparser.add_argument("--remove", help="Aemove field_count table", action='store_true')
        subparser.add_argument("--threads", help="Amount of threads to use", type=int, default=1)

        subparser.add_argument("--logfile", help="Add psql timing to sql output")
        subparser.add_argument("--viewname", help="optional view name")

    def run_logged_command(self, args):

        engine = sa.create_engine(self.config.database_uri)

        field_counts = FieldCounts(engine=engine)
        field_counts.run(viewname=args.viewname, remove=args.remove, threads=args.threads)
