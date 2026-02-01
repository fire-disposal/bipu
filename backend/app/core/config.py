from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import List, Optional
import os
from urllib.parse import quote_plus
import warnings
from hashlib import sha256


class Settings(BaseSettings):
    """应用配置"""
    
    # 项目基本信息
    PROJECT_NAME: str = "bipupu"
    VERSION: str = "1.5.0"
    DESCRIPTION: str = "bipupu backend API"
    DEBUG: bool = False
    
    # 数据库配置
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_SERVER: str = "db"
    POSTGRES_PORT: str = "5432"
    POSTGRES_DB: str = "bipupu"
    
    @property
    def DATABASE_URL(self) -> str:
        """
        如果环境变量中设置了 DATABASE_URL，则直接使用。
        否则根据 POSTGRES_* 变量构建。
        强制使用 PostgreSQL，不再支持 SQLite 回退。
        """
        if os.getenv("DATABASE_URL"):
            return os.getenv("DATABASE_URL")
        
        password = quote_plus(self.POSTGRES_PASSWORD)
        pg_url = f"postgresql://{self.POSTGRES_USER}:{password}@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        
        return pg_url

    # Redis配置
    REDIS_PASSWORD: Optional[str] = None
    REDIS_HOST: str = "redis"
    REDIS_PORT: str = "6379"
    
    @property
    def REDIS_URL(self) -> str:
        if os.getenv("REDIS_URL"):
            return os.getenv("REDIS_URL")
        
        auth = ""
        if self.REDIS_PASSWORD:
            password = quote_plus(self.REDIS_PASSWORD)
            auth = f":{password}@"
            
        return f"redis://{auth}{self.REDIS_HOST}:{self.REDIS_PORT}/0"

    @property
    def CELERY_BROKER_URL(self) -> str:
        if os.getenv("CELERY_BROKER_URL"):
            return os.getenv("CELERY_BROKER_URL")
            
        auth = ""
        if self.REDIS_PASSWORD:
            password = quote_plus(self.REDIS_PASSWORD)
            auth = f":{password}@"
            
        return f"redis://{auth}{self.REDIS_HOST}:{self.REDIS_PORT}/1"

    @property
    def CELERY_RESULT_BACKEND(self) -> str:
        if os.getenv("CELERY_RESULT_BACKEND"):
            return os.getenv("CELERY_RESULT_BACKEND")
            
        auth = ""
        if self.REDIS_PASSWORD:
            password = quote_plus(self.REDIS_PASSWORD)
            auth = f":{password}@"
            
        return f"redis://{auth}{self.REDIS_HOST}:{self.REDIS_PORT}/2"
    
    # CORS配置
    ALLOWED_HOSTS: List[str] = ["*"]
    
    # JWT配置
    SECRET_KEY: str = "your-super-secret-jwt-key-change-this-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    JWT_TOKEN_PREFIX: str = "Bearer"

    # 默认管理员配置
    ADMIN_EMAIL: str = "adminemail@qq.com"
    ADMIN_PASSWORD: str = "admin123"
    ADMIN_USERNAME: str = "admin"
    
    # 安全配置
    PASSWORD_HASH_ALGORITHM: str = "bcrypt"
    
    # 日志配置
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "text"
    
    # 分页配置
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100
    
    # 文件上传配置
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    UPLOAD_DIR: str = "uploads"
    
    # 时区配置
    TIMEZONE: str = "Asia/Shanghai"

    @field_validator("SECRET_KEY")
    @classmethod
    def validate_secret_key(cls, v: str):
        """Normalize secret key for minimal length while staying deterministic."""
        default = "your-super-secret-jwt-key-change-this-in-production"
        if not v:
            raise ValueError("SECRET_KEY cannot be empty")
        if v == default:
            warnings.warn("Using default SECRET_KEY; override in production", UserWarning)
        # Ensure length >= 32 by hashing short keys; keeps compatibility across runtimes
        if len(v) < 32:
            v = sha256(v.encode("utf-8")).hexdigest()
        return v
    
    @field_validator("ADMIN_EMAIL", "ADMIN_USERNAME", "ADMIN_PASSWORD", mode="before")
    @classmethod
    def empty_str_to_none(cls, v: Optional[str]):
        if v == "":
            return None
        return v
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"


# 创建配置实例
settings = Settings()