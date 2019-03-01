import os
from timeit import default_timer as timer
import glob
from collections import OrderedDict
import datetime

import sqlalchemy as sa
from logzero import logger

import ocdskingfisherviews.cli.commands.base



class RefreshCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'refresh-views'

    def configure_subparser(self, subparser):
        subparser.add_argument("--remove", help="remove all views", action='store_true')

        subparser.add_argument("--start", help="Start at script. i.e 4 will start at 004-planning.sql", type=int, default=0)
        subparser.add_argument("--end", help="End at script i.e 4 will end at 004-planning.sql", type=int, default=1000)

        subparser.add_argument("--sql", help="Just output sql and do not run", action='store_true')
        subparser.add_argument("--sql-timing", help="Add psql timing to sql output", action='store_true')

        subparser.add_argument("--logfile", help="optional output logfile")

    def run_logged_command(self, args):

        dir_path = os.path.dirname(os.path.realpath(__file__))

        sql_scripts_path = os.path.join(dir_path, '../../../sql')
        all_scripts = glob.glob(sql_scripts_path + '/*.sql') 

        
        search_path_string = 'set search_path = views, public;\n'
                           
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
                script = search_path_string + script_file.read()

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
            with engine.begin() as connection:
                connection.execute('set search_path = views, public;\n')
                start = timer()
                logger.info('running script: {}'.format(statement_name))
                connection.execute(statement, tuple())
                logger.info('running time: {}s'.format(timer() - start))

        logger.info('total running time: {}s'.format(timer() - start_all))
