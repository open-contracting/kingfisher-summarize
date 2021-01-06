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

SummaryTable = namedtuple('SummaryTable', 'name primary_keys data_field is_table')

SUMMARY_TABLES = [
    SummaryTable('award_documents_summary', 'id, award_index, document_index', 'document', True),
    SummaryTable('award_items_summary', 'id, award_index, item_index', 'item', True),
    SummaryTable('award_suppliers_summary', 'id, award_index, supplier_index', 'supplier', True),
    SummaryTable('awards_summary', 'id, award_index', 'award', False),
    SummaryTable('buyer_summary', 'id', 'buyer', True),
    SummaryTable('contract_documents_summary', 'id, contract_index, document_index', 'document', True),
    SummaryTable('contract_implementation_documents_summary',
                 'id, contract_index, document_index', 'document', True),
    SummaryTable('contract_implementation_milestones_summary',
                 'id, contract_index, milestone_index', 'milestone', True),
    SummaryTable('contract_implementation_transactions_summary',
                 'id, contract_index, transaction_index', 'transaction', True),
    SummaryTable('contract_items_summary', 'id, contract_index, item_index', 'item', True),
    SummaryTable('contract_milestones_summary', 'id, contract_index, milestone_index', 'milestone', True),
    SummaryTable('contracts_summary', 'id, contract_index', 'contract', False),
    SummaryTable('parties_summary', 'id, party_index', 'party', False),
    SummaryTable('planning_documents_summary', 'id, document_index', 'document', True),
    SummaryTable('planning_milestones_summary', 'id, milestone_index', 'milestone', True),
    SummaryTable('planning_summary', 'id', 'planning', False),
    SummaryTable('procuringentity_summary', 'id', 'procuringentity', True),
    SummaryTable('release_summary', 'id', 'release', False),
    SummaryTable('tender_documents_summary', 'id', 'document', True),
    SummaryTable('tender_items_summary', 'id, item_index', 'item', True),
    SummaryTable('tender_milestones_summary', 'id, milestone_index', 'milestone', True),
    SummaryTable('tender_summary', 'id', 'tender', False),
    SummaryTable('tenderers_summary', 'id, tenderer_index', 'tenderer', True),
]


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
@click.option('--name', help='A custom name for the SQL schema ("view_data_" will be prepended).')
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
    db.execute(sql.SQL('CREATE SCHEMA {schema}').format(schema=sql.Identifier(schema)))
    db.set_search_path([schema])

    db.execute('CREATE TABLE selected_collections (id INTEGER PRIMARY KEY)')
    db.execute_values('INSERT INTO selected_collections (id) VALUES %s', [(_id,) for _id in collections])

    db.execute('CREATE TABLE note (id SERIAL, note TEXT NOT NULL, created_at TIMESTAMP WITHOUT TIME ZONE)')
    db.execute(sql.SQL('INSERT INTO note (note, created_at) VALUES (%(note)s, %(at)s)'),
               {'note': note, 'at': datetime.utcnow()})

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
        db.execute(sql.SQL('GRANT USAGE ON SCHEMA {schema} to {user}').format(schema=schema, user=user))
        db.execute(sql.SQL('GRANT SELECT ON ALL TABLES IN SCHEMA {schema} to {user}').format(schema=schema, user=user))
        db.commit()

        logger.info('Configured read-only access to %s', name)



@click.command()
@click.argument('name', callback=validate_name)
def remove(name):
    """
    Drops a schema.

    NAME is the last part of a schema's name after "view_data_".
    """
    logger = logging.getLogger('ocdskingfisher.summarize.remove')
    logger.info('Arguments: name=%s', name)

    # `CASCADE` drops all objects (tables, functions, etc.) in the schema.
    statement = sql.SQL('DROP SCHEMA {schema} CASCADE').format(schema=sql.Identifier(name))
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

    for schema in db.schemas():
        db.set_search_path([schema])

        collections = map(str, db.pluck('SELECT id FROM selected_collections ORDER BY id'))
        notes = db.all('SELECT note, created_at FROM note ORDER BY created_at')

        table = [[schema[10:], ', '.join(collections), format_note(notes[0])]]
        for note in notes[1:]:
            table.append([None, None, format_note(note)])

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

    :param str name: the last part of a schema's name after "view_data_"
    :param boolean tables_only: whether to create SQL tables instead of SQL views
    """
    logger = logging.getLogger('ocdskingfisher.summarize.summary-tables')

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


def _run_collection(name, collection_id):
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

    :param str name: the last part of a schema's name after "view_data_"
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


def _add_field_list_column(summary_table, tables_only):

    if tables_only or summary_table.is_table:
        relation_type = "TABLE"
    else:
        relation_type = "VIEW"

    # Use jsonb_object_agg instead of array_agg so that paths are unique, and so that queries against the field use the
    # faster "in" operator for objects (?&) than for arrays (@>).
    db.execute(f"""
        CREATE TABLE {summary_table.name}_field_list AS
        SELECT
            {summary_table.primary_keys},
            jsonb_object_agg(path, NULL) AS field_list
        FROM
            {summary_table.name}
        CROSS JOIN
            flatten({summary_table.name}.{summary_table.data_field})
        GROUP BY
            {summary_table.primary_keys};

        CREATE UNIQUE INDEX {summary_table.name}_field_list_keys ON
               {summary_table.name}_field_list({summary_table.primary_keys});

        ALTER {relation_type} {summary_table.name} RENAME TO {summary_table.name}_no_field_list;

        CREATE {'TABLE' if tables_only else 'VIEW'} {summary_table.name} AS
        SELECT
            {summary_table.name}_no_field_list.*,
            {summary_table.name}_field_list.field_list
        FROM
            {summary_table.name}_no_field_list
        JOIN
            {summary_table.name}_field_list USING ({summary_table.primary_keys});
    """)


def _add_field_list_comments(summary_table, name):

    statement = """
        SELECT
            isc.column_name,
            pg_catalog.col_description(format('%%s.%%s', isc.table_schema,isc.table_name)::regclass::oid,
                                       isc.ordinal_position) AS column_description
        FROM
            information_schema.columns isc
        WHERE
            table_schema = %(schema)s AND LOWER(isc.table_name) = LOWER(%(table)s)
    """

    for row in db.all(statement, {'schema': name, 'table': f'{summary_table.name}_no_field_list'}):
        db.execute(f'COMMENT ON COLUMN {summary_table.name}.{row[0]} IS %(comment)s', {'comment': row[1]})

    comment = (f'All JSON paths in the {summary_table.data_field} object, excluding array indices, expressed as '
               f'a JSONB object in which keys are paths and values are NULL. '
               f'This column is only available if the --field-lists option was used.')
    db.execute(f'COMMENT ON COLUMN {summary_table.name}.field_list IS %(comment)s', {'comment': comment})


def field_lists(name, tables_only=False):
    """
    Adds the field_list column on all summary tables.

    :param str name: the last part of a schema's name after "view_data_"
    :param bool tables_only: whether to create SQL tables instead of SQL views
    """
    logger = logging.getLogger('ocdskingfisher.summarize.field-lists')

    db.set_search_path([name, 'public'])

    start = time()

    for summary_table in SUMMARY_TABLES:
        _add_field_list_column(summary_table, tables_only)
        _add_field_list_comments(summary_table, name)

    logger.info('Total time: %ss', time() - start)


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

    filename = os.path.join(basedir, 'docs', 'definitions', '{}.csv')
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


cli.add_command(add)
cli.add_command(remove)
cli.add_command(index)
cli.add_command(docs_table_ref)

if __name__ == '__main__':
    cli()
