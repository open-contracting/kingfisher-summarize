from datetime import datetime
from textwrap import dedent
from unittest.mock import patch

from click.testing import CliRunner
from psycopg2 import sql

from manage import cli
from tests import assert_log_records, assert_log_running, fixture, noop

command = 'index'


def test_command_none(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, [command])

    assert result.exit_code == 0
    assert result.output == ''
    assert_log_running(caplog, command)


@patch('manage.summary_tables', noop)
@patch('manage.field_counts', noop)
def test_command(db, caplog):
    with fixture(db):
        runner = CliRunner()

        result = runner.invoke(cli, [command])

        text = dedent("""\
        | Name         | Collections   | Note                          |
        |--------------|---------------|-------------------------------|
        | collection_1 | 1             | Default (202""")

        assert result.exit_code == 0
        assert result.output.startswith(text)
        assert_log_records(caplog, command, [])


@patch('manage.summary_tables', noop)
@patch('manage.field_counts', noop)
def test_command_multiple(db, caplog):
    with fixture(db, collections='1,2'):
        runner = CliRunner()

        statement = sql.SQL("INSERT INTO {table} (note, created_at) VALUES (%(note)s, %(created_at)s)").format(
            table=sql.Identifier('view_data_collection_1_2', 'note'))
        db.execute(statement, {'note': 'Another', 'created_at': datetime(2000, 1, 1)})
        db.commit()

        result = runner.invoke(cli, [command])

        text = dedent("""\
        | Name           | Collections   | Note                          |
        |----------------|---------------|-------------------------------|
        | collection_1_2 | 1, 2          | Another (2000-01-01 00:00:00) |
        |                |               | Default (202""")

        assert result.exit_code == 0
        assert result.output.startswith(text)
        assert_log_records(caplog, command, [])
