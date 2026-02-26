from fastapi import APIRouter

# 导入所有路由模块
from app.api.routes.public import router as public_router
from app.api.routes.messages import router as messages_router
from app.api.routes.blocks import router as blocks_router
from app.api.routes.profile import router as profile_router
from app.api.routes.users import router as users_router
from app.api.routes.contacts import router as contacts_router
from app.api.routes.websocket import router as websocket_router
from app.api.routes.service_accounts import router as service_accounts_router
from app.api.routes.posters import router as posters_router
from app.api.routes.admin_web import router as admin_web_router
from app.api.routes.root import router as root_router

api_router = APIRouter()

# System routes (health checks, API info, etc.)
api_router.include_router(root_router, tags=["system"])

# Public routes (authentication related)
api_router.include_router(public_router, prefix="/public", tags=["authentication"])

# Message routes
api_router.include_router(messages_router, prefix="/messages", tags=["messages"])

# Blacklist routes
api_router.include_router(blocks_router, prefix="/blocks", tags=["blacklist"])

# User profile routes
api_router.include_router(profile_router, prefix="/profile", tags=["user-profile"])

# User public info routes
api_router.include_router(users_router, prefix="/users", tags=["users"])

# Contact routes
api_router.include_router(contacts_router, prefix="/contacts", tags=["contacts"])

# Service account routes
api_router.include_router(service_accounts_router, prefix="/service_accounts", tags=["service-accounts"])

# Poster routes
api_router.include_router(posters_router, prefix="/posters", tags=["posters"])

# WebSocket routes
api_router.include_router(websocket_router, prefix="/ws", tags=["websocket"])

# Admin web routes (web interface)
api_router.include_router(admin_web_router, prefix="/admin", tags=["admin"])
