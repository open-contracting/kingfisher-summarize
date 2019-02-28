import sqlalchemy as sa
from timeit import default_timer as timer

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

class FieldCountsCommand(ocdskingfisherviews.cli.commands.base.CLICommand):
    command = 'field-counts'

    def run_command(self, args):
        search_path_string = 'set search_path = views, public;'
        engine = sa.create_engine(self.config.database_uri)

        with engine.begin() as connection:
            connection.execute(search_path_string)

            connection.execute('drop table if exists field_counts_temp')
            connection.execute('create table field_counts_temp(collection_id text, path text, object_property bigint, array_count bigint, distinct_releases bigint)')
            selected_collections = [
                result['id'] for result in connection.execute('select id from selected_collections')
            ]

            overall_start = timer()
            for collection in selected_collections:
                start = timer()
                print('processing collection: {}'.format(collection))
                results = connection.execute(field_count_query, collection)
                if results:
                    connection.execute('insert into field_counts_temp values (%s, %s, %s, %s, %s)', *results)
                print('running time: {}s'.format(timer() - start))

            connection.execute('drop table if exists field_counts')
            connection.execute('alter table field_counts_temp rename to field_counts')
            print('total running time: {}s'.format(timer() - start))




