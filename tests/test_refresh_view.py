import random

import pytest
import sqlalchemy as sa

import ocdskingfisherviews.config
from ocdskingfisherviews.cli import run_command


@pytest.fixture(scope='module')
def engine():
    return sa.create_engine(ocdskingfisherviews.config.get_database_uri())


VIEWS_TABLES = {
    "award_documents_summary",
    "award_items_summary",
    "award_suppliers_summary",
    "awards_summary",
    "buyer_summary",
    "contract_documents_summary",
    "contract_implementation_documents_summary",
    "contract_implementation_milestones_summary",
    "contract_implementation_transactions_summary",
    "contract_items_summary",
    "contract_milestones_summary",
    "contracts_summary",
    "parties_summary",
    "planning_documents_summary",
    "planning_milestones_summary",
    "planning_summary",
    "procuringentity_summary",
    "release_summary",
    "release_summary_with_data",
    "release_summary_with_checks",
    "tender_documents_summary",
    "tender_items_summary",
    "tender_milestones_summary",
    "tender_summary",
    "tender_summary_with_data",
    "tenderers_summary"
}


NO_COMMENTS_QUERY = '''
SELECT
    isc.table_name,
    isc.column_name,
    isc.data_type
FROM
    information_schema.columns isc
where
    isc.table_schema=%s
    and lower(isc.table_name) !~ 'tmp_.*'
    and lower(isc.table_name) !~ 'staged_.*'
    and lower(isc.table_name) !~ '.*_no_data'
    and lower(isc.table_name) not in  ('note', 'selected_collections')
    and pg_catalog.col_description(
        format('%%s.%%s',isc.table_schema,isc.table_name)::regclass::oid,
        isc.ordinal_position) is null
'''


def test_refresh_runs(engine):
    viewname = 'viewname' + str(random.randint(1, 10000000))
    run_command(['add-view', '--name', viewname, '1', 'Note'])
    run_command(['refresh-views', viewname, '--remove'])
    run_command(['refresh-views', viewname])
    get_current_tables_query = "select table_name from information_schema.tables " + \
                               "where table_schema = 'view_data_" + viewname + "'"

    with engine.connect() as conn:
        results = conn.execute(get_current_tables_query)
        db_tables = {result['table_name'] for result in results}
        assert db_tables.issuperset(VIEWS_TABLES)

    with engine.connect() as conn:
        results = conn.execute(NO_COMMENTS_QUERY, 'view_data_' + viewname)
        missing_comments = [result for result in results]
        assert missing_comments == []

    run_command(['refresh-views', viewname, '--remove'])
    with engine.connect() as conn:
        results = conn.execute(get_current_tables_query)
        db_tables = {result['table_name'] for result in results}
        assert db_tables.isdisjoint(VIEWS_TABLES)

    run_command(['delete-view', viewname])


def test_field_count_runs(engine):
    viewname = 'viewname' + str(random.randint(1, 10000000))
    run_command(['add-view', '--name', viewname, '1', 'Note'])
    run_command(['refresh-views', viewname, '--remove'])
    run_command(['field-counts', viewname, '--remove'])
    run_command(['refresh-views', viewname])
    run_command(['field-counts', viewname])
    get_current_tables_query = "select table_name from information_schema.tables " + \
                               "where table_schema = 'view_data_" + viewname + "'"

    with engine.connect() as conn:
        results = conn.execute(get_current_tables_query)
        db_tables = {result['table_name'] for result in results}
        assert 'field_counts' in db_tables

    run_command(['refresh-views', viewname, '--remove'])
    run_command(['field-counts', viewname, '--remove'])

    with engine.connect() as conn:
        results = conn.execute(get_current_tables_query)
        db_tables = {result['table_name'] for result in results}
        assert 'field_counts' not in db_tables

    run_command(['delete-view', viewname])
