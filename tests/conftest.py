import pytest

from ocdskingfisherviews.db import Database


@pytest.fixture(scope='session')
def db():
    return Database()
