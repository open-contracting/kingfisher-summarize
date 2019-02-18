import json
import os
from timeit import default_timer as timer

import sqlalchemy as sa
import alembic.config

import ocdskingfisherviews.cli.commands.base



class refreshCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'refresh-views'

    def configure_subparser(self, subparser):
        subparser.add_argument("--clear", help="clear all materialized views", action='store_true')

        subparser.add_argument("--sql", help="Just output sql and do not run", action='store_true')
        subparser.add_argument("--sql-timing", help="Add psql timing to sql output", action='store_true')

    def run_command(self, args):

        dir_path = os.path.dirname(os.path.realpath(__file__))
        
        with open(os.path.join(dir_path, '../../../views_refresh_order.json')) as f:
            view_order = json.load(f)
                           
        engine = sa.create_engine(self.config.database_uri)

        exists = set()
        is_not_populated = set()

        with engine.begin() as connection:
            results = connection.execute('''
                SELECT relname, relispopulated  FROM pg_class join pg_namespace on pg_namespace.oid = relnamespace where nspname = 'views';
            ''')
            for result in results:
                exists.add(result['relname'])
                if not result['relispopulated']:
                    is_not_populated.add(result['relname'])


        statements = []

        sql_template = '''REFRESH MATERIALIZED VIEW {concurrently} "{name}" WITH {no} DATA'''

        for item in view_order:
            if item['name'] not in exists:
                print("ERROR: View {} does not exist, you may need to upgrade your database".format(item['name']))
                return
            context = {"concurrently": "concurrently",
                       "name": item['name'],
                       "no": ""}
            if item['name'] in is_not_populated or args.clear or item.get('clear') or item['name'].startswith('tmp_'):
                context["concurrently"] = ""
            if item.get('clear') or args.clear:
                context["no"] = "NO"
            statements.append(sql_template.format(**context))

        statement_string = 'set search_path = views, public;\n'
        statement_string += ";\n".join(statements) + ';'
        if args.sql:
            if args.sql_timing:
                statement_string = r'\timing' + '\n' + statement_string
            print(statement_string)
            return

        with engine.begin() as connection:
            connection.execute('set search_path = views, public;\n')
            for statement in statements:
                start = timer()
                print('running statement: {}'.format(statement))
                connection.execute(statement)
                print('running time: {}s'.format(timer() - start))

