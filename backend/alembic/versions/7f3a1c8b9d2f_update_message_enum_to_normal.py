"""update_message_enum_to_normal

Revision ID: 7f3a1c8b9d2f
Revises: 2eac0e65a9a8
Create Date: 2026-02-15 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '7f3a1c8b9d2f'
down_revision = '2eac0e65a9a8'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create new enum type with desired values
    op.execute("CREATE TYPE messagetype_new AS ENUM('NORMAL','VOICE','SYSTEM');")
    # Safer approach: add a temporary column of the new enum type, populate it
    # using a CASE mapping, then drop/rename columns. This avoids direct
    # in-place TYPE casts that can fail on some Postgres setups.
    op.add_column('messages', sa.Column('message_type_new', sa.Enum('NORMAL', 'VOICE', 'SYSTEM', name='messagetype_new'), nullable=True))

    op.execute(
        """
        UPDATE messages SET message_type_new = (
            CASE
                WHEN message_type::text = 'SYSTEM' THEN 'SYSTEM'
                WHEN message_type::text IN ('VOICE_TRANSCRIPT','VOICE') THEN 'VOICE'
                WHEN message_type::text IN ('USER','ALERT','NOTIFICATION','USER_POSTCARD','COSMIC_BROADCAST','SERVICE_REPLY') THEN 'NORMAL'
                ELSE 'NORMAL'
            END
        );
        """
    )

    # Make new column non-nullable if old column was non-nullable
    op.alter_column('messages', 'message_type_new', nullable=False)

    # Drop old column and rename new one to the original name
    op.drop_column('messages', 'message_type')
    op.alter_column('messages', 'message_type_new', new_column_name='message_type')

    # Now drop the old enum type (if exists) and rename the new type to the original name
    op.execute('DROP TYPE IF EXISTS messagetype;')
    op.execute("ALTER TYPE messagetype_new RENAME TO messagetype;")


def downgrade() -> None:
    # Recreate previous enum type (best-effort) and map back
    op.execute("CREATE TYPE messagetype_old AS ENUM('SYSTEM','USER','ALERT','NOTIFICATION');")

    # Add temporary column using old enum and populate from current values
    op.add_column('messages', sa.Column('message_type_old', sa.Enum('SYSTEM','USER','ALERT','NOTIFICATION', name='messagetype_old'), nullable=True))

    op.execute(
        """
        UPDATE messages SET message_type_old = (
            CASE
                WHEN message_type::text = 'SYSTEM' THEN 'SYSTEM'
                WHEN message_type::text = 'VOICE' THEN 'USER'
                WHEN message_type::text = 'NORMAL' THEN 'USER'
                ELSE 'USER'
            END
        );
        """
    )

    op.alter_column('messages', 'message_type_old', nullable=False)
    op.drop_column('messages', 'message_type')
    op.alter_column('messages', 'message_type_old', new_column_name='message_type')

    op.execute('DROP TYPE IF EXISTS messagetype;')
    op.execute("ALTER TYPE messagetype_old RENAME TO messagetype;")
