#!/usr/bin/env python
import concurrent.futures
import csv
import glob
import json
import logging
import logging.config
import os
import re
from collections import defaultdict, namedtuple
from datetime import datetime
from time import time

import click
from dotenv import load_dotenv
from psycopg2 import sql
from tabulate import tabulate

from ocdskingfishersummarize.db import Database
from ocdskingfishersummarize.exceptions import AmbiguousSourceError

global db

flags = re.MULTILINE | re.IGNORECASE
basedir = os.path.dirname(os.path.realpath(__file__))

Summary = namedtuple('Summary', 'name primary_keys data_column is_table')

SUMMARIES = [
    Summary('award_documents_summary', ['id', 'award_index', 'document_index'], 'document', True),
    Summary('award_items_summary', ['id', 'award_index', 'item_index'], 'item', True),
    Summary('award_suppliers_summary', ['id', 'award_index', 'supplier_index'], 'supplier', True),
    Summary('awards_summary', ['id', 'award_index'], 'award', False),
    Summary('buyer_summary', ['id'], 'buyer', True),
    Summary('contract_documents_summary', ['id', 'contract_index', 'document_index'], 'document', True),
    Summary('contract_implementation_documents_summary',
            ['id', 'contract_index', 'document_index'], 'document', True),
    Summary('contract_implementation_milestones_summary',
            ['id', 'contract_index', 'milestone_index'], 'milestone', True),
    Summary('contract_implementation_transactions_summary',
            ['id', 'contract_index', 'transaction_index'], 'transaction', True),
    Summary('contract_items_summary', ['id', 'contract_index', 'item_index'], 'item', True),
    Summary('contract_milestones_summary', ['id', 'contract_index', 'milestone_index'], 'milestone', True),
    Summary('contracts_summary', ['id', 'contract_index'], 'contract', False),
    Summary('parties_summary', ['id', 'party_index'], 'party', False),
    Summary('planning_documents_summary', ['id', 'document_index'], 'document', True),
    Summary('planning_milestones_summary', ['id', 'milestone_index'], 'milestone', True),
    Summary('planning_summary', ['id'], 'planning', False),
    Summary('procuringentity_summary', ['id'], 'procuringentity', True),
    Summary('release_summary', ['id'], 'release', False),
    Summary('tender_documents_summary', ['id'], 'document', True),
    Summary('tender_items_summary', ['id', 'item_index'], 'item', True),
    Summary('tender_milestones_summary', ['id', 'milestone_index'], 'milestone', True),
    Summary('tender_summary', ['id'], 'tender', False),
    Summary('tenderers_summary', ['id', 'tenderer_index'], 'tenderer', True),
]

COLUMN_COMMENTS_SQL = """
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


def sql_files(directory, tables_only=False):
    """
    Returns a dict in which the key is the identifier of a SQL file and the value is its content.

    :param str directory: a sub-directory containing SQL files
    :param bool tables_only: whether to create SQL tables instead of SQL views
    """
    files = {}

    filenames = glob.glob(os.path.join(basedir, 'sql', directory, '*.sql'))
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
                       :func:`~manage.sql_files`
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
        # Kingfisher Summarize
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
    Returns a schema suffix. Raises an error if the suffix isn't lowercase.
    """
    if value and value != value.lower():
        raise click.BadParameter(f'value must be lowercase')

    return value


def validate_schema(ctx, param, value):
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

    path = os.path.join(click.get_app_dir('Kingfisher Summarize'), 'logging.json')
    if os.path.isfile(path):
        with open(path) as f:
            logging.config.dictConfig(json.load(f))
    # Python's root logger only prints warning and above.
    else:
        logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)

    logger = logging.getLogger('ocdskingfisher.summarize.cli')
    logger.info('Running %s', ctx.invoked_subcommand)

    global db
    db = Database()


@click.command()
@click.argument('collections', callback=validate_collections)
@click.argument('note')
@click.option('--name', callback=validate_name,
              help='A custom name for the SQL schema ("view_data_" will be prepended).')
@click.option('--tables-only', is_flag=True, help='Create SQL tables instead of SQL views.')
@click.option('--field-counts/--no-field-counts', 'field_counts_option', default=True,
              help="Whether to create the field_counts table (default true).")
@click.option('--field-lists/--no-field-lists', 'field_lists_option', default=False,
              help="Whether to add a field_list column to all summary tables (default false).")
