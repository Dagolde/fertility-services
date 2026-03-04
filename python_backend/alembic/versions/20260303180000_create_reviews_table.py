"""Create reviews table

Revision ID: 20260303180000
Revises: 20260303170000
Create Date: 2026-03-03 18:00:00

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import mysql

# revision identifiers, used by Alembic.
revision = '20260303180000'
down_revision = '20260303170000'
branch_labels = None
depends_on = None


def upgrade():
    """
    Create reviews table with:
    - user_id, hospital_id, appointment_id foreign keys
    - rating (1-5), comment (max 1000 chars)
    - is_flagged, flag_count, is_hidden for moderation
    - hospital_response (max 500 chars), hospital_response_date
    - is_immutable, immutable_after (48 hours after creation)
    - Unique constraint on (user_id, appointment_id)
    - Indexes on hospital_id, rating, is_flagged
    """
    op.create_table(
        'reviews',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('hospital_id', sa.Integer(), nullable=False),
        sa.Column('appointment_id', sa.Integer(), nullable=False),
        sa.Column('rating', sa.Integer(), nullable=False),
        sa.Column('comment', sa.Text(), nullable=True),
        sa.Column('is_flagged', sa.Boolean(), nullable=False, server_default='0'),
        sa.Column('flag_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_hidden', sa.Boolean(), nullable=False, server_default='0'),
        sa.Column('hospital_response', sa.Text(), nullable=True),
        sa.Column('hospital_response_date', sa.DateTime(), nullable=True),
        sa.Column('is_immutable', sa.Boolean(), nullable=False, server_default='0'),
        sa.Column('immutable_after', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP')),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], name='fk_reviews_user_id'),
        sa.ForeignKeyConstraint(['hospital_id'], ['hospitals.id'], name='fk_reviews_hospital_id'),
        sa.ForeignKeyConstraint(['appointment_id'], ['appointments.id'], name='fk_reviews_appointment_id'),
        sa.UniqueConstraint('user_id', 'appointment_id', name='unique_review_per_appointment'),
        mysql_charset='utf8mb4',
        mysql_collate='utf8mb4_unicode_ci'
    )
    
    # Create indexes for performance
    op.create_index('idx_hospital_id', 'reviews', ['hospital_id'], unique=False)
    op.create_index('idx_rating', 'reviews', ['rating'], unique=False)
    op.create_index('idx_is_flagged', 'reviews', ['is_flagged'], unique=False)
    
    # Add check constraint for rating (1-5)
    op.create_check_constraint(
        'check_rating_range',
        'reviews',
        'rating >= 1 AND rating <= 5'
    )
    
    # Update hospitals table to add total_reviews column if it doesn't exist
    # Check if column exists first
    connection = op.get_bind()
    inspector = sa.inspect(connection)
    columns = [col['name'] for col in inspector.get_columns('hospitals')]
    
    if 'total_reviews' not in columns:
        op.add_column('hospitals', sa.Column('total_reviews', sa.Integer(), nullable=False, server_default='0'))


def downgrade():
    """
    Drop reviews table and related constraints
    """
    # Drop indexes
    op.drop_index('idx_is_flagged', table_name='reviews')
    op.drop_index('idx_rating', table_name='reviews')
    op.drop_index('idx_hospital_id', table_name='reviews')
    
    # Drop check constraint
    op.drop_constraint('check_rating_range', 'reviews', type_='check')
    
    # Drop table (foreign keys will be dropped automatically)
    op.drop_table('reviews')
    
    # Remove total_reviews column from hospitals if it was added
    connection = op.get_bind()
    inspector = sa.inspect(connection)
    columns = [col['name'] for col in inspector.get_columns('hospitals')]
    
    if 'total_reviews' in columns:
        op.drop_column('hospitals', 'total_reviews')
