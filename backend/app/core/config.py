from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List, Optional
import os
from urllib.parse import quote_plus


class Settings(BaseSettings):
    """应用配置"""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )


    # 项目配置
    PROJECT_NAME: str = "bipupu"
    VERSION: str = "0.2.0"
    DESCRIPTION: str = "BIPUPU API 服务"
    # 默认管理员配置
    ADMIN_PASSWORD: str = "admin123"
    ADMIN_USERNAME: str = "admin"

    # JWT配置
    SECRET_KEY: str = "your-super-secret-jwt-key-change-this-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24小时
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30  # 30天
    JWT_TOKEN_PREFIX: str = "Bearer"

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

    # 数据库配置
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_SERVER: str = "db"
    POSTGRES_PORT: str = "5432"
    POSTGRES_DB: str = "bipupu"

    @property
    def DATABASE_URL(self) -> str:
        """构建数据库URL"""
        if url := os.getenv("DATABASE_URL"):
            return url

        password = quote_plus(self.POSTGRES_PASSWORD)
        return f"postgresql://{self.POSTGRES_USER}:{password}@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"

    # Redis配置
    REDIS_PASSWORD: Optional[str] = None
    REDIS_HOST: str = "redis"
    REDIS_PORT: str = "6379"
    USE_MEMORY_CACHE: bool = False

    @property
    def REDIS_URL(self) -> str:
        if url := os.getenv("REDIS_URL"):
            return url

        auth = f":{quote_plus(self.REDIS_PASSWORD)}@" if self.REDIS_PASSWORD else ""
        return f"redis://{auth}{self.REDIS_HOST}:{self.REDIS_PORT}/0"

    @property
    def CELERY_BROKER_URL(self) -> str:
        if url := os.getenv("CELERY_BROKER_URL"):
            return url

        auth = f":{quote_plus(self.REDIS_PASSWORD)}@" if self.REDIS_PASSWORD else ""
        return f"redis://{auth}{self.REDIS_HOST}:{self.REDIS_PORT}/1"

    @property
    def CELERY_RESULT_BACKEND(self) -> str:
        if url := os.getenv("CELERY_RESULT_BACKEND"):
            return url

        auth = f":{quote_plus(self.REDIS_PASSWORD)}@" if self.REDIS_PASSWORD else ""
        return f"redis://{auth}{self.REDIS_HOST}:{self.REDIS_PORT}/2"



# 创建配置实例
settings = Settings()
