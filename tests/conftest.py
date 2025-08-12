import pytest

from ocdskingfishersummarize.db import Database


@pytest.fixture(scope="session")
def db():
    return Database()
