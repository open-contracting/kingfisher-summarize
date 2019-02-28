import sqlalchemy as sa
from timeit import default_timer as timer
import concurrent.futures

import ocdskingfisherviews.cli.commands.base

field_count_query = '''
    select 
        collection_id,
        path, 
        sum(object_property) object_property, 
        sum(array_item) array_count, 
        count(distinct id) distinct_releases
    from 
        tmp_release_summary_with_release_data 
    cross join
        flatten(data)
    where 
        tmp_release_summary_with_release_data.collection_id = %s
    group by collection_id, path;
'''

search_path_string = 'set search_path = views, public;'

class FieldCountsCommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'field-counts'

    def run_collection(self, collection):

        with self.engine.begin() as connection:
            start = timer()
            connection.execute(search_path_string)
            print('processing collection: {}'.format(collection))
            results = tuple(connection.execute(field_count_query, collection))
            if results:
                connection.execute('insert into field_counts_temp values (%s, %s, %s, %s, %s)', *results)
            print('running time for collection {}: {}s'.format(collection, timer() - start))

    def run_command(self, args):
        self.engine = sa.create_engine(self.config.database_uri)
        overall_start = timer()

        with self.engine.begin() as connection:
            connection.execute(search_path_string)

            connection.execute('drop table if exists field_counts_temp')
            connection.execute('create table field_counts_temp(collection_id text, path text, object_property bigint, array_count bigint, distinct_releases bigint)')
            selected_collections = [
                result['id'] for result in connection.execute('select id from selected_collections')
            ]

        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(self.run_collection, collection) for collection in selected_collections]

            for future in concurrent.futures.as_completed(futures):
                continue

        with self.engine.begin() as connection:
            connection.execute('drop table if exists field_counts')
            connection.execute('alter table field_counts_temp rename to field_counts')
            print('total running time: {}s'.format(timer() - overall_start))

