import configparser
import getpass
import logging
import os

import pgpasslib

logger = logging.getLogger('ocdskingfisherviews')


def get_database_uri():
    database_uri = os.getenv('KINGFISHER_VIEWS_DB_URI')
    if database_uri:
        return database_uri

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

    # Instead of setting the database URI to "postgresql://:@:5432/dbname" (which implicitly uses the default
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

    return 'postgresql://{}:{}@{}:{}/{}'.format(username, password, hostname, port, dbname)
