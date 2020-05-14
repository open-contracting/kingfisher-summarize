"""Move tables to views schema

Revision ID: be8308b994ed
Revises: ef71f7dd7e45
Create Date: 2020-05-14 18:21:35.312191

"""

from alembic import op

# revision identifiers, used by Alembic.
revision = 'be8308b994ed'
down_revision = 'ef71f7dd7e45'
branch_labels = None
depends_on = None


def upgrade():
    op.execute('SET search_path = views, view_info, view_meta')
    op.execute("ALTER TABLE mapping_sheets SET SCHEMA views")
    op.execute("ALTER TABLE read_only_user SET SCHEMA views")


def downgrade():
    op.execute('SET search_path = views')
    op.execute("ALTER TABLE mapping_sheets SET SCHEMA view_info")
    op.execute("ALTER TABLE read_only_user SET SCHEMA view_meta")
