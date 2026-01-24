from celery import shared_task
from app.core.logging import get_logger

logger = get_logger(__name__)


@shared_task(name="diagnostics.ping")
def ping() -> str:
    """快速心跳任务，验证 worker 可用"""
    logger.debug("Ping task executed")
    return "pong"
