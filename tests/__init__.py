import re
from contextlib import contextmanager

from click.testing import CliRunner

from ocdskingfisherviews.cli import cli
from ocdskingfisherviews.db import get_connection, get_cursor, pluck, schema_exists

ADD_VIEW_TABLES = {
    'note',
    'selected_collections',
}

REFRESH_VIEWS_TABLES = {
    'award_documents_summary',
    'award_items_summary',
    'award_suppliers_summary',
    'awards_summary',
    'awards_summary_no_data',
    'buyer_summary',
    'contract_documents_summary',
    'contract_implementation_documents_summary',
    'contract_implementation_milestones_summary',
    'contract_implementation_transactions_summary',
    'contract_items_summary',
    'contract_milestones_summary',
    'contracts_summary',
    'contracts_summary_no_data',
    'parties_summary',
    'parties_summary_no_data',
    'planning_documents_summary',
    'planning_milestones_summary',
    'planning_summary',
    'procuringentity_summary',
    'release_summary',
    'release_summary_with_data',
    'release_summary_with_checks',
    'tender_documents_summary',
    'tender_items_summary',
    'tender_milestones_summary',
    'tender_summary',
    'tender_summary_with_data',
    'tenderers_summary',
}

REFRESH_VIEWS_VIEWS = {
    'awards_summary',
    'contracts_summary',
    'parties_summary',
    'release_summary_with_checks',
    'release_summary_with_data',
    'tender_summary_with_data',
}


@contextmanager
def fixture(collections='1', dontbuild=True, name=None, tables_only=None, threads=None):
    runner = CliRunner()

    args = ['add-view', collections, 'Default']
    if name:
        args.extend(['--name', name])
    else:
        name = f"collection_{'_'.join(collections.split(','))}"
    if dontbuild:
        args.append('--dontbuild')
    if tables_only:
        args.append('--tables-only')
    if threads:
        args.extend(['--threads', threads])

    result = runner.invoke(cli, args)

    try:
        yield result
    finally:
        connection = get_connection()
        connection.rollback()
        runner.invoke(cli, ['delete-view', name])


# Click seems to use different quoting on different platforms.
def assert_bad_argument(result, argument, message):
    expression = rf"""\nError: Invalid value for ['"']{argument}['"']: {message}\n$"""
    assert re.search(expression, result.output)


def assert_log_running(caplog, command):
    assert len(caplog.records) == 1, [record.message for record in caplog.records]
    assert caplog.records[0].name == 'ocdskingfisher.views.cli'
    assert caplog.records[0].levelname == 'INFO'
    assert caplog.records[0].message == f'Running {command}'


def assert_log_records(caplog, name, messages):
    records = [record for record in caplog.records if record.name == f'ocdskingfisher.views.{name}']

    assert len(records) == len(messages), [record.message for record in records]
    assert all(record.levelname == 'INFO' for record in records)
    for i, record in enumerate(records):
        message = messages[i]
        if isinstance(message, str):
            assert record.message == message
        else:
            assert message.search(record.message)


def fetch_all(statement, variables=None):
    cursor = get_cursor()
    cursor.execute(statement, variables)
    return cursor.fetchall()


def get_tables(schema):
    return set(pluck('SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s',
                     {'schema': schema}))


def get_views(schema):
    return set(pluck("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                     "AND table_type = 'VIEW'", {'schema': schema}))


def get_columns_without_comments(schema):
    assert schema_exists(schema)

    return fetch_all("""
        SELECT
            isc.table_name,
            isc.column_name,
            isc.data_type
        FROM
            information_schema.columns isc
        WHERE
            isc.table_schema = %(schema)s
            AND LOWER(isc.table_name) NOT IN ('selected_collections', 'note', 'awards_summary_no_data',
                                              'contracts_summary_no_data', 'parties_summary_no_data')
            AND pg_catalog.col_description(format('%%s.%%s',isc.table_schema,isc.table_name)::regclass::oid,
                                           isc.ordinal_position) IS NULL
    """, {'schema': schema})
