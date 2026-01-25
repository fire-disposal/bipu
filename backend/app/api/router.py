from fastapi import APIRouter

from app.api.endpoints import (
    admin_logs,
    friendships,
    health,
    messages,
    message_ack,
    message_management,
    subscription_management,
    system_notifications,
    users,
    user_settings,
)

api_router = APIRouter()

# 包含各个模块的路由
# 系统健康
api_router.include_router(health.router, prefix="/health", tags=["System Health"])

# 用户与设置
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(user_settings.router, prefix="/user-settings", tags=["User Settings"])
api_router.include_router(friendships.router, prefix="/friendships", tags=["Friendships"])

# 消息系统
api_router.include_router(messages.router, prefix="/messages", tags=["Messages"])
api_router.include_router(message_ack.router, prefix="/message-ack", tags=["Message Acknowledgments"])
api_router.include_router(message_management.router, prefix="/message-management", tags=["Message Management"])

# 系统管理与通知
api_router.include_router(subscription_management.router, prefix="/subscriptions", tags=["Subscriptions"])
api_router.include_router(system_notifications.router, prefix="/system-notifications", tags=["System Notifications"])
api_router.include_router(admin_logs.router, prefix="/admin-logs", tags=["Admin Logs"])