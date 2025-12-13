"""Celery配置"""
import os
from celery import Celery
from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

# 获取容器角色
CONTAINER_ROLE = os.getenv("CONTAINER_ROLE", "backend")

# 创建Celery实例
celery_app = Celery(
    "bipupu",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=["app.tasks"]
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
        "cleanup-old-messages": {
            "task": "app.tasks.cleanup.cleanup_old_messages",
            "schedule": 3600.0,  # 每小时执行一次
        },
        "cleanup-old-notifications": {
            "task": "app.tasks.cleanup.cleanup_old_notifications",
            "schedule": 3600.0,  # 每小时执行一次
        },
        "update-device-status": {
            "task": "app.tasks.device.update_device_status",
            "schedule": 300.0,  # 每5分钟执行一次
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

# 自动发现任务
celery_app.autodiscover_tasks(["app.tasks"])