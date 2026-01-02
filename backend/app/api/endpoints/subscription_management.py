"""订阅管理端点"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional, Dict, Any
from datetime import datetime

from app.db.database import get_db
from app.models.user import User
from app.models.subscription import SubscriptionType, UserSubscription
from app.schemas.user_settings import SubscriptionSettings
from app.schemas.subscription import (
    SubscriptionTypeResponse, UserSubscriptionResponse,
    SubscriptionTypeCreate, SubscriptionTypeUpdate
)
from app.schemas.common import PaginatedResponse
from app.core.security import get_current_active_user
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger
import math

router = APIRouter()
logger = get_logger(__name__)


@router.get("/subscription-types", response_model=PaginatedResponse[SubscriptionTypeResponse])
async def get_subscription_types(
    page: int = 1,
    size: int = 20,
    category: Optional[str] = None,
    is_active: Optional[bool] = True,
    db: Session = Depends(get_db)
):
    """获取订阅类型列表"""
    skip = (page - 1) * size
    query = db.query(SubscriptionType)
    
    if category:
        query = query.filter(SubscriptionType.category == category)
    if is_active is not None:
        query = query.filter(SubscriptionType.is_active == is_active)
    
    total = query.count()
    subscription_types = query.offset(skip).limit(size).all()
    pages = math.ceil(total / size) if size > 0 else 0
    
    return {
        "items": subscription_types,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    }


@router.get("/subscription-types/{subscription_type_id}", response_model=SubscriptionTypeResponse)
async def get_subscription_type(
    subscription_type_id: int,
    db: Session = Depends(get_db)
):
    """获取订阅类型详情"""
    subscription_type = db.query(SubscriptionType).filter(
        SubscriptionType.id == subscription_type_id
    ).first()
    
    if not subscription_type:
        raise NotFoundException("订阅类型不存在")
    
    return subscription_type


@router.post("/subscription-types", response_model=SubscriptionTypeResponse)
async def create_subscription_type(
    subscription_type_in: SubscriptionTypeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """创建订阅类型（管理员功能）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="需要管理员权限")
    
    # 检查名称是否已存在
    existing = db.query(SubscriptionType).filter(
        SubscriptionType.name == subscription_type_in.name
    ).first()
    
    if existing:
        raise ValidationException("订阅类型名称已存在")
    
    subscription_type = SubscriptionType(
        name=subscription_type_in.name,
        description=subscription_type_in.description,
        category=subscription_type_in.category,
        is_active=subscription_type_in.is_active,
        default_settings=subscription_type_in.default_settings or {}
    )
    
    db.add(subscription_type)
    db.commit()
    db.refresh(subscription_type)
    
    logger.info(f"订阅类型创建: {current_user.username} 创建 {name}")
    return subscription_type


@router.put("/subscription-types/{subscription_type_id}")
async def update_subscription_type(
    subscription_type_id: int,
    name: Optional[str] = None,
    description: Optional[str] = None,
    category: Optional[str] = None,
    is_active: Optional[bool] = None,
    default_settings: Optional[Dict[str, Any]] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新订阅类型（管理员功能）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="需要管理员权限")
    
    subscription_type = db.query(SubscriptionType).filter(
        SubscriptionType.id == subscription_type_id
    ).first()
    
    if not subscription_type:
        raise NotFoundException("订阅类型不存在")
    
    # 更新字段
    if name is not None:
        # 检查名称是否已存在
        existing = db.query(SubscriptionType).filter(
            SubscriptionType.name == name,
            SubscriptionType.id != subscription_type_id
        ).first()
        
        if existing:
            raise ValidationException("订阅类型名称已存在")
        
        subscription_type.name = name
    
    if description is not None:
        subscription_type.description = description
    if category is not None:
        subscription_type.category = category
    if is_active is not None:
        subscription_type.is_active = is_active
    if default_settings is not None:
        subscription_type.default_settings = default_settings
    
    subscription_type.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(subscription_type)
    
    logger.info(f"订阅类型更新: {current_user.username} 更新 {subscription_type.name}")
    return subscription_type


