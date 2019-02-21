"""007-contracts

Revision ID: 28ab82610c2a
Revises: 43b175e7f072
Create Date: 2019-02-19 13:25:59.217030

"""

import os 
from alembic import op
import sqlalchemy as sa


dir_path = os.path.dirname(os.path.realpath(__file__))
sql_dir = os.path.join(dir_path, '../../../sql/')

# revision identifiers, used by Alembic.
revision = '28ab82610c2a'
down_revision = '43b175e7f072'
branch_labels = None
depends_on = None


def upgrade():
    sql_file = os.path.join(sql_dir, '''007-contracts.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    


def downgrade():
    sql_file = os.path.join(sql_dir, '''007-contracts_downgrade.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    
