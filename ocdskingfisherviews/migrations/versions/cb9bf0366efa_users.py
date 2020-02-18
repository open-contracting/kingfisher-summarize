"""users

Revision ID: cb9bf0366efa
Revises: 6fa01f350461
Create Date: 2019-11-26 14:53:42.530850

"""

import os
from alembic import op


dir_path = os.path.dirname(os.path.realpath(__file__))
sql_dir = os.path.join(dir_path, '../../../sql/')

# revision identifiers, used by Alembic.
revision = 'cb9bf0366efa'
down_revision = '6fa01f350461'
branch_labels = None
depends_on = None


def upgrade():
    create_text = '''
       create table read_only_user(
           username varchar(64) not null primary key
       )
    '''
    op.execute('set search_path = view_meta')
    op.execute(create_text)


def downgrade():
    op.execute('set search_path = view_meta')
    op.execute('drop table read_only_user')
