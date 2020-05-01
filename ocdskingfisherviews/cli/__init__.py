#!/usr/bin/env python
import argparse
import json
import logging
import logging.config
import os

import ocdskingfisherviews.cli.util


def run_command(input_args=None):
    logging_config_file_full_path = os.path.expanduser('~/.config/ocdskingfisher-views/logging.json')
    if os.path.isfile(logging_config_file_full_path):
        with open(logging_config_file_full_path) as f:
            logging.config.dictConfig(json.load(f))

    logger = logging.getLogger('ocdskingfisher.views.cli')

    parser = argparse.ArgumentParser()

    subparsers = parser.add_subparsers(dest='subcommand')

    commands = ocdskingfisherviews.cli.util.gather_cli_commands_instances()

    for command in commands.values():
        command.configure_subparser(subparsers.add_parser(command.command))

    args = parser.parse_args(input_args)

    if args.subcommand and args.subcommand in commands.keys():
        logger.info("Running CLI command " + args.subcommand + " " + repr(args))
        commands[args.subcommand].run_command(args)
    else:
        print("Please select a subcommand (try --help)")
