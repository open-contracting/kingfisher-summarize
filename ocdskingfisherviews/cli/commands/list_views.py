
import sqlalchemy as sa

import ocdskingfisherviews.cli.commands.base


class ListViewCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'list-views'

    def configure_subparser(self, subparser):
        pass

    def run_command(self, args):

        engine = sa.create_engine(self.config.database_uri)

        # Get list of views
        schemas = []
        sql = 'select schema_name from information_schema.schemata;'
        with engine.begin() as connection:
            for row in connection.execute(sql):
                if row['schema_name'].startswith('view_data_'):
                    schemas.append(row['schema_name'][len("view_data_"):])

        # Print each one, getting notes as we do
        for schema in schemas:
            print("-----")
            print("VIEW: " + schema)
            with engine.begin() as connection:
                connection.execute('set search_path = view_data_'+schema+';')
                for row in connection.execute('SELECT * FROM selected_collections'):
                    print("Collection Id: " + str(row['id']))
                for row in connection.execute('SELECT * FROM note'):
                    print("Note: " + row['note'] + ' (' + str(row['created_at'])+')')
