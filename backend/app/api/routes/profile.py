"""客户端个人资料API路由 - 用户业务功能，无需管理员权限

包含：
1. 用户基本信息管理
2. 头像上传
3. 时区设置
"""

from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Request
from sqlalchemy.orm import Session
from datetime import date

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import (
    UserPrivate, UserUpdate, UserPasswordUpdate,
    TimezoneUpdate
)
from app.schemas.common import SuccessResponse
from app.core.security import get_current_active_user, verify_password, get_password_hash
from app.core.exceptions import ValidationException
from app.core.logging import get_logger
from app.services.redis_service import RedisService
from app.services.storage_service import StorageService
from app.services.lunar_service import compute_bazi
from app.core.user_utils import get_western_zodiac
from app.core.config import settings

router = APIRouter()
logger = get_logger(__name__)


@router.post("/avatar", response_model=UserPrivate)
async def upload_avatar(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """上传并更新用户头像"""
    try:
        # 文件大小验证
        file_content = await file.read()
        file_size = len(file_content)

        if file_size > settings.MAX_FILE_SIZE:
            raise ValidationException(f"文件过大，最大支持 {settings.MAX_FILE_SIZE // (1024*1024)}MB")

        # 验证文件类型（宽松检查：Dio 移动端可能上报 application/octet-stream）
        # 实际图片格式由 StorageService.save_avatar_bytes() 通过 PIL image.verify() 验证
        if file.content_type and not file.content_type.startswith('image/') \
                and file.content_type not in ('application/octet-stream', 'binary/octet-stream'):
            raise ValidationException("请上传图片文件（支持JPG、PNG等格式）")

        # 使用存储服务处理头像（直接传入已读取的字节数据，避免重复读取）
        user_id = current_user.id
        if not user_id:
            raise ValidationException("用户ID获取失败")

        try:
            avatar_data = await StorageService.save_avatar_bytes(file_content)
        except ValueError as e:
            raise ValidationException(str(e))
        except Exception as e:
            logger.error(f"头像处理失败: {e}")
            raise ValidationException("头像处理失败，请确保图片格式正确且尺寸合理")

        # 更新数据库
        current_user.avatar_data = avatar_data

        try:
            db.commit()
            db.refresh(current_user)
        except Exception:
            db.rollback()
            raise

        # 更新缓存
        profile_data = UserPrivate.model_validate(current_user).model_dump()
        user_id = int(getattr(current_user, 'id', 0))
        await RedisService.cache_user_data(user_id, profile_data)

        logger.info(f"用户头像上传成功: user_id={current_user.id}, bipupu_id={current_user.bipupu_id}")
        return UserPrivate.model_validate(current_user)

    except ValidationException:
        raise
    except Exception as e:
        logger.error(f"头像上传失败: {e}")
        db.rollback()
        raise ValidationException(f"头像上传失败: {str(e)}")


@router.get("/me", response_model=UserPrivate)
async def get_current_user_info(
    current_user: User = Depends(get_current_active_user)
):
    """获取当前用户信息"""
    return UserPrivate.model_validate(current_user)


@router.get("/", response_model=UserPrivate)
async def get_profile(
    current_user: User = Depends(get_current_active_user)
):
    """获取个人资料（兼容性接口）"""
    return UserPrivate.model_validate(current_user)


@router.put("/", response_model=UserPrivate)
async def update_profile(
    update_data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新个人资料"""
    try:
        # 更新用户信息（exclude_none 防止客户端发来的 null 覆盖数据库现有值）
        update_dict = update_data.model_dump(exclude_unset=True, exclude_none=True)

        for field, value in update_dict.items():
            setattr(current_user, field, value)

        # 当 birthday 或 birth_time 被更新时，自动推导衍生字段
        birthday_changed = "birthday" in update_dict or "birth_time" in update_dict
        if birthday_changed:
            birthday: date | None = getattr(current_user, "birthday", None)
            birth_time: str | None = getattr(current_user, "birth_time", None)

            if birthday:
                # 自动计算生辰八字（客户端未显式传入时）
                if "bazi" not in update_dict:
                    computed_bazi = compute_bazi(str(birthday), birth_time)
                    if computed_bazi:
                        current_user.bazi = computed_bazi
                        logger.debug(f"自动计算八字: {computed_bazi}")

                # 自动计算西方星座（客户端未显式传入时）
                if "zodiac" not in update_dict:
                    zodiac = get_western_zodiac(birthday)
                    if zodiac:
                        current_user.zodiac = zodiac

                # 自动计算年龄（客户端未显式传入时）
                if "age" not in update_dict:
                    today = date.today()
                    current_user.age = (
                        today.year - birthday.year
                        - ((today.month, today.day) < (birthday.month, birthday.day))
                    )

        db.commit()
        db.refresh(current_user)

        # 更新缓存
        profile_data = UserPrivate.model_validate(current_user).model_dump()
        user_id = int(getattr(current_user, 'id', 0))
        await RedisService.cache_user_data(user_id, profile_data)

        logger.info(f"用户资料更新成功: user_id={current_user.id}")
        return UserPrivate.model_validate(current_user)

    except Exception as e:
        db.rollback()
        logger.error(f"更新用户资料失败: {e}")
        raise HTTPException(status_code=500, detail="更新失败")


@router.put("/password", response_model=SuccessResponse)
async def update_password(
    password_data: UserPasswordUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新密码"""
    try:
        # 验证原密码
        if not verify_password(password_data.old_password, str(current_user.hashed_password)):
            raise ValidationException("原密码错误")

        # 更新密码
        current_user.hashed_password = get_password_hash(password_data.new_password)

        db.commit()

        logger.info(f"用户密码更新成功: user_id={current_user.id}")
        return SuccessResponse(message="密码更新成功")

    except ValidationException as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        db.rollback()
        logger.error(f"更新密码失败: {e}")
        raise HTTPException(status_code=500, detail="密码更新失败")


@router.put("/timezone", response_model=SuccessResponse)
async def update_timezone(
    timezone_data: TimezoneUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新时区"""
    try:
        # 更新时区
        current_user.timezone = timezone_data.timezone

        db.commit()

        logger.info(f"用户时区更新成功: user_id={current_user.id}, timezone={timezone_data.timezone}")
        return SuccessResponse(message="时区更新成功")

    except Exception as e:
        db.rollback()
        logger.error(f"更新时区失败: {e}")
        raise HTTPException(status_code=500, detail="时区更新失败")


@router.get("/push-settings", response_model=dict)
async def get_push_settings(
    current_user: User = Depends(get_current_active_user)
):
    """获取推送设置（兼容性接口）"""
    return {"message": "推送设置功能暂未实现"}


@router.get("/avatar/{bipupu_id}")
async def get_user_avatar(
    request: Request,
    bipupu_id: str,
    db: Session = Depends(get_db)
):
    """获取用户头像（公开接口）"""
    from app.api.routes.users import get_user_avatar_by_bipupu_id

    # 重定向到公共接口
    return await get_user_avatar_by_bipupu_id(request=request, bipupu_id=bipupu_id, db=db)
