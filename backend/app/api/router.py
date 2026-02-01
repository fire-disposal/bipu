from fastapi import APIRouter

# 导入新的路由模块
from app.api.routes.root import router as root_router
from app.api.routes.public import router as public_router
from app.api.routes.client import router as client_router  # 这会导入 client.py 文件
from app.api.routes.admin import router as admin_router    # 这会导入 admin.py 文件

api_router = APIRouter()

# 根目录路由 (健康检查、文档等)
api_router.include_router(root_router)

# 公共接口路由 (登录注册等通用功能)
api_router.include_router(public_router, prefix="/public", tags=["Public"])

# 客户端API路由 (用户业务功能，无需管理员权限)
api_router.include_router(client_router, prefix="/client", tags=["Client"])

# 管理员API路由 (需要管理员身份)
api_router.include_router(admin_router, prefix="/admin", tags=["Admin"])