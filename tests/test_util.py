from click.testing import CliRunner

from ocdskingfisherviews.cli import cli
from tests import assert_log_records, fixture

command = 'docs-table-ref'


# This is a development command, so we don't bother testing it deeply.
def test_command(db, caplog):
    with fixture(db):
        runner = CliRunner()

        result = runner.invoke(cli, [command, 'collection_1'])

        assert result.exit_code == 0
        assert result.output == ''
        assert_log_records(caplog, command, [])
