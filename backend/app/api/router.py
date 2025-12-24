from fastapi import APIRouter

from app.api.endpoints import health, users, devices, messages, notifications, friendships, message_ack, admin_logs

api_router = APIRouter()

# 包含各个模块的路由
api_router.include_router(health.router, prefix="/health", tags=["health"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(devices.router, prefix="/devices", tags=["devices"])
api_router.include_router(messages.router, prefix="/messages", tags=["messages"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
api_router.include_router(friendships.router, prefix="/friendships", tags=["friendships"])
api_router.include_router(message_ack.router, prefix="/message-ack", tags=["message-ack"])
api_router.include_router(admin_logs.router, prefix="/admin-logs", tags=["admin-logs"])