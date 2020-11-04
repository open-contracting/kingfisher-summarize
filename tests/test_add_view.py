import re
from unittest.mock import patch

import pytest
from click.testing import CliRunner

from ocdskingfisherviews.cli import cli
from ocdskingfisherviews.db import get_cursor, pluck, schema_exists
from tests import assert_bad_argument, assert_log_records, assert_log_running, fixture, noop

command = 'add-view'

TABLES = {
    'note',
    'selected_collections',
    # refresh_views
    'award_documents_summary',
    'award_items_summary',
    'award_suppliers_summary',
    'awards_summary_no_data',
    'buyer_summary',
    'contract_documents_summary',
    'contract_implementation_documents_summary',
    'contract_implementation_milestones_summary',
    'contract_implementation_transactions_summary',
    'contract_items_summary',
    'contract_milestones_summary',
    'contracts_summary_no_data',
    'parties_summary_no_data',
    'planning_documents_summary',
    'planning_milestones_summary',
    'planning_summary',
    'procuringentity_summary',
    'release_summary_no_data',
    'tender_documents_summary',
    'tender_items_summary',
    'tender_milestones_summary',
    'tender_summary_no_data',
    'tenderers_summary',
    # field_counts
    'field_counts',
}

VIEWS = {
    'awards_summary',
    'contracts_summary',
    'parties_summary',
    'release_summary',
    'tender_summary',
}


def fetch_all(statement, variables=None):
    cursor = get_cursor()
    cursor.execute(statement, variables)
    return cursor.fetchall()


def test_validate_collections_noninteger(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, [command, 'a'])

    assert result.exit_code == 2
    assert_bad_argument(result, 'COLLECTIONS', 'Collection IDs must be integers')
    assert_log_running(caplog, command)


def test_validate_collections_nonexistent(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, [command, '1,10,100'])

    assert result.exit_code == 2
    assert_bad_argument(result, 'COLLECTIONS', 'Collection IDs {10, 100} not found')
    assert_log_running(caplog, command)


@patch('ocdskingfisherviews.cli.refresh_views', noop)
@patch('ocdskingfisherviews.cli.field_counts', noop)
def test_command_default_name(caplog):
    with fixture() as result:
        assert schema_exists('view_data_collection_1')
        assert fetch_all('SELECT * FROM view_data_collection_1.selected_collections') == [(1,)]
        assert fetch_all('SELECT id, note FROM view_data_collection_1.note') == [(1, 'Default')]

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            'Arguments: collections=(1,) note=Default name=None tables_only=False',
            'Added collection_1',
            'Running refresh-views routine',
            'Running field-counts routine',
            'Running correct-user-permissions command',
        ])


@patch('ocdskingfisherviews.cli.refresh_views', noop)
@patch('ocdskingfisherviews.cli.field_counts', noop)
def test_command_default_name_multiple(caplog):
    with fixture(collections='1,2') as result:
        assert schema_exists('view_data_collection_1_2')
        assert fetch_all('SELECT * FROM view_data_collection_1_2.selected_collections') == [(1,), (2,)]
        assert fetch_all('SELECT id, note FROM view_data_collection_1_2.note') == [(1, 'Default')]

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            'Arguments: collections=(1, 2) note=Default name=None tables_only=False',
            'Added collection_1_2',
            'Running refresh-views routine',
            'Running field-counts routine',
            'Running correct-user-permissions command',
        ])


@pytest.mark.parametrize('tables_only, tables, views', [
    (False, TABLES, VIEWS),
    (True, TABLES | VIEWS, set()),
])
def test_command(tables_only, tables, views, caplog):
    with fixture(tables_only=tables_only) as result:
        rows = fetch_all('SELECT * FROM view_data_collection_1.field_counts')

        # Check existence of schema, tables and views.
        assert schema_exists('view_data_collection_1')
        assert set(pluck("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                         " AND table_type = 'BASE TABLE'", {'schema': 'view_data_collection_1'})) == tables
        assert set(pluck("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                         "AND table_type = 'VIEW'", {'schema': 'view_data_collection_1'})) == views

        # Check contents of tables and views.
        assert len(rows) == 65235
        assert rows[0] == (1, 'release', 'awards', 100, 301, 100)

        # All columns have comments.
        assert not fetch_all("""
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
        """, {'schema': 'view_data_collection_1'})

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            f'Arguments: collections=(1,) note=Default name=None tables_only={tables_only!r}',
            'Added collection_1',
            'Running refresh-views routine',
            'Running field-counts routine',
            'Running correct-user-permissions command',
        ])
        assert_log_records(caplog, 'field-counts', [
            'Processing collection ID 1',
            re.compile(r'^Time for collection ID 1: \d+\.\d+s$'),
            re.compile(r'^Total time: \d+\.\d+s$'),
        ])


@patch('ocdskingfisherviews.cli.refresh_views', noop)
@patch('ocdskingfisherviews.cli.field_counts', noop)
def test_command_name_option(caplog):
    with fixture(name='custom') as result:
        assert schema_exists('view_data_custom')

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            'Arguments: collections=(1,) note=Default name=custom tables_only=False',
            'Added custom',
            'Running refresh-views routine',
            'Running field-counts routine',
            'Running correct-user-permissions command',
        ])
