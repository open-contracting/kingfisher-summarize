"""005-tender

Revision ID: 0f73955630db
Revises: c8c2b087b273
Create Date: 2019-02-18 20:41:49.661826

"""

import os 
from alembic import op
import sqlalchemy as sa


dir_path = os.path.dirname(os.path.realpath(__file__))
sql_dir = os.path.join(dir_path, '../../../sql/')

# revision identifiers, used by Alembic.
revision = '0f73955630db'
down_revision = 'c8c2b087b273'
branch_labels = None
depends_on = None


def upgrade():
    sql_file = os.path.join(sql_dir, '''005-tender.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    


def downgrade():
    sql_file = os.path.join(sql_dir, '''005-tender_downgrade.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    
