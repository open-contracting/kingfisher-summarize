import os
import glob
import inspect
import importlib

import ocdskingfisherviews.cli.commands.base


def gather_cli_commands_instances(config=None):
    commands = {}
    dir_path = os.path.dirname(os.path.realpath(__file__))
    commands_dir = os.path.join(dir_path, 'commands')
    for file in glob.glob(commands_dir + '/*.py'):
        module = importlib.import_module('ocdskingfisherviews.cli.commands.' + file.split('/')[-1].split('.')[0])
        for item in dir(module):
            value = getattr(module, item)
            if inspect.isclass(value) and issubclass(value, ocdskingfisherviews.cli.commands.base.CLICommand) \
                    and value is not ocdskingfisherviews.cli.commands.base.CLICommand:
                commands[getattr(value, 'command')] = value(config=config)
    return commands
