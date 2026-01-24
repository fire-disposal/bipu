"""用户设置管理端点"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import Optional, Dict, Any

from app.db.database import get_db
from app.models.user import User
from app.schemas.user_settings import (
    UserProfileUpdate, UserProfileResponse, UserSettingsUpdate,
    PasswordChange, TermsAcceptance, BlockUserRequest,
    BlockedUserResponse, ExportMessagesRequest,
    ExportMessagesResponse, MessageStatsRequest, MessageStatsResponse,
    PrivacySettings, SubscriptionSettings
)
from app.schemas.common import PaginationParams, PaginatedResponse
from app.core.security import get_current_active_user
from app.services.user_settings_service import UserSettingsService
from app.core.logging import get_logger
from pydantic import BaseModel

router = APIRouter()
logger = get_logger(__name__)

def get_user_settings_service(db: Session = Depends(get_db)) -> UserSettingsService:
    return UserSettingsService(db)


@router.get("/profile", response_model=UserProfileResponse)
async def get_user_profile(
    current_user: User = Depends(get_current_active_user)
):
    """获取用户个人资料"""
    return current_user


@router.put("/profile", response_model=UserProfileResponse)
async def update_user_profile(
    profile_update: UserProfileUpdate,
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户个人资料"""
    updated_user = service.update_profile(current_user, profile_update)
    logger.info(f"用户资料更新: {current_user.username}")
    return updated_user


@router.put("/settings", response_model=UserProfileResponse)
async def update_user_settings(
    settings_update: UserSettingsUpdate,
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户设置"""
    updated_user = service.update_settings(current_user, settings_update)
    logger.info(f"用户设置更新: {current_user.username}")
    return updated_user


class StatusResponse(BaseModel):
    message: str

@router.put("/password", response_model=StatusResponse)
async def change_password(
    password_change: PasswordChange,
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """修改密码"""
    service.change_password(current_user, password_change)
    logger.info(f"用户密码修改: {current_user.username}")
    return {"message": "密码修改成功"}


@router.put("/terms/accept")
async def accept_terms(
    terms_acceptance: TermsAcceptance,
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """接受用户协议"""
    service.accept_terms(current_user, terms_acceptance.accepted)
    logger.info(f"用户协议接受: {current_user.username}")
    return {"message": "用户协议已接受"}


@router.get("/terms/status")
async def get_terms_status(
    current_user: User = Depends(get_current_active_user)
):
    """获取用户协议状态"""
    return {
        "accepted": current_user.terms_accepted,
        "accepted_at": current_user.terms_accepted_at
    }


# 黑名单管理
@router.post("/blocks")
async def block_user(
    block_request: BlockUserRequest,
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """拉黑用户"""
    service.block_user(current_user, block_request)
    logger.info(f"用户拉黑: {current_user.username} 拉黑 {block_request.user_id}")
    return {"message": "用户已拉黑"}


@router.delete("/blocks/{user_id}")
async def unblock_user(
    user_id: int,
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """解除拉黑"""
    service.unblock_user(current_user, user_id)
    logger.info(f"用户解除拉黑: {current_user.username} 解除拉黑用户ID {user_id}")
    return {"message": "已解除拉黑"}


@router.get("/blocks", response_model=PaginatedResponse[BlockedUserResponse])
async def get_blocked_users(
    params: PaginationParams = Depends(),
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取黑名单列表"""
    users, total = service.get_blocked_users(current_user, params)
    
    items = []
    for user in users:
        items.append(BlockedUserResponse(
            id=user.id,
            username=user.username,
            nickname=user.nickname,
            avatar_url=user.avatar_url,
            blocked_at=user.blocked_at
        ))
    
    return PaginatedResponse.create(items, total, params)


# 消息管理
@router.post("/messages/export", response_model=ExportMessagesResponse)
async def export_messages(
    export_request: ExportMessagesRequest,
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """导出消息"""
    result = service.export_messages(current_user, export_request)
    return ExportMessagesResponse(**result)


@router.get("/messages/stats", response_model=MessageStatsResponse)
async def get_message_stats(
    stats_request: MessageStatsRequest = Depends(),
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取消息统计"""
    result = service.get_message_stats(current_user, stats_request)
    return MessageStatsResponse(**result)


# 订阅管理
@router.get("/subscriptions")
async def get_user_subscriptions(
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取用户订阅"""
    subscriptions = service.get_subscriptions(current_user)
    return {
        "items": subscriptions,
        "total": len(subscriptions)
    }


@router.put("/subscriptions/{subscription_type_id}")
async def update_subscription(
    subscription_type_id: int,
    is_enabled: bool,
    custom_settings: Optional[Dict[str, Any]] = None,
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """更新订阅设置"""
    user_subscription = service.update_subscription(
        current_user, subscription_type_id, is_enabled, custom_settings
    )
    logger.info(f"订阅更新: {current_user.username} 订阅类型 {subscription_type_id}")
    return user_subscription


# 隐私设置快捷接口
@router.get("/privacy-settings")
async def get_privacy_settings(
    current_user: User = Depends(get_current_active_user)
):
    """获取隐私设置"""
    return current_user.privacy_settings


@router.put("/privacy-settings")
async def update_privacy_settings(
    privacy_settings: PrivacySettings,
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """更新隐私设置"""
    settings_update = UserSettingsUpdate(privacy_settings=privacy_settings)
    service.update_settings(current_user, settings_update)
    logger.info(f"隐私设置更新: {current_user.username}")
    return current_user.privacy_settings


# 订阅设置快捷接口
@router.get("/subscription-settings")
async def get_subscription_settings(
    current_user: User = Depends(get_current_active_user)
):
    """获取订阅设置"""
    return current_user.subscription_settings


@router.put("/subscription-settings")
async def update_subscription_settings(
    subscription_settings: SubscriptionSettings,
    service: UserSettingsService = Depends(get_user_settings_service),
    current_user: User = Depends(get_current_active_user)
):
    """更新订阅设置"""
    settings_update = UserSettingsUpdate(subscription_settings=subscription_settings)
    service.update_settings(current_user, settings_update)
    logger.info(f"订阅设置更新: {current_user.username}")
    return current_user.subscription_settings