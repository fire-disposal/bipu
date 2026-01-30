from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import os
from app.api.router import api_router
from app.core.config import settings
from app.db.database import init_db, init_redis, close_redis
from app.db.init_data import init_default_data
from app.core.logging import get_logger
import uvicorn
from app.core.openapi_util import export_openapi_json

from app.core.logging import setup_logging
setup_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    logger.info("🚀 服务启动中")
    
    # 显示当前使用的数据库信息
    db_url = settings.DATABASE_URL
    if "sqlite" in db_url:
        db_name = db_url.split("///")[-1] if "///" in db_url else "SQLite"
        logger.info(f"🗄️  使用 SQLite 数据库: {db_name}")
    elif "postgresql" in db_url:
        db_name = db_url.split("/")[-1] if "/" in db_url else "PostgreSQL"
        logger.info(f"🐘 使用 PostgreSQL 数据库: {db_name}")
    else:
        logger.info(f"📊 使用数据库: {db_url}")
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
        
        # 初始化Redis
        await init_redis()
        logger.info("✅ Redis initialized")
        # 生成 OpenAPI.json 文件

        try:
            export_openapi_json(app)
            logger.info("✅ OpenAPI.json 文件已生成")
        except Exception as e:
            logger.error(f"❌ OpenAPI.json 生成失败: {e}")

        port = os.getenv("PORT", "8000")
        logger.info("✅ 服务启动完成 ")
        logger.info(f"📚 API文档地址:    http://localhost:{port}/api/docs")
        logger.info(f"📋 OpenAPI.json 地址: http://localhost:{port}/api/openapi.json")

 
    
    except Exception as e:
        logger.error(f"❌ 初始化错误: {e}")
        raise
    
    yield
    
    # 清理资源
    try:
        await close_redis()
        logger.info("✅ Redis连接已关闭")
    except Exception as e:
        logger.error(f"❌ 关闭Redis连接时出错: {e}")
    
    logger.info("🛑 服务停止中")

def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        description=settings.DESCRIPTION,
        lifespan=lifespan,
        openapi_url="/api/openapi.json",
        docs_url="/api/docs",
        redoc_url="/api/redoc",
    )

    @app.middleware("http")
    async def add_security_headers(request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Frame-Options"] = "SAMEORIGIN"
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        return response

    # 挂载静态文件 (替代 Nginx 功能)
    # 确保上传目录存在
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

    # 注册你的业务路由
    app.include_router(api_router, prefix="/api")

    @app.get("/health", tags=["System"])
    async def health_check():
        return {"status": "healthy"}

    return app

app = create_app()

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=True)