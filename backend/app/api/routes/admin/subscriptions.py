"""管理员订阅API路由 - 订阅管理功能，需要管理员权限"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional, Dict, Any, List
from datetime import datetime
from pydantic import BaseModel

from app.db.database import get_db
from app.models.user import User
from app.models.subscription import SubscriptionType, UserSubscription
from app.schemas.subscription import (
    SubscriptionTypeResponse,
    SubscriptionTypeCreate,
    SubscriptionTypeUpdate,
    UserSubscriptionModelResponse
)
from app.schemas.common import PaginationParams, PaginatedResponse
from app.schemas.user import UserResponse
from app.core.security import get_current_superuser
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


class SubscriptionTypeStatusUpdate(BaseModel):
    """订阅类型状态更新请求"""
    is_active: bool


class SubscriptionCountResponse(BaseModel):
    """订阅人数统计响应"""
    subscription_type_id: int
    subscription_type_name: str
    total_subscribers: int
    active_subscribers: int
    inactive_subscribers: int


class SubscriberItem(BaseModel):
    """订阅者列表项"""
    user: UserResponse
    subscription: UserSubscriptionModelResponse
    subscribed_at: datetime

    class Config:
        from_attributes = True


class SubscriptionTypeDetailResponse(BaseModel):
    """订阅类型详情（包含统计）"""
    id: int
    name: str
    description: Optional[str]
    category: str
    is_active: bool
    default_settings: Dict[str, Any]
    created_at: datetime
    updated_at: Optional[datetime]
    subscriber_count: int
    active_subscriber_count: int

    class Config:
        from_attributes = True


@router.get("/subscription-types", response_model=PaginatedResponse[SubscriptionTypeDetailResponse], tags=["Subscription Management"])
async def get_all_subscription_types(
    params: PaginationParams = Depends(),
    category: Optional[str] = None,
    is_active: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """获取所有订阅列表及其实际状态（管理员）"""
    query = db.query(SubscriptionType)
    
    if category:
        query = query.filter(SubscriptionType.category == category)
    if is_active is not None:
        query = query.filter(SubscriptionType.is_active == is_active)
    
    total = query.count()
    subscription_types = query.offset(params.skip).limit(params.size).all()
    
    # 构建包含统计信息的响应
    result = []
    for sub_type in subscription_types:
        subscriber_count = db.query(UserSubscription).filter(
            UserSubscription.subscription_type_id == sub_type.id
        ).count()
        
        active_subscriber_count = db.query(UserSubscription).filter(
            UserSubscription.subscription_type_id == sub_type.id,
            UserSubscription.is_enabled == True
        ).count()
        
        result.append(SubscriptionTypeDetailResponse(
            **sub_type.__dict__,
            subscriber_count=subscriber_count,
            active_subscriber_count=active_subscriber_count
        ))
    
    return PaginatedResponse.create(result, total, params)


@router.get("/subscription-types/{subscription_type_id}", response_model=SubscriptionTypeDetailResponse, tags=["Subscription Management"])
async def get_subscription_type_detail(
    subscription_type_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """获取订阅类型详情及统计（管理员）"""
    subscription_type = db.query(SubscriptionType).filter(
        SubscriptionType.id == subscription_type_id
    ).first()
    
    if not subscription_type:
        raise NotFoundException("订阅类型不存在")
    
    subscriber_count = db.query(UserSubscription).filter(
        UserSubscription.subscription_type_id == subscription_type_id
    ).count()
    
    active_subscriber_count = db.query(UserSubscription).filter(
        UserSubscription.subscription_type_id == subscription_type_id,
        UserSubscription.is_enabled == True
    ).count()
    
    return SubscriptionTypeDetailResponse(
        **subscription_type.__dict__,
        subscriber_count=subscriber_count,
        active_subscriber_count=active_subscriber_count
    )


@router.post("/subscription-types", response_model=SubscriptionTypeResponse, tags=["Subscription Management"])
async def create_subscription_type(
    subscription_type_in: SubscriptionTypeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """创建新的系统订阅类型（管理员）"""
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
    
    logger.info(f"订阅类型创建: 管理员 {current_user.username} 创建 {subscription_type.name}")
    return subscription_type


@router.put("/subscription-types/{subscription_type_id}", response_model=SubscriptionTypeResponse, tags=["Subscription Management"])
async def update_subscription_type(
    subscription_type_id: int,
    subscription_update: SubscriptionTypeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """更新订阅类型（管理员）"""
    subscription_type = db.query(SubscriptionType).filter(
        SubscriptionType.id == subscription_type_id
    ).first()
    
    if not subscription_type:
        raise NotFoundException("订阅类型不存在")
    
    update_data = subscription_update.dict(exclude_unset=True)
    
    # 如果更新名称，检查是否已存在
    if "name" in update_data and update_data["name"] != subscription_type.name:
        existing = db.query(SubscriptionType).filter(
            SubscriptionType.name == update_data["name"],
            SubscriptionType.id != subscription_type_id
        ).first()
        
        if existing:
            raise ValidationException("订阅类型名称已存在")
    
    # 更新字段
    for key, value in update_data.items():
        setattr(subscription_type, key, value)
    
    subscription_type.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(subscription_type)
    
    logger.info(f"订阅类型更新: 管理员 {current_user.username} 更新 {subscription_type.name}")
    return subscription_type


@router.put("/subscription-types/{subscription_type_id}/status", response_model=SubscriptionTypeResponse, tags=["Subscription Management"])
async def toggle_subscription_type_status(
    subscription_type_id: int,
    status_update: SubscriptionTypeStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """禁用/使能系统订阅（管理员）"""
    subscription_type = db.query(SubscriptionType).filter(
        SubscriptionType.id == subscription_type_id
    ).first()
    
    if not subscription_type:
        raise NotFoundException("订阅类型不存在")
    
    subscription_type.is_active = status_update.is_active
    subscription_type.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(subscription_type)
    
    action = "启用" if status_update.is_active else "禁用"
    logger.info(f"订阅类型{action}: 管理员 {current_user.username} {action} {subscription_type.name}")
    
    return subscription_type


@router.delete("/subscription-types/{subscription_type_id}", tags=["Subscription Management"])
async def delete_subscription_type(
    subscription_type_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """删除订阅类型（管理员）"""
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
        raise ValidationException(f"该订阅类型已有 {subscription_count} 位用户订阅，无法删除")
    
    type_name = subscription_type.name
    db.delete(subscription_type)
    db.commit()
    
    logger.info(f"订阅类型删除: 管理员 {current_user.username} 删除 {type_name}")
    return {"message": "订阅类型已删除"}


@router.get("/subscription-types/{subscription_type_id}/count", response_model=SubscriptionCountResponse, tags=["Subscription Management"])
async def get_subscription_count(
    subscription_type_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """查询某订阅的实际订阅人数（管理员）"""
    subscription_type = db.query(SubscriptionType).filter(
        SubscriptionType.id == subscription_type_id
    ).first()
    
    if not subscription_type:
        raise NotFoundException("订阅类型不存在")
    
    # 统计订阅人数
    total_subscribers = db.query(UserSubscription).filter(
        UserSubscription.subscription_type_id == subscription_type_id
    ).count()
    
    active_subscribers = db.query(UserSubscription).filter(
        UserSubscription.subscription_type_id == subscription_type_id,
        UserSubscription.is_enabled == True
    ).count()
    
    inactive_subscribers = total_subscribers - active_subscribers
    
    return SubscriptionCountResponse(
        subscription_type_id=subscription_type_id,
        subscription_type_name=subscription_type.name,
        total_subscribers=total_subscribers,
        active_subscribers=active_subscribers,
        inactive_subscribers=inactive_subscribers
    )


@router.get("/subscription-types/{subscription_type_id}/subscribers", response_model=PaginatedResponse[SubscriberItem], tags=["Subscription Management"])
async def get_subscription_subscribers(
    subscription_type_id: int,
    params: PaginationParams = Depends(),
    is_enabled: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """查询某订阅的订阅人员列表（分页）（管理员）"""
    # 检查订阅类型是否存在
    subscription_type = db.query(SubscriptionType).filter(
        SubscriptionType.id == subscription_type_id
    ).first()
    
    if not subscription_type:
        raise NotFoundException("订阅类型不存在")
    
    # 构建查询
    query = db.query(UserSubscription, User).join(
        User, UserSubscription.user_id == User.id
    ).filter(
        UserSubscription.subscription_type_id == subscription_type_id
    )
    
    if is_enabled is not None:
        query = query.filter(UserSubscription.is_enabled == is_enabled)
    
    total = query.count()
    results = query.offset(params.skip).limit(params.size).all()
    
    # 构建响应
    items = []
    for user_sub, user in results:
        items.append(SubscriberItem(
            user=user,
            subscription=user_sub,
            subscribed_at=user_sub.created_at
        ))
    
    return PaginatedResponse.create(items, total, params)


@router.get("/stats/overview", tags=["Subscription Management"])
async def get_subscription_overview(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """获取订阅系统概览统计（管理员）"""
    # 订阅类型统计
    total_types = db.query(SubscriptionType).count()
    active_types = db.query(SubscriptionType).filter(SubscriptionType.is_active == True).count()
    inactive_types = total_types - active_types
    
    # 用户订阅统计
    total_subscriptions = db.query(UserSubscription).count()
    active_subscriptions = db.query(UserSubscription).filter(UserSubscription.is_enabled == True).count()
    inactive_subscriptions = total_subscriptions - active_subscriptions
    
    # 按分类统计
    category_stats = db.query(
        SubscriptionType.category,
        func.count(SubscriptionType.id)
    ).group_by(SubscriptionType.category).all()
    
    category_summary = {category: count for category, count in category_stats}
    
    # 热门订阅类型（按订阅人数排序）
    popular_subscriptions = db.query(
        SubscriptionType.id,
        SubscriptionType.name,
        func.count(UserSubscription.id).label("subscriber_count")
    ).outerjoin(
        UserSubscription, SubscriptionType.id == UserSubscription.subscription_type_id
    ).group_by(SubscriptionType.id).order_by(func.count(UserSubscription.id).desc()).limit(5).all()
    
    popular_list = [
        {
            "id": sub_id,
            "name": name,
            "subscriber_count": count
        }
        for sub_id, name, count in popular_subscriptions
    ]
    
    return {
        "subscription_types": {
            "total": total_types,
            "active": active_types,
            "inactive": inactive_types
        },
        "user_subscriptions": {
            "total": total_subscriptions,
            "active": active_subscriptions,
            "inactive": inactive_subscriptions
        },
        "by_category": category_summary,
        "popular_subscriptions": popular_list
    }
