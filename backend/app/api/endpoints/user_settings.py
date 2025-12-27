"""用户设置管理端点"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta

from app.db.database import get_db
from app.models.user import User
from app.models.user_block import UserBlock
from app.models.message_favorite import MessageFavorite
from app.models.message import Message, MessageStatus
from app.models.subscription import SubscriptionType, UserSubscription
from app.schemas.user_settings import (
    UserProfileUpdate, UserProfileResponse, UserSettingsUpdate,
    PasswordChange, TermsAcceptance, BlockUserRequest,
    BlockedUserResponse, UserBlockList, ExportMessagesRequest,
    ExportMessagesResponse, MessageStatsRequest, MessageStatsResponse,
    PrivacySettings, SubscriptionSettings
)
from app.core.security import get_current_active_user, get_password_hash, verify_password
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/profile", response_model=UserProfileResponse)
async def get_user_profile(
    current_user: User = Depends(get_current_active_user)
):
    """获取用户个人资料"""
    return current_user


@router.put("/profile", response_model=UserProfileResponse)
async def update_user_profile(
    profile_update: UserProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户个人资料"""
    update_data = profile_update.dict(exclude_unset=True)
    
    # 更新用户信息
    for key, value in update_data.items():
        setattr(current_user, key, value)
    
    current_user.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(current_user)
    
    logger.info(f"用户资料更新: {current_user.username}")
    return current_user


