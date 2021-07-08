import csv
import os.path
import re
import warnings
from glob import glob

plurals = {
    'party': 'parties',
    # Never plural.
    'implementation': 'implementation',
    'planning': 'planning',
    'tag': 'tag',
    'tender': 'tender',
}
singulars = {
    'parties': 'party',
}
words = [
    'additionalClassifications',
    'additionalIdentifiers',
    'additionalProcurementCategories',
    'awardCriteria',
    'awardID',
    'budget_projectID',
    'dateSigned',
    'documentType',
    'eligibilityCriteria',
    'hasEnquiries',
    'mainProcurementCategory',
    'numberOfTenderers',
    'procurementMethod',
    'procuringEntity',
    'submissionMethod',
]
for period in ('awardPeriod', 'contractPeriod', 'enquiryPeriod', 'period', 'tenderPeriod'):
    words.extend([
        f'{period}_startDate',
        f'{period}_endDate',
        f'{period}_maxExtentDate',
        f'{period}_durationInDays',
    ])
for value in ('minValue',):
    words.extend([
        f'{value}_amount',
        f'{value}_currency',
    ])
paths = {word.lower(): word for word in words}

cwd = os.getcwd()


def custom_warning_formatter(message, category, filename, lineno, line=None):
    return str(message).replace(cwd + os.sep, '')


warnings.formatwarning = custom_warning_formatter


def humanize(word):
    return re.sub(r'(?<=[a-z])[A-Z]', lambda match: f' {match[0].lower()}', word)


def pluralize(word):
    if word in plurals:
        return plurals[word]
    if word.endswith('s'):
        return word
    return f'{word}s'


def singularize(word):
    if word in singulars:
        return singulars[word]
    if word.endswith('s'):
        return word[:-1]
    return word


def pluralize_path(path):
    return '/'.join(map(pluralize, path.split('/')))


def column_to_path(word):
    return paths.get(word, word).replace('_', '/')


