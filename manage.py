#!/usr/bin/env python
import concurrent.futures
import csv
import datetime
import glob
import hashlib
import json
import logging
import logging.config
import os
import re
from collections import defaultdict
from time import time
from typing import NamedTuple

import click
from dotenv import load_dotenv
from psycopg2 import sql
from tabulate import tabulate

from ocdskingfishersummarize.db import Database
from ocdskingfishersummarize.exceptions import AmbiguousSourceError

flags = re.MULTILINE | re.IGNORECASE
basedir = os.path.dirname(os.path.realpath(__file__))


class Summary(NamedTuple):
    primary_keys: list[str]
    data_column: str
    is_table: bool


SCHEMA_PREFIX = 'summary_'

MAX_COLLECTIONS = 5

SUMMARIES = {
    'award_documents_summary': Summary(['id', 'award_index', 'document_index'], 'document', is_table=True),
    'award_items_summary': Summary(['id', 'award_index', 'item_index'], 'item', is_table=True),
    'award_suppliers_summary': Summary(['id', 'award_index', 'supplier_index'], 'supplier', is_table=True),
    'awards_summary': Summary(['id', 'award_index'], 'award', is_table=False),
    'buyer_summary': Summary(['id'], 'buyer', is_table=True),
    'contract_documents_summary': Summary(['id', 'contract_index', 'document_index'], 'document', is_table=True),
    'contract_implementation_documents_summary': Summary(
        ['id', 'contract_index', 'document_index'], 'document', is_table=True
    ),
    'contract_implementation_milestones_summary': Summary(
        ['id', 'contract_index', 'milestone_index'], 'milestone', is_table=True
    ),
    'contract_implementation_transactions_summary': Summary(
        ['id', 'contract_index', 'transaction_index'], 'transaction', is_table=True
    ),
    'contract_items_summary': Summary(['id', 'contract_index', 'item_index'], 'item', is_table=True),
    'contract_milestones_summary': Summary(['id', 'contract_index', 'milestone_index'], 'milestone', is_table=True),
    'parties_summary': Summary(['id', 'party_index'], 'party', is_table=False),
    'planning_documents_summary': Summary(['id', 'document_index'], 'document', is_table=True),
    'planning_milestones_summary': Summary(['id', 'milestone_index'], 'milestone', is_table=True),
    'planning_summary': Summary(['id'], 'planning', is_table=False),
    'procuringentity_summary': Summary(['id'], 'procuringentity', is_table=True),
    'relatedprocesses_summary': Summary(['id', 'relatedprocess_index'], 'relatedprocess', is_table=True),
    'release_summary': Summary(['id'], 'release', is_table=False),
    'tender_documents_summary': Summary(['id'], 'document', is_table=True),
    'tender_items_summary': Summary(['id', 'item_index'], 'item', is_table=True),
    'tender_milestones_summary': Summary(['id', 'milestone_index'], 'milestone', is_table=True),
    'tender_summary': Summary(['id'], 'tender', is_table=False),
    'tenderers_summary': Summary(['id', 'tenderer_index'], 'tenderer', is_table=True),
    'contracts_summary': Summary(['id', 'contract_index'], 'contract', is_table=False),
}

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


def sql_files(directory, *, tables_only=False, where_fragment=None):
    """
    Return a dict in which the key is the identifier of a SQL file and the value is its content.

    :param str directory: a sub-directory containing SQL files
    :param bool tables_only: whether to create SQL tables instead of SQL views
    :param str where_fragment: part of a WHERE clause to use when selecting the data
    """
    files = {}

    for filename in glob.glob(os.path.join(basedir, 'sql', directory, '*.sql')):
        identifier = f'{directory}:{os.path.splitext(os.path.basename(filename))[0]}'
        with open(filename) as f:
            content = f.read()
        if tables_only:
            content = re.sub(r'^(CREATE|DROP) VIEW', r'\1 TABLE', content, flags=flags)
        if where_fragment:
            content = content.replace('--  WHEREFRAGMENT', where_fragment)
        files[identifier] = content

    return files


