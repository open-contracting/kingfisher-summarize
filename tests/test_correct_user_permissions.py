from click.testing import CliRunner

from ocdskingfisherviews.cli import cli

command = 'correct-user-permissions'


def test_correct_user_permissions_nonexistent(db, caplog):
    runner = CliRunner()

    db.execute('INSERT INTO views.read_only_user VALUES (%(user)s) ON CONFLICT DO NOTHING', {'user': 'nonexistent'})
    db.commit()

    result = runner.invoke(cli, [command])

    assert result.exit_code == 0
    assert len(caplog.records) == 1, [record.message for record in caplog.records]
    assert caplog.records[0].name == 'ocdskingfisher.views.cli'
    assert caplog.records[0].levelname == 'INFO'
    assert caplog.records[0].message == f'Running {command}'
