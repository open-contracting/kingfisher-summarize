from click.testing import CliRunner

from manage import cli
from tests import assert_log_records

command = 'install'


def test_command(db, caplog):
    runner = CliRunner()

    result = runner.invoke(cli, [command])

    assert db.one('SELECT COUNT(*) FROM views.mapping_sheets')[0] == 559
    assert result.exit_code == 0
    assert result.output == ''
    assert_log_records(caplog, command, [
        'Created tables'
    ])

    caplog.clear()

    # The command can be run a second time for no effect.
    result = runner.invoke(cli, [command])

    assert db.one('SELECT COUNT(*) FROM views.mapping_sheets')[0] == 559
    assert result.exit_code == 0
    assert result.output == ''
    assert_log_records(caplog, command, [
        'Created tables'
    ])
