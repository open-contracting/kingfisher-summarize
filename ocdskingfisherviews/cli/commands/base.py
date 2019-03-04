import os.path

import logzero
from logzero import logger


class CLICommand:
    command = ''

    def __init__(self, config=None):
        self.collection = None
        self.config = config

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
