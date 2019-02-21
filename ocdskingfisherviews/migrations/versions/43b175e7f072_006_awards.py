"""006-awards

Revision ID: 43b175e7f072
Revises: 0f73955630db
Create Date: 2019-02-19 11:51:48.003384

"""

import os 
from alembic import op
import sqlalchemy as sa


dir_path = os.path.dirname(os.path.realpath(__file__))
sql_dir = os.path.join(dir_path, '../../../sql/')

# revision identifiers, used by Alembic.
revision = '43b175e7f072'
down_revision = '0f73955630db'
branch_labels = None
depends_on = None


def upgrade():
    sql_file = os.path.join(sql_dir, '''006-awards.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    


def downgrade():
    sql_file = os.path.join(sql_dir, '''006-awards_downgrade.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    
