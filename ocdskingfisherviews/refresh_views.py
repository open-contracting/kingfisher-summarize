import glob
import os
from collections import OrderedDict
from timeit import default_timer as timer

from logzero import logger


def refresh_views(engine, viewname, remove=False):
    dir_path = os.path.dirname(os.path.realpath(__file__))

    sql_scripts_path = os.path.join(dir_path, '../sql')
    all_scripts = glob.glob(sql_scripts_path + '/*.sql')

    statements = OrderedDict()

    if remove:
        all_scripts.sort(reverse=True)
    else:
        all_scripts.sort()

    for script_path in all_scripts:
        script_name = script_path.split('/')[-1].split('.')[0]

        with open(script_path) as script_file:
            script = script_file.read()

        if script_name.endswith('_downgrade') and remove:
            statements[script_name] = script
        if not script_name.endswith('_downgrade') and not remove:
            statements[script_name] = script

    start_all = timer()

    for statement_name, statement in statements.items():
        # special marker to split statements up.
        statement_parts = statement.split('----')
        start = timer()
        logger.info('running script: {}'.format(statement_name))

        for statement_part in statement_parts:
            with engine.begin() as connection:
                schema_name = engine.dialect.identifier_preparer.quote_schema('view_data_' + viewname)
                connection.execute('SET search_path = {}, public;'.format(schema_name))
                connection.execute(statement_part, tuple())

        logger.info('running time: {}s'.format(timer() - start))

    logger.info('total running time: {}s'.format(timer() - start_all))