def _get_export_import_tables_from_functions(content):
    exports, imports = [], []

    for sub_group_name, object_name, group_name in re.findall(
        r'\bcreate_(\w+)\(\'(\w+)\', \'(\w+)\'', content, flags=re.MULTILINE
    ):
        if sub_group_name == 'parties':
            exports.append(f'{group_name}_summary')
            imports.append('parties_summary')
        else:
            exports.append(f'{object_name}_{sub_group_name}_summary')
            imports.append(f'tmp_{group_name}_summary')

    return exports, imports


def dependency_graph(files):
    """
    Return each SQL file's dependencies, as a dict.

    The key is the identifier of a SQL file and the value is the set of identifiers of SQL files
    on which that SQL file depends.

    :param dict files: the identifiers and contents of SQL files, as returned by :func:`~manage.sql_files`
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
        'summaries',
    }

    # The key is a table/view, and the value is the file by which it is created.
    sources = {}

    # The key is a file, and the value is the set of tables/views it requires.
    imports = defaultdict(set)
    for identifier, content in files.items():
        exports_from_function, imports_from_function = _get_export_import_tables_from_functions(content)

        # The set of tables/views this file creates.
        exports = set()
        for object_name in re.findall(r'\bCREATE\s+(?:TABLE|VIEW)\s+(\w+)', content, flags=flags):
            exports.add(object_name)
        exports.update(exports_from_function)

        # The set of tables/views this file requires, minus temporary tables, created tables and common dependencies.
        for object_name in re.findall(r'\b(?:FROM|JOIN)\s+(\w+)', content, flags=re.MULTILINE):
            imports[identifier].add(object_name)
        imports[identifier].update(imports_from_function)
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
        graph[identifier] = {sources[object_name] for object_name in object_names}

    return graph


def run_concurrently(graph, function, function_args):
    """
    Run functions concurrently, following a dependency graph.

    :param dict graph: a dict in which the key is a node and the value is the set of nodes on which it depends
    :param function: The function to call
    :param function_args: A function that returns the arguments for the function to call
    """

    def submit(node):
        """
        If a node's dependencies are met, remove it from the dependency graph and submit it.

        :param str node: the node in the graph
        """
        if not graph[node]:
            del graph[node]
            futures.add(executor.submit(function, *function_args(node)))

    futures = set()
    with concurrent.futures.ProcessPoolExecutor() as executor:
        # Submit files whose dependencies are met.
        for node in list(graph):
            submit(node)

        # The for-loop terminates after its given futures, so it needs to start again with new futures.
        while futures:
            for future in concurrent.futures.as_completed(futures):
                result = future.result()
                futures.remove(future)

                # Update dependencies, and submit files whose dependencies are met.
                for node in list(graph):
                    graph[node].discard(result)
                    submit(node)


def validate_collections(ctx, param, value):
    """Return a list of collection IDs. Raise an error if an ID isn't in the collection table."""
    try:
        ids = tuple(int(_id) for _id in value.split(','))
    except ValueError:
        raise click.BadParameter('Collection IDs must be integers') from None

    difference = set(ids) - set(db.pluck('SELECT id FROM collection WHERE id IN %(ids)s', {'ids': ids}))
    if difference:
        raise click.BadParameter(f'Collection IDs {difference} not found')

    return ids


def validate_name(ctx, param, value):
    """Return a schema suffix. Raise an error if the suffix isn't lowercase."""
    if value and value != value.lower():
        raise click.BadParameter('value must be lowercase')

    return value


def validate_schema(ctx, param, value):
    """Return a schema name. Raise an error if the schema isn't in the database."""
    schema = f'{SCHEMA_PREFIX}{value}'

    if not db.schema_exists(schema):
        raise click.BadParameter(f'SQL schema "{schema}" not found')

    return schema


