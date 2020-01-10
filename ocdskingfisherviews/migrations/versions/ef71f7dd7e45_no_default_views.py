"""no-default-views

Revision ID: ef71f7dd7e45
Revises: cb9bf0366efa
Create Date: 2019-12-12 12:38:06.730478

"""

import os
from alembic import op


dir_path = os.path.dirname(os.path.realpath(__file__))
sql_dir = os.path.join(dir_path, '../../../sql/')

# revision identifiers, used by Alembic.
revision = 'ef71f7dd7e45'
down_revision = 'cb9bf0366efa'
branch_labels = None
depends_on = None


# This is duplicated in ocdskingfisherviews/migrations/versions/947ad833b815_select_collection_tables.py
def upgrade():
    sql_text = '''
    set search_path = views, public;
    drop view selected_collections;
    drop table extra_collections;
    '''
    op.execute(sql_text)


# This is duplicated in ocdskingfisherviews/migrations/versions/947ad833b815_select_collection_tables.py
def downgrade():
    sql_text = '''
    set search_path = views, public;
    create table extra_collections(collection_id integer primary key);


    create view selected_collections
    as
    select
       id
    from
       collection
    join
        (
        select
            source_id,
            data_version,
            row_number() over (partition by source_id order by data_version desc) date_order
        from (
            select
                source_id,
                data_version
            from
                collection
            where
                not sample
            group by
                source_id, data_version
            ) grouped
        ) with_date_order
        using
            (source_id, data_version)
    where
        date_order <= 2

    union

    select collection_id from extra_collections;
    '''
    op.execute(sql_text)
