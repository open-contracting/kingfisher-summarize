

def correct_user_permissions(engine):
    # Get list of Users
    users = []
    with engine.begin() as connection:
        for row in connection.execute('SELECT username FROM views.read_only_user'):
            users.append(row['username'])

    # Get list of views
    schemas = []
    sql = 'SELECT schema_name FROM information_schema.schemata;'
    with engine.begin() as connection:
        for row in connection.execute(sql):
            if row['schema_name'].startswith('view_data_'):
                schemas.append(row['schema_name'])

    # Apply permissions
    for user in users:
        user = engine.dialect.identifier_preparer.quote(user)

        with engine.begin() as connection:
            # Grant access to all tables in the public schema.
            connection.execute('GRANT USAGE ON SCHEMA public TO ' + user)
            connection.execute('GRANT SELECT ON ALL TABLES IN SCHEMA public TO ' + user)

            # Grant access to the mapping_sheets table in the views schema.
            connection.execute('GRANT USAGE ON SCHEMA views TO ' + user)
            connection.execute('GRANT SELECT ON views.mapping_sheets TO ' + user)

            # Grant access to all tables in every schema created by Kingfisher Views.
            for schema in schemas:
                schema = engine.dialect.identifier_preparer.quote(schema)

                connection.execute('GRANT USAGE ON SCHEMA ' + schema + ' TO ' + user)
                connection.execute('GRANT SELECT ON ALL TABLES IN SCHEMA ' + schema + ' TO ' + user)
