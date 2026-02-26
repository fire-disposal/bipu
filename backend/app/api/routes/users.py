"""用户公开信息路由"""
from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import Response
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserPublic
from app.core.logging import get_logger
from app.services.storage_service import StorageService
from app.services.redis_service import RedisService

router = APIRouter()
logger = get_logger(__name__)


@router.get("/users/{bipupu_id}", response_model=UserPublic)
async def get_user_by_bipupu_id(
    bipupu_id: str,
    db: Session = Depends(get_db)
):
    """通过 bipupu_id 获取用户公开信息

    参数：
    - bipupu_id: 用户的业务标识符

    返回：
    - 成功：返回用户公开信息
    - 失败：404（用户不存在）

    包含信息：
    - 用户名、昵称、bipupu_id
    - 头像URL
    - 用户状态（是否活跃）
    - 创建时间等基本信息

    注意：
    - 无需认证，公开接口
    - 不返回敏感信息（如邮箱、密码等）
    - 只返回 is_active=True 的用户信息
    """
    user = db.query(User).filter(
        User.bipupu_id == bipupu_id,
        User.is_active == True
    ).first()

    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    return user


@router.get("/users/{bipupu_id}/avatar")
async def get_user_avatar_by_bipupu_id(
    request: Request,
    bipupu_id: str,
    db: Session = Depends(get_db)
):
    """通过 bipupu_id 获取用户头像

    参数：
    - bipupu_id: 用户的业务标识符

    特性：
    - 支持ETag缓存，减少带宽消耗
    - 支持HTTP 304 Not Modified响应
    - 头像数据缓存24小时
    - 自动处理头像版本更新

    返回：
    - 成功：返回JPEG格式的头像图片
    - 失败：404（用户或头像不存在）

    注意：
    - 无需认证，公开接口
    - 支持缓存控制头（Cache-Control, ETag）
    - 如果用户没有头像，返回404错误
    - 前端应处理无头像情况（如显示首字母）
    """
    user = db.query(User).filter(
        User.bipupu_id == bipupu_id,
        User.is_active == True
    ).first()

    if not user or not user.avatar_data:
        raise HTTPException(status_code=404, detail="头像不存在")

    # 生成ETag - 使用版本号和时间戳
    version = user.avatar_version or 0
    updated_at_timestamp = user.updated_at.timestamp() if user.updated_at else 0
    etag_input = f"{version}:{updated_at_timestamp}".encode()
    etag = StorageService.get_avatar_etag(user.avatar_data, etag_input)

    # 检查ETag匹配
    if request.headers.get("if-none-match") == etag:
        return Response(status_code=304)

    # 尝试从缓存获取头像
    cache_key = StorageService.get_avatar_cache_key(bipupu_id)
    cached_avatar = await RedisService.get_cache(cache_key)

    # 如果缓存存在且ETag匹配，使用缓存
    if cached_avatar:
        cached_etag = StorageService.get_avatar_etag(cached_avatar, etag_input)
        if cached_etag == etag:
            logger.debug(f"头像缓存命中: {bipupu_id}")
            return Response(
                content=cached_avatar,
                media_type="image/jpeg",
                headers={
                    "Cache-Control": "public, max-age=86400",  # 缓存1天
                    "ETag": etag
                }
            )

    # 缓存头像数据（或更新缓存）
    await RedisService.set_cache(cache_key, user.avatar_data, expire=86400)

    return Response(
        content=user.avatar_data,
        media_type="image/jpeg",
        headers={
            "Cache-Control": "public, max-age=86400",  # 缓存1天
            "ETag": etag
        }
    )
