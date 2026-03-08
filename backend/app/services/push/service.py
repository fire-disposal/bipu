"""
推送服务 Façade  REST API 层的唯一入口

直接委托给 service_accounts.send_push()，不再引入独立的推送引擎。
定时推送由 Celery Beat 执行（subscriptions.check_push_times_task），此处不启动任何调度循环。
"""
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Any

from sqlalchemy.orm import Session

from app.services import service_accounts
from app.models.service_account import ServiceAccount
from app.core.logging import get_logger

logger = get_logger(__name__)


class PushService:
    """推送服务 Façade  仅供 REST API（modern_push.py）使用"""

    def __init__(self, db_session: Session):
        self.db = db_session

    # ------------------------------------------------------------------
    # 单条 / 批量 / 广播
    # ------------------------------------------------------------------

    async def send_push(
        self,
        service_name: str,
        user_id: str,
        content: Optional[str] = None,
        priority: int = 2,
    ) -> Dict[str, Any]:
        """向指定用户发送一条推送。content 为 None 时由 service_accounts 自动生成。"""
        try:
            msg = await service_accounts.send_push(
                self.db, service_name, user_id, content=content
            )
            return {
                "success": True,
                "message_id": msg.id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
        except Exception as e:
            logger.error(f"发送推送失败: {service_name} -> {user_id}: {e}")
            return {
                "success": False,
                "error": str(e),
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }

    async def send_batch(
        self,
        service_name: str,
        user_ids: List[str],
        content: Optional[str] = None,
        priority: int = 2,
    ) -> Dict[str, Any]:
        """批量发送推送（串行，按顺序发送，小并发下最安全可靠）。"""
        success_count = 0
        failed_count = 0
        for user_id in user_ids:
            try:
                await service_accounts.send_push(
                    self.db, service_name, user_id, content=content
                )
                success_count += 1
            except Exception as e:
                failed_count += 1
                logger.warning(f"批量推送单条失败: {service_name} -> {user_id}: {e}")

        return {
            "success": success_count > 0 or len(user_ids) == 0,
            "total": len(user_ids),
            "successful": success_count,
            "failed": failed_count,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

    async def broadcast(
        self,
        service_name: str,
        content: Optional[str] = None,
        priority: int = 2,
    ) -> Dict[str, Any]:
        """向服务号所有订阅者广播推送。"""
        service = self.db.query(ServiceAccount).filter(
            ServiceAccount.name == service_name
        ).first()

        if not service:
            return {
                "success": False,
                "error": f"服务不存在: {service_name}",
                "total": 0,
                "successful": 0,
                "failed": 0,
            }

        subscribers = [
            str(u.bipupu_id)
            for u in service.subscribers
            if getattr(u, "bipupu_id", None)
        ]

        if not subscribers:
            return {
                "success": True,
                "message": "没有订阅者",
                "total": 0,
                "successful": 0,
                "failed": 0,
            }

        return await self.send_batch(service_name, subscribers, content, priority)

    # ------------------------------------------------------------------
    # 测试推送
    # ------------------------------------------------------------------

    async def test_push(self, service_name: str, user_id: str) -> Dict[str, Any]:
        """发送测试推送，验证推送链路是否正常。"""
        test_content = (
            f"测试推送来自 {service_name}\n\n"
            f"时间: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M')}\n\n"
            "这是一个测试消息，用于验证推送系统是否正常工作。"
        )
        return await self.send_push(service_name, user_id, test_content, priority=1)

    # ------------------------------------------------------------------
    # 手动触发定时推送
    # ------------------------------------------------------------------

    async def check_and_send_scheduled(self) -> Dict[str, Any]:
        """手动触发一次定时推送检查（供 POST /push/scheduled/run 接口调用）。"""
        from app.services.push.content import ContentGenerator
        from app.services.push.utils import get_users_for_push_time

        current_time = datetime.now(timezone.utc)
        content_gen = ContentGenerator()
        services = self.db.query(ServiceAccount.name).filter(
            ServiceAccount.is_active.is_(True)
        ).all()

        details = []
        for (svc_name,) in services:
            users = get_users_for_push_time(
                self.db, svc_name, current_time.hour, current_time.minute
            )
            if not users:
                continue
            ok = 0
            for _, bipupu_id in users:
                content = content_gen.get_service_content(svc_name, bipupu_id, current_time)
                try:
                    await service_accounts.send_push(
                        self.db, svc_name, bipupu_id, content=content
                    )
                    ok += 1
                except Exception as e:
                    logger.warning(f"[{svc_name}] 手动定时推送失败 -> {bipupu_id}: {e}")
            details.append({
                "service_name": svc_name,
                "total_users": len(users),
                "success": ok,
                "failed": len(users) - ok,
            })
            logger.info(f"[{svc_name}] 手动推送完成: 成功 {ok}/{len(users)}")

        total = sum(d["total_users"] for d in details)
        ok_total = sum(d["success"] for d in details)
        return {
            "check_time": current_time.isoformat(),
            "total_messages": total,
            "successful_pushes": ok_total,
            "failed_pushes": total - ok_total,
            "details": details,
        }

    # ------------------------------------------------------------------
    # 重试 / 清理
    # ------------------------------------------------------------------

    async def retry_failed(self, max_retries: int = 3) -> Dict[str, Any]:
        """重试失败的推送（每次最多 100 条）。"""
        from app.models.push_log import PushLog, PushStatus

        failed_logs = (
            self.db.query(PushLog)
            .filter(PushLog.status == PushStatus.FAILED, PushLog.retry_count < max_retries)
            .limit(100)
            .all()
        )

        if not failed_logs:
            return {"total_retries": 0, "successful_retries": 0, "failed_retries": 0}

        ok = 0
        for log in failed_logs:
            try:
                await service_accounts.send_push(
                    self.db,
                    str(log.service_name or ""),
                    str(log.receiver_bipupu_id or ""),
                )
                log.status = PushStatus.SUCCESS
                log.completed_at = datetime.now(timezone.utc)
                ok += 1
            except Exception as e:
                log.error_message = str(e)
            finally:
                log.retry_count = (int(log.retry_count) if log.retry_count is not None else 0) + 1

        self.db.commit()
        logger.info(f"重试完成: 成功 {ok}/{len(failed_logs)}")
        return {
            "total_retries": len(failed_logs),
            "successful_retries": ok,
            "failed_retries": len(failed_logs) - ok,
        }

    async def cleanup_old_logs(self, days: int = 30) -> Dict[str, Any]:
        """删除早于 N 天的 success/failed 推送日志。"""
        from app.models.push_log import PushLog

        cutoff = datetime.now(timezone.utc) - timedelta(days=days)
        try:
            deleted = (
                self.db.query(PushLog)
                .filter(
                    PushLog.created_at < cutoff,
                    PushLog.status.in_(["success", "failed"]),
                )
                .delete()
            )
            self.db.commit()
            return {
                "success": True,
                "deleted_count": deleted,
                "cutoff_date": cutoff.isoformat(),
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
        except Exception as e:
            self.db.rollback()
            logger.error(f"清理旧日志失败: {e}")
            return {"success": False, "error": str(e), "deleted_count": 0}

    # ------------------------------------------------------------------
    # 状态
    # ------------------------------------------------------------------

    def get_service_status(self) -> Dict[str, Any]:
        """获取服务状态（供 REST API 使用）。"""
        try:
            services = self.db.query(ServiceAccount).all()
            service_list = []
            for svc in services:
                pt = svc.default_push_time
                service_list.append({
                    "name": str(svc.name or ""),
                    "is_active": bool(svc.is_active),
                    "subscribers": len(svc.subscribers),
                    "default_push_time": pt.strftime("%H:%M") if pt and hasattr(pt, "strftime") else (str(pt) if pt else None),
                })
            return {
                "services": {"count": len(service_list), "list": service_list},
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
        except Exception as e:
            logger.error(f"获取服务状态失败: {e}")
            return {"error": str(e), "timestamp": datetime.now(timezone.utc).isoformat()}
