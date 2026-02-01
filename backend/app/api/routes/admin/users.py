"""管理员用户管理API路由 - 需要管理员身份"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse, UserUpdate
from app.schemas.common import PaginatedResponse, PaginationParams
from app.core.security import get_current_superuser
from app.core.exceptions import ValidationException, NotFoundException
from app.core.logging import get_logger
from app.services.stats_service import StatsService
from app.services.redis_service import RedisService
from app.services.user_service import UserService

router = APIRouter()
logger = get_logger(__name__)


@router.get("/users", response_model=PaginatedResponse[UserResponse], tags=["User Management"])
async def get_users(
    pagination: PaginationParams = Depends(),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """获取用户列表（需要超级用户权限）"""
    # 尝试从缓存获取用户列表
    cache_key = f"admin:users:page_{pagination.page}_size_{pagination.size}"
    cached_result = await RedisService.get_cached_api_response(cache_key)
    if cached_result is not None:
        return PaginatedResponse(**cached_result)
    
    total = db.query(User).count()
    users = db.query(User).offset(pagination.skip).limit(pagination.size).all()
    
    result = PaginatedResponse.create(users, total, pagination)
    
    # 缓存结果，但设置较短的过期时间
    await RedisService.cache_api_response(cache_key, result.dict(), expire=60)  # 1分钟缓存
    
    return result


@router.get("/users/{user_id}", response_model=UserResponse, tags=["User Management"])
async def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """获取指定用户（需要超级用户权限）"""
    # 尝试从缓存获取用户数据
    cached_data = await RedisService.get_cached_user_data(user_id)
    if cached_data:
        return UserResponse(**cached_data)
    
    user = UserService.get_user_by_id(db, user_id)
    if not user:
        raise NotFoundException("User not found")
    
    # 缓存用户数据
    user_dict = {column.name: getattr(user, column.name) for column in user.__table__.columns}
    await RedisService.cache_user_data(user_id, user_dict)
    
    return user


@router.put("/users/{user_id}", response_model=UserResponse, tags=["User Management"])
async def update_user(
    user_id: int,
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """更新用户信息（需要超级用户权限）"""
    user = UserService.get_user_by_id(db, user_id)
    if not user:
        raise NotFoundException("User not found")
    
    try:
        # 使用用户服务层更新用户信息
        updated_user = UserService.update_user(db, user, user_update, current_user)
        
        logger.info(f"User updated by admin: id={updated_user.id}, username={updated_user.username}")
        return updated_user
    except ValidationException:
        raise
    except Exception as e:
        logger.error(f"User update error: {e}")
        raise ValidationException("User update failed")


@router.delete("/users/{user_id}", tags=["User Management"])
async def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """删除用户（需要超级用户权限）"""
    user = UserService.get_user_by_id(db, user_id)
    if not user:
        raise NotFoundException("User not found")
    
    try:
        # 使用用户服务层删除用户
        UserService.delete_user(db, user)
        
        # 同时清除用户列表的缓存
        await RedisService.delete_cache(f"admin:users:*")
        
        logger.info(f"User deleted: id={user.id}, username={user.username}")
        return {"message": "User deleted successfully"}
    except Exception as e:
        logger.error(f"User deletion error: {e}")
        raise ValidationException("User deletion failed")


@router.put("/users/{user_id}/status", tags=["User Management"])
async def update_user_status(
    user_id: int,
    is_active: bool,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """更新用户状态（需要超级用户权限）"""
    user = UserService.get_user_by_id(db, user_id)
    if not user:
        raise NotFoundException("User not found")
    
    try:
        # 使用用户服务层更新用户状态
        updated_user = UserService.update_user_status(db, user, is_active)
        
        # 同时清除用户列表的缓存
        await RedisService.delete_cache(f"admin:users:*")
        
        status_text = "activated" if is_active else "deactivated"
        logger.info(f"Admin {current_user.username} {status_text} user {updated_user.username}")
        return {"message": f"User {status_text} successfully"}
    except Exception as e:
        logger.error(f"User status update error: {e}")
        raise ValidationException("User status update failed")


@router.get("/users/stats", tags=["User Management"])
async def get_user_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """获取用户统计（需要超级用户权限）"""
    # 尝试从缓存获取统计信息
    cache_key = "admin:user_stats"
    cached_stats = await RedisService.get_cached_api_response(cache_key)
    if cached_stats is not None:
        return cached_stats
    
    stats = StatsService.get_user_stats(db)
    
    # 缓存统计信息，但设置较短的过期时间
    await RedisService.cache_api_response(cache_key, stats, expire=300)  # 5分钟缓存
    
    return stats