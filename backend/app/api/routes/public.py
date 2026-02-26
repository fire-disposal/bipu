"""公共接口路由 - 登录注册等通用功能

设计原则：
1. 精简：只包含必要的认证功能
2. 安全：使用安全的密码处理和令牌管理
3. 验证：严格的输入验证
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import Optional

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import (
    UserCreate, UserPrivate, UserLogin, Token, TokenRefresh
)
from app.schemas.common import StatusResponse, SuccessResponse
from app.core.security import (
    verify_password, create_access_token, create_refresh_token,
    decode_token, get_password_hash
)
from app.core.exceptions import ValidationException
from app.core.logging import get_logger
from app.core.config import settings
from app.services.redis_service import RedisService
from app.services.user_service import UserService

router = APIRouter()
logger = get_logger(__name__)


@router.post("/register", response_model=UserPrivate)
async def register_user(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """用户注册

    参数：
    - username: 用户名，用于登录
    - password: 密码，长度限制为6-128字符
    - nickname: 昵称，可选

    返回：
    - 成功：返回新创建的用户信息
    - 失败：400（验证失败）或500（数据库操作失败）

    特性：
    - 密码自动哈希存储
    - 自动生成唯一的 bipupu_id
    - 验证用户名和密码格式

    注意：
    - 用户名必须是唯一的
    - 密码在传输和存储中都会加密
    - 注册后用户自动处于活跃状态
    """
    try:
        # 检查用户名是否已存在
        existing_user = db.query(User).filter(User.username == user_data.username).first()
        if existing_user:
            raise ValidationException("用户名已存在")

        # 创建用户
        user = User(
            username=user_data.username,
            password_hash=get_password_hash(user_data.password),
            nickname=user_data.nickname,
            is_active=True
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        logger.info(f"用户注册成功: username={user.username}, id={user.id}")
        return user

    except ValidationException as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        db.rollback()
        logger.error(f"用户注册失败: {e}")
        raise HTTPException(status_code=500, detail="注册失败")


@router.post("/login", response_model=Token)
async def login_user(
    login_data: UserLogin,
    db: Session = Depends(get_db)
):
    """用户登录

    参数：
    - username: 用户名
    - password: 密码

    返回：
    - 成功：返回访问令牌和刷新令牌
    - 失败：401（认证失败）或400（验证失败）

    特性：
    - 支持JWT令牌
    - 令牌有过期时间
    - 支持刷新令牌机制

    注意：
    - 只允许活跃用户登录
    - 令牌存储在安全的地方
    """
    try:
        # 查找用户
        user = db.query(User).filter(
            User.username == login_data.username,
            User.is_active == True
        ).first()

        if not user:
            raise ValidationException("用户名或密码错误")

        # 验证密码
        if not verify_password(login_data.password, user.password_hash):
            raise ValidationException("用户名或密码错误")

        # 更新最后活跃时间
        user.update_last_active()
        db.add(user)
        db.commit()

        # 创建令牌
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        refresh_token_expires = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

        access_token = create_access_token(
            data={"sub": user.username},
            expires_delta=access_token_expires
        )

        refresh_token = create_refresh_token(
            data={"sub": user.username},
            expires_delta=refresh_token_expires
        )

        logger.info(f"用户登录成功: username={user.username}, id={user.id}")
        return Token(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=int(access_token_expires.total_seconds())
        )

    except ValidationException as e:
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        logger.error(f"用户登录失败: {e}")
        raise HTTPException(status_code=500, detail="登录失败")


@router.post("/refresh", response_model=Token)
async def refresh_token(
    token_data: TokenRefresh,
    db: Session = Depends(get_db)
):
    """刷新访问令牌

    参数：
    - refresh_token: 刷新令牌

    返回：
    - 成功：返回新的访问令牌和刷新令牌
    - 失败：401（令牌无效或过期）或400（验证失败）

    特性：
    - 使用刷新令牌获取新的访问令牌
    - 刷新令牌可以轮换
    - 支持令牌黑名单

    注意：
    - 刷新令牌只能使用一次
    - 旧的刷新令牌会被加入黑名单
    """
    try:
        # 验证刷新令牌
        payload = decode_token(token_data.refresh_token)
        if not payload or payload.get("type") != "refresh":
            raise ValidationException("无效的刷新令牌")

        username = payload.get("sub")
        if not username:
            raise ValidationException("无效的令牌载荷")

        # 查找用户
        user = db.query(User).filter(
            User.username == username,
            User.is_active == True
        ).first()

        if not user:
            raise ValidationException("用户不存在或已禁用")

        # 检查令牌是否在黑名单中
        if await RedisService.is_token_blacklisted(token_data.refresh_token):
            raise ValidationException("令牌已失效")

        # 将旧的刷新令牌加入黑名单
        token_exp = payload.get("exp", 0)
        current_time = timedelta(seconds=token_exp)
        await RedisService.add_token_to_blacklist(
            token_data.refresh_token,
            int(current_time.total_seconds())
        )

        # 创建新的令牌
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        refresh_token_expires = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

        access_token = create_access_token(
            data={"sub": user.username},
            expires_delta=access_token_expires
        )

        new_refresh_token = create_refresh_token(
            data={"sub": user.username},
            expires_delta=refresh_token_expires
        )

        logger.info(f"令牌刷新成功: username={user.username}")
        return Token(
            access_token=access_token,
            refresh_token=new_refresh_token,
            expires_in=int(access_token_expires.total_seconds())
        )

    except ValidationException as e:
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        logger.error(f"令牌刷新失败: {e}")
        raise HTTPException(status_code=500, detail="令牌刷新失败")


@router.post("/logout", response_model=SuccessResponse)
async def logout_user(
    credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer()),
    current_user: User = Depends(lambda: None)  # 占位符，实际由依赖注入
):
    """用户登出

    参数：
    - Authorization: Bearer令牌

    返回：
    - 成功：返回登出成功消息
    - 失败：401（认证失败）

    特性：
    - 将访问令牌加入黑名单
    - 支持立即令牌失效

    注意：
    - 登出后令牌立即失效
    - 需要有效的访问令牌
    """
    try:
        token = credentials.credentials

        # 将令牌加入黑名单
        payload = decode_token(token)
        if payload and "exp" in payload:
            token_exp = payload.get("exp", 0)
            current_time = timedelta(seconds=token_exp)
            await RedisService.add_token_to_blacklist(
                token,
                int(current_time.total_seconds())
            )

        logger.info("用户登出成功")
        return SuccessResponse(message="登出成功")

    except Exception as e:
        logger.error(f"用户登出失败: {e}")
        raise HTTPException(status_code=500, detail="登出失败")


@router.get("/verify-token", response_model=SuccessResponse)
async def verify_token(
    credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer())
):
    """验证令牌有效性

    参数：
    - Authorization: Bearer令牌

    返回：
    - 成功：返回验证成功消息
    - 失败：401（令牌无效）

    特性：
    - 快速令牌验证
    - 不执行数据库查询

    注意：
    - 只验证令牌格式和签名
    - 不检查用户状态
    """
    try:
        token = credentials.credentials

        # 验证令牌
        payload = decode_token(token)
        if not payload:
            raise ValidationException("无效的令牌")

        # 检查令牌是否在黑名单中
        if await RedisService.is_token_blacklisted(token):
            raise ValidationException("令牌已失效")

        return SuccessResponse(message="令牌有效")

    except ValidationException as e:
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        logger.error(f"令牌验证失败: {e}")
        raise HTTPException(status_code=500, detail="令牌验证失败")
