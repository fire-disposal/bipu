from pydantic_settings import BaseSettings
from typing import List, Optional
import os
from urllib.parse import quote_plus
import warnings


class Settings(BaseSettings):
    """应用配置"""
    
    # 项目基本信息
    PROJECT_NAME: str = "BIPU Backend"
    VERSION: str = "1.5.0"
    DESCRIPTION: str = "BIPU,an BLE bp message platform"
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
        在无法连接 PostgreSQL 时，自动回退到 SQLite。
        """
        if os.getenv("DATABASE_URL"):
            return os.getenv("DATABASE_URL")
        
        password = quote_plus(self.POSTGRES_PASSWORD)
        pg_url = f"postgresql://{self.POSTGRES_USER}:{password}@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"

        # 更果断的自动回退逻辑：尝试连接 PostgreSQL，失败则回退到 SQLite
        import socket
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1.0)  # 给足时间检测
            sock.connect((self.POSTGRES_SERVER, int(self.POSTGRES_PORT)))
            sock.close()
        except Exception:
            return "sqlite:///./bipupu.db"
        
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
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"


# 创建配置实例
settings = Settings()