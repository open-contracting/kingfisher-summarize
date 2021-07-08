import csv
import os.path
import warnings
from glob import glob

cwd = os.getcwd()


def custom_warning_formatter(message, category, filename, lineno, line=None):
    return str(message).replace(cwd + os.sep, '')


warnings.formatwarning = custom_warning_formatter


def test_docs():
    basedir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))

    # Review these manually.
    skip = {
        # common_comments
        'id',
        'release_type',
        'collection_id',
        'ocid',
        'release_id',
        'data_id',
        # note
        'note',
        'created_at',
        # field_counts
        'object_property',
        'array_count',
        'distinct_releases',
        # release_summary
        'table_id',
        'package_data_id',
        'package_version',
        'release_check',
        'release_check11',
        'record_check',
        'record_check11',
    }

    kingfisher = {
        'source_id',
        'data_version',
        'store_start_at',
        'store_end_at',
        'sample',
        'transform_type',
        'transform_from_collection_id',
        'deleted_at',
    }
    singulars = {
        'parties': 'party',
    }
    plurals = {
        'party': 'parties',
    }
    arrays = {
        'roles',
        'tag',
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
    capitals = {word.lower(): word for word in words}

    for filename in glob(os.path.join(basedir, 'docs', 'definitions', '*.csv')):
        basename = os.path.splitext(os.path.basename(filename))[0]

        if '_summary' in basename:  # ..._summary and ..._summary_no_data
            object_name = basename.split('_summary', 1)[0]
            if '_' in object_name:  # e.g. "items" from "contract_items"
                object_name = object_name.rsplit('_', 1)[1]
            if object_name.endswith('s'):  # e.g. don't singularize "tender"
                object_name = singulars.get(object_name, object_name[:-1])
        else:
            object_name = 'UNKNOWN'

        with open(filename) as f:
            reader = csv.DictReader(f)

            for row in reader:
                column = row['Column Name']
                if not row['Description'] or column in skip:
                    continue

                if column.startswith('total_'):
                    name = column[6:]
                elif column.endswith('_index'):
                    name = column[:-6]
                else:
                    name = column

                plural = plurals.get(name, f'{name}s')
                singular = singulars.get(name, name[:-1])
                capital = capitals.get(name, name).replace('_', '/')

                candidates = []

                if column in kingfisher:
                    candidates = [f"``{column}`` from the Kingfisher Process ``collection`` table"]
                elif column in ('link_with_role', 'party_index', 'unique_identifier_attempt', 'identifier', 'classification'):
                    # TODO (break into separate if branches)
                    pass
                elif column.endswith('_index'):
                    candidates = [f"Position of the {name} in the ``{plural}`` array"]
                elif column.endswith(('_counts', '_ids')):
                    # TODO (break into separate if branches)
                    pass
                elif column.startswith('first_'):
                    # TODO
                    pass
                elif column.startswith('last_'):
                    # TODO
                    pass
                elif column.startswith(('link_to_', 'sum_')):
                    # TODO
                    pass

                elif column.startswith('total_'):
                    if object_name == 'release':
                        if '/' in capital:
                            head, tail = capital.split('/', 1)
                            infix = f'{head}s/{tail}'
                        else:
                            infix = capital

                        candidates = [
                            f"Length of the ``{capital}`` array",
                            f"Cumulative length of all {singular} arrays",
                            f"Cumulative length of all ``{infix}`` arrays",
                        ]
                    else:
                        candidates = [f"Length of the ``{capital}`` array in the {object_name} object"]

                elif column.endswith('_id'):
                    candidates = [f"Value of the ``id`` field in the {object_name} object"]
                    # The column is "parties_id" even though not in the parties array.
                    assert column.rsplit('_', 1)[0] in (object_name, 'parties')

                elif '_summary' in basename:  # ..._summary and ..._summary_no_data
                    if capital in arrays:
                        infix = 'array'
                    else:
                        infix = 'field'
                    candidates = [
                        f"The {capital} object",
                        f"Value of the ``{capital}`` {infix} in the {object_name} object",
                    ]

                elif '_' not in column:
                    candidates = [
                        f"The {capital} object",
                    ]
                else:
                    warnings.warn(f"{basename}.{column}: No candidates for \"{row['Description']}\"")

                # TODO
                if candidates and row['Description'] not in candidates:
                    warnings.warn(f"{basename}.{column}: {row['Description']} not in {candidates}")
