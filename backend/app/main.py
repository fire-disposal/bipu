from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from contextlib import asynccontextmanager
import os
from app.api.router import api_router
from app.api.routes.root import router as root_router
from app.core.config import settings
from app.db.database import redis_client, MemoryCacheWrapper, init_redis
from app.db.init_data import init_default_data
from app.core.logging import get_logger
import uvicorn
from app.core.openapi_util import export_openapi_json
from app.core.exceptions import custom_exception_handler, http_exception_handler, general_exception_handler, BaseCustomException, AdminAuthException, admin_auth_exception_handler, request_validation_exception_handler
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException


from app.core.logging import setup_logging
setup_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    logger.info("🚀 服务启动中")

    # 显示当前使用的数据库信息
    db_url = settings.DATABASE_URL
    db_name = db_url.split("/")[-1] if "/" in db_url else "PostgreSQL"
    logger.info(f"✅ 使用数据库: {db_name}")

    # logger.info(
    #     "\n"
    #     "██████╗ ██╗██████╗ ██╗   ██╗██████╗ ██╗   ██╗██████╗ ██╗   ██╗\n"
    #     "██╔══██╗██║██╔══██╗██║   ██║██╔══██╗██║   ██║██╔══██╗╚██╗ ██╔╝\n"
    #     "██████╔╝██║██████╔╝██║   ██║██████╔╝██║   ██║██████╔╝ ╚████╔╝ \n"
    #     "██╔═══╝ ██║██╔══██╗██║   ██║██╔═══╝ ██║   ██║██╔═══╝   ╚██╔╝  \n"
    #     "██║     ██║██║  ██║╚██████╔╝██║     ╚██████╔╝██║        ██║   \n"
    #     "╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝      ╚═════╝ ╚═╝        ╚═╝   \n"
    # )
    # 初始化数据库
    try:
        # 初始化默认数据
        await init_default_data()
        # 初始化Redis（失败时自动使用内存缓存）
        await init_redis()

        port = os.getenv("PORT", "8000")
        logger.info(f"📚 API文档地址:    http://localhost:{port}/api/docs")
        logger.info(f"📋 OpenAPI.json 地址: http://localhost:{port}/api/openapi.json")
        logger.info(f"🔧 管理后台入口:  http://localhost:{port}/admin")

        # 显示缓存状态
        cache_type = "内存缓存" if isinstance(redis_client, MemoryCacheWrapper) else "Redis"
        logger.info(f"💾 缓存服务: {cache_type}")

        # 生成 OpenAPI.json 文件
        try:
            export_openapi_json(app)
            logger.info("✅ OpenAPI.json 文件已生成")
        except Exception as e:
            logger.error(f"❌ OpenAPI.json 生成失败: {e}")

        logger.info("✅ 服务启动完成")



    except Exception as e:
        logger.error(f"❌ 初始化错误: {e}")
        raise

    yield

    # 清理资源
    try:
        if redis_client and hasattr(redis_client, 'close'):
            await redis_client.close()
        logger.info("✅ Redis连接已关闭")
    except Exception as e:
        logger.error(f"❌ 关闭Redis连接时出错: {e}")

    logger.info("🛑 服务停止中")

def create_app() -> FastAPI:
    tags_metadata = [
        {"name": "system", "description": "System health checks, service information and API root path"},
        {"name": "authentication", "description": "User registration, login, token refresh, logout and other authentication related interfaces"},
        {"name": "messages", "description": "Instant message sending, receiving, favoriting, deletion and other message management functions"},
        {"name": "contacts", "description": "Contact adding, querying, updating, deletion and other contact management functions"},
        {"name": "blacklist", "description": "User blocking, unblocking, blacklist query functions"},
        {"name": "user-profile", "description": "User personal information, avatar, password, push settings and other profile management"},
        {"name": "users", "description": "User public information query, including user profiles and avatar retrieval"},
        {"name": "service-accounts", "description": "Service account list, details, subscription management, push settings and other functions"},
        {"name": "subscriptions", "description": "User subscribed service account list and subscription settings management"},
        {"name": "admin", "description": "Administrator backend management interface, including user, message, service account management"},
        {"name": "posters", "description": "Poster management, including creation, update, deletion and image handling"},
        {"name": "websocket", "description": "WebSocket connections for real-time messaging and notifications"},
    ]
    app = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        description=settings.DESCRIPTION,
        lifespan=lifespan,
        openapi_url="/api/openapi.json",
        docs_url="/api/docs",
        redoc_url="/api/redoc",
        openapi_tags=tags_metadata,
    )

    # 配置Jinja2模板
    Jinja2Templates(directory="templates")

    # 挂载静态文件 (替代 Nginx 功能)
    # 确保上传目录存在
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

    # 注册系统根路由 (健康检查等，保持在根路径 /)
    app.include_router(root_router)

    # 注册你的业务路由
    app.include_router(api_router, prefix="/api")

    # 注册管理后台Web路由
    from app.api.routes.admin_web import router as admin_web_router
    app.include_router(admin_web_router, prefix="/admin")

    # 注册全局异常处理器
    app.add_exception_handler(AdminAuthException, admin_auth_exception_handler)  # type: ignore
    app.add_exception_handler(BaseCustomException, custom_exception_handler)  # type: ignore
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)  # type: ignore
    app.add_exception_handler(RequestValidationError, request_validation_exception_handler)  # type: ignore
    app.add_exception_handler(Exception, general_exception_handler)
    
    return app

app = create_app()

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=True)
