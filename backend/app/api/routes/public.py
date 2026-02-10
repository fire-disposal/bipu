"""公共接口路由 - 登录注册等通用功能"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from datetime import timedelta

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse, UserLogin, Token, TokenRefresh
from app.schemas.common import StatusResponse
from app.core.security import (
    verify_password, create_access_token, create_refresh_token,
    decode_token
)
from app.core.exceptions import ValidationException
from app.core.logging import get_logger
from app.core.config import settings
from app.services.redis_service import RedisService
from app.services.user_service import UserService

router = APIRouter()
logger = get_logger(__name__)

@router.post("/register", response_model=UserResponse, tags=["认证"])
async def register_user(
    user: UserCreate,
    db: Session = Depends(get_db)
):
    """用户注册"""
    # 速率限制：每个IP每小时最多10次注册
    # 这里简化处理，使用用户名作为速率限制键
    rate_limit_key = f"register:{user.username}"
    allowed, _ = await RedisService.rate_limit(rate_limit_key, limit=10, window=3600)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many registration attempts"
        )
    
    try:
        db_user = UserService.create_user(db, user)
        logger.info(f"User registered: id={db_user.id}, username={db_user.username}")
        return db_user
    except ValidationException:
        raise
    except Exception as e:
        logger.error(f"Registration error: {e}")
        raise ValidationException("Registration failed")


@router.post("/login", response_model=Token, tags=["认证"])
async def login(
    user_credentials: UserLogin,
    db: Session = Depends(get_db)
):
    """用户登录"""
    # 速率限制：每个用户名每分钟最多5次登录尝试
    rate_limit_key = f"login:{user_credentials.username}"
    allowed, _ = await RedisService.rate_limit(rate_limit_key, limit=5, window=60)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many login attempts"
        )
    
    # 查找用户
    user = UserService.get_user_by_email_or_username(db, user_credentials.username)
    
    if not user or not verify_password(user_credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    # 创建访问令牌，使用配置中的过期时间
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.id}, expires_delta=access_token_expires
    )
    
    logger.info(f"User logged in: id={user.id}, username={user.username}")
    
    # 创建刷新令牌
    refresh_token = create_refresh_token(data={"sub": user.id})
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "user": user
    }


@router.post("/refresh", response_model=Token, tags=["认证"])
async def refresh_token(
    token_refresh: TokenRefresh,
    db: Session = Depends(get_db)
):
    """刷新访问令牌"""
    # 速率限制：每个刷新令牌每小时最多10次刷新
    rate_limit_key = f"refresh:{token_refresh.refresh_token[:20]}"  # 使用令牌前20字符作为键
    allowed, _ = await RedisService.rate_limit(rate_limit_key, limit=10, window=3600)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many token refresh attempts"
        )
    
    try:
        payload = decode_token(token_refresh.refresh_token)
        if payload is None or payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        user_id: int = int(payload.get("sub"))
        user = UserService.get_user_by_id(db, user_id)
        
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid user",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 创建新的访问令牌，使用配置中的过期时间
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.id}, expires_delta=access_token_expires
        )
        
        # 返回新的 refresh token 以支持刷新令牌轮换
        new_refresh = create_refresh_token(data={"sub": user.id})
        logger.info(f"Token refreshed for user: id={user.id}, username={user.username}")
        return {
            "access_token": access_token,
            "refresh_token": new_refresh,
            "token_type": "bearer",
            "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        }
        
    except Exception as e:
        logger.error(f"Token refresh error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )


@router.post("/logout", response_model=StatusResponse, tags=["认证"])
async def logout(
    credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer()),
):
    """用户登出"""
    try:
        token = credentials.credentials
        # 解码令牌以获取过期时间
        payload = decode_token(token)
        if payload and "exp" in payload:
            # 计算剩余过期时间（秒）
            import time
            current_time = int(time.time())
            expire_time = payload["exp"]
            remaining_seconds = max(0, expire_time - current_time)
            
            # 将令牌添加到黑名单，过期时间为剩余时间
            await RedisService.add_token_to_blacklist(token, remaining_seconds)
        
        return {"message": "Logged out successfully"}
    except Exception as e:
        logger.error(f"Logout error: {e}")
        return {"message": "Logout processed"}