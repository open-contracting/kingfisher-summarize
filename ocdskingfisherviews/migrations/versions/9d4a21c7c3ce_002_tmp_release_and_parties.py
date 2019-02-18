"""002-tmp_release_and_parties

Revision ID: 9d4a21c7c3ce
Revises: 941f79a90ace
Create Date: 2019-02-18 15:04:54.314964

"""

import os 
from alembic import op
import sqlalchemy as sa


dir_path = os.path.dirname(os.path.realpath(__file__))
sql_dir = os.path.join(dir_path, '../../../sql/')

# revision identifiers, used by Alembic.
revision = '9d4a21c7c3ce'
down_revision = '941f79a90ace'
branch_labels = None
depends_on = None


def upgrade():
    sql_file = os.path.join(sql_dir, '''002-tmp_release_and_parties.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    


def downgrade():
    sql_file = os.path.join(sql_dir, '''002-tmp_release_and_parties_downgrade.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    
