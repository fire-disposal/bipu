"""客户端订阅API路由 - 用户订阅管理功能"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import Optional, Dict, Any
from datetime import datetime
from pydantic import BaseModel

from app.db.database import get_db
from app.models.user import User
from app.models.subscription import SubscriptionType, UserSubscription
from app.schemas.subscription import (
    SubscriptionTypeResponse,
    UserSubscriptionModelResponse,
    UserSubscriptionResponse,
    SubscribeRequest,
    SubscribeResponse,
    MySubscriptionItem
)
from app.schemas.common import PaginationParams, PaginatedResponse
from app.core.security import get_current_active_user
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/available", response_model=PaginatedResponse[SubscriptionTypeResponse], tags=["Subscriptions"])
async def get_available_subscriptions(
    params: PaginationParams = Depends(),
    category: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取可用状态下的系统服务订阅列表"""
    query = db.query(SubscriptionType).filter(SubscriptionType.is_active == True)
    
    if category:
        query = query.filter(SubscriptionType.category == category)
    
    total = query.count()
    subscription_types = query.offset(params.skip).limit(params.size).all()
    
    return PaginatedResponse.create(subscription_types, total, params)


@router.get("/my", response_model=PaginatedResponse[MySubscriptionItem], tags=["Subscriptions"])
async def get_my_subscriptions(
    params: PaginationParams = Depends(),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取自身订阅情况"""
    user_subscriptions = db.query(UserSubscription).filter(
        UserSubscription.user_id == current_user.id
    ).all()
    
    available_types = db.query(SubscriptionType).filter(
        SubscriptionType.is_active == True
    ).all()
    
    result = []
    for sub_type in available_types:
        user_sub = next(
            (us for us in user_subscriptions if us.subscription_type_id == sub_type.id),
            None
        )
        
        result.append(MySubscriptionItem(
            subscription_type=sub_type,
            user_subscription=user_sub,
            is_subscribed=user_sub is not None
        ))
    
    total = len(result)
    items = result[params.skip : params.skip + params.size]
    
    return PaginatedResponse.create(items, total, params)


@router.post("/{subscription_type_id}/subscribe", response_model=SubscribeResponse, tags=["Subscriptions"])
async def subscribe_to_service(
    subscription_type_id: int,
    request: SubscribeRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """订阅某个系统服务"""
    # 检查订阅类型是否存在且可用
    subscription_type = db.query(SubscriptionType).filter(
        SubscriptionType.id == subscription_type_id,
        SubscriptionType.is_active == True
    ).first()
    
    if not subscription_type:
        raise NotFoundException("订阅类型不存在或不可用")
    
    # 查找或创建用户订阅
    user_subscription = db.query(UserSubscription).filter(
        UserSubscription.user_id == current_user.id,
        UserSubscription.subscription_type_id == subscription_type_id
    ).first()
    
    if not user_subscription:
        # 创建新订阅
        user_subscription = UserSubscription(
            user_id=current_user.id,
            subscription_type_id=subscription_type_id,
            is_enabled=request.is_enabled,
            custom_settings=request.custom_settings or subscription_type.default_settings or {},
            notification_time_start=request.notification_time_start or "09:00",
            notification_time_end=request.notification_time_end or "22:00",
            timezone=request.timezone or "Asia/Shanghai"
        )
        db.add(user_subscription)
        logger.info(f"用户订阅创建: {current_user.username} 订阅 {subscription_type.name}")
    else:
        # 更新现有订阅
        user_subscription.is_enabled = request.is_enabled
        if request.custom_settings is not None:
            user_subscription.custom_settings = request.custom_settings
        if request.notification_time_start is not None:
            user_subscription.notification_time_start = request.notification_time_start
        if request.notification_time_end is not None:
            user_subscription.notification_time_end = request.notification_time_end
        if request.timezone is not None:
            user_subscription.timezone = request.timezone
        user_subscription.updated_at = datetime.utcnow()
        logger.info(f"用户订阅更新: {current_user.username} 更新订阅 {subscription_type.name}")
    
    db.commit()
    db.refresh(user_subscription)
    
    return SubscribeResponse(
        message="订阅成功",
        subscription=user_subscription
    )


@router.post("/{subscription_type_id}/unsubscribe", response_model=SubscribeResponse, tags=["Subscriptions"])
async def unsubscribe_from_service(
    subscription_type_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """取消订阅某个系统服务"""
    # 查找用户订阅
    user_subscription = db.query(UserSubscription).filter(
        UserSubscription.user_id == current_user.id,
        UserSubscription.subscription_type_id == subscription_type_id
    ).first()
    
    if not user_subscription:
        raise NotFoundException("您未订阅该服务")
    
    # 获取订阅类型名称用于日志
    subscription_type = db.query(SubscriptionType).filter(
        SubscriptionType.id == subscription_type_id
    ).first()
    type_name = subscription_type.name if subscription_type else f"ID:{subscription_type_id}"
    
    # 删除订阅记录
    db.delete(user_subscription)
    db.commit()
    
    logger.info(f"用户取消订阅: {current_user.username} 取消订阅 {type_name}")
    
    return SubscribeResponse(
        message="取消订阅成功",
        subscription=None
    )


@router.put("/{subscription_type_id}/settings", response_model=UserSubscriptionModelResponse, tags=["Subscriptions"])
async def update_subscription_settings(
    subscription_type_id: int,
    is_enabled: Optional[bool] = None,
    custom_settings: Optional[Dict[str, Any]] = None,
    notification_time_start: Optional[str] = None,
    notification_time_end: Optional[str] = None,
    timezone: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新订阅设置"""
    # 查找用户订阅
    user_subscription = db.query(UserSubscription).filter(
        UserSubscription.user_id == current_user.id,
        UserSubscription.subscription_type_id == subscription_type_id
    ).first()
    
    if not user_subscription:
        raise NotFoundException("您未订阅该服务，无法更新设置")
    
    # 更新字段
    if is_enabled is not None:
        user_subscription.is_enabled = is_enabled
    if custom_settings is not None:
        user_subscription.custom_settings = custom_settings
    if notification_time_start is not None:
        user_subscription.notification_time_start = notification_time_start
    if notification_time_end is not None:
        user_subscription.notification_time_end = notification_time_end
    if timezone is not None:
        user_subscription.timezone = timezone
    
    user_subscription.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(user_subscription)
    
    logger.info(f"用户订阅设置更新: {current_user.username} 更新订阅类型 {subscription_type_id}")
    
    return user_subscription
