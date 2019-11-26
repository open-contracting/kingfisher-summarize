
import sqlalchemy as sa

import ocdskingfisherviews.cli.commands.base


class CorrectUserPermissionsCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'correct-user-permissions'

    def configure_subparser(self, subparser):
        pass

    def run_command(self, args):

        engine = sa.create_engine(self.config.database_uri)

        # Get list of Users
        users = []
        with engine.begin() as connection:
            connection.execute('set search_path=view_meta')
            for row in connection.execute('select username from read_only_user'):
                users.append(row['username'])

        # Get list of views
        schemas = []
        sql = 'select schema_name from information_schema.schemata;'
        with engine.begin() as connection:
            for row in connection.execute(sql):
                if row['schema_name'].startswith('view_data_'):
                    schemas.append(row['schema_name'])

        # Apply permissions
        for user in users:
            with engine.begin() as connection:
                connection.execute('GRANT USAGE ON SCHEMA public TO ' + user)
                connection.execute('GRANT SELECT ON ALL TABLES IN SCHEMA public TO ' + user)
                for schema in schemas:
                    connection.execute('GRANT USAGE ON SCHEMA ' + schema + ' TO ' + user)
                    connection.execute('GRANT SELECT ON ALL TABLES IN SCHEMA ' + schema + ' TO ' + user)
