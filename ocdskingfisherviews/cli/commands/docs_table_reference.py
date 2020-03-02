import csv
import glob
import os
import re

import sqlalchemy as sa

import ocdskingfisherviews.cli.commands.base

column_info_query = '''
    SELECT
        isc.column_name,
        isc.data_type,
        pg_catalog.col_description(format('%%s.%%s',isc.table_schema,isc.table_name)::regclass::oid,
                                   isc.ordinal_position) as column_description
    FROM
        information_schema.columns isc where table_schema=%s and lower(isc.table_name) = lower(%s);
'''


class DocsTableRefCommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'docs-table-ref'

    def configure_subparser(self, subparser):
        subparser.add_argument("name", help="Name Of View")

    def run_command(self, args):

        dir_path = os.path.dirname(os.path.realpath(__file__))

        docs_path = os.path.join(dir_path, '../../../docs')
        docs_csv = os.path.join(docs_path, 'definitions')

        sql_scripts_path = os.path.join(dir_path, '../../../sql')
        all_scripts = sorted(glob.glob(sql_scripts_path + '/*.sql'))

        all_tables = []
        for script_path in all_scripts:
            script_name = script_path.split('/')[-1].split('.')[0]
            if script_name.endswith('_downgrade'):
                continue
            with open(script_path) as script_file:
                script = script_file.read()

            for table_name in re.findall(r'^create (?:table|view)[\s]*([\S]*)\s', script, flags=(re.M | re.I)):
                if table_name.startswith(('tmp_', 'staged_')) or table_name.endswith('_no_data'):
                    continue
                all_tables.append(table_name)

        all_tables.append('field_counts')

        engine = sa.create_engine(self.config.database_uri)

        headers = {
            'column_name': 'Column Name',
            'data_type': 'Data Type',
            'column_description': 'Description',
        }

        for table in all_tables:
            csv_file_name = os.path.join(docs_csv, table + '.csv')
            with engine.begin() as connection, open(csv_file_name, 'w+') as output:
                writer = csv.DictWriter(output, headers.keys(), lineterminator='\n')
                writer.writerow(headers)

                for result in connection.execute(column_info_query, ['view_data_' + args.name, table]):
                    result_dict = dict(result)
                    if 'timestamp' in result_dict['data_type']:
                        result_dict['data_type'] = 'timestamp'
                    writer.writerow(result_dict)
