import concurrent.futures
import csv
import glob
import json
import logging
import logging.config
import os.path
import re
from datetime import datetime
from timeit import default_timer as timer

import click
from psycopg2 import sql
from psycopg2.extras import execute_values
from tabulate import tabulate

from ocdskingfisherviews.db import (commit, get_connection, get_cursor, get_schemas, pluck, schema_exists,
                                    set_search_path)


def _read_sql_files(remove=False):
    """
    Returns a dict in which keys are the basenames of SQL files and values are their contents.

    :param bool remove: whether to read the *_downgrade.sql files
    """
    contents = {}

    filenames = glob.glob(os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', 'sql', '*.sql'))
    for filename in sorted(filenames, reverse=remove):
        basename = os.path.splitext(os.path.basename(filename))[0]
        if not (basename.endswith('_downgrade') ^ remove):
            with open(filename) as f:
                contents[basename] = f.read()

    return contents


def validate_collections(ctx, param, value):
    """
    Returns a list of collection IDs. Raises an error if an ID isn't in the collection table.
    """
    try:
        ids = tuple(int(_id) for _id in value.split(','))
    except ValueError:
        raise click.BadParameter(f'Collection IDs must be integers')

    difference = set(ids) - set(pluck('SELECT id FROM collection WHERE id IN %(ids)s', {'ids': ids}))
    if difference:
        raise click.BadParameter(f'Collection IDs {difference} not found')

    return ids


def validate_name(ctx, param, value):
    """
    Returns a schema name. Raises an error if the schema isn't in the database.
    """
    schema = f'view_data_{value}'

    if not schema_exists(schema):
        raise click.BadParameter(f'SQL schema "{schema}" not found')

    return schema


@click.group()
@click.pass_context
def cli(ctx):
    path = os.path.expanduser('~/.config/ocdskingfisher-views/logging.json')
    if os.path.isfile(path):
        with open(path) as f:
            logging.config.dictConfig(json.load(f))
    # Python's root logger only prints warning and above.
    else:
        logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)

    logger = logging.getLogger('ocdskingfisher.views.cli')
    logger.info('Running %s', ctx.invoked_subcommand)

    global connection
    connection = get_connection()

    global cursor
    cursor = get_cursor()


