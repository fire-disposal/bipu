from fastapi import APIRouter

# 导入新的路由模块
from app.api.routes.public import router as public_router
from app.api.routes.client import router as client_router

api_router = APIRouter()

# 公共接口路由 (认证相关)
api_router.include_router(public_router, prefix="/public", tags=["认证"])

# 客户端API路由 (用户业务功能，无需管理员权限)
api_router.include_router(client_router, prefix="/client")