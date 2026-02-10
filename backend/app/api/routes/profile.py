"""客户端个人资料API路由 - 用户业务功能，无需管理员权限"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse, UserUpdate, UserPasswordUpdate
from app.schemas.common import StatusResponse
from app.core.security import get_current_active_user, decode_token
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.exceptions import ValidationException
from app.core.logging import get_logger
from app.services.redis_service import RedisService
from app.services.user_service import UserService
from app.services.storage_service import StorageService
from fastapi import File, UploadFile

router = APIRouter()
logger = get_logger(__name__)

@router.post("/avatar", response_model=UserResponse, tags=["用户资料"])
async def upload_avatar(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """上传并更新用户头像（存储到数据库）"""
    try:
        # 文件大小验证
        from app.core.config import settings
        file_content = await file.read()
        file_size = len(file_content)
        
        if file_size > settings.MAX_FILE_SIZE:
            raise ValidationException(f"File too large. Maximum size is {settings.MAX_FILE_SIZE // (1024*1024)}MB")
        
        # 重新创建文件对象
        from io import BytesIO
        file.file = BytesIO(file_content)
        
        # 保存头像到数据库
        avatar_data, filename, mimetype = await StorageService.save_avatar_to_db(file, current_user.id, db)
        
        # 更新数据库
        current_user.avatar_data = avatar_data
        current_user.avatar_filename = filename
        current_user.avatar_mimetype = mimetype
        
        db.add(current_user)
        db.commit()
        db.refresh(current_user)
        
        # 更新缓存 (使用 Schema 生成字典以确保字段完整)
        profile_data = UserResponse.model_validate(current_user).model_dump()
        # 处理 datetime 对象序列化
        profile_data['created_at'] = profile_data['created_at'].isoformat() if profile_data.get('created_at') else None
        profile_data['updated_at'] = profile_data['updated_at'].isoformat() if profile_data.get('updated_at') else None
        profile_data['last_active'] = profile_data['last_active'].isoformat() if profile_data.get('last_active') else None
        
        await RedisService.cache_user_data(current_user.id, profile_data)
        
        return current_user
    except Exception as e:
        logger.error(f"Avatar upload error: {e}")
        raise ValidationException("Avatar upload failed")

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


@router.get("/", response_model=UserResponse, tags=["用户资料"])
async def get_user_profile(
    current_user: User = Depends(get_current_active_user)
):
    """获取用户详细资料"""
    # 尝试从缓存获取用户数据
    cached_data = await RedisService.get_cached_user_data(current_user.id)
    if cached_data:
        return UserResponse(**cached_data)
    
    # 如果缓存不存在，构建并缓存用户资料
    profile_data = UserResponse.model_validate(current_user).model_dump()
    # 处理 datetime 对象序列化
    profile_data['created_at'] = profile_data['created_at'].isoformat() if profile_data.get('created_at') else None
    profile_data['updated_at'] = profile_data['updated_at'].isoformat() if profile_data.get('updated_at') else None
    profile_data['last_active'] = profile_data['last_active'].isoformat() if profile_data.get('last_active') else None
    
    # 缓存用户资料
    await RedisService.cache_user_data(current_user.id, profile_data)
    
    return current_user


@router.put("/", response_model=UserResponse, tags=["用户资料"])
async def update_user_profile(
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户详细资料"""
    try:
        # 使用用户服务层更新用户信息
        updated_user = UserService.update_user(db, current_user, user_update)
        
        logger.info(f"User profile updated: id={updated_user.id}, username={updated_user.username}")
        
        # 返回更新后的用户资料
        profile_data = UserResponse.model_validate(updated_user).model_dump()
        # 处理 datetime 对象序列化
        profile_data['created_at'] = profile_data['created_at'].isoformat() if profile_data.get('created_at') else None
        profile_data['updated_at'] = profile_data['updated_at'].isoformat() if profile_data.get('updated_at') else None
        profile_data['last_active'] = profile_data['last_active'].isoformat() if profile_data.get('last_active') else None
        
        # 重新缓存用户资料
        await RedisService.cache_user_data(updated_user.id, profile_data)
        
        return updated_user
    except ValidationException:
        raise
    except Exception as e:
        logger.error(f"Profile update error: {e}")
        raise ValidationException("Profile update failed")





@router.put("/password", response_model=StatusResponse, tags=["用户资料"])
async def update_password(
    password_update: UserPasswordUpdate,
    db: Session = Depends(get_db),
    db_credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer()),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户密码"""
    try:
        UserService.update_password(db, current_user, password_update)
        # 确保缓存失效
        await RedisService.invalidate_user_cache(current_user.id)

        # 将当前 access token 加入黑名单，强制当前会话登出
        try:
            token = db_credentials.credentials
            payload = decode_token(token)
            if payload and "exp" in payload:
                import time
                current_time = int(time.time())
                remaining = max(0, int(payload["exp"]) - current_time)
                await RedisService.add_token_to_blacklist(token, remaining)
        except Exception:
            # 不要因为黑名单失败而阻止密码更新
            logger.warning("Failed to blacklist current token after password change")

        return {"message": "Password updated"}
    except ValidationException:
        raise
    except Exception as e:
        logger.error(f"Password update error: {e}")
        raise ValidationException("Password update failed")


@router.get("/avatar/{user_id}", tags=["用户资料"])
async def get_user_avatar(
    user_id: int,
    db: Session = Depends(get_db)
):
    """获取用户头像（从数据库提供）"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.avatar_data:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Avatar not found")
    
    from fastapi.responses import Response
    return Response(
        content=user.avatar_data,
        media_type=user.avatar_mimetype or "image/jpeg",
        headers={"Cache-Control": "public, max-age=3600"}  # 缓存1小时
    )
