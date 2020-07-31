from datetime import datetime
from textwrap import dedent

from click.testing import CliRunner
from psycopg2 import sql

from ocdskingfisherviews.cli import cli
from ocdskingfisherviews.db import commit, get_cursor
from tests import fixture


def test_command_none(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, ['list-views'])

    assert result.exit_code == 0
    assert result.output == ''
    assert len(caplog.records) == 1
    assert caplog.records[0].message == 'Running list-views'


def test_command(caplog):
    with fixture():
        runner = CliRunner()

        result = runner.invoke(cli, ['list-views'])

        text = dedent(f"""\
        -----
        Name: collection_1
        Schema: view_data_collection_1
        Collection ID: 1
        Note: Default ({datetime.utcnow().strftime('%Y-%m-%d')} """)

        assert result.exit_code == 0
        assert result.output.startswith(text)
        assert len(caplog.records[3:]) == 0


def test_command_multiple(caplog):
    with fixture(collections='1,2'):
        runner = CliRunner()

        cursor = get_cursor()
        cursor.execute(sql.SQL("INSERT INTO {table} (note, created_at) VALUES (%(note)s, %(created_at)s)").format(
            table=sql.Identifier(f'view_data_collection_1_2', 'note')), {'note': 'Another', 'created_at': datetime(2000, 1, 1)})
        commit()

        result = runner.invoke(cli, ['list-views'])

        text = dedent(f"""\
        -----
        Name: collection_1_2
        Schema: view_data_collection_1_2
        Collection ID: 1
        Collection ID: 2
        Note: Another (2000-01-01 00:00:00)
        Note: Default ({datetime.utcnow().strftime('%Y-%m-%d')} """)

        assert result.exit_code == 0
        assert result.output.startswith(text)
        assert len(caplog.records[3:]) == 0
