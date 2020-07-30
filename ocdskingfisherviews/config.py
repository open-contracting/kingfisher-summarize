import configparser
import getpass
import logging
import os
from urllib.parse import urlparse

import pgpasslib

logger = logging.getLogger('ocdskingfisher.views.config')


def get_database_uri():
    """
    Returns the database connection URL.
    """
    database_url = os.getenv('KINGFISHER_VIEWS_DB_URI')
    if database_url:
        return database_url

    return 'postgresql://{user}:{password}@{host}:{port}/{dbname}'.format(**get_connection_parameters())


def get_connection_parameters():
    """
    Returns the database connection parameters as a dict.
    """
    database_url = os.getenv('KINGFISHER_VIEWS_DB_URI')
    if database_url:
        parts = urlparse(database_url)
        return {
            'user': parts.username,
            'password': parts.password,
            'host': parts.hostname,
            'port': parts.port,
            'dbname': parts.path[1:],
        }

    userpath = '~/.config/ocdskingfisher-views/config.ini'
    fullpath = os.path.expanduser(userpath)
    if not os.path.isfile(fullpath):
        raise Exception('You must either set the KINGFISHER_VIEWS_DB_URI environment variable or create the {} file.\n'
                        'See https://kingfisher-views.readthedocs.io/en/latest/get-started.html'.format(userpath))

    # Same defaults as https://github.com/gmr/pgpasslib/blob/master/pgpasslib.py
    default_username = getpass.getuser()
    default_hostname = 'localhost'

    config = configparser.ConfigParser()
    config.read(fullpath)

    username = config.get('DBHOST', 'USERNAME', fallback=default_username)
    password = config.get('DBHOST', 'PASSWORD', fallback='')
    hostname = config.get('DBHOST', 'HOSTNAME', fallback=default_hostname)
    try:
        port = config.getint('DBHOST', 'PORT', fallback=5432)
    except ValueError as e:
        raise Exception('PORT is invalid in {}. ({})'.format(userpath, e))
    # We don't use the default database name (that matches the user name) as this is rarely what the user intends.
    dbname = config.get('DBHOST', 'DBNAME')

    # Instead of setting the database URL to "postgresql://:@:5432/dbname" (which implicitly uses the default
    # username and default hostname), we set it to, for example, "postgresql://morgan:@localhost:5432/dbname".
    if not username:
        username = default_username
    if not hostname:
        hostname = default_hostname
    if not dbname:
        raise Exception('You must set DBNAME in {}.'.format(userpath))

    # https://pgpasslib.readthedocs.io/en/latest/
    try:
        password_pgpass = pgpasslib.getpass(hostname, port, dbname, username)
        if password_pgpass is not None:
            password = password_pgpass
    except pgpasslib.FileNotFound:
        pass
    except pgpasslib.InvalidPermissions as e:
        logger.warning('Skipping PostgreSQL Password File: {}.\nTry: chmod 600 {}'.format(e, e.args[0]))
    except pgpasslib.InvalidEntry as e:
        logger.warning('Skipping PostgreSQL Password File: {}'.format(e))

    return {
        'user': username,
        'password': password,
        'host': hostname,
        'port': port,
        'dbname': dbname,
    }
