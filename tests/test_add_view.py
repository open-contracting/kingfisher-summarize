from click.testing import CliRunner

from ocdskingfisherviews.cli import cli
from ocdskingfisherviews.db import schema_exists
from tests import ADD_VIEW_TABLES, REFRESH_VIEWS_TABLES, fetch_all, fixture, get_tables


def test_validate_collections_noninteger(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, ['add-view', 'a'])

    assert result.exit_code == 2
    assert result.output.endswith('\nError: Invalid value for "COLLECTIONS": Collection IDs must be integers\n')
    assert len(caplog.records) == 1
    assert caplog.records[0].levelname == 'INFO'
    assert caplog.records[0].message == 'Running add-view'


def test_validate_collections_nonexistent(caplog):
    runner = CliRunner()

    result = runner.invoke(cli, ['add-view', '1,10,100'])

    assert result.exit_code == 2
    assert result.output.endswith('\nError: Invalid value for "COLLECTIONS": Collection IDs {10, 100} not found\n')
    assert len(caplog.records) == 1
    assert caplog.records[0].levelname == 'INFO'
    assert caplog.records[0].message == 'Running add-view'


def test_command(caplog):
    with fixture() as result:
        assert schema_exists('view_data_collection_1')
        assert fetch_all('SELECT * FROM view_data_collection_1.selected_collections') == [(1,)]
        assert fetch_all('SELECT id, note FROM view_data_collection_1.note') == [(1, 'Default')]

        assert result.exit_code == 0
        assert result.output == ''
        assert len(caplog.records) == 2
        assert caplog.records[0].levelname == 'INFO'
        assert caplog.records[0].message == 'Running add-view'
        assert caplog.records[1].levelname == 'INFO'
        assert caplog.records[1].message == 'Added collection_1'


def test_command_multiple(caplog):
    with fixture(collections='1,2') as result:
        assert schema_exists('view_data_collection_1_2')
        assert fetch_all('SELECT * FROM view_data_collection_1_2.selected_collections') == [(1,), (2,)]
        assert fetch_all('SELECT id, note FROM view_data_collection_1_2.note') == [(1, 'Default')]

        assert result.exit_code == 0
        assert result.output == ''
        assert len(caplog.records) == 2
        assert caplog.records[0].levelname == 'INFO'
        assert caplog.records[0].message == 'Running add-view'
        assert caplog.records[1].levelname == 'INFO'
        assert caplog.records[1].message == 'Added collection_1_2'


def test_command_name(caplog):
    with fixture(name='custom'):
        assert schema_exists('view_data_custom')


def test_command_build(caplog):
    with fixture(dontbuild=False):
        assert get_tables('view_data_collection_1') == ADD_VIEW_TABLES | REFRESH_VIEWS_TABLES | {'field_counts'}
