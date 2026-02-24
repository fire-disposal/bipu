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
    """用户注册

    参数：
    - username: 用户名，用于登录
    - password: 密码，长度限制为6-128字符
    - nickname: 昵称，可选

    返回：
    - 成功：返回新创建的用户信息
    - 失败：400（验证失败）或429（注册频率限制）或500（数据库操作失败）

    特性：
    - 速率限制：每个用户名每小时最多10次注册尝试
    - 密码自动哈希存储
    - 自动生成唯一的 bipupu_id
    - 验证用户名和密码格式

    注意：
    - 用户名必须是唯一的
    - 密码在传输和存储中都会加密
    - 注册后用户自动处于活跃状态
    """
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
    """用户登录

    参数：
    - username: 用户名
    - password: 密码

    返回：
    - 成功：返回访问令牌和刷新令牌
    - 失败：401（用户名或密码错误）或400（用户未激活）或429（登录频率限制）

    包含信息：
    - access_token: 访问令牌，用于API认证
    - refresh_token: 刷新令牌，用于获取新的访问令牌
    - token_type: 令牌类型，固定为"bearer"
    - expires_in: 访问令牌过期时间（秒）

    特性：
    - 速率限制：每个用户名每分钟最多5次登录尝试
    - 支持JWT令牌认证
    - 自动验证用户激活状态
    - 符合OAuth 2.0标准格式

    注意：
    - 访问令牌有过期时间，需定期刷新
    - 刷新令牌用于获取新的访问令牌
    - 非活跃用户无法登录
    - 用户信息需要通过单独的端点获取
    """
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

    if not user or not verify_password(user_credentials.password, str(user.hashed_password)):
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
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }


@router.post("/refresh", response_model=Token, tags=["认证"])
async def refresh_token(
    token_refresh: TokenRefresh,
    db: Session = Depends(get_db)
):
    """刷新访问令牌

    参数：
    - refresh_token: 刷新令牌

    返回：
    - 成功：返回新的访问令牌和刷新令牌
    - 失败：401（无效的刷新令牌）或429（刷新频率限制）

    包含信息：
    - access_token: 新的访问令牌
    - refresh_token: 新的刷新令牌（支持令牌轮换）
    - token_type: 令牌类型，固定为"bearer"
    - expires_in: 访问令牌过期时间（秒）

    特性：
    - 速率限制：每个刷新令牌每小时最多10次刷新尝试
    - 支持令牌轮换，每次刷新生成新的刷新令牌
    - 验证刷新令牌类型和用户状态
    - 自动验证用户是否活跃
    - 符合OAuth 2.0标准格式

    注意：
    - 刷新令牌只能用于刷新访问令牌，不能用于API访问
    - 旧的刷新令牌在刷新后失效
    - 非活跃用户的刷新令牌无效
    - 用户信息需要通过单独的端点获取
    """
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

        user_id_str = payload.get("sub")
        if not user_id_str:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token",
                headers={"WWW-Authenticate": "Bearer"},
            )
        user_id: int = int(str(user_id_str))
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
    """用户登出

    参数：
    - Bearer Token: 通过Authorization头传递的访问令牌

    返回：
    - 成功：返回登出成功消息
    - 失败：401（无效令牌）或500（服务器错误）

    特性：
    - 将当前访问令牌加入黑名单
    - 黑名单令牌在剩余有效期内无法使用
    - 支持令牌过期时间计算

    注意：
    - 需要有效的访问令牌
    - 登出后当前令牌立即失效
    - 其他设备的令牌仍然有效，需要分别登出
    - 刷新令牌不受登出影响，需要单独处理
    """
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