@click.pass_context
def add(ctx, collections, note, name, tables_only, field_counts_option, field_lists_option):
    """
    Creates a schema containing summary tables about one or more collections.

    \b
    COLLECTIONS is one or more comma-separated collection IDs
    NOTE is your name and a description of your purpose
    """
    logger = logging.getLogger('ocdskingfisher.summarize.add')
    logger.info('Arguments: collections=%s note=%s name=%s tables_only=%s',
                collections, note, name, tables_only)

    if not name:
        if len(collections) > 5:
            raise click.UsageError('--name is required for more than 5 collections')
        name = f"collection_{'_'.join(str(_id) for _id in sorted(collections))}"

    schema = f'view_data_{name}'
    db.execute('CREATE SCHEMA {schema}', schema=schema)
    db.set_search_path([schema])

    db.execute('CREATE TABLE selected_collections (id INTEGER PRIMARY KEY)')
    db.execute_values('INSERT INTO selected_collections (id) VALUES %s', [(_id,) for _id in collections])

    db.execute('CREATE TABLE note (id SERIAL, note TEXT NOT NULL, created_at TIMESTAMP WITHOUT TIME ZONE)')
    db.execute('INSERT INTO note (note, created_at) VALUES (%(note)s, %(created_at)s)',
               {'note': note, 'created_at': datetime.utcnow()})

    # https://github.com/open-contracting/kingfisher-summarize/issues/92
    db.execute('ANALYZE selected_collections')
    db.commit()

    logger.info('Added %s', name)

    logger.info('Running summary-tables routine')
    summary_tables(schema, tables_only=tables_only)

    if field_counts_option:
        logger.info('Running field-counts routine')
        field_counts(schema)

    if field_lists_option:
        logger.info('Running field-lists routine')
        field_lists(schema, tables_only=tables_only)

    role = os.getenv('KINGFISHER_SUMMARIZE_READONLY_ROLE', '')
    if db.one("SELECT 1 FROM pg_roles WHERE rolname = %(role)s", {'role': role}):
        db.execute('GRANT USAGE ON SCHEMA {schema} TO {role}', schema=schema, role=role)
        db.execute('GRANT SELECT ON ALL TABLES IN SCHEMA {schema} TO {role}', schema=schema, role=role)
        db.commit()

        logger.info('Configured read-only access to %s', name)


@click.command()
@click.argument('name', callback=validate_schema)
def remove(name):
    """
    Drops a schema.

    NAME is the last part of a schema's name after "view_data_".
    """
    logger = logging.getLogger('ocdskingfisher.summarize.remove')
    logger.info('Arguments: name=%s', name)

    # `CASCADE` drops all objects (tables, functions, etc.) in the schema.
    statement = db.format('DROP SCHEMA {schema} CASCADE', schema=name)
    db.execute(statement)
    db.commit()

    logger.info(statement.as_string(db.connection))


@click.command()
def index():
    """
    Lists the schemas, with collection IDs and creator's notes.
    """
    def format_note(note):
        return f"{note[0]} ({note[1].strftime('%Y-%m-%d %H:%M:%S')})"

    table = []
    for schema in db.schemas():
        db.set_search_path([schema])

        collections = map(str, db.pluck('SELECT id FROM selected_collections ORDER BY id'))
        notes = db.all('SELECT note, created_at FROM note ORDER BY created_at')

        table.append([schema[10:], ', '.join(collections), format_note(notes[0])])
        for note in notes[1:]:
            table.append([None, None, format_note(note)])

    if table:
        click.echo(tabulate(table, headers=['Name', 'Collections', 'Note'], tablefmt='github', numalign='left'))


def _run_file(name, identifier, content):
    logger = logging.getLogger('ocdskingfisher.summarize.summary-tables')
    logger.info(f'Processing {identifier}')

    start = time()

    db = Database()
    db.set_search_path([name, 'public'])

    db.execute(f'/* kingfisher-summarize {identifier} */\n' + content)
    db.commit()

    logger.info('%s: %ss', identifier, time() - start)


def summary_tables(name, tables_only=False):
    """
    Creates the summary tables in a schema.

    :param str name: the schema's name
    :param boolean tables_only: whether to create SQL tables instead of SQL views
    """
    logger = logging.getLogger('ocdskingfisher.summarize.summary-tables')

    start = time()

    files = {directory: sql_files(directory, tables_only=tables_only) for directory in ('initial', 'middle', 'final')}
    graph = dependency_graph(files['middle'])

    def run(directory):
        """
        Runs the files in a directory in sequence.

        :param str directory: a sub-directory containing SQL files
        """
        for identifier, content in files[directory].items():
            _run_file(name, identifier, content)

    def submit(identifier):
        """
        If a file's dependencies are met, removes it from the dependency graph and submits it.

        :param str identifier: the identifier of a SQL file
        """
        if not graph[identifier]:
            graph.pop(identifier)
            futures[executor.submit(_run_file, name, identifier, files['middle'][identifier])] = identifier

    # The initial files are fast, and don't need multiprocessing.
    run('initial')

    futures = {}
    with concurrent.futures.ProcessPoolExecutor() as executor:
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


