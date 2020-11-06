from unittest.mock import patch

import pytest
from click.testing import CliRunner
from psycopg2 import sql

from ocdskingfisherviews.cli import cli
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


@pytest.mark.parametrize('collections, message', [
    ('a', 'Collection IDs must be integers'),
    ('1,10,100', 'Collection IDs {10, 100} not found'),
])
def test_validate_collections(collections, message, caplog):
    runner = CliRunner()

    result = runner.invoke(cli, [command, collections])

    assert result.exit_code == 2
    assert_bad_argument(result, 'COLLECTIONS', message)
    assert_log_running(caplog, command)


@patch('ocdskingfisherviews.cli.refresh_views', noop)
@patch('ocdskingfisherviews.cli.field_counts', noop)
@pytest.mark.parametrize('kwargs, name, collections', [
    ({}, 'collection_1', (1,)),
    ({'collections': '1,2'}, 'collection_1_2', (1, 2)),
    ({'name': 'custom'}, 'custom', (1,)),
])
def test_command_name(kwargs, name, collections, db, caplog):
    schema = f'view_data_{name}'
    identifier = sql.Identifier(schema)

    with fixture(db, **kwargs) as result:
        assert db.schema_exists(schema)
        assert db.all(sql.SQL('SELECT * FROM {schema}.selected_collections').format(schema=identifier)) == [
            (collection,) for collection in collections
        ]
        assert db.all(sql.SQL('SELECT id, note FROM {schema}.note').format(schema=identifier)) == [
            (1, 'Default'),
        ]

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            f'Arguments: collections={collections!r} note=Default name={kwargs.get("name")} tables_only=False',
            f'Added {name}',
            'Running refresh-views routine',
            'Running field-counts routine',
            'Running correct-user-permissions command',
        ])


@pytest.mark.parametrize('tables_only, tables, views', [
    (False, TABLES, VIEWS),
    (True, TABLES | VIEWS, set()),
])
def test_command(db, tables_only, tables, views, caplog):
    with fixture(db, tables_only=tables_only) as result:
        rows = db.all('SELECT * FROM view_data_collection_1.field_counts')

        # Check existence of schema, tables and views.
        assert db.schema_exists('view_data_collection_1')
        assert set(db.pluck("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                            " AND table_type = 'BASE TABLE'", {'schema': 'view_data_collection_1'})) == tables
        assert set(db.pluck("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                            "AND table_type = 'VIEW'", {'schema': 'view_data_collection_1'})) == views

        # Check contents of tables and views.
        assert len(rows) == 65235
        assert rows[0] == (1, 'release', 'awards', 100, 301, 100)

        # All columns have comments.
        assert not db.all("""
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
