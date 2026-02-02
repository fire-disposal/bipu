"""客户端API路由聚合 - 用户业务功能，无需管理员权限"""

from fastapi import APIRouter

from app.api.routes.client.messages import router as messages_router
from app.api.routes.client.friends import router as friends_router
from app.api.routes.client.blocks import router as blocks_router
from app.api.routes.client.profile import router as profile_router
from app.api.routes.client.subscriptions import router as subscriptions_router

router = APIRouter()

# 包含子路由
router.include_router(messages_router, prefix="/messages", tags=["消息"])
router.include_router(friends_router, prefix="/friends", tags=["好友"])
router.include_router(blocks_router, prefix="/blocks", tags=["黑名单"])
router.include_router(profile_router, prefix="/profile", tags=["用户资料"])
router.include_router(subscriptions_router, prefix="/subscriptions", tags=["订阅"])