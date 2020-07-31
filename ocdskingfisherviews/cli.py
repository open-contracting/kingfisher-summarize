import concurrent.futures
import csv
import glob
import json
import logging
import logging.config
import os.path
import re
from contextlib import contextmanager
from datetime import datetime
from timeit import default_timer as timer

import click
from psycopg2 import sql
from psycopg2.extras import execute_values

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
    else:
        logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)

    logger = logging.getLogger('ocdskingfisher.views.cli')
    logger.info(f'Running {ctx.invoked_subcommand}')

    global connection
    connection = get_connection()

    global cursor
    cursor = get_cursor()


@click.command()
@click.argument('collections', callback=validate_collections)
@click.argument('note')
@click.option('--name', help='A custom name for the SQL schema ("view_data_" will be prepended).')
@click.option('--dontbuild', is_flag=True, help="Don't run the refresh-views, field-counts and "
                                                "correct-user-permissions commands.")
@click.option('--tables-only', is_flag=True, help='Create SQL tables instead of SQL views.')
@click.option('--threads', type=int, default=1, help='The number of threads for the field-counts command to use '
                                                     '(up to the number of collections).')
@click.pass_context
def add_view(ctx, collections, note, name, dontbuild, tables_only, threads):
    """
    Creates a schema containing summary tables about one or more collections.

    \b
    COLLECTIONS is one or more comma-separated collection IDs
    NOTE is your name and a description of your purpose
    """
    logger = logging.getLogger('ocdskingfisher.views.add-view')

    if not name:
        if len(collections) > 5:
            raise click.UsageError('--name is required for more than 5 collections')
        name = f"collection_{'_'.join(str(_id) for _id in sorted(collections))}"

    schema = f'view_data_{name}'
    cursor.execute(sql.SQL('CREATE SCHEMA {schema}').format(schema=sql.Identifier(schema)))
    set_search_path([schema])

    cursor.execute('CREATE TABLE selected_collections(id INTEGER PRIMARY KEY)')
    execute_values(cursor, 'INSERT INTO selected_collections (id) VALUES %s', [(_id,) for _id in collections])

    cursor.execute('CREATE TABLE note(id SERIAL, note TEXT NOT NULL, created_at TIMESTAMP WITHOUT TIME ZONE)')
    cursor.execute(sql.SQL('INSERT INTO note (note, created_at) VALUES (%(note)s, %(at)s)'),
                   {'note': note, 'at': datetime.utcnow()})

    cursor.execute('ANALYZE selected_collections')
    commit()

    logger.info(f'Added {name}')

    if not dontbuild:
        message = [f'Running refresh-views {name}']
        if tables_only:
            message.append(' --tables-only')
        logger.info(''.join(message))
        ctx.invoke(refresh_views, name=schema, tables_only=tables_only)

        message = [f'Running field-counts {name}']
        if threads != 1:
            message.append(f' --threads {threads}')
        logger.info(''.join(message))
        ctx.invoke(field_counts, name=schema, threads=threads)

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
    for schema in get_schemas():
        click.echo(f'-----\nName: {schema[10:]}\nSchema: {schema}')

        cursor.execute(sql.SQL('SELECT id FROM {table} ORDER BY id').format(
            table=sql.Identifier(schema, 'selected_collections')))
        for row in cursor.fetchall():
            click.echo(f"Collection ID: {row[0]}")

        cursor.execute(sql.SQL('SELECT note, created_at FROM {table} ORDER BY created_at').format(
            table=sql.Identifier(schema, 'note')))
        for row in cursor.fetchall():
            click.echo(f"Note: {row[0]} ({row[1].strftime('%Y-%m-%d %H:%M:%S')})")


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
    set_search_path([name, 'public'])

    command_timer = timer()

    for basename, content in _read_sql_files(remove).items():
        file_timer = timer()
        logger.info(f'Running {basename}')

        for part in content.split('----'):
            if tables_only:
                part = re.sub('^CREATE VIEW', 'CREATE TABLE', part, flags=re.MULTILINE | re.IGNORECASE)
                part = re.sub('^DROP VIEW', 'DROP TABLE', part, flags=re.MULTILINE | re.IGNORECASE)
            cursor.execute('/* kingfisher-views refresh-views */\n' + part, tuple())
            commit()

        logger.info(f'Time: {timer() - file_timer}s')

    logger.info(f'Total time: {timer() - command_timer}s')