@router.put("/settings", response_model=UserProfileResponse)
async def update_user_settings(
    settings_update: UserSettingsUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户设置"""
    update_data = settings_update.dict(exclude_unset=True)
    
    # 更新隐私设置
    if "privacy_settings" in update_data:
        current_user.privacy_settings = update_data["privacy_settings"].dict()
    
    # 更新订阅设置
    if "subscription_settings" in update_data:
        current_user.subscription_settings = update_data["subscription_settings"].dict()
    
    current_user.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(current_user)
    
    logger.info(f"用户设置更新: {current_user.username}")
    return current_user


@router.put("/password")
async def change_password(
    password_change: PasswordChange,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """修改密码"""
    # 验证当前密码
    if not verify_password(password_change.current_password, current_user.hashed_password):
        raise ValidationException("当前密码不正确")
    
    # 更新密码
    current_user.hashed_password = get_password_hash(password_change.new_password)
    current_user.updated_at = datetime.utcnow()
    db.commit()
    
    logger.info(f"用户密码修改: {current_user.username}")
    return {"message": "密码修改成功"}


@router.put("/terms/accept")
async def accept_terms(
    terms_acceptance: TermsAcceptance,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """接受用户协议"""
    current_user.terms_accepted = terms_acceptance.accepted
    current_user.terms_accepted_at = datetime.utcnow()
    current_user.updated_at = datetime.utcnow()
    db.commit()
    
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
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """拉黑用户"""
    # 检查是否尝试拉黑自己
    if block_request.user_id == current_user.id:
        raise ValidationException("不能拉黑自己")
    
    # 检查用户是否存在
    target_user = db.query(User).filter(User.id == block_request.user_id).first()
    if not target_user:
        raise NotFoundException("用户不存在")
    
    # 检查是否已经拉黑
    existing_block = db.query(UserBlock).filter(
        UserBlock.blocker_id == current_user.id,
        UserBlock.blocked_id == block_request.user_id
    ).first()
    
    if existing_block:
        raise ValidationException("已经拉黑该用户")
    
    # 创建黑名单记录
    user_block = UserBlock(
        blocker_id=current_user.id,
        blocked_id=block_request.user_id
    )
    db.add(user_block)
    db.commit()
    
    logger.info(f"用户拉黑: {current_user.username} 拉黑 {target_user.username}")
    return {"message": "用户已拉黑"}


@router.delete("/blocks/{user_id}")
async def unblock_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """解除拉黑"""
    user_block = db.query(UserBlock).filter(
        UserBlock.blocker_id == current_user.id,
        UserBlock.blocked_id == user_id
    ).first()
    
    if not user_block:
        raise NotFoundException("未找到拉黑记录")
    
    db.delete(user_block)
    db.commit()
    
    logger.info(f"用户解除拉黑: {current_user.username} 解除拉黑用户ID {user_id}")
    return {"message": "已解除拉黑"}


@router.get("/blocks", response_model=UserBlockList)
async def get_blocked_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取黑名单列表"""
    query = db.query(UserBlock).filter(UserBlock.blocker_id == current_user.id)
    
    total = query.count()
    blocks = query.offset(skip).limit(limit).all()
    
    items = []
    for block in blocks:
        blocked_user = db.query(User).filter(User.id == block.blocked_id).first()
        if blocked_user:
            items.append(BlockedUserResponse(
                id=blocked_user.id,
                username=blocked_user.username,
                nickname=blocked_user.nickname,
                avatar_url=blocked_user.avatar_url,
                blocked_at=block.created_at
            ))
    
    return UserBlockList(
        items=items,
        total=total,
        page=skip // limit + 1,
        size=limit
    )


# 消息管理
@router.post("/messages/export", response_model=ExportMessagesResponse)
async def export_messages(
    export_request: ExportMessagesRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """导出消息"""
    # 构建查询
    query = db.query(Message).filter(
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
    )
    
    # 应用过滤条件
    if export_request.message_type == "sent":
        query = query.filter(Message.sender_id == current_user.id)
    elif export_request.message_type == "received":
        query = query.filter(Message.receiver_id == current_user.id)
    
    if export_request.date_from:
        query = query.filter(Message.created_at >= export_request.date_from)
    if export_request.date_to:
        query = query.filter(Message.created_at <= export_request.date_to)
    
    messages = query.all()
    
    # 这里可以实现实际的文件导出逻辑
    # 现在只是模拟返回一个下载链接
    download_url = f"/api/v1/downloads/messages_export_{current_user.id}_{int(datetime.utcnow().timestamp())}.json"
    
    return ExportMessagesResponse(
        download_url=download_url,
        file_size=len(str([msg.__dict__ for msg in messages])),  # 模拟文件大小
        record_count=len(messages),
        expires_at=datetime.utcnow() + timedelta(hours=24)
    )


@router.get("/messages/stats", response_model=MessageStatsResponse)
async def get_message_stats(
    stats_request: MessageStatsRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取消息统计"""
    # 基础查询
    query = db.query(Message).filter(
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
    )
    
    if stats_request.date_from:
        query = query.filter(Message.created_at >= stats_request.date_from)
    if stats_request.date_to:
        query = query.filter(Message.created_at <= stats_request.date_to)
    
    # 统计信息
    total_sent = query.filter(Message.sender_id == current_user.id).count()
    total_received = query.filter(Message.receiver_id == current_user.id).count()
    
    # 收藏统计
    total_favorites = db.query(MessageFavorite).filter(
        MessageFavorite.user_id == current_user.id
    ).count()
    
    # 按类型统计
    by_type = {}
    for msg_type in ["system", "user", "alert", "notification"]:
        count = query.filter(Message.message_type == msg_type).count()
        by_type[msg_type] = count
    
    # 按日期统计（简化版）
    by_date = {}
    # 这里可以根据 stats_request.group_by 实现更复杂的日期分组
    
    return MessageStatsResponse(
        total_sent=total_sent,
        total_received=total_received,
        total_favorites=total_favorites,
        by_type=by_type,
        by_date=by_date
    )


# 订阅管理
@router.get("/subscriptions")
async def get_user_subscriptions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取用户订阅"""
    subscriptions = db.query(UserSubscription).filter(
        UserSubscription.user_id == current_user.id
    ).all()
    
    return {
        "items": subscriptions,
        "total": len(subscriptions)
    }


@router.put("/subscriptions/{subscription_type_id}")
async def update_subscription(
    subscription_type_id: int,
    is_enabled: bool,
    custom_settings: Optional[Dict[str, Any]] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新订阅设置"""
    # 检查订阅类型是否存在
    subscription_type = db.query(SubscriptionType).filter(
        SubscriptionType.id == subscription_type_id
    ).first()
    
    if not subscription_type:
        raise NotFoundException("订阅类型不存在")
    
    # 查找或创建用户订阅
    user_subscription = db.query(UserSubscription).filter(
        UserSubscription.user_id == current_user.id,
        UserSubscription.subscription_type_id == subscription_type_id
    ).first()
    
    if not user_subscription:
        user_subscription = UserSubscription(
            user_id=current_user.id,
            subscription_type_id=subscription_type_id
        )
        db.add(user_subscription)
    
    # 更新设置
    user_subscription.is_enabled = is_enabled
    if custom_settings:
        user_subscription.custom_settings = custom_settings
    
    db.commit()
    db.refresh(user_subscription)
    
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
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新隐私设置"""
    current_user.privacy_settings = privacy_settings.dict()
    current_user.updated_at = datetime.utcnow()
    db.commit()
    
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
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新订阅设置"""
    current_user.subscription_settings = subscription_settings.dict()
    current_user.updated_at = datetime.utcnow()
    db.commit()
    
    logger.info(f"订阅设置更新: {current_user.username}")
    return current_user.subscription_settings