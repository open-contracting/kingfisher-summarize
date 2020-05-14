"""users

Revision ID: cb9bf0366efa
Revises: 6fa01f350461
Create Date: 2019-11-26 14:53:42.530850

"""

from alembic import op

# revision identifiers, used by Alembic.
revision = 'cb9bf0366efa'
down_revision = '6fa01f350461'
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()
    query = conn.execute("SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'view_meta';")
    if query.fetchall():
        schema = 'view_meta'
    else:
        schema = 'views'

    op.execute('SET search_path = {}'.format(schema))
    op.execute('CREATE TABLE read_only_user(username VARCHAR(64) NOT NULL PRIMARY KEY)')


def downgrade():
    op.execute('SET search_path = view_meta')
    op.execute('DROP TABLE read_only_user')
