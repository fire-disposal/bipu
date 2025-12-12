from celery import Celery
from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

# 创建Celery实例
celery_app = Celery(
    "fastapi-app",
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
)

# 配置任务路由
celery_app.conf.task_routes = {
    "app.tasks.*": {"queue": "default"},
}


@celery_app.task(bind=True)
def debug_task(self):
    """调试任务"""
    logger.info(f"Request: {self.request!r}")
    return {"status": "success", "task_id": self.request.id}


@celery_app.on_after_configure.connect
def setup_periodic_tasks(sender, **kwargs):
    """配置定时任务"""
    # 每分钟执行一次调试任务
    sender.add_periodic_task(
        60.0,  # 60秒
        debug_task.s(),
        name="debug every minute"
    )
    logger.info("Periodic tasks configured")


if __name__ == "__main__":
    celery_app.start()