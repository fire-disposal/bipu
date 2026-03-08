"""Celery配置"""
import os
from celery import Celery
from celery.schedules import crontab
from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

# 获取容器角色
CONTAINER_ROLE = os.getenv("CONTAINER_ROLE", "backend")

celery_app = Celery(
    "bipupu",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=[
        "app.tasks.subscriptions",    # 推送调度任务（定时推送 + 日志清理）
    ]
)

# 配置Celery
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone=settings.TIMEZONE,
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,  # 30分钟
    task_soft_time_limit=25 * 60,  # 25分钟
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=1000,
    beat_schedule={
        # 每15分钟检查定时推送时间窗口，向应接收推送的用户发送消息
        "subscriptions-check-push-times": {
            "task": "subscriptions.check_push_times",
            "schedule": crontab(minute="*/15"),
        },
        # 每天凌晨3点清理30天前的旧推送日志
        "subscriptions-cleanup-push-logs": {
            "task": "subscriptions.cleanup_push_logs",
            "schedule": crontab(hour=3, minute=0),
        },
    }
)

# 根据容器角色配置不同的日志级别
if CONTAINER_ROLE == "worker":
    celery_app.conf.worker_log_level = "INFO"
    logger.info("Celery worker configured")
elif CONTAINER_ROLE == "beat":
    celery_app.conf.beat_log_level = "INFO"
    logger.info("Celery beat configured")
else:
    logger.info("Celery app configured for backend")