def test_docs():
    basedir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))

    # Review these manually.
    skip = {
        # field_counts command
        'path',
        'object_property',
        'array_count',
        'distinct_releases',
        # field_lists command
        'field_list',
        # common_comments function
        'id',
        'release_type',
        'collection_id',
        'ocid',
        'release_id',
        'data_id',
        # note table
        'note',
        'created_at',
        # release_summary table
        'table_id',
        'package_data_id',
        'package_version',
        'total_parties_roles',
        'total_unique_award_suppliers',  # TODO
        'total_contract_link_to_awards',  # TODO
        'release_check',
        'release_check11',
        'record_check',
        'record_check11',
        'release',
        'package_data',
        # contract_implementation_transactions_summary table
        # These columns fall back to deprecated fields.
        'value_amount',
        'value_currency',
    }
    kingfisher_columns = {
        'source_id',
        'data_version',
        'store_start_at',
        'store_end_at',
        'sample',
        'transform_type',
        'transform_from_collection_id',
        'deleted_at',
    }
    string_arrays = {
        'roles',
        'tag',
    }
    party_objects = {
        'buyer',
        'procuring entity',
        'supplier',
        'tenderer',
    }
    parents = {
        'documentType': 'documents',
        'roles': 'parties',
        'type': 'milestones',
    }

    # For inconsistencies in column naming.
    overrides = {
        'milestonetype': 'type',
    }

    for filename in glob(os.path.join(basedir, 'docs', 'definitions', '*.csv')):
        basename = os.path.splitext(os.path.basename(filename))[0]

        if '_summary' in basename:  # e.g. "release" from "release_summary_no_data"
            object_name = humanize(basename.split('_summary', 1)[0])
            if '_' in object_name:  # e.g. "items" from "contract_items"
                object_name = object_name.rsplit('_', 1)[1]
            if object_name.endswith('s'):  # e.g. don't singularize "tender"
                object_name = singularize(object_name)
        else:  # e.g. "field_counts"
            object_name = 'UNKNOWN'

        with open(filename) as f:
            reader = csv.DictReader(f)

            for row in reader:
                column = row['Column Name']
                if not row['Description'] or column in skip:  # some _no_data tables have no descriptions
                    continue

                ancestors = None
                if column.startswith('total_'):
                    field_name = column.split('_', 1)[1]
                elif column.startswith(('first_', 'last_')):
                    ancestors, field_name = column.split('_', 2)[1:]
                elif column.endswith(('_counts', '_ids', '_index')):
                    field_name = column.rsplit('_', 1)[0]
                    if '_' in field_name:
                        ancestors, field_name = field_name.rsplit('_', 1)
                else:
                    field_name = column
                field_name = overrides.get(field_name, field_name)

                path = column_to_path(field_name)
                singular_path = singularize(path)
                plural_path = pluralize(path)
                if ancestors:
                    ancestors = column_to_path(ancestors)

                candidates = []

                if column in kingfisher_columns:
                    candidates = [f"``{column}`` from the Kingfisher Process ``collection`` table"]

                elif column in ('link_with_role', 'party_index', 'unique_identifier_attempt', 'identifier',
                                'classification'):
                    # TODO (break into separate if branches)
                    pass
                elif column.endswith('_index'):
                    candidates = [f"Position of the {singular_path} in the ``{plural_path}`` array"]
                elif column.startswith('first_'):
                    candidates = [f"Earliest ``{path}`` across all {ancestors} objects"]
                elif column.startswith('last_'):
                    candidates = [f"Latest ``{path}`` across all {ancestors} objects"]
                elif column.startswith(('link_to_', 'sum_')):
                    # TODO
                    pass

                elif column.endswith('_ids'):
                    if object_name in party_objects:
                        candidates = [f"The hyphenation of ``scheme`` and ``id`` for each entry of the ``{path}`` "
                                      f"array in the {object_name}'s entry in the parties array"]
                    else:
                        candidates = [f"The hyphenation of ``scheme`` and ``id`` for each entry of the ``{path}`` "
                                      f"array in the {object_name} object"]

                elif column.endswith('_counts'):
                    if plural_path in string_arrays:  # e.g. parties_role
                        candidates = [
                            f"JSONB object in which each key is a unique ``{plural_path}`` entry and each value is "
                            f"its number of occurrences across all ``{parents[plural_path]}`` arrays",
                        ]
                    elif object_name == 'release':
                        array = parents[path]
                        if ancestors:  # contract_milestonetype_counts, contract_implementation_documenttype_counts
                            array = f"{pluralize_path(ancestors)}/{array}"
                        candidates = [
                            f"JSONB object in which each key is a unique ``{path}`` value and each value is "
                            f"its number of occurrences in the ``{array}`` array",  # planning_documenttype_counts
                            f"JSONB object in which each key is a unique ``{path}`` value and each value is "
                            f"its number of occurrences across all ``{array}`` arrays",  # award_documenttype_counts
                            f"JSONB object in which each key is a unique ``{path}`` value and each value is "
                            f"its number of occurrences across all {singularize(array)} arrays",  # documenttype_counts
                        ]
                    else:
                        array = parents[path]
                        if ancestors:  # e.g. implementation_documenttype_counts
                            array = f"{pluralize_path(ancestors)}/{array}"
                        candidates = [
                            f"JSONB object in which each key is a unique ``{path}`` value and each value is "
                            f"its number of occurrences in the ``{array}`` array of the {object_name} object",
                        ]

                elif column.startswith('total_'):
                    if object_name == 'release':
                        candidates = [f"Length of the ``{path}`` array"]  # e.g. total_planning_documents, total_contracts
                        if '/' in path:  # e.g. total_contract_documents
                            candidates.append(f"Cumulative length of all ``{pluralize_path(path)}`` arrays")
                        else:  # e.g. total_documents
                            candidates.append(f"Cumulative length of all {singular_path} arrays")
                    elif object_name in party_objects:
                        candidates = [f"Length of the ``{path}`` array in the {object_name}'s entry in the parties array"]
                    else:
                        candidates = [f"Length of the ``{path}`` array in the {object_name} object"]

                elif column.endswith('_id'):
                    candidates = [f"Value of the ``id`` field in the {object_name} object"]
                    # The column prefix is expected to match the object name, unless the column is "parties_id", which
                    # is used for all organization reference fields.
                    assert column.rsplit('_', 1)[0] in (object_name, 'parties')

                elif '_summary' in basename:
                    infix = 'array' if path in string_arrays else 'field'
                    candidates = [
                        f"The {humanize(path)} object",  # e.g. procuringEntity
                        f"Value of the ``{path}`` {infix} in the {object_name} object",
                    ]

                else:
                    warnings.warn(f"{basename}.{column}: No candidates for \"{row['Description']}\"")

                # TODO
                if candidates and row['Description'] not in candidates:
                    warnings.warn(f"{basename}.{column} ({object_name}): {row['Description']} not in {candidates}")
