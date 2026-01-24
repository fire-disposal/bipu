from fastapi import APIRouter

from app.api.endpoints import health, users

api_router = APIRouter()

# 包含各个模块的路由
api_router.include_router(health.router, prefix="/health", tags=["health"])
api_router.include_router(users.router, prefix="/users", tags=["users"])