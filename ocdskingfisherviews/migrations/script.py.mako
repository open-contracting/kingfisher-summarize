"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}

"""

import os 
from alembic import op
${imports if imports else ""}

dir_path = os.path.dirname(os.path.realpath(__file__))
sql_dir = os.path.join(dir_path, '../../../sql/')

# revision identifiers, used by Alembic.
revision = ${repr(up_revision)}
down_revision = ${repr(down_revision)}
branch_labels = ${repr(branch_labels)}
depends_on = ${repr(depends_on)}


def upgrade():
    sql_file = os.path.join(sql_dir, '''${message}.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    ${upgrades if upgrades else ""}


def downgrade():
    sql_file = os.path.join(sql_dir, '''${message}_downgrade.sql''')
    with open(sql_file) as f:
        sql_text = f.read()
    op.execute(sql_text)
    ${downgrades if downgrades else ""}
