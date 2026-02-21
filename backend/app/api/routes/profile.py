"""客户端个人资料API路由 - 用户业务功能，无需管理员权限

包含：
1. 用户基本信息管理
2. 头像上传
3. 时区设置
"""

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse, UserUpdate, UserPasswordUpdate, TimezoneUpdate
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
    """上传并更新用户头像（存储到数据库）- 优化版本"""
    try:
        # 文件大小验证
        from app.core.config import settings
        file_content = await file.read()
        file_size = len(file_content)

        if file_size > settings.MAX_FILE_SIZE:
            raise ValidationException(f"文件过大，最大支持 {settings.MAX_FILE_SIZE // (1024*1024)}MB")

        # 验证文件类型
        if not file.content_type or not file.content_type.startswith('image/'):
            raise ValidationException("请上传图片文件")

        # 重新创建文件对象用于后续处理
        from io import BytesIO
        file.file = BytesIO(file_content)

        # 使用优化后的存储服务处理头像
        user_id = getattr(current_user, 'id', None)
        if not user_id:
            raise ValidationException("用户ID获取失败")

        avatar_data = await StorageService.save_avatar(file)

        # 更新数据库
        current_user.avatar_data = avatar_data
        current_user.increment_avatar_version()  # 增加版本号，使缓存失效

        db.add(current_user)
        try:
            db.commit()
            db.refresh(current_user)
        except Exception:
            db.rollback()
            raise

        # 更新缓存 (使用 Schema 生成字典以确保字段完整)
        profile_data = UserResponse.model_validate(current_user).model_dump()
        # 处理 datetime 对象序列化
        profile_data['created_at'] = profile_data['created_at'].isoformat() if profile_data.get('created_at') else None
        profile_data['updated_at'] = profile_data['updated_at'].isoformat() if profile_data.get('updated_at') else None
        profile_data['last_active'] = profile_data['last_active'].isoformat() if profile_data.get('last_active') else None

        await RedisService.cache_user_data(user_id, profile_data)

        logger.info(f"用户头像上传成功: user_id={current_user.id}, bipupu_id={current_user.bipupu_id}, size={len(avatar_data)}bytes")
        return current_user

    except ValidationException:
        raise
    except Exception as e:
        logger.error(f"头像上传失败: {e}")
        db.rollback()
        raise ValidationException("头像上传失败，请检查图片格式")

@router.get("/me", response_model=UserResponse, tags=["用户资料"])
async def get_current_user_info(
    current_user: User = Depends(get_current_active_user)
):
    """获取当前用户信息"""
    user_id = getattr(current_user, 'id', None)
    if not user_id:
        return current_user

    # 尝试从缓存获取用户数据
    cached_data = await RedisService.get_cached_user_data(user_id)
    if cached_data:
        return UserResponse(**cached_data)

    # 如果缓存不存在，返回当前用户对象
    return current_user


@router.get("/", response_model=UserResponse, tags=["用户资料"])
async def get_user_profile(
    current_user: User = Depends(get_current_active_user)
):
    """获取用户详细资料"""
    user_id = getattr(current_user, 'id', None)
    if not user_id:
        return current_user

    # 尝试从缓存获取用户数据
    cached_data = await RedisService.get_cached_user_data(user_id)
    if cached_data:
        return UserResponse(**cached_data)

    # 如果缓存不存在，构建并缓存用户资料
    profile_data = UserResponse.model_validate(current_user).model_dump()
    # 处理 datetime 对象序列化
    profile_data['created_at'] = profile_data['created_at'].isoformat() if profile_data.get('created_at') else None
    profile_data['updated_at'] = profile_data['updated_at'].isoformat() if profile_data.get('updated_at') else None
    profile_data['last_active'] = profile_data['last_active'].isoformat() if profile_data.get('last_active') else None

    # 缓存用户资料
    await RedisService.cache_user_data(user_id, profile_data)

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

        user_id = getattr(updated_user, 'id', None)
        if user_id:
            logger.info(f"用户资料更新成功: id={user_id}, username={updated_user.username}")

            # 返回更新后的用户资料
            profile_data = UserResponse.model_validate(updated_user).model_dump()
            # 处理 datetime 对象序列化
            profile_data['created_at'] = profile_data['created_at'].isoformat() if profile_data.get('created_at') else None
            profile_data['updated_at'] = profile_data['updated_at'].isoformat() if profile_data.get('updated_at') else None
            profile_data['last_active'] = profile_data['last_active'].isoformat() if profile_data.get('last_active') else None

            # 重新缓存用户资料
            await RedisService.cache_user_data(user_id, profile_data)

        return updated_user
    except ValidationException:
        raise
    except Exception as e:
        logger.error(f"用户资料更新失败: {e}")
        raise ValidationException("用户资料更新失败")





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
        user_id = getattr(current_user, 'id', None)
        if user_id:
            await RedisService.invalidate_user_cache(user_id)

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
            logger.warning("密码更新后无法将当前token加入黑名单")

        return {"message": "密码已更新"}
    except ValidationException:
        raise
    except Exception as e:
        logger.error(f"密码更新失败: {e}")
        raise ValidationException("密码更新失败")





