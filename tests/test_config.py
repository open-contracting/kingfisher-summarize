import os.path
from configparser import NoOptionError, NoSectionError
from unittest import TestCase
from unittest.mock import patch

import pytest

from ocdskingfisherviews.config import Config


def get_database_uri():
    config = Config()
    config.load_user_config()
    return config.database_uri


def fixture(filename):
    path = os.path.join('tests', 'fixtures', filename)
    if not os.path.isfile(path):
        raise Exception('fixture {} is missing'.format(path))
    return path


@patch.dict('os.environ', {'KINGFISHER_VIEWS_DB_URI': 'postgresql:///test', 'PGPASSFILE': fixture('pgpass.txt')})
@patch('os.path.expanduser')
def test_env(ini):
    ini.return_value = fixture('config.ini')

    database_uri = get_database_uri()

    assert database_uri == 'postgresql:///test'


@patch.dict('os.environ', {'KINGFISHER_VIEWS_DB_URI': ''})
@patch('os.path.expanduser')
class NoEnv(TestCase):
    @pytest.fixture(autouse=True)
    def fixtures(self, caplog):
        self.caplog = caplog

    def test_ini(self, ini):
        ini.return_value = fixture('config.ini')

        database_uri = get_database_uri()

        assert database_uri == 'postgresql://ocdskingfisher:secret@localhost:5432/ocdskingfisher'
        assert len(self.caplog.records) == 0

    @patch.dict('os.environ', {'PGPASSFILE': fixture('pgpass.txt')})
    def test_pgpass(self, ini):
        ini.return_value = fixture('config.ini')

        database_uri = get_database_uri()

        assert database_uri == 'postgresql://ocdskingfisher:protected@localhost:5432/ocdskingfisher'
        assert len(self.caplog.records) == 0

    @patch.dict('os.environ', {'PGPASSFILE': fixture('pgpass-empty-file.txt')})
    def test_pgpass_empty_file(self, ini):
        ini.return_value = fixture('config.ini')

        database_uri = get_database_uri()

        assert database_uri == 'postgresql://ocdskingfisher:secret@localhost:5432/ocdskingfisher'
        assert len(self.caplog.records) == 0

    @patch.dict('os.environ', {'PGPASSFILE': fixture('pgpass-no-match.txt')})
    def test_pgpass_no_match(self, ini):
        ini.return_value = fixture('config.ini')

        database_uri = get_database_uri()

        assert database_uri == 'postgresql://ocdskingfisher:secret@localhost:5432/ocdskingfisher'
        assert len(self.caplog.records) == 0

    @patch.dict('os.environ', {'PGPASSFILE': fixture('pgpass-bad-permissions.txt')})
    def test_pgpass_bad_permissions(self, ini):
        ini.return_value = fixture('config.ini')

        database_uri = get_database_uri()

        assert database_uri == 'postgresql://ocdskingfisher:secret@localhost:5432/ocdskingfisher'
        assert len(self.caplog.records) == 1
        assert self.caplog.records[0].levelname == 'WARNING'
        assert self.caplog.records[0].message == 'Skipping PostgreSQL Password File: Invalid Permissions for tests/' \
                                                 'fixtures/pgpass-bad-permissions.txt: 0o644.\nTry: chmod 600 tests/' \
                                                 'fixtures/pgpass-bad-permissions.txt'

    @patch.dict('os.environ', {'PGPASSFILE': fixture('pgpass-bad-port.txt')})
    def test_pgpass_bad_port(self, ini):
        ini.return_value = fixture('config.ini')

        database_uri = get_database_uri()

        assert database_uri == 'postgresql://ocdskingfisher:secret@localhost:5432/ocdskingfisher'
        assert len(self.caplog.records) == 1
        assert self.caplog.records[0].levelname == 'WARNING'
        assert self.caplog.records[0].message == 'Skipping PostgreSQL Password File: Error validating port value ' \
                                                 '"invalid"'

    def test_ini_nonexistent(self, ini):
        ini.return_value = 'nonexistent.ini'

        database_uri = get_database_uri()

        assert database_uri == ''

    def test_ini_empty_file(self, ini):
        ini.return_value = fixture('config-empty-file.ini')

        with pytest.raises(NoSectionError):
            get_database_uri()

    def test_ini_empty_section(self, ini):
        ini.return_value = fixture('config-empty-section.ini')

        with pytest.raises(NoOptionError):
            get_database_uri()

    def test_ini_empty_dbname(self, ini):
        ini.return_value = fixture('config-empty-dbname.ini')

        database_uri = get_database_uri()

        assert database_uri == 'postgresql://:@:invalid/'

    def test_ini_bad_port(self, ini):
        ini.return_value = fixture('config-bad-port.ini')

        with pytest.raises(Exception) as excinfo:
            get_database_uri()

        assert str(excinfo.value) == "invalid literal for int() with base 10: 'invalid'"

    @patch('getpass.getuser')
    def test_ini_empty_options(self, user, ini):
        user.return_value = 'morgan'
        ini.return_value = fixture('config-empty-options.ini')

        database_uri = get_database_uri()

        assert database_uri == 'postgresql://:@:5432/ocdskingfisher'
