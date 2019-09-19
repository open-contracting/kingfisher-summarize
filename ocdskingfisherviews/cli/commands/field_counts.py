import sqlalchemy as sa
from timeit import default_timer as timer
import concurrent.futures
from logzero import logger

import ocdskingfisherviews.cli.commands.base

field_count_query = '''
    set parallel_tuple_cost=0.00001;
    set parallel_setup_cost=0.00001;
    set work_mem='10MB';

    select
        collection_id,
        release_type,
        path,
        sum(object_property) object_property,
        sum(array_item) array_count,
        count(distinct id) distinct_releases
    from
        release_summary_with_data
    cross join
        flatten(data)
    where
        release_summary_with_data.collection_id = %s
    group by collection_id, release_type, path;
'''

search_path_string = 'set search_path = views, public;'


class FieldCountsCommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'field-counts'

    def configure_subparser(self, subparser):
        subparser.add_argument("--remove", help="Aemove field_count table", action='store_true')
        subparser.add_argument("--threads", help="Amount of threads to use", type=int, default=1)

        subparser.add_argument("--logfile", help="Add psql timing to sql output")

    def run_collection(self, collection):

        with self.engine.begin() as connection:
            start = timer()
            connection.execute(search_path_string)
            logger.info('processing collection: {}'.format(collection))
            results = tuple(connection.execute(field_count_query, collection))
            if results:
                connection.execute('insert into field_counts_temp values (%s, %s, %s, %s, %s, %s)', *results)
            logger.info('running time for collection {}: {}s'.format(collection, timer() - start))

    def run_logged_command(self, args):

        self.engine = sa.create_engine(self.config.database_uri)
        overall_start = timer()

        if args.remove:
            with self.engine.begin() as connection:
                connection.execute(search_path_string)
                connection.execute('drop table if exists field_counts_temp;')
                connection.execute('drop table if exists field_counts')
            return

        with self.engine.begin() as connection:
            connection.execute(search_path_string)

            connection.execute('drop table if exists field_counts_temp')
            connection.execute(
                '''create table field_counts_temp(
                       collection_id bigint,
                       release_type text,
                       path text,
                       object_property bigint,
                       array_count bigint,
                       distinct_releases bigint
                )'''
            )
            selected_collections = [result['id'] for result in
                                    connection.execute('select id from selected_collections')]

        with concurrent.futures.ThreadPoolExecutor(max_workers=args.threads) as executor:
            futures = [executor.submit(self.run_collection, collection) for collection in selected_collections]

            for future in concurrent.futures.as_completed(futures):
                continue

        with self.engine.begin() as connection:
            connection.execute('drop table if exists field_counts')
            connection.execute('alter table field_counts_temp rename to field_counts')

            connection.execute("Comment on column field_counts.collection_id IS "
                               "'id from the kingfisher collection table' ")
            connection.execute("Comment on column field_counts.release_type IS "
                               "'Either release, compiled_release or record. compiled_release are releases generated "
                               "by kingfisher release compilation' ")
            connection.execute("Comment on column field_counts.path IS 'JSON path of the field' ")
            connection.execute("Comment on column field_counts.object_property IS "
                               "'The total number of times the field at this path appears' ")
            connection.execute("Comment on column field_counts.array_count IS "
                               "'For arrays, the total number of items in this array across all releases' ")
            connection.execute("Comment on column field_counts.distinct_releases IS "
                               "'The total number of distinct releases in which the field at this path appears' ")

            logger.info('total running time: {}s'.format(timer() - overall_start))
