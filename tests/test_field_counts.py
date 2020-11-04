import re

from click.testing import CliRunner

from ocdskingfisherviews.cli import cli
from tests import (assert_bad_argument, assert_log_records, assert_log_running, fixture, get_columns_without_comments,
                   get_tables)

command = 'field-counts'


def test_validate_name(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, [command, 'nonexistent'])

    assert result.exit_code == 2
    assert_bad_argument(result, 'NAME', 'SQL schema "view_data_nonexistent" not found')
    assert_log_running(caplog, command)


def test_command_error(db, caplog):
    with fixture(db):
        runner = CliRunner()

        result = runner.invoke(cli, [command, 'collection_1'])

        assert result.exit_code == 2
        assert result.output.endswith('Error: release_summary table not found. Run refresh-views first.\n')
        assert_log_records(caplog, command, [
            'Arguments: name=view_data_collection_1 remove=False',
        ])


def test_command(db, caplog):
    with fixture(db):
        runner = CliRunner()

        runner.invoke(cli, ['refresh-views', 'collection_1'])

        # The command can be run multiple times.
        for i in range(2):
            result = runner.invoke(cli, [command, 'collection_1'])
            rows = db.all('SELECT * FROM view_data_collection_1.field_counts')

            assert 'field_counts' in get_tables(db, 'view_data_collection_1')
            assert result.exit_code == 0
            assert result.output == ''
            assert_log_records(caplog, command, [
                'Arguments: name=view_data_collection_1 remove=False',
                # See # https://github.com/pytest-dev/pytest/issues/3037#issuecomment-662993108
                # 'Processing collection ID 1',
                # re.compile(r'^Time for collection ID 1: \d+\.\d+s$'),
                re.compile(r'^Total time: \d+\.\d+s$'),
            ])

            assert len(rows) == 65235
            assert rows[0] == (1, 'release', 'awards', 100, 301, 100)

            caplog.clear()

        # All columns have comments.
        assert not get_columns_without_comments(db, 'view_data_collection_1')

        # The command can be reversed.
        result = runner.invoke(cli, [command, 'collection_1', '--remove'])

        assert 'field_counts' not in get_tables(db, 'view_data_collection_1')
        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            'Arguments: name=view_data_collection_1 remove=True',
            'Dropped tables field_counts',
        ])
