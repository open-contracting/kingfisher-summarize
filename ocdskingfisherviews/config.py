import configparser
import logging
import os

import pgpasslib

"""This holds configuration information for Kingfisher Views.
Whatever tool is calling it - CLI or other code - should create one of these, set it up as required and pass it around.
"""

logger = logging.getLogger('ocdskingfisherviews')


class Config:

    def __init__(self):
        self.database_uri = ''
        self._database_host = ''
        self._database_port = 5432
        self._database_user = ''
        self._database_name = ''
        self._database_password = ''

    def load_user_config(self):
        # First, try and load any config in the ini files
        self._load_user_config_ini()
        # Second, loook for password in .pggass
        self._load_user_config_pgpass()
        # Third, try and load any config in the env (so env overwrites ini)
        self._load_user_config_env()

    def _load_user_config_pgpass(self):
        if not self._database_name or not self._database_user:
            return

        try:
            password = pgpasslib.getpass(
                self._database_host,
                self._database_port,
                self._database_name,
                self._database_user
            )
            if password:
                self._database_password = password
                self.database_uri = 'postgresql://{}:{}@{}:{}/{}'.format(
                    self._database_user,
                    self._database_password,
                    self._database_host,
                    self._database_port,
                    self._database_name
                )

        except pgpasslib.FileNotFound:
            # Fail silently when no files found.
            return
        except pgpasslib.InvalidPermissions as e:
            logger.warning('Skipping PostgreSQL Password File: {}.\nTry: chmod 600 {}'.format(e, e.args[0]))
            return
        except pgpasslib.PgPassException as e:
            logger.warning('Skipping PostgreSQL Password File: {}'.format(e))
            return

    def _load_user_config_env(self):
        if os.environ.get('KINGFISHER_VIEWS_DB_URI'):
            self.database_uri = os.environ.get('KINGFISHER_VIEWS_DB_URI')

    def _load_user_config_ini(self):
        config = configparser.ConfigParser()

        if os.path.isfile(os.path.expanduser('~/.config/ocdskingfisher-views/config.ini')):
            config.read(os.path.expanduser('~/.config/ocdskingfisher-views/config.ini'))
        else:
            return

        self._database_host = config.get('DBHOST', 'HOSTNAME')
        self._database_port = config.get('DBHOST', 'PORT')
        self._database_user = config.get('DBHOST', 'USERNAME')
        self._database_name = config.get('DBHOST', 'DBNAME')
        self._database_password = config.get('DBHOST', 'PASSWORD', fallback='')

        self.database_uri = 'postgresql://{}:{}@{}:{}/{}'.format(
            self._database_user,
            self._database_password,
            self._database_host,
            self._database_port,
            self._database_name
        )
