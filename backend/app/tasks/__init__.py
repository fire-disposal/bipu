"""Celery任务模块，集中导入以便 autodiscover"""

from .diagnostics import ping  # noqa: F401
from .stats import user_counts  # noqa: F401

__all__ = [
	"ping",
	"user_counts",
]