#!/usr/bin/env python
import argparse

import ocdskingfisherviews.cli.util


def run_command(input_args=None):
    parser = argparse.ArgumentParser()

    subparsers = parser.add_subparsers(dest='subcommand')

    commands = ocdskingfisherviews.cli.util.gather_cli_commands_instances()

    for command in commands.values():
        command.configure_subparser(subparsers.add_parser(command.command))

    args = parser.parse_args(input_args)

    if args.subcommand and args.subcommand in commands.keys():
        commands[args.subcommand].run_command(args)
    else:
        print("Please select a subcommand (try --help)")
