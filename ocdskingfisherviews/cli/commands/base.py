import os.path

import logzero
from logzero import logger

from ocdskingfisherviews.config import get_database_uri


class CLICommand:
    command = ''

    def __init__(self):
        self.database_uri = get_database_uri()

    def configure_subparser(self, subparser):
        pass

    def run_command(self, args):
        if args.logfile:
            logzero.logfile(os.path.expanduser(args.logfile))

        try:
            self.run_logged_command(args)
        except Exception as e:
            logger.exception(e)
            raise
