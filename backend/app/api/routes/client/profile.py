"""客户端个人资料API路由 - 用户业务功能，无需管理员权限"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse, UserUpdate, UserProfile
from app.schemas.user_settings import OnlineStatusUpdate
from app.schemas.common import StatusResponse
from app.core.security import get_current_active_user
from app.core.exceptions import ValidationException
from app.core.logging import get_logger
from app.services.redis_service import RedisService
from app.services.user_service import UserService

router = APIRouter()
logger = get_logger(__name__)

@router.get("/me", response_model=UserResponse, tags=["用户资料"])
async def get_current_user_info(
    current_user: User = Depends(get_current_active_user)
):
    """获取当前用户信息"""
    # 尝试从缓存获取用户数据
    cached_data = await RedisService.get_cached_user_data(current_user.id)
    if cached_data:
        return UserResponse(**cached_data)
    
    # 如果缓存不存在，返回当前用户对象
    return current_user


@router.get("/profile", response_model=UserProfile, tags=["用户资料"])
async def get_user_profile(
    current_user: User = Depends(get_current_active_user)
):
    """获取用户详细资料"""
    # 尝试从缓存获取用户数据
    cached_data = await RedisService.get_cached_user_data(current_user.id)
    if cached_data:
        return UserProfile(**cached_data)
    
    # 如果缓存不存在，构建并返回用户资料
    profile = {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
        "nickname": current_user.nickname,
        "is_active": current_user.is_active,
        "is_superuser": current_user.is_superuser,
        "role": current_user.role,
        "last_active": current_user.last_active,
        "created_at": current_user.created_at,
        "updated_at": current_user.updated_at
    }
    
    # 缓存用户资料
    await RedisService.cache_user_data(current_user.id, profile)
    
    return profile


@router.put("/profile", response_model=UserProfile, tags=["用户资料"])
async def update_user_profile(
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户详细资料"""
    try:
        # 使用用户服务层更新用户信息
        updated_user = UserService.update_user(db, current_user, user_update, current_user)
        
        logger.info(f"User profile updated: id={updated_user.id}, username={updated_user.username}")
        
        # 返回更新后的用户资料
        profile = {
            "id": updated_user.id,
            "username": updated_user.username,
            "email": updated_user.email,
            "nickname": updated_user.nickname,
            "is_active": updated_user.is_active,
            "is_superuser": updated_user.is_superuser,
            "role": updated_user.role,
            "last_active": updated_user.last_active,
            "created_at": updated_user.created_at,
            "updated_at": updated_user.updated_at
        }
        
        # 重新缓存用户资料
        await RedisService.cache_user_data(updated_user.id, profile)
        
        return profile
    except ValidationException:
        raise
    except Exception as e:
        logger.error(f"Profile update error: {e}")
        raise ValidationException("Profile update failed")


@router.put("/online-status", response_model=StatusResponse, tags=["用户资料"])
async def update_online_status(
    update: OnlineStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户在线状态"""
    current_user.last_active = datetime.now(timezone.utc)
    db.commit()
    
    # 更新Redis中的用户状态
    status_text = "online" if update.is_online else "offline"
    await RedisService.cache_user_status(current_user.id, status_text)
    
    logger.info(f"User {current_user.username} is now {status_text}")
    return {"message": f"User is now {status_text}"}