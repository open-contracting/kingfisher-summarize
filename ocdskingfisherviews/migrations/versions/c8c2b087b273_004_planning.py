"""004-planning

Revision ID: c8c2b087b273
Revises: 5f7ff1b6d796
Create Date: 2019-02-18 20:30:00.039061

"""

import os 
from alembic import op
import sqlalchemy as sa


dir_path = os.path.dirname(os.path.realpath(__file__))
sql_dir = os.path.join(dir_path, '../../../sql/')

# revision identifiers, used by Alembic.
revision = 'c8c2b087b273'
down_revision = '5f7ff1b6d796'
branch_labels = None
depends_on = None


def upgrade():
    sql_file = os.path.join(sql_dir, '''004-planning.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    


def downgrade():
    sql_file = os.path.join(sql_dir, '''004-planning_downgrade.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    
