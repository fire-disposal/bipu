from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
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
        
        # # 初始化Redis
        # await init_redis()
        # logger.info("✅ Redis initialized")
        # 生成 OpenAPI.json 文件
        try:
            export_openapi_json(app)
            logger.info("✅ OpenAPI.json 文件已生成")
        except Exception as e:
            logger.error(f"❌ OpenAPI.json 生成失败: {e}")

        logger.info("✅ 服务启动完成 ")
        logger.info("📚 API文档地址:    http://localhost:8848/api/docs")
        logger.info("📋 OpenAPI.json 地址: http://localhost:8848/api/openapi.json")

 
    
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

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # 注册你的业务路由
    app.include_router(api_router, prefix="/api")

    @app.get("/health", tags=["System"])
    async def health_check():
        return {"status": "healthy"}

    return app

app = create_app()

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8848, reload=True)