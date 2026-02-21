"""Celery任务模块，集中导入以便 autodiscover"""

from .subscriptions import fortune_task, weather_task  # noqa: F401

__all__ = [
    "fortune_task",
    "weather_task",
]