def construct_where_fragment(cursor, filter_field, filter_value):
    """
    Return part of a WHERE clause, for the given filter parameters.

    :param cursor: a psycopg2 database cursor
    :param str filter_field: a period-separated field name, e.g. "tender.procurementMethod"
    :param str filter_value: the value of the specified field, e.g. "direct"
    """
    path = filter_field.split('.')
    format_string = ' AND d.data' + '->%s' * (len(path) - 1) + '->>%s = %s'
    where_fragment = cursor.mogrify(format_string, [*path, filter_value])
    return where_fragment.decode()


def construct_where_fragment_sql_json_path(cursor, filter_sql_json_path):
    """
    Return part of a WHERE clause, to filter on the given SQL/JSON Path Language expression.

    :param cursor: a psycopg2 database cursor
    :param str filter_sql_json_path: a SQL/JSON Path Language expression, e.g. '$.tender.procurementMethod == "direct"'
    """
    where_fragment = cursor.mogrify(' AND jsonb_path_match(d.data,  %s)', [filter_sql_json_path])
    return where_fragment.decode()


@click.group()
@click.option('-q', '--quiet', is_flag=True, help='Change the log level to warning')
@click.pass_context
def cli(ctx, quiet):
    """Configure the command-line interface."""
    load_dotenv()

    path = os.getenv(
        'KINGFISHER_SUMMARIZE_LOGGING_JSON',
        os.path.join(click.get_app_dir('Kingfisher Summarize'), 'logging.json')
    )
    if os.path.isfile(path):
        with open(path) as f:
            logging.config.dictConfig(json.load(f))
    # Python's root logger only prints warning and above.
    else:
        logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)

    if quiet:
        logging.getLogger('ocdskingfisher').setLevel(logging.WARNING)

    logger = logging.getLogger('ocdskingfisher.summarize.cli')
    logger.info('Running %s', ctx.invoked_subcommand)

    global db  # noqa: PLW0603
    db = Database()


@cli.command()
@click.argument('collections', callback=validate_collections)
@click.argument('note')
@click.option('--name', callback=validate_name,
              help=f'A custom name for the SQL schema ("{SCHEMA_PREFIX}" will be prepended).')
@click.option('--tables-only', is_flag=True, help='Create SQL tables instead of SQL views.')
@click.option('--field-counts/--no-field-counts', 'field_counts_option', default=True,
              help="Whether to create the field_counts table (default true).")
@click.option('--field-lists/--no-field-lists', 'field_lists_option', default=False,
              help="Whether to add a field_list column to all summary tables (default false).")
@click.option('--skip', multiple=True,
              help="Any SQL files to skip. Dependent files and final files will be skipped.")
@click.option('--filter', "filters", nargs=2, multiple=True,
              help="A field and value to filter by, like --filter tender.procurementMethod direct")
@click.option('--filter-sql-json-path', "filters_sql_json_path", multiple=True,
              help="A SQL/JSON Path Language expression to filter by, e.g. '$.tender.procurementMethod == \"direct\"'")
