import glob
import os
from collections import OrderedDict
from timeit import default_timer as timer

import sqlalchemy as sa
from logzero import logger

import ocdskingfisherviews.cli.commands.base


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

        dir_path = os.path.dirname(os.path.realpath(__file__))

        sql_scripts_path = os.path.join(dir_path, '../../../sql')
        all_scripts = glob.glob(sql_scripts_path + '/*.sql')

        engine = sa.create_engine(self.config.database_uri)

        statements = OrderedDict()

        if args.remove:
            all_scripts.sort(reverse=True)
        else:
            all_scripts.sort()

        for script_path in all_scripts:
            script_name = script_path.split('/')[-1].split('.')[0]
            script_number = int(script_name[:3])

            if script_number < args.start or script_number > args.end:
                continue

            with open(script_path) as script_file:
                script = script_file.read()

            if script_name.endswith('_downgrade') and args.remove:
                statements[script_name] = script
            if not script_name.endswith('_downgrade') and not args.remove:
                statements[script_name] = script

        if args.sql:
            all_sql = ';\n'.join(statements.values())
            if args.sql_timing:
                all_sql = r'\timing' + '\n' + all_sql
            print(all_sql)
            return

        start_all = timer()

        for statement_name, statement in statements.items():
            # special marker to split statements up.
            statement_parts = statement.split('----')
            start = timer()
            logger.info('running script: {}'.format(statement_name))

            for statement_part in statement_parts:
                with engine.begin() as connection:
                    if args.viewname:
                        # Technically this is SQL injection opportunity,
                        # but as operators have access to the DB anyway we don't care.
                        connection.execute('set search_path = view_data_'+args.viewname+', public;\n')
                    else:
                        connection.execute('set search_path = views, public;\n')
                    connection.execute(statement_part, tuple())

            logger.info('running time: {}s'.format(timer() - start))

        logger.info('total running time: {}s'.format(timer() - start_all))
