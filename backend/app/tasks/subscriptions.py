"""订阅推送任务

职责：
1. 定时检查所有活跃服务号的推送时间窗口（check_push_times_task）
2. 通用推送派发（push_service_task）—— 不与任何具体服务号耦合
3. 推送日志定期清理（cleanup_push_logs_task）

设计原则：
- 任务层不感知具体服务号业务（运势/天气等），内容生成由 ContentGenerator 负责
- 新增服务号无需修改此文件，只需在数据库创建服务号记录即可
"""
import asyncio
from datetime import datetime, timezone, timedelta
from typing import List, Tuple

from celery import shared_task

from app.db.database import SessionLocal
from app.core.logging import get_logger
from app.models.service_account import ServiceAccount
from app.services.push.utils import get_users_for_push_time  # noqa: F401 — re-exported

logger = get_logger(__name__)


@shared_task(name="subscriptions.check_push_times", bind=True, max_retries=3, default_retry_delay=60)
def check_push_times_task(self) -> dict:
    """每 15 分钟检查所有活跃服务号，向当前时间窗口内到期的用户派发推送任务。

    动态查询所有 is_active=True 的服务号，不与具体服务名耦合。
    """
    db = SessionLocal()
    try:
        current_utc = datetime.now(timezone.utc)
        logger.info(f"检查推送时间窗口: {current_utc.strftime('%Y-%m-%d %H:%M')} UTC")

        active_services = db.query(ServiceAccount.name).filter(
            ServiceAccount.is_active.is_(True)
        ).all()

        dispatched: dict = {}
        for (service_name,) in active_services:
            users = get_users_for_push_time(
                db, service_name, current_utc.hour, current_utc.minute
            )
            if users:
                push_service_task.delay(service_name, users)
                dispatched[service_name] = len(users)
                logger.info(f"派发推送: {service_name} → {len(users)} 用户")

        logger.info(f"时间窗口检查完成，共派发 {sum(dispatched.values())} 条推送")
        return {"check_time": current_utc.isoformat(), "dispatched": dispatched}

    except Exception as e:
        logger.error(f"推送时间检查失败: {e}")
        self.retry(exc=e)
        return {"error": str(e)}
    finally:
        db.close()


@shared_task(name="subscriptions.push_service", bind=True, max_retries=3, default_retry_delay=60)
def push_service_task(
    self,
    service_name: str,
    target_users: List[Tuple[int, str]],
) -> dict:
    """向目标用户列表发送指定服务号的推送消息（通用，不绑定具体服务号）。

    内容生成由 service_accounts.send_push → ContentGenerator 处理。

    Args:
        service_name: 服务号名称（如 "cosmic.fortune"、"weather.service"）
        target_users: [(user_id, bipupu_id), ...] 列表
    """
    db = SessionLocal()
    try:
        from app.services.service_accounts import send_push

        async def _send_all() -> Tuple[int, int]:
            tasks = [
                send_push(db, service_name, bipupu_id)
                for _, bipupu_id in target_users
                if bipupu_id
            ]
            results = await asyncio.gather(*tasks, return_exceptions=True)
            ok = sum(1 for r in results if not isinstance(r, Exception))
            fail = len(results) - ok
            for r in results:
                if isinstance(r, Exception):
                    logger.error(f"推送异常 [{service_name}]: {r}")
            return ok, fail

        ok, fail = asyncio.run(_send_all())
        logger.info(f"推送完成 [{service_name}]: 成功 {ok}/{len(target_users)}")
        return {
            "service_name": service_name,
            "success": ok,
            "failed": fail,
            "total": len(target_users),
        }

    except Exception as e:
        logger.error(f"推送任务失败 [{service_name}]: {e}")
        self.retry(exc=e)
        return {"error": str(e)}
    finally:
        db.close()


@shared_task(name="subscriptions.cleanup_push_logs", bind=True, max_retries=2, default_retry_delay=60)
def cleanup_push_logs_task(self, days: int = 30) -> dict:
    """清理超过 `days` 天的 success/failed 推送日志。

    由 Celery beat 每天凌晨 3 点自动执行。
    pending/processing 状态日志不会被删除。
    """
    from app.models.push_log import PushLog

    db = SessionLocal()
    try:
        cutoff = datetime.now(timezone.utc) - timedelta(days=days)
        deleted = db.query(PushLog).filter(
            PushLog.created_at < cutoff,
            PushLog.status.in_(["success", "failed"]),
        ).delete(synchronize_session=False)
        db.commit()
        logger.info(f"推送日志清理完成：删除 {deleted} 条（{days} 天前）")
        return {"deleted_count": deleted, "cutoff_date": cutoff.isoformat(), "days": days}
    except Exception as e:
        db.rollback()
        logger.error(f"清理推送日志失败: {e}")
        self.retry(exc=e)
        return {"error": str(e)}
    finally:
        db.close()
