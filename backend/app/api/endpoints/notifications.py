"""站内信管理端点"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime

from app.db.database import get_db
from app.models.notification import Notification, NotificationStatus
from app.models.user import User
from app.models.message import Message
from app.schemas.notification import (
    NotificationCreate, NotificationUpdate, NotificationResponse,
    NotificationList, NotificationStats
)
from app.core.security import get_current_active_user
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.post("/", response_model=NotificationResponse)
async def create_notification(
    notification: NotificationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """创建站内信"""
    # 验证消息是否存在且属于当前用户
    if notification.message_id:
        message = db.query(Message).filter(
            Message.id == notification.message_id,
            Message.user_id == current_user.id
        ).first()
        
        if not message:
            raise ValidationException("Message not found or not owned by user")
    
    # 创建站内信
    notification_data = notification.dict()
    notification_data["user_id"] = current_user.id
    
    db_notification = Notification(**notification_data)
    db.add(db_notification)
    db.commit()
    db.refresh(db_notification)
    
    logger.info(f"站内信创建: {notification.title} 用户 {current_user.email}")
    return db_notification


@router.get("/", response_model=NotificationList)
async def get_notifications(
    skip: int = 0,
    limit: int = 100,
    status: Optional[NotificationStatus] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取站内信列表"""
    query = db.query(Notification).filter(Notification.user_id == current_user.id)
    
    # 应用过滤条件
    if status:
        query = query.filter(Notification.status == status)
    
    total = query.count()
    notifications = query.order_by(Notification.created_at.desc()).offset(skip).limit(limit).all()
    
    return NotificationList(
        items=notifications,
        total=total,
        page=skip // limit + 1,
        size=limit
    )


@router.get("/stats", response_model=NotificationStats)
async def get_notification_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取站内信统计信息"""
    query = db.query(Notification).filter(Notification.user_id == current_user.id)
    
    total = query.count()
    unread = query.filter(Notification.status == NotificationStatus.UNREAD).count()
    read = query.filter(Notification.status == NotificationStatus.READ).count()
    deleted = query.filter(Notification.status == NotificationStatus.DELETED).count()
    
    return NotificationStats(
        total=total,
        unread=unread,
        read=read,
        deleted=deleted
    )


@router.get("/{notification_id}", response_model=NotificationResponse)
async def get_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取指定站内信"""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise NotFoundException("Notification not found")
    
    return notification


@router.put("/{notification_id}", response_model=NotificationResponse)
async def update_notification(
    notification_id: int,
    notification_update: NotificationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新站内信"""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise NotFoundException("Notification not found")
    
    update_data = notification_update.dict(exclude_unset=True)
    
    # 如果标记为已读，设置阅读时间
    if "status" in update_data and update_data["status"] == NotificationStatus.READ and notification.status == NotificationStatus.UNREAD:
        update_data["read_at"] = datetime.utcnow()
    
    for key, value in update_data.items():
        setattr(notification, key, value)
    
    db.commit()
    db.refresh(notification)
    
    logger.info(f"站内信更新: {notification.title} 用户 {current_user.email}")
    return notification


@router.put("/{notification_id}/read")
async def mark_notification_as_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """标记站内信为已读"""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise NotFoundException("Notification not found")
    
    if notification.status == NotificationStatus.UNREAD:
        notification.status = NotificationStatus.READ
        notification.read_at = datetime.utcnow()
        db.commit()
        
        logger.info(f"站内信标记为已读: {notification.title}")
    
    return {"message": "Notification marked as read"}


@router.put("/read-all")
async def mark_all_notifications_as_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """标记所有站内信为已读"""
    updated_count = db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.status == NotificationStatus.UNREAD
    ).update({
        "status": NotificationStatus.READ,
        "read_at": datetime.utcnow()
    })
    
    db.commit()
    
    logger.info(f"所有站内信标记为已读 用户 {current_user.email}: {updated_count} 封")
    return {"message": f"{updated_count} notifications marked as read"}


@router.delete("/{notification_id}")
async def delete_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除站内信（软删除）"""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise NotFoundException("Notification not found")
    
    # 软删除，只改变状态
    notification.status = NotificationStatus.DELETED
    db.commit()
    
    logger.info(f"站内信删除: {notification.title} 用户 {current_user.email}")
    return {"message": "Notification deleted successfully"}