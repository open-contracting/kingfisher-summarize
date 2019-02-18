"""003-buyer-procuringentity-tenderer

Revision ID: 5f7ff1b6d796
Revises: 9d4a21c7c3ce
Create Date: 2019-02-18 20:14:37.881511

"""

import os 
from alembic import op
import sqlalchemy as sa


dir_path = os.path.dirname(os.path.realpath(__file__))
sql_dir = os.path.join(dir_path, '../../../sql/')

# revision identifiers, used by Alembic.
revision = '5f7ff1b6d796'
down_revision = '9d4a21c7c3ce'
branch_labels = None
depends_on = None


def upgrade():
    sql_file = os.path.join(sql_dir, '''003-buyer-procuringentity-tenderer.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    


def downgrade():
    sql_file = os.path.join(sql_dir, '''003-buyer-procuringentity-tenderer_downgrade.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    
