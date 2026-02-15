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

    # Alter column to use new enum, mapping old values into the new set.
    # Any legacy value that does not match 'SYSTEM' or known voice types will be mapped to 'NORMAL'.
    op.execute(
        """
        ALTER TABLE messages ALTER COLUMN message_type TYPE messagetype_new USING (
            CASE
                WHEN message_type::text = 'SYSTEM' THEN 'SYSTEM'
                WHEN message_type::text IN ('VOICE_TRANSCRIPT','VOICE') THEN 'VOICE'
                WHEN message_type::text IN ('USER','ALERT','NOTIFICATION','USER_POSTCARD','COSMIC_BROADCAST','SERVICE_REPLY') THEN 'NORMAL'
                ELSE 'NORMAL'
            END
        )::messagetype_new;
        """
    )

    # Drop old enum type and rename new type
    op.execute('DROP TYPE IF EXISTS messagetype;')
    op.execute("ALTER TYPE messagetype_new RENAME TO messagetype;")


def downgrade() -> None:
    # Recreate previous enum type (best-effort) and map back
    op.execute("CREATE TYPE messagetype_old AS ENUM('SYSTEM','USER','ALERT','NOTIFICATION');")

    op.execute(
        """
        ALTER TABLE messages ALTER COLUMN message_type TYPE messagetype_old USING (
            CASE
                WHEN message_type::text = 'SYSTEM' THEN 'SYSTEM'
                WHEN message_type::text = 'VOICE' THEN 'USER'
                WHEN message_type::text = 'NORMAL' THEN 'USER'
                ELSE 'USER'
            END
        )::messagetype_old;
        """
    )

    op.execute('DROP TYPE IF EXISTS messagetype;')
    op.execute("ALTER TYPE messagetype_old RENAME TO messagetype;")
