from unittest.mock import patch

from click.testing import CliRunner

from manage import cli
from tests import assert_bad_argument, assert_log_records, assert_log_running, fixture, noop

command = 'delete'


def test_validate_name(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, [command, 'nonexistent'])

    assert result.exit_code == 2
    assert_bad_argument(result, 'NAME', 'SQL schema "view_data_nonexistent" not found')
    assert_log_running(caplog, command)


@patch('manage.summary_tables', noop)
@patch('manage.field_counts', noop)
def test_command(db, caplog):
    with fixture(db):
        runner = CliRunner()

        schema = f'view_data_collection_1'

        assert db.schema_exists(schema)

        result = runner.invoke(cli, [command, 'collection_1'])

        assert not db.schema_exists(schema)

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            'Arguments: name=view_data_collection_1',
            f'DROP SCHEMA "{schema}" CASCADE',
        ])