@click.pass_context
def add(ctx, collections, note, name, tables_only, field_counts_option, field_lists_option, skip, filters,
        filters_sql_json_path):
    """
    Create a schema containing summary tables about one or more collections.

    \b
    COLLECTIONS is one or more comma-separated collection IDs
    NOTE is your name and a description of your purpose
    """
    logger = logging.getLogger('ocdskingfisher.summarize.add')
    logger.info('Arguments: collections=%s note=%s name=%s tables_only=%s filters=%s filters_sql_json_path=%s',
                collections, note, name, tables_only, filters, filters_sql_json_path)

    if not name:
        if len(collections) > MAX_COLLECTIONS:
            raise click.UsageError(f'--name is required for more than {MAX_COLLECTIONS} collections')
        name = f"collection_{'_'.join(str(_id) for _id in sorted(collections))}"

    where_fragment = ''.join(
        [construct_where_fragment(db.cursor, field, value) for field, value in filters] +
        [construct_where_fragment_sql_json_path(db.cursor, filter_sjp) for filter_sjp in filters_sql_json_path]
    )

    schema = f'{SCHEMA_PREFIX}{name}'

    # Create the summaries.selected_collections table, if it doesn't exist.
    if not db.schema_exists('summaries'):
        db.execute('CREATE SCHEMA summaries')
    db.set_search_path(['summaries'])
    db.execute("""CREATE TABLE IF NOT EXISTS selected_collections
                  (schema TEXT NOT NULL, collection_id INTEGER NOT NULL)""")
    db.execute("""CREATE UNIQUE INDEX IF NOT EXISTS selected_collections_schema_collection_id
                  ON selected_collections (schema, collection_id)""")

    # Add the new summary's collections to the summaries.selected_collections table.
    db.execute_values('INSERT INTO selected_collections (schema, collection_id) VALUES %s',
                      [(schema, _id) for _id in collections])
    # https://github.com/open-contracting/kingfisher-summarize/issues/92
    db.execute('ANALYZE selected_collections')

    db.execute('CREATE SCHEMA {schema}', schema=schema)
    db.set_search_path([schema])

    db.execute('CREATE TABLE note (id SERIAL, note TEXT NOT NULL, created_at TIMESTAMP WITHOUT TIME ZONE)')
    db.execute('INSERT INTO note (note, created_at) VALUES (%(note)s, %(created_at)s)',
               {'note': note, 'created_at': datetime.datetime.now(tz=datetime.timezone.utc)})

    db.commit()

    logger.info('Added %s', name)

    logger.info('Running summary-tables routine')
    summary_tables(schema, tables_only=tables_only, skip=skip, where_fragment=where_fragment)

    if field_counts_option:
        logger.info('Running field-counts routine')
        field_counts(schema)

    if field_lists_option:
        logger.info('Running field-lists routine')
        field_lists(schema, tables_only=tables_only)

    role = os.getenv('KINGFISHER_SUMMARIZE_READONLY_ROLE', '')
    if db.one('SELECT 1 FROM pg_roles WHERE rolname = %(role)s', {'role': role}):
        db.execute('GRANT USAGE ON SCHEMA {schema} TO {role}', schema=schema, role=role)
        db.execute('GRANT SELECT ON ALL TABLES IN SCHEMA {schema} TO {role}', schema=schema, role=role)
        db.commit()

        logger.info('Configured read-only access to %s', name)


@cli.command()
@click.argument('name', callback=validate_schema)
def remove(name):
    """
    Drop a schema.

    NAME is the last part of a schema's name after "summary_".
    """  # SCHEMA_PREFIX
    logger = logging.getLogger('ocdskingfisher.summarize.remove')
    logger.info('Arguments: name=%s', name)

    db.execute('DELETE FROM summaries.selected_collections WHERE schema = %(schema)s', {'schema': name})

    # `CASCADE` drops all objects (tables, functions, etc.) in the schema.
    statement = db.format('DROP SCHEMA {schema} CASCADE', schema=name)
    db.execute(statement)
    db.commit()

    logger.info(statement.as_string(db.connection))


def _get_selected_collections(schema):
    statement = """
        SELECT collection_id FROM summaries.selected_collections WHERE schema = %(schema)s ORDER BY collection_id
    """
    return db.pluck(statement, {'schema': schema})


@cli.command()
def index():
    """List the schemas, with collection IDs and creator's notes."""
    def format_note(note):
        return f"{note[0]} ({note[1].strftime('%Y-%m-%d %H:%M:%S')})"

    table = []
    for schema in db.schemas():
        db.set_search_path([schema])

        collections = map(str, _get_selected_collections(schema))
        notes = db.all('SELECT note, created_at FROM note ORDER BY created_at')

        table.append([schema.removeprefix(SCHEMA_PREFIX), ', '.join(collections), format_note(notes[0])])
        table.extend([None, None, format_note(note)] for note in notes[1:])

    if table:
        click.echo(tabulate(table, headers=['Name', 'Collections', 'Note'], tablefmt='github', numalign='left'))


