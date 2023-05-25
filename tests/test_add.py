import datetime
import decimal
from unittest.mock import patch

import pytest
from click.testing import CliRunner
from psycopg2 import sql

from manage import SUMMARIES, cli, construct_where_fragment
from tests import assert_bad_argument, assert_log_records, assert_log_running, fixture, noop

command = 'add'

TABLES = {
    'note',
}
SUMMARY_TABLES = set()
SUMMARY_VIEWS = set()
FIELD_LIST_TABLES = set()
NO_FIELD_LIST_TABLES = set()
NO_FIELD_LIST_VIEWS = set()

for table_name, table in SUMMARIES.items():
    FIELD_LIST_TABLES.add(f'{table_name}_field_list')

    if table.is_table:
        SUMMARY_TABLES.add(table_name)
        NO_FIELD_LIST_TABLES.add(f'{table_name}_no_field_list')
    else:
        SUMMARY_VIEWS.add(table_name)
        NO_FIELD_LIST_VIEWS.add(f'{table_name}_no_field_list')
        TABLES.add(f'{table_name}_no_data')


def test_construct_where_fragment(db):
    assert construct_where_fragment(db.cursor, 'a', 'z') == " AND d.data->>'a' = 'z'"
    assert construct_where_fragment(db.cursor, 'a.b', 'z') == " AND d.data->'a'->>'b' = 'z'"
    assert construct_where_fragment(db.cursor, 'a.b.c', 'z') == " AND d.data->'a'->'b'->>'c' = 'z'"
    assert construct_where_fragment(db.cursor, 'a.b.c.d', 'z') == " AND d.data->'a'->'b'->'c'->>'d' = 'z'"
    assert construct_where_fragment(db.cursor, 'a.b.c', '') == " AND d.data->'a'->'b'->>'c' = ''"
    assert construct_where_fragment(db.cursor, '', 'z') == " AND d.data->>'' = 'z'"


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


def test_validate_name(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, [command, '1', '--name', 'camelCase'])

    assert result.exit_code == 2
    assert_bad_argument(result, '--name', 'value must be lowercase')
    assert_log_running(caplog, command)


@patch('manage.summary_tables', noop)
@patch('manage.field_counts', noop)
@patch('manage.field_lists', noop)
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
        assert db.all('SELECT collection_id, schema FROM summaries.selected_collections WHERE schema=%(schema)s',
                      {'schema': schema}) == [(collection, schema,) for collection in collections]
        assert db.all(sql.SQL('SELECT id, note FROM {schema}.note').format(schema=identifier)) == [
            (1, 'Default'),
        ]

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            f'Arguments: collections={collections!r} note=Default name={kwargs.get("name")} tables_only=False '
            'filters=() filters_sql_json_path=()',
            f'Added {name}',
            'Running summary-tables routine',
            'Running field-counts routine',
            'Running field-lists routine',
        ])


