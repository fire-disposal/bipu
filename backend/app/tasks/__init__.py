"""Celery任务模块，集中导入以便 autodiscover"""

from .diagnostics import ping  # noqa: F401
from .maintenance import cleanup_admin_logs  # noqa: F401
from .stats import user_counts  # noqa: F401
from .subscription_tasks import generate_weather_subscription, generate_fortune_subscription  # noqa: F401

__all__ = [
	"ping",
	"cleanup_admin_logs",
	"user_counts",
	"generate_weather_subscription",
	"generate_fortune_subscription",
]