def _run_summary_tables(name, identifier, content):
    logger = logging.getLogger('ocdskingfisher.summarize.summary-tables')
    logger.info('Processing %s', identifier)

    start = time()

    db = Database()
    db.set_search_path([name, 'public'])

    db.execute(f'/* kingfisher-summarize {identifier} */\n' + content)
    db.commit()

    logger.info('%s: %ss', identifier, time() - start)
    return identifier


def summary_tables(name, *, tables_only=False, skip=(), where_fragment=None):
    """
    Create the summary tables in a schema.

    :param str name: the schema's name
    :param boolean tables_only: whether to create SQL tables instead of SQL views
    :param tuple skip: any SQL files to skip
    :param str where_fragment: part of a WHERE clause to use when selecting the data
    """
    logger = logging.getLogger('ocdskingfisher.summarize.summary-tables')

    start = time()

    files = {directory: sql_files(directory, tables_only=tables_only, where_fragment=where_fragment)
             for directory in ('initial', 'middle', 'final')}
    graph = dependency_graph(files['middle'])

    if skip:
        for basename in skip:
            del graph[f'middle:{basename}']
        files['final'] = {}

    def run(directory):
        """
        Run the files in a directory in sequence.

        :param str directory: a sub-directory containing SQL files
        """
        for identifier, content in files[directory].items():
            _run_summary_tables(name, identifier, content)

    # The initial files are fast, and don't need multiprocessing.
    run('initial')

    run_concurrently(graph, _run_summary_tables, lambda identifier: (name, identifier, files['middle'][identifier]))

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
    Create the field_counts table in a schema.

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

    selected_collections = _get_selected_collections(name)
    with concurrent.futures.ProcessPoolExecutor() as executor:
        futures = [executor.submit(_run_field_counts, name, collection) for collection in selected_collections]
        for future in concurrent.futures.as_completed(futures):
            future.result()

    db.execute("COMMENT ON COLUMN field_counts.collection_id IS "
               "'``id`` from the Kingfisher Process ``collection`` table'")
    db.execute("COMMENT ON COLUMN field_counts.release_type IS "
               """'Either "release", "compiled_release", "record" or "embedded_release"'""")
    db.execute("COMMENT ON COLUMN field_counts.path IS "
               "'JSON path of the field, excluding array indices'")
    db.execute("COMMENT ON COLUMN field_counts.object_property IS "
               "'Number of occurrences of the field, across all array entries and all releases'")
    db.execute("COMMENT ON COLUMN field_counts.array_count IS 'If the field is an array, "
               "cumulative length of its occurrences, across all array entries and all releases'")
    db.execute("COMMENT ON COLUMN field_counts.distinct_releases IS "
               "'Number of releases in which the field occurs'")
    db.commit()

    logger.info('Total time: %ss', time() - start)


