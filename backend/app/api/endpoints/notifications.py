"""通知管理端点"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime

from app.db.database import get_db
from app.models.notification import Notification, NotificationType, NotificationStatus
from app.models.user import User
from app.models.message import Message
from app.schemas.notification import (
    NotificationCreate, NotificationUpdate, NotificationResponse, 
    NotificationList, NotificationStats, EmailNotification, 
    PushNotification, SMSNotification, WebhookNotification
)
from app.core.security import get_current_active_user, get_current_superuser
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
    """创建通知"""
    # 验证消息是否存在且属于当前用户
    if notification.message_id:
        message = db.query(Message).filter(
            Message.id == notification.message_id,
            Message.user_id == current_user.id
        ).first()
        
        if not message:
            raise ValidationException("Message not found or not owned by user")
    
    # 创建通知
    notification_data = notification.dict()
    notification_data["user_id"] = current_user.id
    
    db_notification = Notification(**notification_data)
    db.add(db_notification)
    db.commit()
    db.refresh(db_notification)
    
    logger.info(f"Notification created: {notification.title} for user {current_user.email}")
    return db_notification


@router.get("/", response_model=NotificationList)
async def get_notifications(
    skip: int = 0,
    limit: int = 100,
    notification_type: Optional[NotificationType] = None,
    status: Optional[NotificationStatus] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取通知列表"""
    query = db.query(Notification).filter(Notification.user_id == current_user.id)
    
    # 应用过滤条件
    if notification_type:
        query = query.filter(Notification.notification_type == notification_type)
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
    """获取通知统计信息"""
    query = db.query(Notification).filter(Notification.user_id == current_user.id)
    
    total = query.count()
    pending = query.filter(Notification.status == NotificationStatus.PENDING).count()
    sent = query.filter(Notification.status == NotificationStatus.SENT).count()
    failed = query.filter(Notification.status == NotificationStatus.FAILED).count()
    cancelled = query.filter(Notification.status == NotificationStatus.CANCELLED).count()
    
    # 按类型统计
    by_type = {}
    for notif_type in NotificationType:
        count = query.filter(Notification.notification_type == notif_type).count()
        by_type[notif_type.value] = count
    
    return NotificationStats(
        total=total,
        pending=pending,
        sent=sent,
        failed=failed,
        cancelled=cancelled,
        by_type=by_type
    )


@router.get("/{notification_id}", response_model=NotificationResponse)
async def get_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取指定通知"""
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
    """更新通知"""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise NotFoundException("Notification not found")
    
    # 已发送的通知不能修改某些字段
    if notification.status == NotificationStatus.SENT:
        restricted_fields = ["notification_type", "target", "scheduled_at"]
        for field in restricted_fields:
            if field in notification_update.dict(exclude_unset=True):
                raise ValidationException(f"Cannot modify {field} for sent notification")
    
    update_data = notification_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(notification, key, value)
    
    db.commit()
    db.refresh(notification)
    
    logger.info(f"Notification updated: {notification.title} by user {current_user.email}")
    return notification


@router.post("/{notification_id}/send")
async def send_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """发送通知"""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise NotFoundException("Notification not found")
    
    if notification.status != NotificationStatus.PENDING:
        raise ValidationException("Notification is not in pending status")
    
    # 这里应该调用实际的通知发送服务
    # 现在只是模拟发送成功
    notification.status = NotificationStatus.SENT
    notification.sent_at = datetime.utcnow()
    notification.result = "Notification sent successfully"
    
    db.commit()
    
    logger.info(f"Notification sent: {notification.title} to {notification.target}")
    return {"message": "Notification sent successfully"}


@router.post("/{notification_id}/cancel")
async def cancel_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """取消通知"""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise NotFoundException("Notification not found")
    
    if notification.status != NotificationStatus.PENDING:
        raise ValidationException("Only pending notifications can be cancelled")
    
    notification.status = NotificationStatus.CANCELLED
    db.commit()
    
    logger.info(f"Notification cancelled: {notification.title}")
    return {"message": "Notification cancelled successfully"}


@router.delete("/{notification_id}")
async def delete_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除通知"""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise NotFoundException("Notification not found")
    
    db.delete(notification)
    db.commit()
    
    logger.info(f"Notification deleted: {notification.title} by user {current_user.email}")
    return {"message": "Notification deleted successfully"}


# 批量操作端点
@router.post("/batch/send")
async def send_pending_notifications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """批量发送待处理通知（需要超级用户权限）"""
    pending_notifications = db.query(Notification).filter(
        Notification.status == NotificationStatus.PENDING
    ).all()
    
    sent_count = 0
    failed_count = 0
    
    for notification in pending_notifications:
        try:
            # 这里应该调用实际的通知发送服务
            notification.status = NotificationStatus.SENT
            notification.sent_at = datetime.utcnow()
            notification.result = "Notification sent successfully"
            sent_count += 1
        except Exception as e:
            notification.status = NotificationStatus.FAILED
            notification.error_message = str(e)
            notification.retry_count += 1
            failed_count += 1
            logger.error(f"Failed to send notification {notification.id}: {str(e)}")
    
    db.commit()
    
    return {
        "message": f"Batch send completed",
        "sent": sent_count,
        "failed": failed_count
    }


# 特定类型的通知端点
@router.post("/email", response_model=NotificationResponse)
async def create_email_notification(
    email_data: EmailNotification,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """创建邮件通知"""
    notification_data = NotificationCreate(
        title=email_data.subject,
        content=email_data.body,
        notification_type=NotificationType.EMAIL,
        target=email_data.to_email,
        config={"html_body": email_data.html_body} if email_data.html_body else None
    )
    
    return await create_notification(notification_data, db, current_user)


@router.post("/push", response_model=NotificationResponse)
async def create_push_notification(
    push_data: PushNotification,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """创建推送通知"""
    notification_data = NotificationCreate(
        title=push_data.title,
        content=push_data.body,
        notification_type=NotificationType.PUSH,
        target=push_data.device_token,
        config={"data": push_data.data} if push_data.data else None
    )
    
    return await create_notification(notification_data, db, current_user)