@click.command()
@click.argument('name', callback=validate_name)
@click.option('--remove', is_flag=True, help='Drop the field_counts table from the schema')
@click.option('--threads', type=int, default=1, help='The number of threads to use (up to the number of collections)')
def field_counts(name, remove, threads):
    """
    Creates (or re-creates) the field_counts table in a schema.

    NAME is the last part of a schema's name after "view_data_".
    """
    cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                   "AND table_name = 'release_summary_with_data'", {'schema': name})
    if not cursor.fetchone():
        raise click.UsageError('release_summary_with_data table not found. Run refresh-views first.')

    logger = logging.getLogger('ocdskingfisher.views.field-counts')
    set_search_path([name, 'public'])

    if remove:
        cursor.execute('DROP TABLE IF EXISTS field_counts_tmp')
        cursor.execute('DROP TABLE IF EXISTS field_counts')
        commit()

        logger.info('Dropped tables field_counts and field_counts_tmp')
        return

    def _run_collection(collection):
        logger.info(f'Processing collection ID {collection}')

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
                release_summary_with_data
            CROSS JOIN
                flatten(data)
            WHERE
                release_summary_with_data.collection_id = %(id)s
            GROUP BY collection_id, release_type, path
        """, {'id': collection})

        values = cursor.fetchone()
        if values:
            cursor.execute('INSERT INTO field_counts_tmp VALUES %(values)s', {'values': values})
            commit()
        else:
            logger.warning(f'No data for collection ID {collection}!')

        logger.info(f'Time for collection ID {collection}: {timer() - collection_timer}s')

    command_timer = timer()

    with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', 'sql', 'extras', 'flatten.sql')) as f:
        cursor.execute(f.read())
    cursor.execute('DROP TABLE IF EXISTS field_counts_tmp')
    cursor.execute("""
        CREATE TABLE field_counts_tmp(
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
    with concurrent.futures.ThreadPoolExecutor(max_workers=threads) as executor:
        futures = [executor.submit(_run_collection, collection) for collection in selected_collections]
        for future in concurrent.futures.as_completed(futures):
            future.result()

    cursor.execute('DROP TABLE IF EXISTS field_counts')
    cursor.execute('ALTER TABLE field_counts_tmp RENAME TO field_counts')
    cursor.execute("COMMENT ON COLUMN field_counts.collection_id IS "
                   "'id from the kingfisher collection table' ")
    cursor.execute("COMMENT ON COLUMN field_counts.release_type IS "
                   "'Either release, compiled_release or record. compiled_release are releases generated "
                   "by kingfisher release compilation' ")
    cursor.execute("COMMENT ON COLUMN field_counts.path IS 'JSON path of the field' ")
    cursor.execute("COMMENT ON COLUMN field_counts.object_property IS "
                   "'The total number of times the field at this path appears' ")
    cursor.execute("COMMENT ON COLUMN field_counts.array_count IS "
                   "'For arrays, the total number of items in this array across all releases' ")
    cursor.execute("COMMENT ON COLUMN field_counts.distinct_releases IS "
                   "'The total number of distinct releases in which the field at this path appears' ")
    commit()

    logger.info(f'Total time: {timer() - command_timer}s')


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
            if not table.startswith(('tmp_', 'staged_')) and not table.endswith('_no_data'):
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

    filename = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'docs', 'definitions', '{}.csv')
    for table in tables:
        with open(filename.format(table), 'w') as f:
            writer = csv.writer(f, lineterminator='\n')
            writer.writerow(headers)

            cursor.execute(statement, {'schema': name, 'table': table})
            for row in cursor.fetchall():
                if 'timestamp' in row[1]:
                    row[1] = 'timestamp'
                writer.writerow(row)


cli.add_command(add_view)
cli.add_command(correct_user_permissions)
cli.add_command(delete_view)
cli.add_command(docs_table_ref)
cli.add_command(field_counts)
cli.add_command(list_views)
cli.add_command(refresh_views)
