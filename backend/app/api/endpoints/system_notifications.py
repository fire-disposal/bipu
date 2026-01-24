"""系统通知管理端点 - 使用消息模型实现系统通知功能"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta

from app.db.database import get_db
from app.models.user import User
from app.models.message import Message, MessageType, MessageStatus
from app.schemas.message import (
    MessageCreate, MessageResponse, MessageStats
)
from app.schemas.common import PaginatedResponse, PaginationParams
from app.core.security import get_current_active_user, get_current_superuser
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger
from app.api.endpoints.admin_logs import log_admin_action
import math

router = APIRouter()
logger = get_logger(__name__)


from pydantic import BaseModel

class SystemNotificationCreate(BaseModel):
    title: str
    content: str
    priority: int = 5
    target_users: Optional[List[int]] = None
    pattern: Optional[Dict[str, Any]] = None

@router.post("/", response_model=Dict[str, Any])
async def create_system_notification(
    notification: SystemNotificationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """创建系统通知（管理员功能）"""
    if notification.priority < 0 or notification.priority > 10:
        raise ValidationException("优先级必须在0-10之间")
    
    # 获取目标用户列表
    if notification.target_users:
        users = db.query(User).filter(User.id.in_(notification.target_users)).all()
        if len(users) != len(notification.target_users):
            raise ValidationException("部分目标用户不存在")
    else:
        # 如果没有指定目标用户，则发送给所有活跃用户
        # 警告：用户量大时需优化为分批处理
        users = db.query(User).filter(User.is_active == True).all()
    
    messages_to_create = []
    
    # 为每个目标用户创建系统通知消息
    for user in users:
        try:
            # 创建复合信息模式
            notification_pattern = notification.pattern or {}
            notification_pattern.update({
                "source_type": "system",
                "source_id": current_user.id,
                "notification_type": "system_broadcast",
                "rgb": {
                    "r": 255 if notification.priority >= 7 else 100,
                    "g": 100 if notification.priority >= 7 else 150,
                    "b": 100 if notification.priority >= 7 else 255
                },
                "vibe": {
                    "intensity": min(notification.priority * 10, 80),
                    "duration": 2000
                }
            })
            
            message = Message(
                title=notification.title,
                content=notification.content,
                message_type=MessageType.NOTIFICATION,
                status=MessageStatus.UNREAD,
                priority=notification.priority,
                sender_id=current_user.id,  # 使用当前管理员ID作为发送者
                receiver_id=user.id,
                pattern=notification_pattern
            )
            
            messages_to_create.append(message)
            
        except Exception as e:
            logger.error(f"准备用户 {user.id} 的系统通知失败: {e}")
            continue
    
    # 批量插入优化
    if messages_to_create:
        db.bulk_save_objects(messages_to_create)
        db.commit()
    
    logger.info(f"系统通知创建完成: 管理员 {current_user.username} 创建了 {len(messages_to_create)} 条系统通知")
    
    # 记录管理员操作
    log_admin_action(
        db, 
        current_user.id, 
        "create_system_notification", 
        {
            "title": notification.title, 
            "target_count": len(messages_to_create),
            "priority": notification.priority
        }
    )
    
    return {
        "message": f"成功创建 {len(messages_to_create)} 条系统通知",
        "created_count": len(messages_to_create),
        "first_message": messages_to_create[0] if messages_to_create else None
    }


@router.get("/", response_model=PaginatedResponse[MessageResponse])
async def get_system_notifications(
    params: PaginationParams = Depends(),
    status: Optional[str] = None,
    priority_min: Optional[int] = None,
    priority_max: Optional[int] = None,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取系统通知列表"""
    query = db.query(Message).filter(
        Message.message_type == MessageType.NOTIFICATION,
        Message.receiver_id == current_user.id,
        Message.pattern.contains({"source_type": "system"})
    )
    
    # 应用过滤条件
    if status:
        query = query.filter(Message.status == status)
    if priority_min is not None:
        query = query.filter(Message.priority >= priority_min)
    if priority_max is not None:
        query = query.filter(Message.priority <= priority_max)
    if date_from:
        query = query.filter(Message.created_at >= date_from)
    if date_to:
        query = query.filter(Message.created_at <= date_to)
    
    total = query.count()
    messages = query.order_by(Message.created_at.desc()).offset(params.skip).limit(params.size).all()
    
    return PaginatedResponse.create(messages, total, params)