@router.put("/timezone", response_model=UserResponse, tags=["用户资料"])
async def update_timezone(
    timezone_update: TimezoneUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户时区设置"""
    try:
        # 验证时区是否有效
        import pytz
        try:
            pytz.timezone(timezone_update.timezone)
            current_user.timezone = timezone_update.timezone
        except pytz.exceptions.UnknownTimeZoneError:
            raise ValidationException("无效的时区标识符")

        db.add(current_user)
        try:
            db.commit()
            db.refresh(current_user)
        except Exception:
            db.rollback()
            raise

        logger.info(f"用户时区更新: user_id={current_user.id}, timezone={current_user.timezone}")

        # 更新缓存
        user_id = getattr(current_user, 'id', None)
        if user_id:
            profile_data = UserResponse.model_validate(current_user).model_dump()
            profile_data['created_at'] = profile_data['created_at'].isoformat() if profile_data.get('created_at') else None
            profile_data['updated_at'] = profile_data['updated_at'].isoformat() if profile_data.get('updated_at') else None
            profile_data['last_active'] = profile_data['last_active'].isoformat() if profile_data.get('last_active') else None
            await RedisService.cache_user_data(user_id, profile_data)

        return current_user

    except ValidationException:
        raise
    except Exception as e:
        logger.error(f"时区更新失败: {e}")
        raise ValidationException("时区更新失败")


@router.get("/push-settings", response_model=dict, tags=["用户资料"])
async def get_push_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取用户推送设置信息"""
    try:
        from app.tasks.subscriptions import get_push_schedule_stats

        # 获取用户的基本推送设置
        user_settings = {
            "timezone": current_user.timezone,
            "subscriptions": []
        }

        # 获取用户的订阅设置
        from app.models.service_account import subscription_table
        from sqlalchemy import select

        stmt = select(
            subscription_table.c.service_account_id,
            subscription_table.c.push_time,
            subscription_table.c.is_enabled
        ).where(subscription_table.c.user_id == current_user.id)

        subscription_settings = db.execute(stmt).all()

        for setting in subscription_settings:
            service = db.query(ServiceAccount).filter(
                ServiceAccount.id == setting.service_account_id
            ).first()

            if service:
                push_time_str = None
                if setting.push_time:
                    push_time_str = setting.push_time.strftime("%H:%M")

                user_settings["subscriptions"].append({
                    "service_name": service.name,
                    "service_description": service.description,
                    "push_time": push_time_str,
                    "is_enabled": setting.is_enabled
                })

        return user_settings

    except Exception as e:
        logger.error(f"获取推送设置失败: {e}")
        raise ValidationException("获取推送设置失败")


@router.get("/avatar/{bipupu_id}", tags=["用户资料"])
async def get_user_avatar(
    request: Request,
    bipupu_id: str,
    db: Session = Depends(get_db)
):
    """获取用户头像（通过用户业务 ID bipupu_id 提供）- 优化版本"""
    from fastapi import HTTPException
    from fastapi.responses import Response
    from app.services.storage_service import StorageService
    from app.services.redis_service import RedisService

    # 尝试从缓存获取头像
    cache_key = StorageService.get_avatar_cache_key(bipupu_id)
    cached_avatar = await RedisService.get_cache(cache_key)

    user = db.query(User).filter(User.bipupu_id == bipupu_id).first()
    if not user or not user.avatar_data:
        # 根据用户反馈：前端有自动处理无头像并使用首字母显示的方案
        # 没有头像没有关系，无需处理默认头像配置
        raise HTTPException(status_code=404, detail="头像未找到")

    # 生成ETag - 使用版本号和时间戳
    version = user.avatar_version or 0
    updated_at_timestamp = user.updated_at.timestamp() if user.updated_at else 0
    etag_input = f"{version}:{updated_at_timestamp}".encode()
    # avatar_data已经是bytes类型，直接使用
    etag = StorageService.get_avatar_etag(user.avatar_data, etag_input)

    # 检查ETag匹配
    if request and request.headers.get("if-none-match") == etag:
        return Response(status_code=304)

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
                    "ETag": etag,
                    "Content-Disposition": f"inline; filename=avatar_{bipupu_id}.jpg"
                }
            )

    # 缓存头像数据（或更新缓存）
    await RedisService.set_cache(cache_key, user.avatar_data, expire=86400)  # 缓存1天

    return Response(
        content=user.avatar_data,
        media_type="image/jpeg",  # 统一使用JPEG格式，与上传处理保持一致
        headers={
            "Cache-Control": "public, max-age=86400",  # 缓存1天
            "ETag": etag,
            "Content-Disposition": f"inline; filename=avatar_{bipupu_id}.jpg"  # 添加文件名
        }
    )
