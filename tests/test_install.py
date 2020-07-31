from click.testing import CliRunner

from ocdskingfisherviews.cli import cli
from ocdskingfisherviews.db import get_cursor
from tests import assert_log_records

command = 'install'


def test_command(caplog):
    runner = CliRunner()
    cursor = get_cursor()

    result = runner.invoke(cli, [command])
    cursor.execute('SELECT COUNT(*) FROM views.mapping_sheets')

    assert cursor.fetchone()[0] == 559
    assert result.exit_code == 0
    assert result.output == ''
    assert_log_records(caplog, command, [
        'Created tables'
    ])

    caplog.clear()

    # The command can be run a second time for no effect.
    result = runner.invoke(cli, [command])
    cursor.execute('SELECT COUNT(*) FROM views.mapping_sheets')

    assert cursor.fetchone()[0] == 559
    assert result.exit_code == 0
    assert result.output == ''
    assert_log_records(caplog, command, [
        'Created tables'
    ])
