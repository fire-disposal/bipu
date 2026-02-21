"""用户公开信息路由"""
from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import Response
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/users/{bipupu_id}", response_model=UserResponse, tags=["用户"])
async def get_user_by_bipupu_id(
    bipupu_id: str,
    db: Session = Depends(get_db)
):
    """通过 bipupu_id 获取用户公开信息"""
    user = db.query(User).filter(User.bipupu_id == bipupu_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user


@router.get("/users/{bipupu_id}/avatar", tags=["用户"])
async def get_user_avatar_by_bipupu_id(
    request: Request,
    bipupu_id: str,
    db: Session = Depends(get_db)
):
    """通过 bipupu_id 获取用户头像 - 优化版本，支持缓存"""
    from app.services.storage_service import StorageService
    from app.services.redis_service import RedisService

    user = db.query(User).filter(User.bipupu_id == bipupu_id).first()
    if not user or not user.avatar_data:
        # 根据用户反馈：前端有自动处理无头像并使用首字母显示的方案
        # 没有头像没有关系，无需处理默认头像配置
        raise HTTPException(status_code=404, detail="Avatar not found")

    # 生成ETag - 使用版本号和时间戳
    version = user.avatar_version or 0
    updated_at_timestamp = user.updated_at.timestamp() if user.updated_at else 0
    etag_input = f"{version}:{updated_at_timestamp}".encode()
    etag = StorageService.get_avatar_etag(user.avatar_data, etag_input.encode() if isinstance(etag_input, str) else etag_input)

    # 检查ETag匹配
    if request and request.headers.get("if-none-match") == etag:
        return Response(status_code=304)

    # 尝试从缓存获取头像
    cache_key = StorageService.get_avatar_cache_key(bipupu_id)
    cached_avatar = await RedisService.get_cache(cache_key)

    # 如果缓存存在且ETag匹配，使用缓存
    if cached_avatar:
        # 验证缓存是否仍然有效（基于版本号）
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
    await RedisService.set_cache(cache_key, user.avatar_data, expire=86400)  # 缓存1天

    return Response(
        content=user.avatar_data,
        media_type="image/jpeg",  # 统一使用JPEG格式，与上传处理保持一致
        headers={
            "Cache-Control": "public, max-age=86400",  # 缓存1天
            "ETag": etag
        }
    )
