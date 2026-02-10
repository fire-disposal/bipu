from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator
from typing import List, Optional
import os
from urllib.parse import quote_plus
import warnings
from hashlib import sha256


class Settings(BaseSettings):
    """应用配置"""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
        env_prefix="BIPUPU_"  # 所有环境变量需以 BIPUPU_ 开头
    )

    # 项目配置
    PROJECT_NAME: str = "bipupu"
    VERSION: str = "0.2.0"
    DESCRIPTION: str = "BIPUPU API 服务"

    # 数据库配置
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_SERVER: str = "db"
    POSTGRES_PORT: str = "5432"
    POSTGRES_DB: str = "bipupu"
    
    # SQLite配置（fallback）
    SQLITE_DB_PATH: str = "bipupu.db"
    
    @property
    def DATABASE_URL(self) -> str:
        """保持兼容性，返回构建好的 DATABASE_URL，支持自动回退"""
        # 优先使用环境变量
        if os.getenv("BIPUPU_DATABASE_URL"):
            return os.getenv("BIPUPU_DATABASE_URL")
        
        # 尝试构建PostgreSQL URL
        password = quote_plus(self.POSTGRES_PASSWORD)
        postgres_url = f"postgresql://{self.POSTGRES_USER}:{password}@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        
        return postgres_url

    # Redis配置
    REDIS_PASSWORD: Optional[str] = None
    REDIS_HOST: str = "redis"
    REDIS_PORT: str = "6379"
    USE_MEMORY_CACHE: bool = False  # 是否使用内存缓存作为fallback
    
    @property
    def REDIS_URL(self) -> str:
        if os.getenv("BIPUPU_REDIS_URL"):
            return os.getenv("BIPUPU_REDIS_URL")
        
        auth = ""
        if self.REDIS_PASSWORD:
            password = quote_plus(self.REDIS_PASSWORD)
            auth = f":{password}@"
            
        return f"redis://{auth}{self.REDIS_HOST}:{self.REDIS_PORT}/0"

    @property
    def CELERY_BROKER_URL(self) -> str:
        if os.getenv("BIPUPU_CELERY_BROKER_URL"):
            return os.getenv("BIPUPU_CELERY_BROKER_URL")
            
        auth = ""
        if self.REDIS_PASSWORD:
            password = quote_plus(self.REDIS_PASSWORD)
            auth = f":{password}@"
            
        return f"redis://{auth}{self.REDIS_HOST}:{self.REDIS_PORT}/1"

    @property
    def CELERY_RESULT_BACKEND(self) -> str:
        if os.getenv("BIPUPU_CELERY_RESULT_BACKEND"):
            return os.getenv("BIPUPU_CELERY_RESULT_BACKEND")
            
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
    
    @field_validator(
        "ADMIN_USERNAME", 
        "ADMIN_PASSWORD", 
        "POSTGRES_USER", 
        "POSTGRES_PASSWORD", 
        "POSTGRES_SERVER", 
        "POSTGRES_DB",
        mode="before"
    )
    @classmethod
    def empty_str_to_none(cls, v: Optional[str]):
        if v == "":
            return None
        return v


# 创建配置实例
settings = Settings()