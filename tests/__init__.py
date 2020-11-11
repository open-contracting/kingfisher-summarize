import re
from contextlib import contextmanager

from click.testing import CliRunner

from ocdskingfisherviews.cli import cli


def noop(*args, **kwargs):
    return


@contextmanager
def fixture(db, collections='1', name=None, tables_only=None, field_counts=True):
    runner = CliRunner()

    args = ['add-view', collections, 'Default']
    if name:
        args.extend(['--name', name])
    else:
        name = f"collection_{'_'.join(collections.split(','))}"
    if tables_only:
        args.append('--tables-only')
    if not field_counts:
        args.append('--no-field-counts')

    result = runner.invoke(cli, args)

    try:
        yield result
    finally:
        db.connection.rollback()
        runner.invoke(cli, ['delete-view', name])


# Click seems to use different quoting on different platforms.
def assert_bad_argument(result, argument, message):
    expression = rf"""\nError: Invalid value for ['"']{argument}['"']: {message}\n$"""
    assert re.search(expression, result.output)


def assert_log_running(caplog, command):
    assert len(caplog.records) == 1, [record.message for record in caplog.records]
    assert caplog.records[0].name == 'ocdskingfisher.views.cli'
    assert caplog.records[0].levelname == 'INFO'
    assert caplog.records[0].message == f'Running {command}'


def assert_log_records(caplog, name, messages):
    records = [record for record in caplog.records if record.name == f'ocdskingfisher.views.{name}']

    assert len(records) == len(messages), [record.message for record in records]
    assert all(record.levelname == 'INFO' for record in records)
    for i, record in enumerate(records):
        message = messages[i]
        if isinstance(message, str):
            assert record.message == message, f'{record.message!r} != {message!r}'
        else:
            assert message.search(record.message)