def _run_field_lists(name, summary_table, tables_only):
    logger = logging.getLogger('ocdskingfisher.summarize.field-lists')
    logger.info('Processing %s', summary_table)

    start = time()

    db = Database()
    db.set_search_path([name, 'public'])

    table = SUMMARIES[summary_table]

    variables = {}

    if tables_only:
        no_field_list_type = sql.SQL('TABLE')
        final_summary_type = sql.SQL('TABLE')
    else:
        no_field_list_type = sql.SQL('TABLE' if table.is_table else 'VIEW')
        final_summary_type = sql.SQL('VIEW')

    field_list_table = f'{summary_table}_field_list'
    format_kwargs = {
        'summary_table': summary_table,
        'field_list_table': field_list_table,
        'no_field_list_table': f'{summary_table}_no_field_list',
        'no_field_list_type': no_field_list_type,
        'final_summary_type': final_summary_type,
        'data_column': table.data_column,
        'primary_keys': table.primary_keys,
        'qualified_primary_keys': [(summary_table, field) for field in table.primary_keys],
        'index': f'{field_list_table}_id',
    }

    counts_per_path_select = """
        SELECT
            {primary_keys},
            path,
            GREATEST(sum(array_item), sum(object_property)) path_count
        FROM
            {summary_table}
        CROSS JOIN
            flatten({summary_table}.{data_column})
        GROUP BY
            {primary_keys}, path
    """

    # Allow users to measure co-occurrence of fields across related award and contract objects.
    if summary_table in {'contracts_summary', 'awards_summary'}:
        if summary_table == 'contracts_summary':
            variables['path_prefix'] = 'awards'
            format_kwargs['other_data_column'] = 'award'
        else:
            variables['path_prefix'] = 'contracts'
            format_kwargs['other_data_column'] = 'contract'

        counts_per_path_select += """
        UNION ALL

        SELECT
            {qualified_primary_keys},
            %(path_prefix)s || '/' || path AS path,
            GREATEST(sum(array_item), sum(object_property)) path_count
        FROM
            awards_summary
        JOIN
            contracts_summary
        ON
            awards_summary.id = contracts_summary.id AND
            awards_summary.award_id = contracts_summary.awardid
        CROSS JOIN
            flatten({other_data_column})
        GROUP BY
            {qualified_primary_keys}, path

        UNION ALL

        SELECT
            {qualified_primary_keys},
            %(path_prefix)s AS path,
            count(*) path_count
        FROM
            awards_summary
        JOIN
            contracts_summary
        ON
            awards_summary.id = contracts_summary.id AND
            awards_summary.award_id = contracts_summary.awardid
        GROUP BY {qualified_primary_keys}
    """

    # Create a *_field_list table, add a unique index, rename the *_summary table to *_no_field_list, and re-create
    # the *_summary table. Then, copy the comments from the old to the new *_summary table.
    statement = """
        CREATE TABLE {field_list_table} AS
        WITH path_counts AS (
            INNER_SELECT
        )
        SELECT
            {primary_keys},
            jsonb_object_agg(path, path_count) AS field_list
        FROM
            path_counts
        GROUP BY
            {primary_keys}
    """.replace('INNER_SELECT', counts_per_path_select)
    db.execute(statement, variables=variables, **format_kwargs)

    statement = 'CREATE UNIQUE INDEX {index} ON {field_list_table}({primary_keys})'
    db.execute(statement, **format_kwargs)

    statement = 'ALTER {no_field_list_type} {summary_table} RENAME TO {no_field_list_table}'
    db.execute(statement, **format_kwargs)

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
    db.execute(statement, **format_kwargs)

    for row in db.all(COLUMN_COMMENTS_SQL, {'schema': name, 'table': f'{summary_table}_no_field_list'}):
        statement = 'COMMENT ON COLUMN {table}.{column} IS %(comment)s'
        db.execute(statement, {'comment': row[2]}, table=summary_table, column=row[0])

    if summary_table == 'contracts_summary':
        comment = (
            f"All JSON paths in the {table.data_column} object as well as in the related award's "
            f"{format_kwargs['other_data_column']} object (prefixed by {variables['path_prefix']}/), "
            "expressed as a JSONB object in which keys are paths and values are numbers of occurrences. "
            "Paths exclude array indices."
        )
    elif summary_table == 'awards_summary':
        comment = (
            f"All JSON paths in the {table.data_column} object as well as in the related contracts' "
            f"{format_kwargs['other_data_column']} object (prefixed by {variables['path_prefix']}/), "
            "expressed as a JSONB object in which keys are paths and values are numbers of occurrences. "
            "Paths exclude array indices."
        )
    else:
        comment = (
            f"All JSON paths in the {table.data_column} object, expressed as a JSONB object in which keys are "
            "paths and values are numbers of occurrences. Paths exclude array indices."
        )
    comment += ' This column is only available if the --field-lists option is used.'
    db.execute('COMMENT ON COLUMN {table}.field_list IS %(comment)s', {'comment': comment}, table=summary_table)

    db.commit()

    logger.info('%s: %ss', summary_table, time() - start)
    return summary_table


