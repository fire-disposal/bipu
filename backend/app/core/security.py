"""JWT认证和授权相关功能 - 优化版本

设计原则：
1. 精简：移除不必要的依赖
2. 安全：使用安全的密码处理和令牌管理
3. 实用：提供核心认证功能
"""

from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.core.config import settings
from app.db.database import get_db
from app.models.user import User
from app.core.logging import get_logger
from app.services.redis_service import RedisService

logger = get_logger(__name__)

# 密码加密上下文
pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto"
)

# JWT token认证方案
security = HTTPBearer()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """验证密码"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """获取密码哈希"""
    return pwd_context.hash(password)


def authenticate_user(db: Session, username: str, password: str) -> Optional[User]:
    """验证用户凭据"""
    user = db.query(User).filter(
        User.username == username,
        User.is_active == True
    ).first()

    if not user:
        return None

    if not verify_password(password, user.password_hash):
        return None

    return user


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """创建访问令牌"""
    to_encode = data.copy()

    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({
        "exp": expire,
        "type": "access"
    })

    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )

    return encoded_jwt


def create_refresh_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """创建刷新令牌"""
    to_encode = data.copy()

    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    to_encode.update({
        "exp": expire,
        "type": "refresh"
    })

    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )

    return encoded_jwt


def decode_token(token: str) -> Optional[Dict[str, Any]]:
    """解码JWT令牌"""
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError as e:
        logger.error(f"Token decode error: {e}")
        return None


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """获取当前用户（依赖注入）"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无效的认证凭据",
        headers={"WWW-Authenticate": "Bearer"},
    )

    token = credentials.credentials

    # 检查令牌是否在黑名单中
    if await RedisService.is_token_blacklisted(token):
        logger.warning("Token is blacklisted")
        raise credentials_exception

    payload = decode_token(token)
    if payload is None:
        raise credentials_exception

    # 检查令牌类型
    token_type = payload.get("type")
    if token_type != "access":
        logger.warning(f"Invalid token type: {token_type}")
        raise credentials_exception

    # 获取用户名
    username = payload.get("sub")
    if username is None:
        logger.warning("Token missing sub claim")
        raise credentials_exception

    # 查找用户
    user = db.query(User).filter(
        User.username == username,
        User.is_active == True
    ).first()

    if user is None:
        logger.warning(f"User not found: {username}")
        raise credentials_exception

    return user


async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """获取当前活跃用户"""
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="用户未激活")
    return current_user


async def get_current_superuser(
    current_user: User = Depends(get_current_user)
) -> User:
    """获取当前超级用户"""
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="权限不足"
        )
    return current_user


async def get_current_user_web(
    request: Request,
    db: Session = Depends(get_db)
) -> Optional[User]:
    """Web界面获取当前用户（基于会话）"""
    # 从会话中获取用户ID
    user_id = request.session.get("user_id")
    if not user_id:
        return None

    user = db.query(User).filter(
        User.id == user_id,
        User.is_active == True
    ).first()

    return user


async def get_current_superuser_web(
    current_user: User = Depends(get_current_user_web)
) -> User:
    """Web界面获取当前超级用户"""
    if not current_user or not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="权限不足"
        )
    return current_user


async def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: Session = Depends(get_db)
) -> Optional[User]:
    """可选获取当前用户（用于公开接口）"""
    if not credentials:
        return None

    try:
        return await get_current_user(credentials, db)
    except HTTPException:
        return None
