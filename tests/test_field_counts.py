from click.testing import CliRunner

from ocdskingfisherviews.cli import cli
from tests import assert_log_records, fixture, get_columns_without_comments, get_tables


def test_validate_name(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, ['field-counts', 'nonexistent'])

    assert result.exit_code == 2
    assert result.output.endswith('\nError: Invalid value for "NAME": SQL schema "view_data_nonexistent" not found\n')
    assert len(caplog.records) == 1
    assert caplog.records[0].levelname == 'INFO'
    assert caplog.records[0].message == 'Running field-counts'


def test_command_error(caplog):
    with fixture():
        runner = CliRunner()

        result = runner.invoke(cli, ['field-counts', 'collection_1'])

        assert result.exit_code == 2
        assert result.output.endswith('\nError: release_summary_with_data table not found. Run refresh-views first.\n')
        assert_log_records(caplog, 'field-counts', [])


def test_command(caplog):
    with fixture():
        runner = CliRunner()

        runner.invoke(cli, ['refresh-views', 'collection_1'])

        # The command can be run multiple times.
        for i in range(2):
            result = runner.invoke(cli, ['field-counts', 'collection_1'])

            assert 'field_counts' in get_tables('view_data_collection_1')
            assert result.exit_code == 0
            assert result.output == ''
            assert_log_records(caplog, 'field-counts', [])

        # All columns have comments.
        assert not get_columns_without_comments('collection_1')

        # The command can be reversed.
        result = runner.invoke(cli, ['field-counts', 'collection_1', '--remove'])

        assert 'field_counts' not in get_tables('view_data_collection_1')
        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, 'field-counts', [])
