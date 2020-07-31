import concurrent.futures
import glob
import logging
import os
import re
from timeit import default_timer as timer

from psycopg2 import sql

from ocdskingfisherviews.db import commit, pluck


def get_schemas():
    """
    Returns a list of schema names that start with "view_data_".
    """
    return pluck("SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE 'view_data_%'")


def read_sql_files(remove=False):
    contents = {}

    filenames = glob.glob(os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', 'sql', '*.sql'))
    for filename in sorted(filenames, reverse=remove):
        basename = os.path.splitext(os.path.basename(filename))[0]
        if not (basename.endswith('_downgrade') ^ remove):
            with open(filename) as f:
                contents[basename] = f.read()

    return contents


def do_correct_user_permissions(cursor):
    schemas = [sql.Identifier(schema) for schema in get_schemas()]

    for user in pluck('SELECT username FROM views.read_only_user'):
        user = sql.Identifier(user)

        # Grant access to all tables in the public schema.
        cursor.execute(sql.SQL('GRANT USAGE ON SCHEMA public TO {user}').format(user=user))
        cursor.execute(sql.SQL('GRANT SELECT ON ALL TABLES IN SCHEMA public TO {user}').format(user=user))

        # Grant access to the mapping_sheets table in the views schema.
        cursor.execute(sql.SQL('GRANT USAGE ON SCHEMA views TO {user}').format(user=user))
        cursor.execute(sql.SQL('GRANT SELECT ON views.mapping_sheets TO {user}').format(user=user))

        # Grant access to all tables in every schema created by Kingfisher Views.
        for schema in schemas:
            cursor.execute(sql.SQL('GRANT USAGE ON SCHEMA {schema} TO {user}').format(schema=schema, user=user))
            cursor.execute(sql.SQL('GRANT SELECT ON ALL TABLES IN SCHEMA {schema} TO {user}').format(
                schema=schema, user=user))

    commit()


def do_refresh_views(cursor, schema, remove=False, tables_only=False):
    logger = logging.getLogger('ocdskingfisher.views.refresh-views')

    command_timer = timer()
    for basename, content in read_sql_files(remove).items():
        file_timer = timer()
        logger.info(f'Running {basename}')

        # Special marker to split content up.
        for part in content.split('----'):
            cursor.execute(sql.SQL('SET search_path = {schema}, public').format(schema=sql.Identifier(schema)))
            if tables_only:
                part = re.sub('^CREATE VIEW', 'CREATE TABLE', part, flags=re.MULTILINE | re.IGNORECASE)
                part = re.sub('^DROP VIEW', 'DROP TABLE', part, flags=re.MULTILINE | re.IGNORECASE)
            cursor.execute('/*kingfisher-views refresh-views*/\n' + part, tuple())
            commit()

        logger.info(f'Time: {timer() - file_timer}s')

    logger.info(f'Total time: {timer() - command_timer}s')


def do_field_counts(cursor, schema, remove=False, threads=1):
    logger = logging.getLogger('ocdskingfisher.views.field-counts')

    search_path_string = sql.SQL('SET search_path = {schema}, public').format(schema=sql.Identifier(schema))

    if remove:
        cursor.execute(search_path_string)
        cursor.execute('DROP TABLE IF EXISTS field_counts_temp')
        cursor.execute('DROP TABLE IF EXISTS field_counts')
        commit()

        logger.info('Dropped tables field_counts and field_counts_temp')
        return

    def _run_collection(collection):
        collection_timer = timer()
        logger.info(f'Processing collection ID {collection}')

        cursor.execute(search_path_string)
        cursor.execute("""
            /*kingfisher-views field-counts*/

            SET parallel_tuple_cost=0.00001;
            SET parallel_setup_cost=0.00001;
            SET work_mem='10MB';

            SELECT
                collection_id,
                release_type,
                path,
                sum(object_property) object_property,
                sum(array_item) array_count,
                count(distinct id) distinct_releases
            FROM
                release_summary_with_data
            CROSS JOIN
                flatten(data)
            WHERE
                release_summary_with_data.collection_id = %(id)s
            GROUP BY collection_id, release_type, path;
        """, {'id': collection})

        results = cursor.fetchone()
        if results:
            cursor.execute('INSERT INTO field_counts_temp VALUES (%s, %s, %s, %s, %s, %s)', *results)
            commit()

            logger.info(f'Time for collection ID {collection}: {timer() - collection_timer}s')

    command_timer = timer()

    cursor.execute(search_path_string)
    cursor.execute('DROP TABLE IF EXISTS field_counts_temp')
    cursor.execute("""
        CREATE TABLE field_counts_temp(
            collection_id bigint,
            release_type text,
            path text,
            object_property bigint,
            array_count bigint,
            distinct_releases bigint
        )
    """)
    commit()

    selected_collections = pluck('SELECT id FROM selected_collections')

    with concurrent.futures.ThreadPoolExecutor(max_workers=threads) as executor:
        futures = [executor.submit(_run_collection, collection) for collection in selected_collections]

        for future in concurrent.futures.as_completed(futures):
            continue

    cursor.execute(search_path_string)
    cursor.execute('DROP TABLE IF EXISTS field_counts')
    cursor.execute('ALTER TABLE field_counts_temp RENAME TO field_counts')

    cursor.execute("COMMENT ON COLUMN field_counts.collection_id IS "
                   "'id from the kingfisher collection table' ")
    cursor.execute("COMMENT ON COLUMN field_counts.release_type IS "
                   "'Either release, compiled_release or record. compiled_release are releases generated "
                   "by kingfisher release compilation' ")
    cursor.execute("COMMENT ON COLUMN field_counts.path IS 'JSON path of the field' ")
    cursor.execute("COMMENT ON COLUMN field_counts.object_property IS "
                   "'The total number of times the field at this path appears' ")
    cursor.execute("COMMENT ON COLUMN field_counts.array_count IS "
                   "'For arrays, the total number of items in this array across all releases' ")
    cursor.execute("COMMENT ON COLUMN field_counts.distinct_releases IS "
                   "'The total number of distinct releases in which the field at this path appears' ")
    commit()

    logger.info(f'Total time: {timer() - command_timer}s')