@pytest.mark.parametrize('filters, filters_sql_json_path', [
    ((), ()),
    ((('ocid', 'dolore'),), ()),
    ((('id', '川蝉'),), ()),
    ((), ('$.id == "川蝉"',)),
])
@pytest.mark.parametrize('tables_only, field_counts, field_lists, tables, views', [
    (False, True, False,
     TABLES | SUMMARY_TABLES, SUMMARY_VIEWS),
    (True, True, False,
     TABLES | SUMMARY_TABLES | SUMMARY_VIEWS, set()),
    (False, False, True,
     TABLES | FIELD_LIST_TABLES | NO_FIELD_LIST_TABLES, SUMMARY_TABLES | SUMMARY_VIEWS | NO_FIELD_LIST_VIEWS),
    (True, False, True,
     TABLES | FIELD_LIST_TABLES | NO_FIELD_LIST_TABLES | SUMMARY_TABLES | SUMMARY_VIEWS | NO_FIELD_LIST_VIEWS, set()),
])
def test_command(db, tables_only, field_counts, field_lists, tables, views, filters, filters_sql_json_path, caplog):
    # Load collection 2 first, to check that existing collections aren't included when we load collection 1.
    with fixture(db, collections='2', tables_only=tables_only, field_counts=field_counts, field_lists=field_lists,
                 filters=filters, filters_sql_json_path=filters_sql_json_path), \
         fixture(db, tables_only=tables_only, field_counts=field_counts, field_lists=field_lists, filters=filters,
                 filters_sql_json_path=filters_sql_json_path) as result:
        # Check existence of schema, tables and views.
        if field_counts:
            tables.add('field_counts')

        assert db.schema_exists('view_data_collection_1')
        assert db.schema_exists('view_data_collection_2')
        assert set(db.pluck("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                            "AND table_type = 'BASE TABLE'", {'schema': 'view_data_collection_1'})) == tables
        assert set(db.pluck("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                            "AND table_type = 'VIEW'", {'schema': 'view_data_collection_1'})) == views

        # Check contents of summary relations.
        rows = db.all("""
            SELECT
                award_index,
                release_type,
                collection_id,
                ocid,
                release_id,
                award_id,
                title,
                status,
                description,
                value_amount,
                value_currency,
                date,
                contractperiod_startdate,
                contractperiod_enddate,
                contractperiod_maxextentdate,
                contractperiod_durationindays,
                total_suppliers,
                total_documents,
                document_documenttype_counts,
                total_items
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
            2,  # total_suppliers
            4,  # total_documents
            {
                'Excepteur nisi et': 1,
                'proident exercitation in': 1,
                'ut magna dolore velit aute': 1,
                'veniam enim aliqua d': 1,
            },  # document_documenttype_counts
            5,  # total_items
        )
        if filters or filters_sql_json_path:
            assert len(rows) == 4
        else:
            assert len(rows) == 301

        rows = db.all("""
            SELECT
                party_index,
                release_type,
                collection_id,
                ocid,
                release_id,
                party_id,
                roles,
                identifier,
                unique_identifier_attempt,
                additionalidentifiers_ids,
                total_additionalidentifiers
            FROM view_data_collection_1.parties_summary
            ORDER BY id, party_index
        """)

        assert rows[0] == (
            0,  # party_index
            'release',  # release_type
            1,  # collection_id
            'dolore',  # ocid
            'ex laborumsit autein magna veniam',  # release_id
            'voluptate officia tempor dolor',  # party_id
            [
                'ex ',
                'in est exercitation nulla Excepteur',
                'ipsum do',
            ],  # roles
            'ad proident dolor reprehenderit veniam-in quis exercitation reprehenderit',  # identifier
            'voluptate officia tempor dolor',  # unique_identifier_attempt
            [
                'exercitation proident voluptate-sed culpa eamollit consectetur dolor l',
                'magna-dolor ut indolorein in tempor magna mollit',
                'ad occaecat amet anim-laboris ea Duisdeserunt quis sed pariatur mollit',
                'elit mollit-officia proidentmagna',
                'ex-minim Ut consectetur',
            ],  # additionalidentifiers_ids
            5,  # total_additionalidentifiers

        )
        if filters or filters_sql_json_path:
            assert len(rows) == 4
        else:
            assert len(rows) == 296

        if field_counts:
            # Check contents of field_counts table.
            rows = db.all('SELECT * FROM view_data_collection_1.field_counts')

            if filters or filters_sql_json_path:
                assert len(rows) == 1046
                assert rows[0] == (1, 'release', 'awards', 1, 4, 1)
            else:
                assert len(rows) == 65235
                assert rows[0] == (1, 'release', 'awards', 100, 301, 100)

        if field_lists:
            # Check the count of keys in the field_list field for the lowest primary keys in each summary relation.
            statement = """
                SELECT
                    count(*)
                FROM
                    (SELECT
                        jsonb_each(field_list)
                    FROM (
                        SELECT
                            field_list
                        FROM
                            view_data_collection_1.{table}
                        ORDER BY
                            {primary_keys}
                        LIMIT 1) AS field_list
                    ) AS each
            """

            expected = {
                'award_documents_summary': 11,
                'award_items_summary': 26,
                'award_suppliers_summary': 28,
                'awards_summary': 469,
                'buyer_summary': 28,
                'contract_documents_summary': 11,
                'contract_implementation_documents_summary': 11,
                'contract_implementation_milestones_summary': 29,
                'contract_implementation_transactions_summary': 83,
                'contract_items_summary': 26,
                'contract_milestones_summary': 27,
                'contracts_summary': 469,
                'parties_summary': 34,
                'planning_documents_summary': 11,
                'planning_milestones_summary': 29,
                'planning_summary': 61,
                'procuringentity_summary': 32,
                'relatedprocesses_summary': 6,
                'release_summary': 1046,
                'tender_documents_summary': 15,
                'tender_items_summary': 25,
                'tender_milestones_summary': 23,
                'tender_summary': 228,
                'tenderers_summary': 31,
            }

            for table_name, table in SUMMARIES.items():
                count = db.one(db.format(statement, table=table_name, primary_keys=table.primary_keys))[0]

                assert count == expected[table_name], f'{table_name}: {count} != {expected[table_name]}'

            def result_dict(statement):
                result = db.one(statement)
                return {column.name: result for column, result in zip(db.cursor.description, result)}

            statement = """
                SELECT
                    count(*) total,
                    sum(coalesce((field_list ->> 'contracts')::int, 0)) contracts,
                    sum(coalesce((field_list ->> 'awards')::int, 0)) awards,
                    sum(coalesce((field_list ->> 'awards/id')::int, 0)) awards_id,
                    sum(coalesce((field_list ->> 'awards/value/amount')::int, 0)) awards_amount
                FROM
                    view_data_collection_1.contracts_summary
            """

            if filters:
                assert result_dict(statement) == {
                    'awards': 1,
                    'awards_amount': 1,
                    'awards_id': 1,
                    'contracts': 0,
                    'total': 1,
                }
            else:
                assert result_dict(statement) == {
                    'awards': 213,
                    'awards_amount': 213,
                    'awards_id': 213,
                    'contracts': 0,
                    'total': 285,
                }

            statement = """
                SELECT
                    count(*) total,
                    sum(coalesce((field_list ->> 'awards')::int, 0)) awards,
                    sum(coalesce((field_list ->> 'contracts')::int, 0)) contracts,
                    sum(coalesce((field_list ->> 'contracts/id')::int, 0)) contracts_id,
                    sum(coalesce((field_list ->> 'contracts/value/amount')::int, 0)) contracts_amount
                FROM
                    view_data_collection_1.awards_summary
            """

            if filters:
                assert result_dict(statement) == {
                    'contracts': 1,
                    'contracts_amount': 1,
                    'contracts_id': 1,
                    'awards': 0,
                    'total': 4,
                }
            else:
                assert result_dict(statement) == {
                    'contracts': 213,
                    'contracts_amount': 213,
                    'contracts_id': 213,
                    'awards': 0,
                    'total': 301,
                }

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
                AND LOWER(isc.table_name) NOT IN ('selected_collections', 'note')
                AND LOWER(isc.table_name) NOT LIKE '%%_no_data'
                AND LOWER(isc.table_name) NOT LIKE '%%_field_list'
                AND pg_catalog.col_description(format('%%s.%%s',isc.table_schema,isc.table_name)::regclass::oid,
                                               isc.ordinal_position) IS NULL
        """, {'schema': 'view_data_collection_1'})

        expected = []
        for collection_id in [2, 1]:
            expected.extend([
                f'Arguments: collections=({collection_id},) note=Default name=None tables_only={tables_only!r} '
                f'filters={filters!r} filters_sql_json_path={filters_sql_json_path!r}',
                f'Added collection_{collection_id}',
                'Running summary-tables routine',
            ])
            if field_counts:
                expected.append('Running field-counts routine')
            if field_lists:
                expected.append('Running field-lists routine')

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, expected)


@pytest.mark.parametrize('filters, filters_sql_json_path', [
    ((('tender.procurementMethod', 'direct',),), ()),
    ((('tender.procurementMethod', 'direct',), ('tender.status', 'planned',),), ()),
    ((), ('$.tender.procurementMethod == "direct"',)),
    ((), ('$.tender.procurementMethod == "direct"', '$.tender.status == "planned"')),
    ((('tender.status', 'planned',),), ('$.tender.procurementMethod == "direct"',)),
    ((('tender.procurementMethod', 'direct',),), ('$.tender.status == "planned"',)),
])
@pytest.mark.parametrize('tables_only, field_counts, field_lists, tables, views', [
    (False, True, False,
     TABLES | SUMMARY_TABLES, SUMMARY_VIEWS),
    (True, True, False,
     TABLES | SUMMARY_TABLES | SUMMARY_VIEWS, set()),
    (False, False, True,
     TABLES | FIELD_LIST_TABLES | NO_FIELD_LIST_TABLES, SUMMARY_TABLES | SUMMARY_VIEWS | NO_FIELD_LIST_VIEWS),
    (True, False, True,
     TABLES | FIELD_LIST_TABLES | NO_FIELD_LIST_TABLES | SUMMARY_TABLES | SUMMARY_VIEWS | NO_FIELD_LIST_VIEWS, set()),
])
def test_command_filter(db, tables_only, field_counts, field_lists, tables, views, filters, filters_sql_json_path,
                        caplog):
    # Load collection 2 first, to check that existing collections aren't included when we load collection 1.
    with fixture(db, collections='2', tables_only=tables_only, field_counts=field_counts, field_lists=field_lists,
                 filters=filters, filters_sql_json_path=filters_sql_json_path), \
         fixture(db, tables_only=tables_only, field_counts=field_counts, field_lists=field_lists, filters=filters,
                 filters_sql_json_path=filters_sql_json_path) as result:
        # Check existence of schema, tables and views.
        if field_counts:
            tables.add('field_counts')

        assert db.schema_exists('view_data_collection_1')
        assert db.schema_exists('view_data_collection_2')
        assert set(db.pluck("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                            "AND table_type = 'BASE TABLE'", {'schema': 'view_data_collection_1'})) == tables
        assert set(db.pluck("SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s "
                            "AND table_type = 'VIEW'", {'schema': 'view_data_collection_1'})) == views

        # Check that the tender_summary table only has correctly filtered items
        rows = db.all("""
            SELECT
                procurementmethod
            FROM view_data_collection_1.tender_summary
        """)
        for row in rows:
            assert row[0] == 'direct'
        if len(filters + filters_sql_json_path) > 1:
            assert len(rows) == 2
        else:
            assert len(rows) == 19

        # Check data_id's in the summary against the data table
        # This allows us to check that missing data doesn't have the filtered value
        rows = db.all("""
            SELECT
                data_id
            FROM view_data_collection_1.release_summary
        """)
        if len(filters + filters_sql_json_path) > 1:
            assert len(rows) == 2
        else:
            assert len(rows) == 19
        data_ids = [row[0] for row in rows]
        rows = db.all("""
            SELECT
                data.id,
                data.data->'tender'->'procurementMethod',
                data.data->'tender'->'status'
            FROM data
            JOIN release ON release.data_id=data.id
            WHERE release.collection_id=1
        """)
        for row in rows:
            if row[1] == 'direct' and (len(filters + filters_sql_json_path) == 1 or row[2] == 'planned'):
                assert row[0] in data_ids
            else:
                assert row[0] not in data_ids

        # Check contents of summary relations.
        rows = db.all("""
            SELECT
                award_index,
                release_type,
                collection_id,
                ocid,
                release_id,
                award_id,
                title,
                status,
                description,
                value_amount,
                value_currency,
                date,
                contractperiod_startdate,
                contractperiod_enddate,
                contractperiod_maxextentdate,
                contractperiod_durationindays,
                total_suppliers,
                total_documents,
                document_documenttype_counts,
                total_items
            FROM view_data_collection_1.awards_summary
            ORDER BY id, award_index
        """)

        assert rows[0] == (
            0,  # award_index
            'release',  # release_type
            1,  # collection_id
            'officia dolore non',  # ocid
            'laborum irure consectetur fugiat',  # release_id
            'dolorLorem fugiat ut',  # award_id
            'et',  # award_title
            'pending',  # award_status
            'adipisicing ame',  # award_description
            decimal.Decimal('-7139109'),  # award_value_amount
            'AUD',  # award_value_currency
            datetime.datetime(3672, 10, 26, 4, 38, 28, 786000),  # award_date
            datetime.datetime(2192, 8, 27, 0, 9, 1, 626000),  # award_contractperiod_startdate
            datetime.datetime(4204, 1, 22, 22, 4, 18, 268000),  # award_contractperiod_enddate
            datetime.datetime(5117, 12, 26, 11, 33, 27, 496000),  # award_contractperiod_maxextentdate
            decimal.Decimal('-30383739'),  # award_contractperiod_durationindays
            5,  # total_suppliers
            4,  # total_documents
            {
                'in sint enim labore': 1,
                'mollit labore Lorem': 1,
                'minim incididunt sed ipsum': 1,
                'ad reprehenderit sit dolor enim': 1
            },  # document_documenttype_counts
            5,  # total_items
        )
        if len(filters + filters_sql_json_path) > 1:
            assert len(rows) == 7
        else:
            assert len(rows) == 55

        rows = db.all("""
            SELECT
                party_index,
                release_type,
                collection_id,
                ocid,
                release_id,
                party_id,
                roles,
                identifier,
                unique_identifier_attempt,
                additionalidentifiers_ids,
                total_additionalidentifiers
            FROM view_data_collection_1.parties_summary
            ORDER BY id, party_index
        """)

        assert rows[0] == (
            0,  # party_index
            'release',  # release_type
            1,  # collection_id
            'officia dolore non',  # ocid
            'laborum irure consectetur fugiat',  # release_id
            'eu voluptateeiusmod ipsum ea',  # party_id
            [
                'laborum',
                'tempor',
            ],  # roles
            'cupidatat consequat in ullamco-in incididunt commodo elit',  # identifier
            'eu voluptateeiusmod ipsum ea',  # unique_identifier_attempt
            [
                'non ei-commododolor laborum',
            ],  # additionalidentifiers_ids
            1,  # total_additionalidentifiers

        )
        if len(filters + filters_sql_json_path) > 1:
            assert len(rows) == 5
        else:
            assert len(rows) == 56

        if field_counts:
            # Check contents of field_counts table.
            rows = db.all('SELECT * FROM view_data_collection_1.field_counts')

            if len(filters + filters_sql_json_path) > 1:
                assert len(rows) == 1515
                assert rows[0] == (1, 'release', 'awards', 2, 7, 2)
            else:
                assert len(rows) == 13077
                assert rows[0] == (1, 'release', 'awards', 19, 55, 19)

        if field_lists:
            # Check the count of keys in the field_list field for the lowest primary keys in each summary relation.
            statement = """
                SELECT
                    count(*)
                FROM
                    (SELECT
                        jsonb_each(field_list)
                    FROM (
                        SELECT
                            field_list
                        FROM
                            view_data_collection_1.{table}
                        ORDER BY
                            {primary_keys}
                        LIMIT 1) AS field_list
                    ) AS each
            """

            expected = {
                'award_documents_summary': 11,
                'award_items_summary': 29,
                'award_suppliers_summary': 30,
                'awards_summary': 492,
                'buyer_summary': 31,
                'contract_documents_summary': 11,
                'contract_implementation_documents_summary': 11,
                'contract_implementation_milestones_summary': 23,
                'contract_implementation_transactions_summary': 83,
                'contract_items_summary': 26,
                'contract_milestones_summary': 26,
                'contracts_summary': 492,
                'parties_summary': 30,
                'planning_documents_summary': 11,
                'planning_milestones_summary': 27,
                'planning_summary': 99,
                'procuringentity_summary': 30,
                'relatedprocesses_summary': 6,
                'release_summary': 987,
                'tender_documents_summary': 13,
                'tender_items_summary': 28,
                'tender_milestones_summary': 27,
                'tender_summary': 265,
                'tenderers_summary': 32,
            }

            for table_name, table in SUMMARIES.items():
                count = db.one(db.format(statement, table=table_name, primary_keys=table.primary_keys))[0]

                assert count == expected[table_name], f'{table_name}: {count} != {expected[table_name]}'

        expected = []
        for collection_id in [2, 1]:
            expected.extend([
                f'Arguments: collections=({collection_id},) note=Default name=None tables_only={tables_only!r} '
                f'filters={filters!r} filters_sql_json_path={filters_sql_json_path!r}',
                f'Added collection_{collection_id}',
                'Running summary-tables routine',
            ])
            if field_counts:
                expected.append('Running field-counts routine')
            if field_lists:
                expected.append('Running field-lists routine')

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, expected)
