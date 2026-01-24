from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import timedelta

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import (
    UserCreate, UserResponse, UserUpdate, UserLogin, Token, TokenRefresh, UserProfile
)
from app.schemas.common import PaginatedResponse, PaginationParams
from app.core.security import (
    get_password_hash, verify_password, create_access_token, create_refresh_token,
    get_current_active_user, get_current_superuser, decode_token
)
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger
from app.models.adminlog import AdminLog
from app.core.config import settings

router = APIRouter()
logger = get_logger(__name__)


def log_admin_action(db: Session, admin_id: int, action: str, details: Optional[dict] = None):
    """记录管理员操作"""
    try:
        record = AdminLog(admin_id=admin_id, action=action, details=details)
        db.add(record)
        db.commit()
        logger.info(f"Admin action logged: admin_id={admin_id}, action={action}")
    except Exception as e:
        db.rollback()
        logger.error(f"Failed to log admin action: {e}")


@router.post("/register", response_model=UserResponse)
async def register_user(
    user: UserCreate,
    db: Session = Depends(get_db)
):
    """用户注册"""
    # 检查用户是否已存在
    db_user = db.query(User).filter(
        (User.email == user.email) | (User.username == user.username)
    ).first()
    if db_user:
        raise ValidationException("Email or username already registered")
    
    # 创建新用户
    user_data = user.dict(exclude={"password"})
    user_data["hashed_password"] = get_password_hash(user.password)
    # 支持nickname字段
    if hasattr(user, "nickname"):
        user_data["nickname"] = user.nickname
    db_user = User(**user_data)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    logger.info(f"User registered: id={db_user.id}, username={db_user.username}")
    return db_user


@router.post("/login", response_model=Token)
async def login(
    user_credentials: UserLogin,
    db: Session = Depends(get_db)
):
    """用户登录"""
    # 查找用户
    user = db.query(User).filter(
        (User.email == user_credentials.username) |
        (User.username == user_credentials.username)
    ).first()
    
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
    
    # 创建访问令牌
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    logger.info(f"User logged in: id={user.id}, username={user.username}")
    
    # 创建刷新令牌
    refresh_token = create_refresh_token(data={"sub": str(user.id)})
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "user": {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "nickname": user.nickname,
            "is_active": user.is_active,
            "is_superuser": user.is_superuser
        }
    }


@router.post("/refresh", response_model=Token)
async def refresh_token(
    token_refresh: TokenRefresh,
    db: Session = Depends(get_db)
):
    """刷新访问令牌"""
    try:
        payload = decode_token(token_refresh.refresh_token)
        if payload is None or payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        user_id: int = int(payload.get("sub"))
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid user",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # 创建新的访问令牌
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(user.id)}, expires_delta=access_token_expires
        )
        
        logger.info(f"Token refreshed for user: id={user.id}, username={user.username}")
        return {
            "access_token": access_token,
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


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_active_user)
):
    """获取当前用户信息"""
    return current_user


