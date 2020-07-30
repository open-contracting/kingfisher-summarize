import random

from click.testing import CliRunner

from ocdskingfisherviews.cli import cli
from ocdskingfisherviews.db import get_cursor, pluck

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

NO_COMMENTS_QUERY = """
SELECT
    isc.table_name,
    isc.column_name,
    isc.data_type
FROM
    information_schema.columns isc
where
    isc.table_schema=%(schema)s
    and lower(isc.table_name) !~ 'tmp_.*'
    and lower(isc.table_name) !~ 'staged_.*'
    and lower(isc.table_name) !~ '.*_no_data'
    and lower(isc.table_name) not in  ('note', 'selected_collections')
    and pg_catalog.col_description(
        format('%%s.%%s',isc.table_schema,isc.table_name)::regclass::oid,
        isc.ordinal_position) is null
"""


def get_current_tables(schema):
    return set(pluck('SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s',
                     {'schema': schema}))


def test_refresh_runs():
    runner = CliRunner()
    cursor = get_cursor()

    name = 'viewname' + str(random.randint(1, 10000000))
    schema = f'view_data_{name}'

    result = runner.invoke(cli, ['add-view', '--name', name, '1', 'Note'])
    assert result.exit_code == 0

    assert get_current_tables(schema).issuperset(VIEWS_TABLES)

    result = runner.invoke(cli, ['refresh-views', name, '--remove'])
    assert result.exit_code == 0

    assert get_current_tables(schema).isdisjoint(VIEWS_TABLES)

    result = runner.invoke(cli, ['refresh-views', name])
    assert result.exit_code == 0

    assert get_current_tables(schema).issuperset(VIEWS_TABLES)

    cursor.execute(NO_COMMENTS_QUERY, {'schema': schema})

    assert not cursor.fetchall()

    result = runner.invoke(cli, ['delete-view', name])
    assert result.exit_code == 0


def test_refresh_runs_tables_only():
    runner = CliRunner()

    name = 'viewname' + str(random.randint(1, 10000000))
    schema = f'view_data_{name}'

    result = runner.invoke(cli, ['add-view', '--name', name, '1', 'Note', '--tables-only'])
    assert result.exit_code == 0

    assert get_current_tables(schema).issuperset(VIEWS_TABLES)

    result = runner.invoke(cli, ['refresh-views', name, '--tables-only'])
    assert result.exit_code == 0

    assert get_current_tables(schema).issuperset(VIEWS_TABLES)

    result = runner.invoke(cli, ['refresh-views', name, '--remove', '--tables-only'])
    assert result.exit_code == 0

    assert get_current_tables(schema).isdisjoint(VIEWS_TABLES)

    result = runner.invoke(cli, ['delete-view', name])
    assert result.exit_code == 0


def test_field_count_runs():
    runner = CliRunner()

    name = 'viewname' + str(random.randint(1, 10000000))
    schema = f'view_data_{name}'

    result = runner.invoke(cli, ['add-view', '--name', name, '1', 'Note'])
    assert result.exit_code == 0

    result = runner.invoke(cli, ['refresh-views', name, '--remove'])
    assert result.exit_code == 0

    result = runner.invoke(cli, ['field-counts', name, '--remove'])
    assert result.exit_code == 0

    result = runner.invoke(cli, ['refresh-views', name])
    assert result.exit_code == 0

    result = runner.invoke(cli, ['field-counts', name])
    assert result.exit_code == 0

    assert 'field_counts' in get_current_tables(schema)

    result = runner.invoke(cli, ['refresh-views', name, '--remove'])
    assert result.exit_code == 0

    result = runner.invoke(cli, ['field-counts', name, '--remove'])
    assert result.exit_code == 0

    assert 'field_counts' not in get_current_tables(schema)

    result = runner.invoke(cli, ['delete-view', name])
    assert result.exit_code == 0
