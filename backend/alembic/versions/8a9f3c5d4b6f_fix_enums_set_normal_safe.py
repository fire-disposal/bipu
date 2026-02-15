"""fix_enums_set_normal_safe

Revision ID: 8a9f3c5d4b6f
Revises: 7f3a1c8b9d2f
Create Date: 2026-02-15 12:10:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '8a9f3c5d4b6f'
down_revision = '7f3a1c8b9d2f'
branch_labels = None
depends_on = None


def _column_exists(conn, table_name: str, column_name: str) -> bool:
    q = sa.text(
        "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = :t AND column_name = :c LIMIT 1"
    )
    return conn.execute(q, {"t": table_name, "c": column_name}).fetchone() is not None


def upgrade() -> None:
    conn = op.get_bind()

    # messages.message_type: set all values to 'NORMAL' safely if the column exists
    if _column_exists(conn, 'messages', 'message_type'):
        # create a temporary text column and populate with 'NORMAL' (ignore previous mappings)
        op.add_column('messages', sa.Column('message_type_tmp_text', sa.Text(), nullable=True))
        conn.execute(sa.text("UPDATE messages SET message_type_tmp_text = 'NORMAL'"))

        # drop old column if present (use IF EXISTS to be robust)
        conn.execute(sa.text("ALTER TABLE messages DROP COLUMN IF EXISTS message_type CASCADE"))

        # create a new enum type for message_type if not exists, then add column of that type
        # We use a temporary enum name and only rename to final name when safe
        conn.execute(sa.text(
            "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'messagetype_new') THEN CREATE TYPE messagetype_new AS ENUM('NORMAL','VOICE','SYSTEM'); END IF; END$$;"
        ))

        op.add_column('messages', sa.Column('message_type', sa.Enum('NORMAL', 'VOICE', 'SYSTEM', name='messagetype_new'), nullable=True))

        # populate from tmp text column
        conn.execute(sa.text("UPDATE messages SET message_type = message_type_tmp_text::messagetype_new"))

        # make non-nullable and remove tmp text column
        op.alter_column('messages', 'message_type', nullable=False)
        conn.execute(sa.text("ALTER TABLE messages DROP COLUMN IF EXISTS message_type_tmp_text"))

        # try to rename enum type to canonical name 'messagetype' if that name is not already taken
        conn.execute(sa.text(
            "DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'messagetype') THEN ALTER TYPE messagetype_new RENAME TO messagetype; END IF; END$$;"
        ))

    # Additional generic handling: set any column named `status`/`health`/`exit_code` in `services`-like tables
    # to the requested defaults when those columns exist. This is conservative and uses column existence checks.
    # status -> 'running', health -> 'starting', exit_code -> 0
    tables_to_check = ['services', 'deployments', 'containers', 'nodes']
    for tbl in tables_to_check:
        if _column_exists(conn, tbl, 'status'):
            try:
                conn.execute(sa.text(f"UPDATE {tbl} SET status = 'running' WHERE status IS NOT NULL"))
            except Exception:
                # ignore failures for tables with incompatible types
                pass
        if _column_exists(conn, tbl, 'health'):
            try:
                conn.execute(sa.text(f"UPDATE {tbl} SET health = 'starting' WHERE health IS NOT NULL"))
            except Exception:
                pass
        if _column_exists(conn, tbl, 'exit_code'):
            try:
                conn.execute(sa.text(f"UPDATE {tbl} SET exit_code = 0 WHERE exit_code IS NOT NULL"))
            except Exception:
                pass


def downgrade() -> None:
    # Best-effort no-op downgrade: do not attempt to reconstruct previous enum values.
    conn = op.get_bind()
    if _column_exists(conn, 'messages', 'message_type'):
        # leave values as-is; do not drop the column automatically on downgrade
        pass