@click.command()
def install():
    """
    Creates the views schema and the read_only_user and mapping_sheets tables within it, if they don't exist.
    """
    logger = logging.getLogger('ocdskingfisher.views.install')

    cursor.execute('CREATE TABLE IF NOT EXISTS views.read_only_user(username VARCHAR(64) NOT NULL PRIMARY KEY)')
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS views.mapping_sheets (
            id serial primary key,
            version text,
            extension text,
            section text,
            path text,
            title text,
            description text,
            type text,
            range text,
            values text,
            links text,
            deprecated text,
            "deprecationNotes" text
        )
    """)

    cursor.execute('SELECT id FROM views.mapping_sheets LIMIT 1')
    if not cursor.fetchone():
        filename = os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', 'sql', 'extras', '1-1-3.csv')
        with open(filename) as f:
            reader = csv.DictReader(f)

            paths = set()
            values = []
            for row in reader:
                row['version'] = '1.1'
                row['extension'] = 'core'
                if row['path'] not in paths:
                    paths.add(row['path'])
                    values.append(tuple(row))

        statement = sql.SQL('INSERT INTO views.mapping_sheets ({columns}, version, extension) VALUES %s').format(
            columns=sql.SQL(', ').join(sql.Identifier(column) for column in reader.fieldnames))
        execute_values(cursor, statement, values)

    commit()

    logger.info('Created tables')


@click.command()
@click.argument('collections', callback=validate_collections)
@click.argument('note')
@click.option('--name', help='A custom name for the SQL schema ("view_data_" will be prepended).')
@click.option('--dontbuild', is_flag=True, help="Don't run the refresh-views, field-counts and "
                                                "correct-user-permissions commands.")
@click.option('--tables-only', is_flag=True, help='Create SQL tables instead of SQL views.')
@click.pass_context
def add_view(ctx, collections, note, name, dontbuild, tables_only):
    """
    Creates a schema containing summary tables about one or more collections.

    \b
    COLLECTIONS is one or more comma-separated collection IDs
    NOTE is your name and a description of your purpose
    """
    logger = logging.getLogger('ocdskingfisher.views.add-view')
    logger.info('Arguments: collections=%s note=%s name=%s dontbuild=%s tables_only=%s',
                collections, note, name, dontbuild, tables_only)

    if not name:
        if len(collections) > 5:
            raise click.UsageError('--name is required for more than 5 collections')
        name = f"collection_{'_'.join(str(_id) for _id in sorted(collections))}"

    schema = f'view_data_{name}'
    cursor.execute(sql.SQL('CREATE SCHEMA {schema}').format(schema=sql.Identifier(schema)))
    set_search_path([schema])

    cursor.execute('CREATE TABLE selected_collections (id INTEGER PRIMARY KEY)')
    execute_values(cursor, 'INSERT INTO selected_collections (id) VALUES %s', [(_id,) for _id in collections])

    cursor.execute('CREATE TABLE note (id SERIAL, note TEXT NOT NULL, created_at TIMESTAMP WITHOUT TIME ZONE)')
    cursor.execute(sql.SQL('INSERT INTO note (note, created_at) VALUES (%(note)s, %(at)s)'),
                   {'note': note, 'at': datetime.utcnow()})

    cursor.execute('ANALYZE selected_collections')
    commit()

    logger.info('Added %s', name)

    if not dontbuild:
        logger.info('Running refresh-views')
        ctx.invoke(refresh_views, name=schema, tables_only=tables_only)

        logger.info('Running field-counts')
        ctx.invoke(field_counts, name=schema)

        logger.info('Running correct-user-permissions')
        ctx.invoke(correct_user_permissions)


@click.command()
@click.argument('name', callback=validate_name)
def delete_view(name):
    """
    Drops a schema.

    NAME is the last part of a schema's name after "view_data_".
    """
    logger = logging.getLogger('ocdskingfisher.views.delete-view')
    logger.info('Arguments: name=%s', name)

    # `CASCADE` drops all objects (tables, functions, etc.) in the schema.
    statement = sql.SQL('DROP SCHEMA {schema} CASCADE').format(schema=sql.Identifier(name))
    cursor.execute(statement)
    commit()

    logger.info(statement.as_string(connection))


@click.command()
def list_views():
    """
    Lists the schemas, with collection IDs and creator's notes.
    """
    def format_note(note):
        return f"{note[0]} ({note[1].strftime('%Y-%m-%d %H:%M:%S')})"

    for schema in get_schemas():
        set_search_path([schema])

        cursor.execute('SELECT id FROM selected_collections ORDER BY id')
        collections = [str(row[0]) for row in cursor.fetchall()]

        cursor.execute('SELECT note, created_at FROM note ORDER BY created_at')
        notes = cursor.fetchall()

        table = [[schema[10:], ', '.join(collections), format_note(notes[0])]]
        for note in notes[1:]:
            table.append([None, None, format_note(note)])

        click.echo(tabulate(table, headers=['Name', 'Collections', 'Note'], tablefmt='github', numalign='left'))


@click.command()
@click.argument('name', callback=validate_name)
@click.option('--remove', is_flag=True, help='Drop the summary tables from the schema')
@click.option('--tables-only', is_flag=True, help='Create SQL tables instead of SQL views')
def refresh_views(name, remove, tables_only):
    """
    Creates (or re-creates) the summary tables in a schema.

    NAME is the last part of a schema's name after "view_data_".
    """
    logger = logging.getLogger('ocdskingfisher.views.refresh-views')
    logger.info('Arguments: name=%s remove=%s tables_only=%s', name, remove, tables_only)

    set_search_path([name, 'public'])

    command_timer = timer()

    for basename, content in _read_sql_files(remove).items():
        file_timer = timer()
        logger.info('Running %s', basename)

        for part in content.split('----'):
            if tables_only:
                part = re.sub('^CREATE VIEW', 'CREATE TABLE', part, flags=re.MULTILINE | re.IGNORECASE)
                part = re.sub('^DROP VIEW', 'DROP TABLE', part, flags=re.MULTILINE | re.IGNORECASE)
            cursor.execute('/* kingfisher-views refresh-views */\n' + part)
            commit()

        logger.info('Time: %ss', timer() - file_timer)

    logger.info('Total time: %ss', timer() - command_timer)


def _run_collection(collection):
    logger = logging.getLogger('ocdskingfisher.views.field-counts')
    logger.info('Processing collection ID %s', collection)

    collection_timer = timer()

    cursor.execute('SET parallel_tuple_cost = 0.00001')
    cursor.execute('SET parallel_setup_cost = 0.00001')
    cursor.execute("SET work_mem = '10MB'")
    cursor.execute("""
        /* kingfisher-views field-counts */

        SELECT
            collection_id,
            release_type,
            path,
            sum(object_property) object_property,
            sum(array_item) array_count,
            count(distinct id) distinct_releases
        FROM
            release_summary
        CROSS JOIN
            flatten(release)
        WHERE
            release_summary.collection_id = %(id)s
        GROUP BY collection_id, release_type, path
    """, {'id': collection})

    execute_values(cursor, 'INSERT INTO field_counts_tmp VALUES %s', cursor.fetchall())
    commit()

    logger.info('Time for collection ID %s: %ss', collection, timer() - collection_timer)


@click.command()
@click.argument('name', callback=validate_name)
@click.option('--remove', is_flag=True, help='Drop the field_counts table from the schema')
def field_counts(name, remove):
    """
    Creates (or re-creates) the field_counts table in a schema.

    NAME is the last part of a schema's name after "view_data_".
    """
    logger = logging.getLogger('ocdskingfisher.views.field-counts')
    logger.info('Arguments: name=%s remove=%s', name, remove)

    cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                   "AND table_name = 'release_summary'", {'schema': name})
    if not cursor.fetchone():
        raise click.UsageError('release_summary table not found. Run refresh-views first.')

    set_search_path([name, 'public'])

    if remove:
        cursor.execute('DROP TABLE IF EXISTS field_counts_tmp')
        cursor.execute('DROP TABLE IF EXISTS field_counts')
        commit()

        logger.info('Dropped tables field_counts and field_counts_tmp')
        return

    command_timer = timer()

    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', 'sql', 'extras', 'flatten.sql')) as f:
        cursor.execute(f.read())
    cursor.execute('DROP TABLE IF EXISTS field_counts_tmp')
    cursor.execute("""
        CREATE TABLE field_counts_tmp (
            collection_id bigint,
            release_type text,
            path text,
            object_property bigint,
            array_count bigint,
            distinct_releases bigint
        )
    """)
    commit()

    selected_collections = pluck('SELECT id FROM selected_collections')
    with concurrent.futures.ProcessPoolExecutor() as executor:
        futures = [executor.submit(_run_collection, collection) for collection in selected_collections]
        for future in concurrent.futures.as_completed(futures):
            future.result()

    cursor.execute('DROP TABLE IF EXISTS field_counts')
    cursor.execute('ALTER TABLE field_counts_tmp RENAME TO field_counts')
    cursor.execute("COMMENT ON COLUMN field_counts.collection_id IS "
                   "'id from the kingfisher collection table'")
    cursor.execute("COMMENT ON COLUMN field_counts.release_type IS "
                   "'Either release, compiled_release or record. compiled_release are releases generated "
                   "by kingfisher release compilation'")
    cursor.execute("COMMENT ON COLUMN field_counts.path IS 'JSON path of the field'")
    cursor.execute("COMMENT ON COLUMN field_counts.object_property IS "
                   "'The total number of times the field at this path appears'")
    cursor.execute("COMMENT ON COLUMN field_counts.array_count IS "
                   "'For arrays, the total number of items in this array across all releases'")
    cursor.execute("COMMENT ON COLUMN field_counts.distinct_releases IS "
                   "'The total number of distinct releases in which the field at this path appears'")
    commit()

    logger.info('Total time: %ss', timer() - command_timer)


@click.command()
def correct_user_permissions():
    """
    Grants the users in the views.read_only_user table the USAGE privilege on the public, views and collection-specific
    schemas, and the SELECT privilege on public tables, the views.mapping_sheets table, and collection-specific tables.
    """
    schemas = [sql.Identifier(schema) for schema in get_schemas()]

    for user in pluck('SELECT username FROM views.read_only_user'):
        user = sql.Identifier(user)

        # Grant access to all tables in the public schema.
        cursor.execute(sql.SQL('GRANT USAGE ON SCHEMA public TO {user}').format(user=user))
        cursor.execute(sql.SQL('GRANT SELECT ON ALL TABLES IN SCHEMA public TO {user}').format(user=user))

        # Grant access to the mapping_sheets table in the views schema.
        cursor.execute(sql.SQL('GRANT USAGE ON SCHEMA views TO {user}').format(user=user))
        cursor.execute(sql.SQL('GRANT SELECT ON views.mapping_sheets TO {user}').format(user=user))

        # Grant access to all tables in every schema created by Kingfisher Views.
        for schema in schemas:
            cursor.execute(sql.SQL('GRANT USAGE ON SCHEMA {schema} TO {user}').format(schema=schema, user=user))
            cursor.execute(sql.SQL('GRANT SELECT ON ALL TABLES IN SCHEMA {schema} TO {user}').format(
                schema=schema, user=user))

    commit()


@click.command()
@click.argument('name', callback=validate_name)
def docs_table_ref(name):
    """
    Creates or updates the CSV files in docs/definitions.
    """
    tables = []
    for basename, content in _read_sql_files().items():
        for table in re.findall(r'^CREATE\s+(?:TABLE|VIEW)\s+(\S+)', content, flags=re.MULTILINE | re.IGNORECASE):
            if not table.startswith('tmp_'):
                tables.append(table)
    tables.append('field_counts')

    headers = ['Column Name', 'Data Type', 'Description']

    statement = """
        SELECT
            isc.column_name,
            isc.data_type,
            pg_catalog.col_description(format('%%s.%%s', isc.table_schema,isc.table_name)::regclass::oid,
                                       isc.ordinal_position) AS column_description
        FROM
            information_schema.columns isc
        WHERE
            table_schema = %(schema)s AND LOWER(isc.table_name) = LOWER(%(table)s)
    """

    filename = os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', 'docs', 'definitions', '{}.csv')
    for table in tables:
        with open(filename.format(table), 'w') as f:
            writer = csv.writer(f, lineterminator='\n')
            writer.writerow(headers)

            cursor.execute(statement, {'schema': name, 'table': table})
            for row in cursor.fetchall():
                # Change "timestamp without time zone" (and  "timestamp with time zone") to "timestamp".
                if 'timestamp' in row[1]:
                    row = list(row)
                    row[1] = 'timestamp'
                writer.writerow(row)


cli.add_command(add_view)
cli.add_command(correct_user_permissions)
cli.add_command(delete_view)
cli.add_command(docs_table_ref)
cli.add_command(field_counts)
cli.add_command(install)
cli.add_command(list_views)
cli.add_command(refresh_views)