def _run_field_counts(name, collection_id):
    logger = logging.getLogger('ocdskingfisher.summarize.field-counts')
    logger.info('Processing collection ID %s', collection_id)

    start = time()

    db = Database()
    db.set_search_path([name, 'public'])

    db.execute_values('INSERT INTO field_counts VALUES %s', db.all("""
        /* kingfisher-summarize field-counts */

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

    :param str name: the schema's name
    """
    logger = logging.getLogger('ocdskingfisher.summarize.field-counts')

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
        futures = [executor.submit(_run_field_counts, name, collection) for collection in selected_collections]
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


def _run_field_lists(name, table, tables_only):
    logger = logging.getLogger('ocdskingfisher.summarize.field-lists')
    logger.info(f'Processing {table.name}')

    start = time()

    db = Database()
    db.set_search_path([name, 'public'])

    summary_table = table.name
    field_list_table = f'{summary_table}_field_list'
    no_field_list_table = f'{summary_table}_no_field_list'

    if tables_only:
        no_field_list_type = sql.SQL('TABLE')
        final_summary_type = sql.SQL('TABLE')
    else:
        no_field_list_type = sql.SQL('TABLE' if table.is_table else 'VIEW')
        final_summary_type = sql.SQL('VIEW')

    # Create a *_field_list table, add a unique index, rename the *_summary table to *_no_field_list, and re-create
    # the *_summary table. Then, copy the comments from the old to the new *_summary table.

    # Use jsonb_object_agg instead of array_agg so that paths are unique, and so that queries against the field use the
    # faster "in" operator for objects (?&) than for arrays (@>).
    statement = """
        CREATE TABLE {field_list_table} AS
        SELECT
            {primary_keys},
            jsonb_object_agg(path, NULL) AS field_list
        FROM
            {summary_table}
        CROSS JOIN
            flatten({summary_table}.{data_column})
        GROUP BY
            {primary_keys}
    """
    db.execute(statement, summary_table=summary_table, field_list_table=field_list_table,
               data_column=table.data_column, primary_keys=table.primary_keys)

    statement = 'CREATE UNIQUE INDEX {index} ON {field_list_table}({primary_keys})'
    db.execute(statement, index=f'{field_list_table}_id', field_list_table=field_list_table,
               primary_keys=table.primary_keys)

    statement = 'ALTER {no_field_list_type} {summary_table} RENAME TO {no_field_list_table}'
    db.execute(statement, no_field_list_type=no_field_list_type, summary_table=summary_table,
               no_field_list_table=no_field_list_table)

    statement = """
        CREATE {final_summary_type} {summary_table} AS
        SELECT
            {no_field_list_table}.*,
            {field_list_table}.field_list
        FROM
            {no_field_list_table}
        JOIN
            {field_list_table} USING ({primary_keys})
    """
    db.execute(statement, final_summary_type=final_summary_type, summary_table=summary_table,
               no_field_list_table=no_field_list_table, field_list_table=field_list_table,
               primary_keys=table.primary_keys)

    for row in db.all(COLUMN_COMMENTS_SQL, {'schema': name, 'table': f'{table.name}_no_field_list'}):
        statement = 'COMMENT ON COLUMN {table}.{column} IS %(comment)s'
        db.execute(statement, {'comment': row[2]}, table=table.name, column=row[0])

    comment = f'All JSON paths in the {table.data_column} object, excluding array indices, expressed as a JSONB ' \
              'object in which keys are paths and values are NULL. This column is only available if the --field-' \
              'lists option was used.'
    db.execute('COMMENT ON COLUMN {table}.field_list IS %(comment)s', {'comment': comment}, table=table.name)

    db.commit()

    logger.info('%s: %ss', table.name, time() - start)


def field_lists(name, tables_only=False):
    """
    Adds the field_list column on all summary tables.

    :param str name: the schema's name
    :param bool tables_only: whether to create SQL tables instead of SQL views
    """
    logger = logging.getLogger('ocdskingfisher.summarize.field-lists')

    start = time()

    with concurrent.futures.ProcessPoolExecutor() as executor:
        futures = [executor.submit(_run_field_lists, name, table, tables_only) for table in SUMMARIES]
        for future in concurrent.futures.as_completed(futures):
            future.result()

    logger.info('Total time: %ss', time() - start)


@click.command()
@click.argument('name', callback=validate_schema)
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

    filename = os.path.join(basedir, 'docs', 'definitions', '{}.csv')
    for table in tables:
        with open(filename.format(table), 'w') as f:
            writer = csv.writer(f, lineterminator='\n')
            writer.writerow(headers)

            for row in db.all(COLUMN_COMMENTS_SQL, {'schema': name, 'table': table}):
                # Change "timestamp without time zone" (and  "timestamp with time zone") to "timestamp".
                if 'timestamp' in row[1]:
                    row = list(row)
                    row[1] = 'timestamp'
                writer.writerow(row)


cli.add_command(add)
cli.add_command(remove)
cli.add_command(index)
cli.add_command(docs_table_ref)

if __name__ == '__main__':
    cli()
