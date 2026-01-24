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
from app.schemas.common import PaginatedResponse, PaginationParams
from app.core.security import get_current_active_user
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger
import math

router = APIRouter()
logger = get_logger(__name__)


@router.get("/subscription-types", response_model=PaginatedResponse[SubscriptionTypeResponse])
async def get_subscription_types(
    params: PaginationParams = Depends(),
    category: Optional[str] = None,
    is_active: Optional[bool] = True,
    db: Session = Depends(get_db)
):
    """获取订阅类型列表"""
    query = db.query(SubscriptionType)
    
    if category:
        query = query.filter(SubscriptionType.category == category)
    if is_active is not None:
        query = query.filter(SubscriptionType.is_active == is_active)
    
    total = query.count()
    subscription_types = query.offset(params.skip).limit(params.size).all()
    
    return PaginatedResponse.create(subscription_types, total, params)


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
    
    logger.info(f"订阅类型创建: {current_user.username}")
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
    params: PaginationParams = Depends(),
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
    
    # 构建响应数据 - 纯内存组装，不产生数据库副作用
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
            # 创建临时的默认对象，不保存到数据库
            # 注意：这里我们返回一个类似 schema 的结构，而不是 ORM 对象，因为不需要它有 ID
            # 但前端可能期待同样的结构。
            # 为了简单起见，且PaginatedResponse是GenericModel，这里用字典模拟也是可以的，或者构造一个未保存的ORM对象如果Pydantic配置了orm_mode
            
            # 使用 ORM 对象构造，但不要 add 到 session
            default_sub = UserSubscription(
                user_id=current_user.id,
                subscription_type_id=sub_type.id,
                is_enabled=False, # 默认为未启用
                custom_settings=sub_type.default_settings or {},
                notification_time_start="09:00",
                notification_time_end="22:00",
                timezone="Asia/Shanghai"
            )
            result.append({
                "subscription_type": sub_type,
                "user_subscription": default_sub,
                "is_subscribed": False
            })
    
    # 手动分页
    total = len(result)
    items = result[params.skip : params.skip + params.size]
    
    return PaginatedResponse.create(items, total, params)


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