@router.put("/me", response_model=UserResponse)
async def update_current_user(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """更新当前用户信息"""
    update_data = user_update.dict(exclude_unset=True)
    # 唯一性校验
    if "email" in update_data:
        exists = db.query(User.id).filter(
            User.email == update_data["email"],
            User.id != current_user.id
        ).first()
        if exists:
            raise ValidationException("Email already registered")
    if "username" in update_data:
        exists = db.query(User.id).filter(
            User.username == update_data["username"],
            User.id != current_user.id
        ).first()
        if exists:
            raise ValidationException("Username already registered")
    
    # 如果更新密码
    if "password" in update_data:
        update_data["hashed_password"] = get_password_hash(update_data["password"])
        del update_data["password"]
    
    # 支持nickname字段
    if "nickname" in update_data:
        current_user.nickname = update_data["nickname"]
        del update_data["nickname"]
    
    for key, value in update_data.items():
        setattr(current_user, key, value)
    
    db.commit()
    db.refresh(current_user)
    
    logger.info(f"User updated: id={current_user.id}, username={current_user.username}")
    return current_user


@router.get("/", response_model=PaginatedResponse[UserResponse])
async def get_users(
    pagination: PaginationParams = Depends(),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """获取用户列表（需要超级用户权限）"""
    total = db.query(User).count()
    users = db.query(User).offset(pagination.skip).limit(pagination.size).all()
    
    return PaginatedResponse.create(users, total, pagination)


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """获取指定用户（需要超级用户权限）"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundException("User not found")
    return user


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """更新用户信息（需要超级用户权限）"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundException("User not found")
    # 唯一性校验
    update_data = user_update.dict(exclude_unset=True)
    if "email" in update_data:
        exists = db.query(User.id).filter(
            User.email == update_data["email"],
            User.id != user.id
        ).first()
        if exists:
            raise ValidationException("Email already registered")
    if "username" in update_data:
        exists = db.query(User.id).filter(
            User.username == update_data["username"],
            User.id != user.id
        ).first()
        if exists:
            raise ValidationException("Username already registered")
    
    # 如果更新密码
    if "password" in update_data:
        update_data["hashed_password"] = get_password_hash(update_data["password"])
        del update_data["password"]
    
    # 支持nickname字段
    if "nickname" in update_data:
        user.nickname = update_data["nickname"]
        del update_data["nickname"]
    
    for key, value in update_data.items():
        setattr(user, key, value)
    
    db.commit()
    db.refresh(user)
    
    logger.info(f"User updated by admin: id={user.id}, username={user.username}")
    
    # 记录管理员操作
    log_admin_action(
        db, 
        current_user.id, 
        "update_user", 
        {"target_user_id": user.id, "updates": str(update_data)}
    )
    
    return user


@router.delete("/{user_id}")
async def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """删除用户（需要超级用户权限）"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundException("User not found")
    
    db.delete(user)
    db.commit()
    
    logger.info(f"User deleted: id={user.id}, username={user.username}")
    
    # 记录管理员操作
    log_admin_action(
        db, 
        current_user.id, 
        "delete_user", 
        {"target_user_id": user_id, "target_username": user.username}
    )
    
    return {"message": "User deleted successfully"}


@router.post("/logout")
async def logout(
    current_user: User = Depends(get_current_active_user)
):
    """用户登出"""
    logger.info(f"User logged out: id={current_user.id}, username={current_user.username}")
    return {"message": "Logged out successfully"}


@router.get("/profile", response_model=UserProfile)
async def get_user_profile(
    current_user: User = Depends(get_current_active_user)
):
    """获取用户详细资料"""
    return {
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


@router.put("/profile", response_model=UserProfile)
async def update_user_profile(
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户详细资料"""
    return await update_current_user(user_update, current_user, db)


@router.put("/online-status")
async def update_online_status(
    is_online: bool,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户在线状态"""
    from datetime import datetime, timezone
    current_user.last_active = datetime.now(timezone.utc)
    db.commit()
    
    status_text = "online" if is_online else "offline"
    logger.info(f"User {current_user.username} is now {status_text}")
    return {"message": f"User is now {status_text}"}


# 管理端API
@router.get("/admin/all", response_model=PaginatedResponse[UserResponse])
async def admin_get_all_users(
    params: PaginationParams = Depends(),
    is_active: Optional[bool] = None,
    is_superuser: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """管理端：获取所有用户（需要超级用户权限）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    query = db.query(User)
    
    if is_active is not None:
        query = query.filter(User.is_active == is_active)
    if is_superuser is not None:
        query = query.filter(User.is_superuser == is_superuser)
    
    total = query.count()
    users = query.offset(params.skip).limit(params.size).all()
    return PaginatedResponse.create(users, total, params)


@router.put("/admin/{user_id}/status")
async def admin_update_user_status(
    user_id: int,
    is_active: bool,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """管理端：更新用户状态（需要超级用户权限）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundException("User not found")
    
    user.is_active = is_active
    db.commit()
    db.refresh(user)
    
    status_text = "activated" if is_active else "deactivated"
    logger.info(f"Admin {current_user.username} {status_text} user {user.username}")
    return {"message": f"User {status_text} successfully"}


@router.get("/admin/stats")
async def admin_get_user_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """管理端：获取用户统计（需要超级用户权限）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    from app.services.stats_service import StatsService
    return StatsService.get_user_stats(db)