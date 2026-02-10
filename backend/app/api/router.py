from fastapi import APIRouter

# 导入新的路由模块
from app.api.routes.public import router as public_router
from app.api.routes.messages import router as messages_router
from app.api.routes.blocks import router as blocks_router
from app.api.routes.profile import router as profile_router
from app.api.routes.users import router as users_router
from app.api.routes.contacts import router as contacts_router
from app.api.routes.websocket import router as websocket_router
from app.api.routes.service_accounts import router as service_accounts_router

api_router = APIRouter()

# 公共接口路由 (认证相关)
api_router.include_router(public_router, prefix="/public", tags=["认证"])

# 消息/用户/资料 路由
api_router.include_router(messages_router, prefix="/messages", tags=["消息"])
api_router.include_router(blocks_router, tags=["黑名单"])
api_router.include_router(profile_router, prefix="/profile", tags=["用户资料"])
api_router.include_router(users_router, tags=["用户管理"])
api_router.include_router(contacts_router, prefix="/contacts", tags=["联系人"])
api_router.include_router(service_accounts_router, prefix="/service_accounts", tags=["服务号"])

# WebSocket 路由
api_router.include_router(websocket_router, tags=["WebSocket"])