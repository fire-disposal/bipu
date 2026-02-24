"""JWT认证和授权相关功能"""
from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.schemas.user import JWTPayload
from app.core.config import settings
from app.db.database import get_db
from app.models.user import User
from app.core.logging import get_logger
from pydantic import ValidationError
from app.services.redis_service import RedisService

logger = get_logger(__name__)

# 密码加密上下文 - 使用兼容的配置
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
    user = db.query(User).filter(User.username == username).first()
    if not user:
        return None
    if not verify_password(password, str(user.hashed_password)):
        return None
    return user


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """创建访问令牌"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    # 确保 sub 是字符串
    if "sub" in to_encode:
        to_encode["sub"] = str(to_encode["sub"])

    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: dict) -> str:
    """创建刷新令牌"""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    # 确保 sub 是字符串
    if "sub" in to_encode:
        to_encode["sub"] = str(to_encode["sub"])

    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def decode_token(token: str) -> Optional[dict]:
    """解码JWT令牌"""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError as e:
        logger.error(f"JWT Decode Error: {e}")
        return None


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """获取当前用户"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        token = credentials.credentials

        # 检查令牌是否在黑名单中
        if await RedisService.is_token_blacklisted(token):
            logger.warning("Token is blacklisted")
            raise credentials_exception

        payload = decode_token(token)
        if payload is None:
            # decode_token logs the error
            raise credentials_exception

        # 使用 Pydantic 模型验证 payload
        try:
            token_data = JWTPayload(**payload)
        except ValidationError as e:
            logger.error(f"Token payload validation error: {e}")
            raise credentials_exception

        # 检查令牌类型
        if token_data.type != "access":
            logger.warning("Token type is not access")
            raise credentials_exception

        try:
            user_id = int(token_data.sub)
        except (ValueError, TypeError):
            logger.warning(f"Token sub is not an integer: {token_data.sub}")
            raise credentials_exception

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Token validation error: {e}")
        raise credentials_exception

    # 查询用户
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        logger.warning(f"User not found for id: {user_id}")
        raise credentials_exception

    return user


async def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """获取当前活跃用户"""
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


async def get_current_superuser(current_user: User = Depends(get_current_user)) -> User:
    """获取当前超级用户"""
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user


async def get_current_superuser_web(
    request: Request,
    db: Session = Depends(get_db)
) -> User:
    """Web版本的超级用户认证，失败时重定向到登录页面"""
    # 首先尝试从cookie获取token
    token = request.cookies.get("access_token")
    if token and token.startswith("Bearer "):
        token = token[7:]  # 移除 "Bearer " 前缀

    # 如果没有cookie token，尝试Authorization header
    if not token:
        auth_header = request.headers.get("authorization")
        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header[7:]

    if not token:
        from app.core.exceptions import AdminAuthException
        raise AdminAuthException()

    try:
        # 检查令牌是否在黑名单中
        if await RedisService.is_token_blacklisted(token):
            raise Exception("Token blacklisted")

        payload = decode_token(token)
        if payload is None:
            raise Exception("Invalid token")

        # 检查令牌类型
        if payload.get("type") != "access":
            raise Exception("Invalid token type")

        user_id_str = payload.get("sub")
        if user_id_str is None:
             raise Exception("Token missing sub")

        try:
            user_id = int(str(user_id_str))
        except (ValueError, TypeError):
             raise Exception("Invalid token sub")

    except Exception as e:
        logger.error(f"Token validation error: {e}")
        # 重定向到登录页面
        from app.core.exceptions import AdminAuthException
        raise AdminAuthException()

    # 查询用户
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        from app.core.exceptions import AdminAuthException
        raise AdminAuthException()

    if not user.is_superuser:
        from app.core.exceptions import AdminAuthException
        raise AdminAuthException()

    return user