def field_lists(name, *, tables_only=False):
    """
    Add the field_list column on all summary tables.

    :param str name: the schema's name
    :param bool tables_only: whether to create SQL tables instead of SQL views
    """
    logger = logging.getLogger('ocdskingfisher.summarize.field-lists')

    start = time()

    graph = {table_name: set() for table_name in SUMMARIES}
    # field_lists() for awards_summary and contracts_summary cause deadlocks if they are run concurrently.
    graph['contracts_summary'] = {'awards_summary'}

    run_concurrently(graph, _run_field_lists, lambda table_name: (name, table_name, tables_only))

    logger.info('Total time: %ss', time() - start)


@cli.group()
def dev():
    """Commands for developers of Kingfisher Summarize."""


@dev.command()
def stale():
    """Print schemas summarizing deleted collections."""
    skip = os.getenv('KINGFISHER_SUMMARIZE_PROTECT_SCHEMA', '').split(',')

    statement = """
        SELECT 1 FROM summaries.selected_collections sc JOIN collection c ON sc.collection_id = c.id
        WHERE deleted_at IS NULL AND schema = %(schema)s
    """

    for schema in db.schemas():
        if schema not in skip and not db.one(statement, {'schema': schema}):
            click.echo(schema.removeprefix(SCHEMA_PREFIX))


@dev.command()
@click.argument('name', callback=validate_schema)
def docs_table_ref(name):
    """Create or update the CSV files in docs/definitions."""
    tables = []
    for content in sql_files('middle').values():
        tables.extend(
            table
            for table in re.findall(r'\bCREATE\s+(?:TABLE|VIEW)\s+(\w+)', content, flags=flags)
            if not table.startswith('tmp_')
        )
        tables.extend(_get_export_import_tables_from_functions(content)[0])
    tables.extend(('field_counts', 'note', 'summaries.selected_collections'))

    headers = ['Column Name', 'Data Type', 'Description']

    filename = os.path.join(basedir, 'docs', 'definitions', '{}.csv')
    for table in tables:
        with open(filename.format(table), 'w') as f:
            writer = csv.writer(f, lineterminator='\n')
            writer.writerow(headers)
            if '.' in table:
                variables = {'schema': table.split('.')[0], 'table': table.split('.')[1]}
            else:
                variables = {'schema': name, 'table': table}
            for row in db.all(COLUMN_COMMENTS_SQL, variables):
                # Change "timestamp without time zone" (and  "timestamp with time zone") to "timestamp".
                if 'timestamp' in row[1]:
                    row = list(row)
                    row[1] = 'timestamp'
                writer.writerow(row)


@dev.command()
def hash_md5():  # pragma: no cover
    """Sort the data table fixture by the id column and update the hash_md5 column."""
    path = os.path.join(basedir, 'tests', 'fixtures', 'kingfisher-process.sql')

    sections = {'before': [], 'data': [], 'after': []}

    section = 'before'
    with open(path) as f:
        for line in f:
            if section == 'data' and '\\.' in line:
                section = 'after'

            if section == 'data':
                pk, hash_md5, data = line.split('\t')
                hash_md5 = hashlib.md5(  # noqa: S324 # non-cryptographic
                    json.dumps(data, sort_keys=True).encode('utf-8')
                ).hexdigest()
                append = f'{pk}\t{hash_md5}\t{data}'
            else:
                append = line

            sections[section].append(append)

            if section == 'before' and 'COPY public.data' in line:
                section = 'data'

    sections['data'].sort(key=lambda line: int(line.split('\t', 1)[0]))

    with open(path, 'w') as f:
        for section in sections.values():
            for line in section:
                f.write(line)


if __name__ == '__main__':
    cli()
