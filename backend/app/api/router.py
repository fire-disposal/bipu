from fastapi import APIRouter

from app.api.endpoints import health, users, messages, friendships, message_ack, admin_logs, user_settings, message_management, subscription_management, system_notifications

api_router = APIRouter()

# 包含各个模块的路由
api_router.include_router(health.router, prefix="/health", tags=["health"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(messages.router, prefix="/messages", tags=["messages"])
api_router.include_router(system_notifications.router, prefix="/system-notifications", tags=["system-notifications"])
api_router.include_router(friendships.router, prefix="/friendships", tags=["friendships"])
api_router.include_router(message_ack.router, prefix="/message-ack", tags=["message-ack"])
api_router.include_router(admin_logs.router, prefix="/admin-logs", tags=["admin-logs"])
api_router.include_router(user_settings.router, prefix="/user-settings", tags=["user-settings"])
api_router.include_router(message_management.router, prefix="/message-management", tags=["message-management"])
api_router.include_router(subscription_management.router, prefix="/subscriptions", tags=["subscriptions"])