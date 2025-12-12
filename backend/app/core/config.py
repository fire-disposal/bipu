from pydantic_settings import BaseSettings
from typing import List, Optional
import os


class Settings(BaseSettings):
    """应用配置"""
    
    # 项目基本信息
    PROJECT_NAME: str = "FastAPI Backend"
    VERSION: str = "1.0.0"
    DESCRIPTION: str = "FastAPI + PostgreSQL + Redis + Celery Backend"
    DEBUG: bool = False
    
    # 数据库配置
    POSTGRES_PASSWORD: str = "1919810"
    DATABASE_URL: str = f"postgresql://postgres:1919810@db:5432/bipupu"
    
    # Redis配置
    REDIS_URL: str = f"redis://:114514@redis:6379/0"
    CELERY_BROKER_URL: str = f"redis://:114514@redis:6379/1"
    CELERY_RESULT_BACKEND: str = f"redis://:114514@redis:6379/2"
    
    # CORS配置
    ALLOWED_HOSTS: List[str] = ["*"]
    
    # 安全配置
    SECRET_KEY: str = "your-secret-key-here"
    
    # 日志配置
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"  # json or text
    
    # 分页配置
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100
    
    # 文件上传配置
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    UPLOAD_DIR: str = "uploads"
    
    # 时区配置
    TIMEZONE: str = "Asia/Shanghai"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# 创建配置实例
settings = Settings()