import os
import glob
import re
import csv

import sqlalchemy as sa

import ocdskingfisherviews.cli.commands.base


column_info_query = '''
    SELECT
        isc.column_name,
        isc.data_type,
        pg_catalog.col_description(format('%%s.%%s',isc.table_schema,isc.table_name)::regclass::oid,isc.ordinal_position) as column_description
    FROM
        information_schema.columns isc where table_schema='views' and lower(isc.table_name) = lower(%s);
'''

output_rst_base = '''
View Reference
==============
'''

output_rst_table_template = '''
{table_name}
-------------------------------------------
.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: view_definitions/{table_name}.csv
'''

class DocsTableRefCommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'docs-table-ref'

    def run_command(self, args):

        dir_path = os.path.dirname(os.path.realpath(__file__))

        docs_path = os.path.join(dir_path, '../../../docs')
        docs_csv = os.path.join(docs_path, 'view_definitions')
        docs_view_reference = os.path.join(docs_path, 'view-reference.rst')

        sql_scripts_path = os.path.join(dir_path, '../../../sql')
        all_scripts = glob.glob(sql_scripts_path + '/*.sql') 
        all_scripts.sort()

        all_tables = []
        for script_path in all_scripts:
            script_name = script_path.split('/')[-1].split('.')[0]
            if script_name.endswith('_downgrade'):
                continue
            with open(script_path) as script_file:
                script = script_file.read()

            for table_name in re.findall(r'^into[\s]*([\S]*)$', script, flags=(re.M | re.I)):
                if table_name.startswith('tmp_'):
                    continue
                all_tables.append(table_name)

        search_path_string = 'set search_path = views, public;'
                           
        engine = sa.create_engine(self.config.database_uri)

        
        output_rst = output_rst_base

        for table in all_tables:
            results = []
            csv_file_name = os.path.join(docs_csv, table + '.csv')
            with engine.begin() as connection, open(csv_file_name, 'w+') as output:
                writer = csv.DictWriter(output, ['column_name', 'data_type', 'column_description'])
                writer.writerow({'column_name': 'Column Name',
                                 'data_type': 'Data Type',
                                 'column_description': 'Description'})
            
                for result in connection.execute(column_info_query, [table]):
                    result_dict = dict(result)
                    if 'timestamp' in result_dict['data_type']:
                        result_dict['data_type'] = 'timestamp'
                    writer.writerow(result_dict)

            output_rst +=  output_rst_table_template.format(table_name=table)

        with open(docs_view_reference, 'w+') as docs_view_reference_file:
            docs_view_reference_file.write(output_rst)


