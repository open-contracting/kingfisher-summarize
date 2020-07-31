from contextlib import contextmanager

from click.testing import CliRunner

from ocdskingfisherviews.cli import cli
from ocdskingfisherviews.db import pluck

ADD_VIEW_TABLES = {
    'note',
    'selected_collections',
}

REFRESH_VIEWS_TABLES = {
    'award_documents_summary',
    'award_items_summary',
    'award_suppliers_summary',
    'awards_summary',
    'awards_summary_no_data',
    'buyer_summary',
    'contract_documents_summary',
    'contract_implementation_documents_summary',
    'contract_implementation_milestones_summary',
    'contract_implementation_transactions_summary',
    'contract_items_summary',
    'contract_milestones_summary',
    'contracts_summary',
    'contracts_summary_no_data',
    'parties_summary',
    'parties_summary_no_data',
    'planning_documents_summary',
    'planning_milestones_summary',
    'planning_summary',
    'procuringentity_summary',
    'release_summary',
    'release_summary_with_data',
    'release_summary_with_checks',
    'tender_documents_summary',
    'tender_items_summary',
    'tender_milestones_summary',
    'tender_summary',
    'tender_summary_with_data',
    'tenderers_summary',
}


@contextmanager
def fixture(collections='1', dontbuild=True, name=None):
    runner = CliRunner()

    args = ['add-view', collections, 'Default']
    if name:
        args.extend(['--name', name])
    else:
        name = f"collection_{'_'.join(collections.split(','))}"
    if dontbuild:
        args.append('--dontbuild')

    result = runner.invoke(cli, args)

    try:
        yield result
    finally:
        runner.invoke(cli, ['delete-view', name])


def get_tables(schema):
    return set(pluck('SELECT table_name FROM information_schema.tables WHERE table_schema = %(schema)s',
                     {'schema': schema}))
