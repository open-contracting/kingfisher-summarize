from click.testing import CliRunner

from ocdskingfisherviews.cli import cli
from ocdskingfisherviews.db import schema_exists
from tests import assert_bad_argument, assert_log_records, assert_log_running, fixture

command = 'delete-view'


def test_validate_name(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, [command, 'nonexistent'])

    assert result.exit_code == 2
    assert_bad_argument(result, 'NAME', 'SQL schema "view_data_nonexistent" not found')
    assert_log_running(caplog, command)


def test_command(caplog):
    with fixture():
        runner = CliRunner()

        schema = f'view_data_collection_1'

        assert schema_exists(schema)

        result = runner.invoke(cli, [command, 'collection_1'])

        assert not schema_exists(schema)

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            f'DROP SCHEMA "{schema}" CASCADE',
        ])
