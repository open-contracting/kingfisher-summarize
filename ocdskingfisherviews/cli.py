import concurrent.futures
import csv
import glob
import json
import logging
import logging.config
import os
import re
from collections import defaultdict
from datetime import datetime
from time import time

import click
from dotenv import load_dotenv
from psycopg2 import sql
from tabulate import tabulate

from ocdskingfisherviews.db import Database
from ocdskingfisherviews.exceptions import AmbiguousSourceError

global db

flags = re.MULTILINE | re.IGNORECASE
basedir = os.path.dirname(os.path.realpath(__file__))


def sql_files(directory, tables_only=False):
    """
    Returns a dict in which the key is the identifier of a SQL file and the value is its content.

    :param str directory: a sub-directory containing SQL files
    :param bool tables_only: whether to create SQL tables instead of SQL views
    """
    files = {}

    filenames = glob.glob(os.path.join(basedir, '..', 'sql', directory, '*.sql'))
    for filename in filenames:
        identifier = f'{directory}:{os.path.splitext(os.path.basename(filename))[0]}'
        with open(filename) as f:
            content = f.read()
        if tables_only:
            content = re.sub(r'^(CREATE|DROP) VIEW', r'\1 TABLE', content, flags=flags)
        files[identifier] = content

    return files


def dependency_graph(files):
    """
    Returns a dict in which the key is the identifier of a SQL file and the value is the set of identifiers of SQL
    files on which that SQL file depends.

    :param dict files: the identifiers and contents of SQL files, as returned by
                       :func:`~ocdskingfisherviews.cli.sql_files`
    """
    # These dependencies are always met.
    ignore = {
        # PostgreSQL
        'jsonb_array_elements',
        'jsonb_array_elements_text',
        # Kingfisher Process
        'collection',
        'compiled_release',
        'data',
        'package_data',
        'record',
        'record_check',
        'release',
        'release_check',
        # Kingfisher Views
        'selected_collections',
    }

    # The key is a table/view, and the value is the file by which it is created.
    sources = {}

    # The key is a file, and the value is the set of tables/views it requires.
    imports = defaultdict(set)
    for identifier, content in files.items():
        # The set of tables/views this file creates.
        exports = set()
        for object_name in re.findall(r'\bCREATE\s+(?:TABLE|VIEW)\s+(\w+)', content, flags=flags):
            exports.add(object_name)

        # The set of tables/views this file requires, minus temporary tables, created tables and common dependencies.
        for object_name in re.findall(r'\b(?:FROM|JOIN)\s+(\w+)', content, flags=re.MULTILINE):
            imports[identifier].add(object_name)
        for object_name in re.findall(r'\bWITH\s+(\w+)\s+AS', content, flags=re.MULTILINE):
            imports[identifier].discard(object_name)
        imports[identifier].difference_update(exports | ignore)

        # Removes temporary tables from the file's exports. This assumes tables aren't dropped before being created.
        # If that were the case, we could do line-by-line parsing, to calculate which tables remain.
        for object_name in re.findall(r'\bDROP\s+(?:TABLE|VIEW)\s+(\w+)', content, flags=flags):
            exports.discard(object_name)

        # Add the file's exports to the `sources` variable.
        for object_name in exports:
            if object_name in sources:
                raise AmbiguousSourceError(f'{object_name} in {sources[object_name]} and {identifier}')
            sources[object_name] = identifier

    # Build the dependency graph between files.
    graph = {}
    for identifier, object_names in imports.items():
        graph[identifier] = set(sources[object_name] for object_name in object_names)

    return graph


def validate_collections(ctx, param, value):
    """
    Returns a list of collection IDs. Raises an error if an ID isn't in the collection table.
    """
    try:
        ids = tuple(int(_id) for _id in value.split(','))
    except ValueError:
        raise click.BadParameter(f'Collection IDs must be integers')

    difference = set(ids) - set(db.pluck('SELECT id FROM collection WHERE id IN %(ids)s', {'ids': ids}))
    if difference:
        raise click.BadParameter(f'Collection IDs {difference} not found')

    return ids


def validate_name(ctx, param, value):
    """
    Returns a schema name. Raises an error if the schema isn't in the database.
    """
    schema = f'view_data_{value}'

    if not db.schema_exists(schema):
        raise click.BadParameter(f'SQL schema "{schema}" not found')

    return schema


@click.group()
@click.pass_context
def cli(ctx):
    load_dotenv()

    path = os.path.expanduser('~/.config/ocdskingfisher-views/logging.json')
    if os.path.isfile(path):
        with open(path) as f:
            logging.config.dictConfig(json.load(f))
    # Python's root logger only prints warning and above.
    else:
        logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)

    logger = logging.getLogger('ocdskingfisher.views.cli')
    logger.info('Running %s', ctx.invoked_subcommand)

    global db
    db = Database()