@router.get("/admin/all", response_model=PaginatedResponse[MessageResponse])
async def admin_get_all_system_notifications(
    params: PaginationParams = Depends(),
    status: Optional[str] = None,
    priority_min: Optional[int] = None,
    priority_max: Optional[int] = None,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """管理端：获取所有系统通知（需要超级用户权限）"""
    query = db.query(Message).filter(
        Message.message_type == MessageType.NOTIFICATION,
        Message.pattern.contains({"source_type": "system"})
    )
    
    # 应用过滤条件
    if status:
        query = query.filter(Message.status == status)
    if priority_min is not None:
        query = query.filter(Message.priority >= priority_min)
    if priority_max is not None:
        query = query.filter(Message.priority <= priority_max)
    if date_from:
        query = query.filter(Message.created_at >= date_from)
    if date_to:
        query = query.filter(Message.created_at <= date_to)
    
    total = query.count()
    messages = query.order_by(Message.created_at.desc()).offset(params.skip).limit(params.size).all()
    
    return PaginatedResponse.create(messages, total, params)


@router.get("/stats")
async def get_system_notification_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取系统通知统计信息"""
    query = db.query(Message).filter(
        Message.message_type == MessageType.NOTIFICATION,
        Message.receiver_id == current_user.id,
        Message.pattern.contains({"source_type": "system"})
    )
    
    total = query.count()
    unread = query.filter(Message.is_read == False).count()
    read = query.filter(Message.is_read == True).count()
    archived = query.filter(Message.status == MessageStatus.ARCHIVED).count()
    
    # 按优先级统计
    by_priority = {}
    for priority in range(11):
        count = query.filter(Message.priority == priority).count()
        if count > 0:
            by_priority[f"priority_{priority}"] = count
    
    # 按状态统计
    by_status = {}
    for status in [MessageStatus.UNREAD, MessageStatus.READ, MessageStatus.ARCHIVED]:
        count = query.filter(Message.status == status).count()
        by_status[status.value] = count
    
    return {
        "total": total,
        "unread": unread,
        "read": read,
        "archived": archived,
        "by_priority": by_priority,
        "by_status": by_status,
        "read_rate": read / total if total > 0 else 0
    }


@router.get("/admin/stats")
async def admin_get_system_notification_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """管理端：获取系统通知统计（需要超级用户权限）"""
    query = db.query(Message).filter(
        Message.message_type == MessageType.NOTIFICATION,
        Message.pattern.contains({"source_type": "system"})
    )
    
    total = query.count()
    unread = query.filter(Message.is_read == False).count()
    read = query.filter(Message.is_read == True).count()
    archived = query.filter(Message.status == MessageStatus.ARCHIVED).count()
    
    # 按优先级统计
    by_priority = {}
    for priority in range(11):
        count = query.filter(Message.priority == priority).count()
        if count > 0:
            by_priority[f"priority_{priority}"] = count
    
    # 按创建者统计
    by_creator = {}
    creators = db.query(Message.sender_id, func.count(Message.id)).filter(
        Message.message_type == MessageType.NOTIFICATION,
        Message.pattern.contains({"source_type": "system"})
    ).group_by(Message.sender_id).all()
    
    for creator_id, count in creators:
        creator = db.query(User).filter(User.id == creator_id).first()
        creator_name = creator.username if creator else f"用户{creator_id}"
        by_creator[creator_name] = count
    
    # 按日期统计（最近7天）
    by_date = {}
    for i in range(7):
        date = datetime.utcnow().date() - timedelta(days=i)
        count = query.filter(
            func.date(Message.created_at) == date
        ).count()
        by_date[date.isoformat()] = count
    
    return {
        "total": total,
        "unread": unread,
        "read": read,
        "archived": archived,
        "by_priority": by_priority,
        "by_creator": by_creator,
        "by_date": by_date,
        "read_rate": read / total if total > 0 else 0
    }


@router.get("/{notification_id}", response_model=MessageResponse)
async def get_system_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取指定系统通知"""
    notification = db.query(Message).filter(
        Message.id == notification_id,
        Message.message_type == MessageType.NOTIFICATION,
        Message.receiver_id == current_user.id,
        Message.pattern.contains({"source_type": "system"})
    ).first()
    
    if not notification:
        raise NotFoundException("系统通知不存在或无权限访问")
    
    return notification


@router.put("/{notification_id}/read")
async def mark_system_notification_as_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """标记系统通知为已读"""
    notification = db.query(Message).filter(
        Message.id == notification_id,
        Message.message_type == MessageType.NOTIFICATION,
        Message.receiver_id == current_user.id,
        Message.pattern.contains({"source_type": "system"})
    ).first()
    
    if not notification:
        raise NotFoundException("系统通知不存在或无权限访问")
    
    if not notification.is_read:
        notification.is_read = True
        notification.status = MessageStatus.READ
        notification.read_at = datetime.utcnow()
        db.commit()
        
        logger.info(f"系统通知标记为已读: 用户 {current_user.username} 标记通知 {notification_id}")
    
    return {"message": "系统通知已标记为已读"}


@router.put("/read-all")
async def mark_all_system_notifications_as_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """标记所有系统通知为已读"""
    updated_count = db.query(Message).filter(
        Message.receiver_id == current_user.id,
        Message.message_type == MessageType.NOTIFICATION,
        Message.pattern.contains({"source_type": "system"}),
        Message.is_read == False
    ).update({
        "is_read": True,
        "status": MessageStatus.READ,
        "read_at": datetime.utcnow()
    })
    
    db.commit()
    
    logger.info(f"所有系统通知标记为已读: 用户 {current_user.username} 标记了 {updated_count} 条通知")
    return {"message": f"{updated_count} 条系统通知已标记为已读"}


@router.delete("/{notification_id}")
async def delete_system_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除系统通知（软删除）"""
    notification = db.query(Message).filter(
        Message.id == notification_id,
        Message.message_type == MessageType.NOTIFICATION,
        Message.receiver_id == current_user.id,
        Message.pattern.contains({"source_type": "system"})
    ).first()
    
    if not notification:
        raise NotFoundException("系统通知不存在或无权限访问")
    
    # 软删除，只改变状态
    notification.status = MessageStatus.ARCHIVED
    db.commit()
    
    logger.info(f"系统通知删除: 用户 {current_user.username} 删除通知 {notification_id}")
    return {"message": "系统通知已删除"}


# 管理端API
@router.delete("/admin/{notification_id}")
async def admin_delete_system_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """管理端：删除系统通知（需要超级用户权限）"""
    notification = db.query(Message).filter(
        Message.id == notification_id,
        Message.message_type == MessageType.NOTIFICATION,
        Message.pattern.contains({"source_type": "system"})
    ).first()
    
    if not notification:
        raise NotFoundException("系统通知不存在")
    
    db.delete(notification)
    db.commit()
    
    logger.info(f"管理员删除系统通知: {current_user.username} 删除通知 {notification_id}")
    return {"message": "系统通知已永久删除"}