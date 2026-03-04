"""add cancellation fields to appointments

Revision ID: 20260304000000
Revises: 20260303180000
Create Date: 2026-03-04 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '20260304000000'
down_revision = '20260303180000'
branch_labels = None
depends_on = None


def upgrade():
    # Add cancellation_reason column
    op.add_column('appointments', sa.Column('cancellation_reason', sa.String(500), nullable=True))
    
    # Add cancelled_at column
    op.add_column('appointments', sa.Column('cancelled_at', sa.DateTime(), nullable=True))


def downgrade():
    # Remove columns
    op.drop_column('appointments', 'cancelled_at')
    op.drop_column('appointments', 'cancellation_reason')