@click.command()
def install():
    """
    Creates the views schema and the read_only_user and mapping_sheets tables within it, if they don't exist.
    """
    logger = logging.getLogger('ocdskingfisher.views.install')

    db.execute('CREATE TABLE IF NOT EXISTS views.read_only_user(username VARCHAR(64) NOT NULL PRIMARY KEY)')
    db.execute("""
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

    if not db.one('SELECT EXISTS(SELECT 1 FROM views.mapping_sheets)')[0]:
        filename = os.path.join(basedir, '1-1-3.csv')
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
        db.execute_values(statement, values)

    db.commit()

    logger.info('Created tables')


@click.command()
@click.argument('collections', callback=validate_collections)
@click.argument('note')
@click.option('--name', help='A custom name for the SQL schema ("view_data_" will be prepended).')
@click.option('--tables-only', is_flag=True, help='Create SQL tables instead of SQL views.')
@click.option('--field-counts/--no-field-counts', 'field_counts_option', default=True,
              help="Whether to create the field_counts table (default true).")
@click.pass_context
def add_view(ctx, collections, note, name, tables_only, field_counts_option):
    """
    Creates a schema containing summary tables about one or more collections.

    \b
    COLLECTIONS is one or more comma-separated collection IDs
    NOTE is your name and a description of your purpose
    """
    logger = logging.getLogger('ocdskingfisher.views.add-view')
    logger.info('Arguments: collections=%s note=%s name=%s tables_only=%s',
                collections, note, name, tables_only)

    if not name:
        if len(collections) > 5:
            raise click.UsageError('--name is required for more than 5 collections')
        name = f"collection_{'_'.join(str(_id) for _id in sorted(collections))}"

    schema = f'view_data_{name}'
    db.execute(sql.SQL('CREATE SCHEMA {schema}').format(schema=sql.Identifier(schema)))
    db.set_search_path([schema])

    db.execute('CREATE TABLE selected_collections (id INTEGER PRIMARY KEY)')
    db.execute_values('INSERT INTO selected_collections (id) VALUES %s', [(_id,) for _id in collections])

    db.execute('CREATE TABLE note (id SERIAL, note TEXT NOT NULL, created_at TIMESTAMP WITHOUT TIME ZONE)')
    db.execute(sql.SQL('INSERT INTO note (note, created_at) VALUES (%(note)s, %(at)s)'),
               {'note': note, 'at': datetime.utcnow()})

    db.execute('ANALYZE selected_collections')
    db.commit()

    logger.info('Added %s', name)

    logger.info('Running refresh-views routine')
    refresh_views(schema, tables_only=tables_only)

    if field_counts_option:
        logger.info('Running field-counts routine')
        field_counts(schema)

    logger.info('Running correct-user-permissions command')
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
    db.execute(statement)
    db.commit()

    logger.info(statement.as_string(db.connection))


@click.command()
def list_views():
    """
    Lists the schemas, with collection IDs and creator's notes.
    """
    def format_note(note):
        return f"{note[0]} ({note[1].strftime('%Y-%m-%d %H:%M:%S')})"

    for schema in db.schemas():
        db.set_search_path([schema])

        collections = map(str, db.pluck('SELECT id FROM selected_collections ORDER BY id'))
        notes = db.all('SELECT note, created_at FROM note ORDER BY created_at')

        table = [[schema[10:], ', '.join(collections), format_note(notes[0])]]
        for note in notes[1:]:
            table.append([None, None, format_note(note)])

        click.echo(tabulate(table, headers=['Name', 'Collections', 'Note'], tablefmt='github', numalign='left'))


def _run_file(name, identifier, content):
    logger = logging.getLogger('ocdskingfisher.views.refresh-views')
    logger.info(f'Processing {identifier}')

    start = time()

    db = Database()
    db.set_search_path([name, 'public'])
    db.execute(f'/* kingfisher-views {identifier} */\n' + content)
    db.commit()

    logger.info('%s: %ss', identifier, time() - start)


def refresh_views(name, tables_only=False):
    """
    Creates the summary tables in a schema.

    :param str name: the last part of a schema's name after "view_data_"
    :param boolean tables_only: whether to create SQL tables instead of SQL views
    """
    logger = logging.getLogger('ocdskingfisher.views.refresh-views')

    db.set_search_path([name, 'public'])

    start = time()

    files = {directory: sql_files(directory, tables_only=tables_only) for directory in ('initial', 'middle', 'final')}
    graph = dependency_graph(files['middle'])

    def run(directory):
        """
        Runs the files in a directory in sequence.

        :param str directory: a sub-directory containing SQL files
        """
        for identifier, content in files[directory].items():
            logger.info(f'Processing {identifier}')
            _run_file(name, identifier, content)

    def submit(identifier):
        """
        If a file's dependencies are met, removes it from the dependency graph and submits it.

        :param str identifier: the identifier of a SQL file
        """
        if not graph[identifier]:
            graph.pop(identifier)
            futures[executor.submit(_run_file, name, identifier, files['middle'][identifier])] = identifier

    futures = {}
    with concurrent.futures.ProcessPoolExecutor() as executor:
        # The initial files are fast, and don't need multiprocessing.
        run('initial')

        # Submit files whose dependencies are met.
        for identifier in list(graph):
            submit(identifier)

        # The for-loop terminates after its given futures, so it needs to start again with new futures.
        while futures:
            for future in concurrent.futures.as_completed(futures):
                future.result()
                done = futures.pop(future)

                # Update dependencies, and submit files whose dependencies are met.
                for identifier in list(graph):
                    graph[identifier].discard(done)
                    submit(identifier)

        # The final files are fast, and can also deadlock.
        run('final')

    logger.info('Total time: %ss', time() - start)


def _run_collection(name, collection_id):
    logger = logging.getLogger('ocdskingfisher.views.refresh-views')
    logger.info('Processing collection ID %s', collection_id)

    start = time()

    db = Database()
    db.set_search_path([name, 'public'])
    db.execute('SET parallel_tuple_cost = 0.00001')
    db.execute('SET parallel_setup_cost = 0.00001')
    db.execute("SET work_mem = '10MB'")
    db.execute_values('INSERT INTO field_counts VALUES %s', db.all("""
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
            collection_id = %(id)s
        GROUP BY collection_id, release_type, path
    """, {'id': collection_id}))
    db.commit()

    logger.info('Collection ID %s: %ss', collection_id, time() - start)


def field_counts(name):
    """
    Creates the field_counts table in a schema.

    :param str name: the last part of a schema's name after "view_data_"
    """
    logger = logging.getLogger('ocdskingfisher.views.field-counts')

    db.set_search_path([name, 'public'])

    start = time()

    db.execute("""
        CREATE TABLE field_counts (
            collection_id bigint,
            release_type text,
            path text,
            object_property bigint,
            array_count bigint,
            distinct_releases bigint
        )
    """)
    db.commit()

    selected_collections = db.pluck('SELECT id FROM selected_collections')
    with concurrent.futures.ProcessPoolExecutor() as executor:
        futures = [executor.submit(_run_collection, name, collection) for collection in selected_collections]
        for future in concurrent.futures.as_completed(futures):
            future.result()

    db.execute("COMMENT ON COLUMN field_counts.collection_id IS 'id from the kingfisher collection table'")
    db.execute("COMMENT ON COLUMN field_counts.release_type IS 'Either release, compiled_release or record. "
               "compiled_release are releases generated by kingfisher release compilation'")
    db.execute("COMMENT ON COLUMN field_counts.path IS 'JSON path of the field'")
    db.execute("COMMENT ON COLUMN field_counts.object_property IS "
               "'The total number of times the field at this path appears'")
    db.execute("COMMENT ON COLUMN field_counts.array_count IS "
               "'For arrays, the total number of items in this array across all releases'")
    db.execute("COMMENT ON COLUMN field_counts.distinct_releases IS "
               "'The total number of distinct releases in which the field at this path appears'")
    db.commit()

    logger.info('Total time: %ss', time() - start)


@click.command()
def correct_user_permissions():
    """
    Grants the users in the views.read_only_user table the USAGE privilege on the public, views and collection-specific
    schemas, and the SELECT privilege on public tables, the views.mapping_sheets table, and collection-specific tables.
    """
    schemas = [sql.Identifier(schema) for schema in db.schemas()]

    for user in db.pluck('SELECT username FROM views.read_only_user INNER JOIN pg_roles ON rolname = username'):
        user = sql.Identifier(user)

        # Grant access to all tables in the public schema.
        db.execute(sql.SQL('GRANT USAGE ON SCHEMA public TO {user}').format(user=user))
        db.execute(sql.SQL('GRANT SELECT ON ALL TABLES IN SCHEMA public TO {user}').format(user=user))

        # Grant access to the mapping_sheets table in the views schema.
        db.execute(sql.SQL('GRANT USAGE ON SCHEMA views TO {user}').format(user=user))
        db.execute(sql.SQL('GRANT SELECT ON views.mapping_sheets TO {user}').format(user=user))

        # Grant access to all tables in every schema created by Kingfisher Views.
        for schema in schemas:
            db.execute(sql.SQL('GRANT USAGE ON SCHEMA {schema} TO {user}').format(schema=schema, user=user))
            db.execute(sql.SQL('GRANT SELECT ON ALL TABLES IN SCHEMA {schema} TO {user}').format(
                schema=schema, user=user))

    db.commit()


@click.command()
@click.argument('name', callback=validate_name)
def docs_table_ref(name):
    """
    Creates or updates the CSV files in docs/definitions.
    """
    tables = []
    for content in sql_files('middle').values():
        for table in re.findall(r'^CREATE\s+(?:TABLE|VIEW)\s+(\S+)', content, flags=flags):
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

    filename = os.path.join(basedir, '..', 'docs', 'definitions', '{}.csv')
    for table in tables:
        with open(filename.format(table), 'w') as f:
            writer = csv.writer(f, lineterminator='\n')
            writer.writerow(headers)

            for row in db.all(statement, {'schema': name, 'table': table}):
                # Change "timestamp without time zone" (and  "timestamp with time zone") to "timestamp".
                if 'timestamp' in row[1]:
                    row = list(row)
                    row[1] = 'timestamp'
                writer.writerow(row)


cli.add_command(add_view)
cli.add_command(correct_user_permissions)
cli.add_command(delete_view)
cli.add_command(docs_table_ref)
cli.add_command(install)
cli.add_command(list_views)
