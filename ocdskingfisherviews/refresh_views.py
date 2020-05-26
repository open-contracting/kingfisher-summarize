import glob
import logging
import os
from collections import OrderedDict
import re
from timeit import default_timer as timer

COMMENT = '/*kingfisher-views refresh-views*/\n'


def refresh_views(engine, viewname, remove=False, tables_only=False):
    logger = logging.getLogger('ocdskingfisher.views.refresh-views')

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
                schema_name = engine.dialect.identifier_preparer.quote('view_data_' + viewname)
                connection.execute('SET search_path = {}, public;'.format(schema_name))

                if tables_only:
                    statement_part = re.sub('^create view', 'create table', statement_part, flags=re.M | re.I)
                    statement_part = re.sub('^drop view', 'drop table', statement_part, flags=re.M | re.I)

                connection.execute(COMMENT + statement_part, tuple())

        logger.info('running time: {}s'.format(timer() - start))

    logger.info('total running time: {}s'.format(timer() - start_all))
