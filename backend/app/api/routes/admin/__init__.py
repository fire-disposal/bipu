"""管理员API路由聚合 - 需要管理员身份"""

from fastapi import APIRouter

# 导入子路由
from app.api.routes.admin.users import router as users_router
from app.api.routes.admin.subscriptions import router as subscriptions_router


router = APIRouter()

# 包含子路由
router.include_router(users_router, tags=["用户管理"])
router.include_router(subscriptions_router, prefix="/subscriptions", tags=["订阅开关"])