@router.delete("/subscription-types/{subscription_type_id}")
async def delete_subscription_type(
    subscription_type_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除订阅类型（管理员功能）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="需要管理员权限")
    
    subscription_type = db.query(SubscriptionType).filter(
        SubscriptionType.id == subscription_type_id
    ).first()
    
    if not subscription_type:
        raise NotFoundException("订阅类型不存在")
    
    # 检查是否有用户订阅
    subscription_count = db.query(UserSubscription).filter(
        UserSubscription.subscription_type_id == subscription_type_id
    ).count()
    
    if subscription_count > 0:
        raise ValidationException("该订阅类型已有用户订阅，无法删除")
    
    db.delete(subscription_type)
    db.commit()
    
    logger.info(f"订阅类型删除: {current_user.username} 删除 {subscription_type.name}")
    return {"message": "订阅类型已删除"}


# 用户订阅管理
@router.get("/user-subscriptions", response_model=PaginatedResponse[dict])
async def get_user_subscriptions(
    page: int = 1,
    size: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取当前用户的订阅"""
    user_subscriptions = db.query(UserSubscription).filter(
        UserSubscription.user_id == current_user.id
    ).all()
    
    # 获取所有可用的订阅类型
    available_types = db.query(SubscriptionType).filter(
        SubscriptionType.is_active == True
    ).all()
    
    # 构建响应数据
    result = []
    for sub_type in available_types:
        user_sub = next(
            (us for us in user_subscriptions if us.subscription_type_id == sub_type.id),
            None
        )
        
        if user_sub:
            result.append({
                "subscription_type": sub_type,
                "user_subscription": user_sub,
                "is_subscribed": True
            })
        else:
            # 创建默认的用户订阅记录
            default_sub = UserSubscription(
                user_id=current_user.id,
                subscription_type_id=sub_type.id,
                is_enabled=True,
                custom_settings=sub_type.default_settings or {},
                notification_time_start="09:00",
                notification_time_end="22:00",
                timezone="Asia/Shanghai"
            )
            db.add(default_sub)
            result.append({
                "subscription_type": sub_type,
                "user_subscription": default_sub,
                "is_subscribed": True
            })
    
    db.commit()
    
    # 手动分页
    total = len(result)
    start = (page - 1) * size
    end = start + size
    items = result[start:end]
    pages = math.ceil(total / size) if size > 0 else 0
    
    return {
        "items": items,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    }


@router.put("/user-subscriptions/{subscription_type_id}")
async def update_user_subscription(
    subscription_type_id: int,
    is_enabled: bool,
    notification_time_start: Optional[str] = None,
    notification_time_end: Optional[str] = None,
    timezone: Optional[str] = None,
    custom_settings: Optional[Dict[str, Any]] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户订阅设置"""
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
        user_subscription = UserSubscription(
            user_id=current_user.id,
            subscription_type_id=subscription_type_id,
            is_enabled=is_enabled,
            custom_settings=custom_settings or subscription_type.default_settings or {},
            notification_time_start=notification_time_start or "09:00",
            notification_time_end=notification_time_end or "22:00",
            timezone=timezone or "Asia/Shanghai"
        )
        db.add(user_subscription)
    else:
        # 更新现有订阅
        user_subscription.is_enabled = is_enabled
        if notification_time_start is not None:
            user_subscription.notification_time_start = notification_time_start
        if notification_time_end is not None:
            user_subscription.notification_time_end = notification_time_end
        if timezone is not None:
            user_subscription.timezone = timezone
        if custom_settings is not None:
            user_subscription.custom_settings = custom_settings
    
    user_subscription.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(user_subscription)
    
    logger.info(f"用户订阅更新: {current_user.username} 更新订阅类型 {subscription_type_id}")
    return user_subscription


@router.delete("/user-subscriptions/{subscription_type_id}")
async def unsubscribe(
    subscription_type_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """取消订阅"""
    user_subscription = db.query(UserSubscription).filter(
        UserSubscription.user_id == current_user.id,
        UserSubscription.subscription_type_id == subscription_type_id
    ).first()
    
    if not user_subscription:
        raise NotFoundException("未找到订阅记录")
    
    # 软删除，只禁用不删除记录
    user_subscription.is_enabled = False
    user_subscription.updated_at = datetime.utcnow()
    db.commit()
    
    logger.info(f"用户取消订阅: {current_user.username} 取消订阅类型 {subscription_type_id}")
    return {"message": "已取消订阅"}


# 订阅统计
@router.get("/subscription-stats")
async def get_subscription_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取订阅统计"""
    total_subscriptions = db.query(UserSubscription).filter(
        UserSubscription.user_id == current_user.id
    ).count()
    
    enabled_subscriptions = db.query(UserSubscription).filter(
        UserSubscription.user_id == current_user.id,
        UserSubscription.is_enabled == True
    ).count()
    
    # 按分类统计
    category_stats = {}
    user_subs = db.query(UserSubscription).join(
        SubscriptionType,
        UserSubscription.subscription_type_id == SubscriptionType.id
    ).filter(
        UserSubscription.user_id == current_user.id,
        UserSubscription.is_enabled == True
    ).all()
    
    for sub in user_subs:
        category = sub.subscription_type.category
        category_stats[category] = category_stats.get(category, 0) + 1
    
    return {
        "total_subscriptions": total_subscriptions,
        "enabled_subscriptions": enabled_subscriptions,
        "category_stats": category_stats
    }


# 宇宙传讯订阅特殊接口
@router.get("/cosmic-messaging/status")
async def get_cosmic_messaging_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取宇宙传讯订阅状态"""
    cosmic_subscription = db.query(UserSubscription).join(
        SubscriptionType,
        UserSubscription.subscription_type_id == SubscriptionType.id
    ).filter(
        UserSubscription.user_id == current_user.id,
        SubscriptionType.category == "cosmic_messaging"
    ).first()
    
    if not cosmic_subscription:
        return {
            "is_enabled": False,
            "notification_time_start": "09:00",
            "notification_time_end": "22:00",
            "timezone": "Asia/Shanghai",
            "custom_settings": {}
        }
    
    return {
        "is_enabled": cosmic_subscription.is_enabled,
        "notification_time_start": cosmic_subscription.notification_time_start,
        "notification_time_end": cosmic_subscription.notification_time_end,
        "timezone": cosmic_subscription.timezone,
        "custom_settings": cosmic_subscription.custom_settings
    }


@router.put("/cosmic-messaging/settings")
async def update_cosmic_messaging_settings(
    is_enabled: bool,
    notification_time_start: Optional[str] = None,
    notification_time_end: Optional[str] = None,
    timezone: Optional[str] = None,
    custom_settings: Optional[Dict[str, Any]] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新宇宙传讯设置"""
    # 查找宇宙传讯订阅类型
    cosmic_type = db.query(SubscriptionType).filter(
        SubscriptionType.category == "cosmic_messaging",
        SubscriptionType.is_active == True
    ).first()
    
    if not cosmic_type:
        # 如果不存在，创建默认的宇宙传讯订阅类型
        cosmic_type = SubscriptionType(
            name="宇宙传讯",
            description="接收宇宙传讯消息和提醒",
            category="cosmic_messaging",
            is_active=True,
            default_settings={
                "message_types": ["daily_guidance", "cosmic_insights", "energy_updates"],
                "frequency": "daily",
                "priority": "high"
            }
        )
        db.add(cosmic_type)
        db.commit()
        db.refresh(cosmic_type)
    
    # 更新用户订阅
    return await update_user_subscription(
        cosmic_type.id,
        is_enabled,
        notification_time_start,
        notification_time_end,
        timezone,
        custom_settings,
        db,
        current_user
    )