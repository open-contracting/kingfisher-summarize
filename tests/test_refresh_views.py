from click.testing import CliRunner

from ocdskingfisherviews.cli import cli
from tests import (ADD_VIEW_TABLES, REFRESH_VIEWS_TABLES, REFRESH_VIEWS_VIEWS, assert_log_records, fixture,
                   get_columns_without_comments, get_tables, get_views)


def test_validate_name(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, ['refresh-views', 'nonexistent'])

    assert result.exit_code == 2
    assert result.output.endswith('\nError: Invalid value for "NAME": SQL schema "view_data_nonexistent" not found\n')
    assert len(caplog.records) == 1
    assert caplog.records[0].levelname == 'INFO'
    assert caplog.records[0].message == 'Running refresh-views'


def test_command(caplog):
    with fixture():
        runner = CliRunner()

        # The command can be run multiple times.
        for i in range(2):
            result = runner.invoke(cli, ['refresh-views', 'collection_1'])

            assert get_tables('view_data_collection_1') == ADD_VIEW_TABLES | REFRESH_VIEWS_TABLES
            assert get_views('view_data_collection_1') == REFRESH_VIEWS_VIEWS
            assert result.exit_code == 0
            assert result.output == ''
            assert_log_records(caplog, 'refresh-views', [])

        # All columns have comments.
        assert not get_columns_without_comments('collection_1')

        # The command can be reversed.
        result = runner.invoke(cli, ['refresh-views', 'collection_1', '--remove'])

        assert get_tables('view_data_collection_1') == ADD_VIEW_TABLES
        assert get_views('view_data_collection_1') == set()
        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, 'refresh-views', [])


def test_command_tables_only(caplog):
    with fixture():
        runner = CliRunner()

        # The command can be run multiple times.
        for i in range(2):
            result = runner.invoke(cli, ['refresh-views', 'collection_1', '--tables-only'])

            assert get_tables('view_data_collection_1') == ADD_VIEW_TABLES | REFRESH_VIEWS_TABLES
            assert get_views('view_data_collection_1') == set()
            assert result.exit_code == 0
            assert result.output == ''
            assert_log_records(caplog, 'refresh-views', [])

        # All columns have comments.
        assert not get_columns_without_comments('collection_1')

        # The command can be reversed.
        result = runner.invoke(cli, ['refresh-views', 'collection_1', '--tables-only', '--remove'])

        assert get_tables('view_data_collection_1') == ADD_VIEW_TABLES
        assert get_views('view_data_collection_1') == set()
        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, 'refresh-views', [])
