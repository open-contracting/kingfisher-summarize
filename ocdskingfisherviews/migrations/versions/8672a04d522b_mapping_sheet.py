"""mapping-sheet

Revision ID: 8672a04d522b
Revises: 947ad833b815
Create Date: 2019-03-05 15:16:13.974050

"""

import os
import csv
from alembic import op
from sqlalchemy import String
from sqlalchemy.sql import table, column

mapping_table = table(
    'mapping_sheets',
    column('version', String),
    column('extension', String),
    column('section', String),
    column('path', String),
    column('title', String),
    column('description', String),
    column('type', String),
    column('range', String),
    column('values', String),
    column('links', String),
    column('deprecated', String),
    column('deprecationNotes', String)
)


dir_path = os.path.dirname(os.path.realpath(__file__))
mapping_sheet_dir = os.path.join(dir_path, '../../../mapping_sheets/')

# revision identifiers, used by Alembic.
revision = '8672a04d522b'
down_revision = '947ad833b815'
branch_labels = None
depends_on = None


def upgrade():
    mapping_sheet = os.path.join(mapping_sheet_dir, '1-1-3.csv')
    create_text = '''
       create table mapping_sheets(
           version text,
           extension text,
           section text,
           path text,
           title text,
           description text,
           type text,
           range text,
           values text,
           links text,
           deprecated text,
           "deprecationNotes" text
       )
    '''
    op.execute('set search_path = views')
    op.execute(create_text)

    with open(mapping_sheet) as f:
        reader = csv.DictReader(f)

        rows = []
        for row in reader:
            row['version'] = '1.1'
            row['extension'] = 'core'
            rows.append(row)

        op.bulk_insert(
            mapping_table,
            rows
        )


def downgrade():
    op.execute('set search_path = views')
    op.execute('''drop table mapping_sheets''')
