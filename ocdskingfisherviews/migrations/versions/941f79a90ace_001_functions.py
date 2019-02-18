"""001-functions

Revision ID: 941f79a90ace
Revises: 947ad833b815
Create Date: 2019-02-18 14:20:25.036001

"""

import os 
from alembic import op
import sqlalchemy as sa


dir_path = os.path.dirname(os.path.realpath(__file__))
sql_dir = os.path.join(dir_path, '../../../sql/')

# revision identifiers, used by Alembic.
revision = '941f79a90ace'
down_revision = '947ad833b815'
branch_labels = None
depends_on = None


def upgrade():
    sql_file = os.path.join(sql_dir, '''001-functions.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    


def downgrade():
    sql_file = os.path.join(sql_dir, '''001-functions_downgrade.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    
