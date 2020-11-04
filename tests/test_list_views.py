from datetime import datetime
from textwrap import dedent
from unittest.mock import patch

from click.testing import CliRunner
from psycopg2 import sql

from ocdskingfisherviews.cli import cli
from ocdskingfisherviews.db import commit, get_cursor
from tests import assert_log_records, assert_log_running, fixture, noop

command = 'list-views'


def test_command_none(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, [command])

    assert result.exit_code == 0
    assert result.output == ''
    assert_log_running(caplog, command)


@patch('ocdskingfisherviews.cli.refresh_views', noop)
@patch('ocdskingfisherviews.cli.field_counts', noop)
def test_command(caplog):
    with fixture():
        runner = CliRunner()

        result = runner.invoke(cli, [command])

        text = dedent(f"""\
        | Name         | Collections   | Note                          |
        |--------------|---------------|-------------------------------|
        | collection_1 | 1             | Default (202""")

        assert result.exit_code == 0
        assert result.output.startswith(text)
        assert_log_records(caplog, command, [])


@patch('ocdskingfisherviews.cli.refresh_views', noop)
@patch('ocdskingfisherviews.cli.field_counts', noop)
def test_command_multiple(caplog):
    with fixture(collections='1,2'):
        runner = CliRunner()

        cursor = get_cursor()
        statement = sql.SQL("INSERT INTO {table} (note, created_at) VALUES (%(note)s, %(created_at)s)").format(
            table=sql.Identifier(f'view_data_collection_1_2', 'note'))
        cursor.execute(statement, {'note': 'Another', 'created_at': datetime(2000, 1, 1)})
        commit()

        result = runner.invoke(cli, [command])

        text = dedent(f"""\
        | Name           | Collections   | Note                          |
        |----------------|---------------|-------------------------------|
        | collection_1_2 | 1, 2          | Another (2000-01-01 00:00:00) |
        |                |               | Default (202""")

        assert result.exit_code == 0
        assert result.output.startswith(text)
        assert_log_records(caplog, command, [])
