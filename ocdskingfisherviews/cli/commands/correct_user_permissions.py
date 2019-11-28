
import sqlalchemy as sa

import ocdskingfisherviews.cli.commands.base
from ocdskingfisherviews.correct_user_permissions import correct_user_permissions


class CorrectUserPermissionsCLICommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'correct-user-permissions'

    def configure_subparser(self, subparser):
        pass

    def run_command(self, args):

        engine = sa.create_engine(self.config.database_uri)
        correct_user_permissions(engine)
