"""消息回执管理端点"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from app.db.database import get_db
from app.models.messageackevent import MessageAckEvent
from app.models.message import Message
from app.models.user import User
from app.schemas.messageackevent import (
    MessageAckEventCreate, MessageAckEventResponse
)
from app.core.security import get_current_active_user
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.post("/", response_model=MessageAckEventResponse)
async def create_message_ack_event(
    ack_event: MessageAckEventCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """创建消息回执事件"""
    # 验证消息是否存在且用户有权限访问
    message = db.query(Message).filter(
        Message.id == ack_event.message_id
    ).first()
    
    if not message:
        raise NotFoundException("Message not found")
    
    # 验证用户是否是消息的接收者或发送者
    if message.receiver_id != current_user.id and message.sender_id != current_user.id:
        raise ValidationException("No permission to acknowledge this message")
    
    # 验证事件类型
    valid_events = ["delivered", "displayed", "deleted"]
    if ack_event.event not in valid_events:
        raise ValidationException(f"Invalid event type. Must be one of: {valid_events}")
    
    # 创建回执事件
    db_ack_event = MessageAckEvent(**ack_event.dict())
    db.add(db_ack_event)
    db.commit()
    db.refresh(db_ack_event)
    
    # 更新消息状态
    if ack_event.event == "displayed":
        message.is_read = True
        message.read_at = datetime.utcnow()
        db.commit()
    elif ack_event.event == "delivered":
        message.delivered_at = datetime.utcnow()
        db.commit()
    
    logger.info(f"Message ack event created: {ack_event.event} for message {ack_event.message_id}")
    return db_ack_event


@router.get("/message/{message_id}", response_model=List[MessageAckEventResponse])
async def get_message_ack_events(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取指定消息的所有回执事件"""
    # 验证消息是否存在且用户有权限访问
    message = db.query(Message).filter(Message.id == message_id).first()
    if not message:
        raise NotFoundException("Message not found")
    
    if message.receiver_id != current_user.id and message.sender_id != current_user.id:
        raise ValidationException("No permission to view ack events for this message")
    
    ack_events = db.query(MessageAckEvent).filter(
        MessageAckEvent.message_id == message_id
    ).order_by(MessageAckEvent.timestamp.asc()).all()
    
    return ack_events


# 管理端API
@router.get("/admin/all", response_model=List[MessageAckEventResponse])
async def admin_get_all_ack_events(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """管理端：获取所有消息回执事件（需要超级用户权限）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    ack_events = db.query(MessageAckEvent).offset(skip).limit(limit).all()
    return ack_events


@router.get("/admin/stats")
async def admin_get_ack_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """管理端：获取消息回执统计（需要超级用户权限）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    total_events = db.query(MessageAckEvent).count()
    delivered_count = db.query(MessageAckEvent).filter(MessageAckEvent.event == "delivered").count()
    displayed_count = db.query(MessageAckEvent).filter(MessageAckEvent.event == "displayed").count()
    deleted_count = db.query(MessageAckEvent).filter(MessageAckEvent.event == "deleted").count()
    
    return {
        "total_events": total_events,
        "delivered": delivered_count,
        "displayed": displayed_count,
        "deleted": deleted_count,
        "delivery_rate": displayed_count / total_events if total_events > 0 else 0
    }