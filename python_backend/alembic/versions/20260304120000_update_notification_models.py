"""Update notification models

Revision ID: 20260304120000
Revises: 20260303180000
Create Date: 2026-03-04 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import mysql

# revision identifiers, used by Alembic.
revision = '20260304120000'
down_revision = '20260303180000'
branch_labels = None
depends_on = None


def upgrade():
    # Update notifications table
    op.alter_column('notifications', 'user_id',
               existing_type=mysql.INTEGER(),
               nullable=False)
    
    op.alter_column('notifications', 'notification_type',
               existing_type=mysql.VARCHAR(length=50),
               type_=sa.Enum('APPOINTMENT_CONFIRMATION', 'APPOINTMENT_REMINDER', 'APPOINTMENT_CANCELLED', 
                            'APPOINTMENT_RESCHEDULED', 'PAYMENT_CONFIRMATION', 'PAYMENT_REFUND', 
                            'MESSAGE_RECEIVED', 'REVIEW_RESPONSE', 'MARKETING', 'SYSTEM', 
                            name='notificationtype'),
               nullable=False)
    
    op.add_column('notifications', sa.Column('channel', 
                                             sa.Enum('PUSH', 'EMAIL', 'SMS', name='notificationchannel'), 
                                             nullable=False, server_default='PUSH'))
    
    op.add_column('notifications', sa.Column('status', 
                                             sa.Enum('PENDING', 'SENT', 'FAILED', 'DELIVERED', name='notificationstatus'), 
                                             nullable=True, server_default='PENDING'))
    
    op.add_column('notifications', sa.Column('retry_count', sa.Integer(), nullable=True, server_default='0'))
    op.add_column('notifications', sa.Column('scheduled_at', sa.DateTime(), nullable=True))
    op.add_column('notifications', sa.Column('sent_at', sa.DateTime(), nullable=True))
    op.add_column('notifications', sa.Column('delivered_at', sa.DateTime(), nullable=True))
    op.add_column('notifications', sa.Column('failed_reason', sa.Text(), nullable=True))
    op.add_column('notifications', sa.Column('data', sa.JSON(), nullable=True))
    op.add_column('notifications', sa.Column('read_at', sa.DateTime(), nullable=True))
    op.add_column('notifications', sa.Column('updated_at', sa.DateTime(), 
                                             nullable=True, 
                                             server_default=sa.text('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP')))
    
    # Create indexes
    op.create_index('ix_notifications_user_id', 'notifications', ['user_id'])
    op.create_index('ix_notifications_status', 'notifications', ['status'])
    op.create_index('ix_notifications_scheduled_at', 'notifications', ['scheduled_at'])
    
    # Create notification_preferences table
    op.create_table('notification_preferences',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('channel', sa.Enum('PUSH', 'EMAIL', 'SMS', name='notificationchannel'), nullable=False),
        sa.Column('notification_type', sa.Enum('APPOINTMENT_CONFIRMATION', 'APPOINTMENT_REMINDER', 'APPOINTMENT_CANCELLED', 
                                               'APPOINTMENT_RESCHEDULED', 'PAYMENT_CONFIRMATION', 'PAYMENT_REFUND', 
                                               'MESSAGE_RECEIVED', 'REVIEW_RESPONSE', 'MARKETING', 'SYSTEM', 
                                               name='notificationtype'), nullable=False),
        sa.Column('enabled', sa.Boolean(), nullable=True, server_default='1'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'channel', 'notification_type', name='uq_user_channel_type')
    )
    op.create_index('ix_notification_preferences_id', 'notification_preferences', ['id'])
    op.create_index('ix_notification_preferences_user_id', 'notification_preferences', ['user_id'])


def downgrade():
    # Drop notification_preferences table
    op.drop_index('ix_notification_preferences_user_id', table_name='notification_preferences')
    op.drop_index('ix_notification_preferences_id', table_name='notification_preferences')
    op.drop_table('notification_preferences')
    
    # Drop indexes from notifications
    op.drop_index('ix_notifications_scheduled_at', table_name='notifications')
    op.drop_index('ix_notifications_status', table_name='notifications')
    op.drop_index('ix_notifications_user_id', table_name='notifications')
    
    # Remove columns from notifications
    op.drop_column('notifications', 'updated_at')
    op.drop_column('notifications', 'read_at')
    op.drop_column('notifications', 'data')
    op.drop_column('notifications', 'failed_reason')
    op.drop_column('notifications', 'delivered_at')
    op.drop_column('notifications', 'sent_at')
    op.drop_column('notifications', 'scheduled_at')
    op.drop_column('notifications', 'retry_count')
    op.drop_column('notifications', 'status')
    op.drop_column('notifications', 'channel')
    
    op.alter_column('notifications', 'notification_type',
               existing_type=sa.Enum('APPOINTMENT_CONFIRMATION', 'APPOINTMENT_REMINDER', 'APPOINTMENT_CANCELLED', 
                                    'APPOINTMENT_RESCHEDULED', 'PAYMENT_CONFIRMATION', 'PAYMENT_REFUND', 
                                    'MESSAGE_RECEIVED', 'REVIEW_RESPONSE', 'MARKETING', 'SYSTEM', 
                                    name='notificationtype'),
               type_=mysql.VARCHAR(length=50),
               nullable=True)
    
    op.alter_column('notifications', 'user_id',
               existing_type=mysql.INTEGER(),
               nullable=True)
