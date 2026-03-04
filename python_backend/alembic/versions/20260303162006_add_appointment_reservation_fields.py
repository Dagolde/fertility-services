"""Add appointment reservation fields

Revision ID: 20260303162006
Revises: 
Create Date: 2026-03-03 16:20:06

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import mysql

# revision identifiers, used by Alembic.
revision = '20260303162006'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    """
    Add fields to appointments table for reservation system:
    - reserved_until: DateTime field for 10-minute reservation hold
    - cancellation_reason: Text field for cancellation notes
    - cancelled_at: DateTime field for cancellation timestamp
    - Add 'no_show' to status enum
    - Add indexes on user_id, hospital_id, appointment_date, status, reserved_until
    """
    # Modify the status enum to include 'no_show'
    op.execute("ALTER TABLE appointments MODIFY COLUMN status ENUM('pending', 'confirmed', 'completed', 'cancelled', 'no_show') DEFAULT 'pending'")
    
    # Add new columns
    op.add_column('appointments', sa.Column('reserved_until', sa.DateTime(), nullable=True))
    op.add_column('appointments', sa.Column('cancellation_reason', sa.Text(), nullable=True))
    op.add_column('appointments', sa.Column('cancelled_at', sa.DateTime(), nullable=True))
    
    # Create indexes for performance
    op.create_index('idx_user', 'appointments', ['user_id'], unique=False)
    op.create_index('idx_hospital', 'appointments', ['hospital_id'], unique=False)
    op.create_index('idx_date', 'appointments', ['appointment_date'], unique=False)
    op.create_index('idx_status', 'appointments', ['status'], unique=False)
    op.create_index('idx_reserved', 'appointments', ['reserved_until'], unique=False)


def downgrade():
    """
    Remove the added fields and indexes
    """
    # Drop indexes
    op.drop_index('idx_reserved', table_name='appointments')
    op.drop_index('idx_status', table_name='appointments')
    op.drop_index('idx_date', table_name='appointments')
    op.drop_index('idx_hospital', table_name='appointments')
    op.drop_index('idx_user', table_name='appointments')
    
    # Drop columns
    op.drop_column('appointments', 'cancelled_at')
    op.drop_column('appointments', 'cancellation_reason')
    op.drop_column('appointments', 'reserved_until')
    
    # Revert status enum to original values
    op.execute("ALTER TABLE appointments MODIFY COLUMN status ENUM('pending', 'confirmed', 'completed', 'cancelled') DEFAULT 'pending'")
