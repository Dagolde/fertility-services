"""Update service model for catalog management

Revision ID: 20260303170000
Revises: 20260303162006
Create Date: 2026-03-03 17:00:00

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import mysql

# revision identifiers, used by Alembic.
revision = '20260303170000'
down_revision = '20260303162006'
branch_labels = None
depends_on = None


def upgrade():
    """
    Update services table for service catalog management:
    - Add hospital_id foreign key
    - Add category enum field (IVF, IUI, Fertility_Testing, Consultation, Egg_Freezing, Other)
    - Add is_featured boolean field
    - Add view_count and booking_count integer fields
    - Add indexes on hospital_id, category, is_featured, price
    - Add full-text search index on name and description
    """
    # Add hospital_id column with foreign key
    op.add_column('services', sa.Column('hospital_id', sa.Integer(), nullable=True))
    op.create_foreign_key('fk_services_hospital_id', 'services', 'hospitals', ['hospital_id'], ['id'])
    
    # Add category enum column
    op.add_column('services', sa.Column('category', 
        sa.Enum('IVF', 'IUI', 'Fertility_Testing', 'Consultation', 'Egg_Freezing', 'Other', name='servicecategory'),
        nullable=True))
    
    # Add is_featured column
    op.add_column('services', sa.Column('is_featured', sa.Boolean(), nullable=False, server_default='0'))
    
    # Add view_count and booking_count columns
    op.add_column('services', sa.Column('view_count', sa.Integer(), nullable=False, server_default='0'))
    op.add_column('services', sa.Column('booking_count', sa.Integer(), nullable=False, server_default='0'))
    
    # Create indexes for performance
    op.create_index('idx_hospital', 'services', ['hospital_id'], unique=False)
    op.create_index('idx_category', 'services', ['category'], unique=False)
    op.create_index('idx_featured', 'services', ['is_featured'], unique=False)
    op.create_index('idx_price', 'services', ['price'], unique=False)
    
    # Create full-text search index on name and description
    op.execute("ALTER TABLE services ADD FULLTEXT INDEX idx_search (name, description)")
    
    # Update existing records to have a default category
    op.execute("UPDATE services SET category = 'Other' WHERE category IS NULL")
    
    # Make category NOT NULL after setting defaults
    op.alter_column('services', 'category', nullable=False)
    
    # Make hospital_id NOT NULL after setting defaults (if needed)
    # Note: This assumes all existing services will be assigned to a hospital
    # If there are orphaned services, they should be handled before running this migration


def downgrade():
    """
    Remove the added fields and indexes
    """
    # Drop full-text search index
    op.execute("ALTER TABLE services DROP INDEX idx_search")
    
    # Drop indexes
    op.drop_index('idx_price', table_name='services')
    op.drop_index('idx_featured', table_name='services')
    op.drop_index('idx_category', table_name='services')
    op.drop_index('idx_hospital', table_name='services')
    
    # Drop columns
    op.drop_column('services', 'booking_count')
    op.drop_column('services', 'view_count')
    op.drop_column('services', 'is_featured')
    op.drop_column('services', 'category')
    
    # Drop foreign key and column
    op.drop_constraint('fk_services_hospital_id', 'services', type_='foreignkey')
    op.drop_column('services', 'hospital_id')
