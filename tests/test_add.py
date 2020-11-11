import datetime
import decimal
from unittest.mock import patch

import pytest
from click.testing import CliRunner
from psycopg2 import sql

from manage import cli
from tests import assert_bad_argument, assert_log_records, assert_log_running, fixture, noop

command = 'add'

TABLES = {
    'note',
    'selected_collections',

    # summarize
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


@patch('manage.summary_tables', noop)
@patch('manage.field_counts', noop)
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
            'Running summary-tables routine',
            'Running field-counts routine',
            'Running correct-user-permissions command',
        ])


@pytest.mark.parametrize('tables_only, tables, views', [
    (False, TABLES, VIEWS),
    (True, TABLES | VIEWS, set()),
])
def test_command(db, tables_only, tables, views, caplog):
    with fixture(db, tables_only=tables_only) as result:
        # Check existence of schema, tables and views.
        assert db.schema_exists('view_data_collection_1')
        assert set(db.pluck("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                            " AND table_type = 'BASE TABLE'", {'schema': 'view_data_collection_1'})) == tables
        assert set(db.pluck("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                            "AND table_type = 'VIEW'", {'schema': 'view_data_collection_1'})) == views

        # Check contents of summary tables.
        rows = db.all("""
            SELECT
                award_index,
                release_type,
                collection_id,
                ocid,
                release_id,
                award_id,
                award_title,
                award_status,
                award_description,
                award_value_amount,
                award_value_currency,
                award_date,
                award_contractperiod_startdate,
                award_contractperiod_enddate,
                award_contractperiod_maxextentdate,
                award_contractperiod_durationindays,
                suppliers_count,
                documents_count,
                documenttype_counts,
                items_count
            FROM view_data_collection_1.awards_summary
            ORDER BY id, award_index
        """)

        assert rows[0] == (
            0,  # award_index
            'release',  # release_type
            1,  # collection_id
            'dolore',  # ocid
            'ex laborumsit autein magna veniam',  # release_id
            'reprehenderit magna cillum eu nisi',  # award_id
            'laborum aute nisi eiusmod',  # award_title
            'pending',  # award_status
            'ullamco in voluptate',  # award_description
            decimal.Decimal('-95099396'),  # award_value_amount
            'AMD',  # award_value_currency
            datetime.datetime(3263, 12, 5, 21, 24, 19, 161000),  # award_date
            datetime.datetime(4097, 9, 16, 5, 55, 19, 125000),  # award_contractperiod_startdate
            datetime.datetime(4591, 4, 29, 6, 34, 28, 472000),  # award_contractperiod_enddate
            datetime.datetime(3714, 8, 9, 7, 21, 37, 544000),  # award_contractperiod_maxextentdate
            decimal.Decimal('72802012'),  # award_contractperiod_durationindays
            2,  # suppliers_count
            4,  # documents_count
            {
                'Excepteur nisi et': 1,
                'proident exercitation in': 1,
                'ut magna dolore velit aute': 1,
                'veniam enim aliqua d': 1,
            },  # documenttype_counts
            5,  # items_count
        )
        assert len(rows) == 301

        rows = db.all("""
            SELECT
                party_index,
                release_type,
                collection_id,
                ocid,
                release_id,
                parties_id,
                roles,
                identifier,
                unique_identifier_attempt,
                parties_additionalidentifiers_ids,
                parties_additionalidentifiers_count
            FROM view_data_collection_1.parties_summary
            ORDER BY id, party_index
        """)

        assert rows[0] == (
            0,
            'release',
            1,
            'dolore',
            'ex laborumsit autein magna veniam',
            'voluptate officia tempor dolor',
            [
                'ex ',
                'in est exercitation nulla Excepteur',
                'ipsum do',
            ],
            'ad proident dolor reprehenderit veniam-in quis exercitation reprehenderit',
            'voluptate officia tempor dolor',
            [
                'exercitation proident voluptate-sed culpa eamollit consectetur dolor l',
                'magna-dolor ut indolorein in tempor magna mollit',
                'ad occaecat amet anim-laboris ea Duisdeserunt quis sed pariatur mollit',
                'elit mollit-officia proidentmagna',
                'ex-minim Ut consectetur',
            ],
            5,

        )
        assert len(rows) == 296

        # Check contents of field_counts table.
        rows = db.all('SELECT * FROM view_data_collection_1.field_counts')

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
            'Running summary-tables routine',
            'Running field-counts routine',
            'Running correct-user-permissions command',
        ])
