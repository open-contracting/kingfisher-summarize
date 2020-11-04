from click.testing import CliRunner

from ocdskingfisherviews.cli import cli
from tests import (ADD_VIEW_TABLES, REFRESH_VIEWS_TABLES, assert_bad_argument, assert_log_records, assert_log_running,
                   fixture, get_tables)

command = 'add-view'


def test_validate_collections_noninteger(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, [command, 'a'])

    assert result.exit_code == 2
    assert_bad_argument(result, 'COLLECTIONS', 'Collection IDs must be integers')
    assert_log_running(caplog, command)


def test_validate_collections_nonexistent(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, [command, '1,10,100'])

    assert result.exit_code == 2
    assert_bad_argument(result, 'COLLECTIONS', 'Collection IDs {10, 100} not found')
    assert_log_running(caplog, command)


def test_command(db, caplog):
    with fixture(db) as result:
        assert db.schema_exists('view_data_collection_1')
        assert db.all('SELECT * FROM view_data_collection_1.selected_collections') == [(1,)]
        assert db.all('SELECT id, note FROM view_data_collection_1.note') == [(1, 'Default')]

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            'Arguments: collections=(1,) note=Default name=None dontbuild=True tables_only=False',
            'Added collection_1',
        ])


def test_command_multiple(db, caplog):
    with fixture(db, collections='1,2') as result:
        assert db.schema_exists('view_data_collection_1_2')
        assert db.all('SELECT * FROM view_data_collection_1_2.selected_collections') == [(1,), (2,)]
        assert db.all('SELECT id, note FROM view_data_collection_1_2.note') == [(1, 'Default')]

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            'Arguments: collections=(1, 2) note=Default name=None dontbuild=True tables_only=False',
            'Added collection_1_2',
        ])


def test_command_build(db, caplog):
    with fixture(db, dontbuild=False, tables_only=True) as result:
        assert get_tables(db, 'view_data_collection_1') == ADD_VIEW_TABLES | REFRESH_VIEWS_TABLES | {'field_counts'}

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            'Arguments: collections=(1,) note=Default name=None dontbuild=False tables_only=True',
            'Added collection_1',
            'Running refresh-views',
            'Running field-counts',
            'Running correct-user-permissions',
        ])


def test_command_name(db, caplog):
    with fixture(db, name='custom') as result:
        assert db.schema_exists('view_data_custom')

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [
            'Arguments: collections=(1,) note=Default name=custom dontbuild=True tables_only=False',
            'Added custom',
        ])
