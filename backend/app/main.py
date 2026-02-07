from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from contextlib import asynccontextmanager
import os
from app.api.router import api_router
from app.api.routes.root import router as root_router
from app.core.config import settings
from app.db.database import current_db_type, fallback_used, redis_client, MemoryCacheWrapper, init_db, init_redis
from app.db.init_data import init_default_data
from app.core.logging import get_logger
import uvicorn
from app.core.openapi_util import export_openapi_json
from app.core.exceptions import custom_exception_handler, http_exception_handler, general_exception_handler, BaseCustomException
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
    fallback_indicator = " (回退)" if fallback_used else ""
    
    if current_db_type == "sqlite":
        db_name = db_url.split("///")[-1] if "///" in db_url else "SQLite"
        logger.info(f"🗄️  使用 SQLite 数据库: {db_name}{fallback_indicator}")
    elif current_db_type == "postgresql":
        db_name = db_url.split("/")[-1] if "/" in db_url else "PostgreSQL"
        logger.info(f"🐘 使用 PostgreSQL 数据库: {db_name}{fallback_indicator}")
    else:
        logger.info(f"📊 使用数据库: {db_url}{fallback_indicator}")
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
        await init_db()
        logger.info("✅ 数据库初始化完成")
        
        # 初始化默认数据
        await init_default_data()
        logger.info("✅ 默认数据初始化完成")
        
        # 初始化Redis（失败时自动使用内存缓存）
        await init_redis()
        
        port = os.getenv("PORT", "8000")
        logger.info("✅ 服务启动完成 ")
        logger.info(f"📚 API文档地址:    http://localhost:{port}/api/docs")
        logger.info(f"📋 OpenAPI.json 地址: http://localhost:{port}/api/openapi.json")
        logger.info(f"🔧 管理后台入口:  http://localhost:{port}/admin")
        
        # 显示缓存状态
        cache_type = "内存缓存" if isinstance(redis_client, MemoryCacheWrapper) else "Redis"
        logger.info(f"💾 缓存服务: {cache_type}")
        
        db_type = "SQLite" if current_db_type == "sqlite" else "PostgreSQL"
        fallback_note = " (自动回退)" if fallback_used else ""
        logger.info(f"🗄️  数据库: {db_type}{fallback_note}")
        
        # 生成 OpenAPI.json 文件
        try:
            export_openapi_json(app)
            logger.info("✅ OpenAPI.json 文件已生成")
        except Exception as e:
            logger.error(f"❌ OpenAPI.json 生成失败: {e}")

 
    
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
        {"name": "系统", "description": "系统健康检查与服务信息"},
        {"name": "认证", "description": "用户注册、登录、刷新、登出"},
        {"name": "消息", "description": "IM 消息、回执、收藏、归档、搜索"},
        {"name": "好友", "description": "好友请求、同意/拒绝、好友列表"},
        {"name": "黑名单", "description": "拉黑、解除拉黑、黑名单查询"},
        {"name": "用户资料", "description": "用户信息、个人资料、在线状态"},
        {"name": "订阅", "description": "用户侧订阅的查询与管理"},
        {"name": "用户管理", "description": "管理员用户管理"},
        {"name": "订阅管理", "description": "管理员订阅类型与统计"},
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
    templates = Jinja2Templates(directory="templates")
    
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
    app.add_exception_handler(BaseCustomException, custom_exception_handler)
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)
    app.add_exception_handler(RequestValidationError, http_exception_handler)
    app.add_exception_handler(Exception, general_exception_handler)

    return app

app = create_app()

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=True)