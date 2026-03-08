"""推送工具函数

被任务层（app.tasks.subscriptions）和推送引擎（push.engine）共同使用，
提取到此处以避免循环依赖和逻辑重复。
"""
from datetime import datetime, timezone
from typing import List, Tuple

from sqlalchemy import select, and_
from sqlalchemy.orm import Session

from app.core.logging import get_logger
from app.models.service_account import ServiceAccount, subscription_table
from app.models.user import User
import pytz

logger = get_logger(__name__)


def get_users_for_push_time(
    db: Session,
    service_name: str,
    target_hour_utc: int,
    target_minute_utc: int,
) -> List[Tuple[int, str]]:
    """获取在指定 UTC 时间窗口（±15 分钟）内应该接收推送的用户列表。

    推送时间优先级：订阅个人设置 > 服务号默认推送时间。
    跳过未设置任何推送时间的用户。

    Args:
        db: 数据库会话
        service_name: 服务号名称
        target_hour_utc: 目标小时（UTC）
        target_minute_utc: 目标分钟（UTC）

    Returns:
        List of (user_id, bipupu_id)
    """
    service = db.query(ServiceAccount).filter(
        ServiceAccount.name == service_name,
        ServiceAccount.is_active.is_(True),
    ).first()
    if not service:
        return []

    stmt = select(
        User.id,
        User.bipupu_id,
        User.timezone,
        subscription_table.c.push_time,
        ServiceAccount.default_push_time,
    ).join(
        subscription_table, User.id == subscription_table.c.user_id
    ).join(
        ServiceAccount, ServiceAccount.id == subscription_table.c.service_account_id
    ).where(and_(
        subscription_table.c.service_account_id == service.id,
        subscription_table.c.is_enabled.is_(True) | subscription_table.c.is_enabled.is_(None),
    ))

    current_utc = datetime.now(timezone.utc)
    target_time_utc = current_utc.replace(
        hour=target_hour_utc, minute=target_minute_utc, second=0, microsecond=0
    )

    target_users: List[Tuple[int, str]] = []
    for user_id, bipupu_id, user_timezone, sub_push_time, svc_push_time in db.execute(stmt).all():
        push_time = sub_push_time or svc_push_time
        if not push_time:
            continue
        try:
            tz = pytz.timezone(user_timezone or "Asia/Shanghai")
            user_target_utc = tz.localize(
                datetime.combine(target_time_utc.date(), push_time)
            ).astimezone(timezone.utc)
            if abs((user_target_utc - target_time_utc).total_seconds()) <= 900:
                target_users.append((user_id, bipupu_id))
        except Exception as e:
            logger.error(f"处理用户时区失败 {bipupu_id}: {e}")

    return target_users
