from datetime import datetime
from decimal import Decimal
from unittest.mock import patch

import pytest

from tests import fixture


@patch('manage.dependency_graph', dict)
@pytest.mark.parametrize(('text', 'expected'), [
    ('123.456', Decimal('123.456')),
    ('123a', None),
])
def test_convert_to_numeric(db, text, expected):
    with fixture(db, field_counts=False):
        value = db.one('SELECT summary_collection_1.convert_to_numeric(%(text)s)', {'text': text})[0]

        assert value == expected


@patch('manage.dependency_graph', dict)
@pytest.mark.parametrize(('text', 'expected'), [
    ('2020-02-29T00:00:00Z', datetime(2020, 2, 29, 0, 0)),
    ('2020-02-30T00:00:00Z', None),
    ('0000-00-00T00:00:00Z', None),
])
def test_convert_to_timestamp(db, text, expected):
    with fixture(db, field_counts=False):
        value = db.one('SELECT summary_collection_1.convert_to_timestamp(%(text)s)', {'text': text})[0]

        assert value == expected


@patch('manage.dependency_graph', dict)
@pytest.mark.parametrize(('scheme', 'id_', 'expected'), [
    ('prefix', '123', 'prefix-123'),
    ('prefix', None, 'prefix'),
    (None, '123', '123'),
    (None, None, None),
])
def test_hyphenate(db, scheme, id_, expected):
    with fixture(db, field_counts=False):
        value = db.one('SELECT summary_collection_1.hyphenate(%(scheme)s, %(id)s)', {'scheme': scheme, 'id': id_})[0]

        assert value == expected
