"""infoschema

Revision ID: 6fa01f350461
Revises: 8672a04d522b
Create Date: 2019-11-26 12:39:17.590043

"""

from alembic import op

# revision identifiers, used by Alembic.
revision = '6fa01f350461'
down_revision = '8672a04d522b'
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()
    query = conn.execute("SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'view_info';")
    if query.fetchall():
        schema = 'view_info'
    else:
        schema = 'views'

    op.execute('SET search_path = views')
    op.execute('ALTER TABLE mapping_sheets SET SCHEMA {}'.format(schema))


def downgrade():
    op.execute('SET search_path = view_info')
    op.execute('ALTER TABLE mapping_sheets SET SCHEMA views')
