"""消息管理端点"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime

from app.db.database import get_db
from app.models.message import Message, MessageType, MessageStatus
from app.models.user import User
from app.models.device import Device
from app.schemas.message import (
    MessageCreate, MessageUpdate, MessageResponse, MessageList, MessageStats
)
from app.core.security import get_current_active_user
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.post("/", response_model=MessageResponse)
async def create_message(
    message: MessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """创建消息"""
    # 验证设备是否存在且属于当前用户
    if message.device_id:
        device = db.query(Device).filter(
            Device.id == message.device_id,
            Device.user_id == current_user.id
        ).first()
        
        if not device:
            raise ValidationException("Device not found or not owned by user")
    
    # 创建消息
    message_data = message.dict()
    message_data["user_id"] = current_user.id
    
    db_message = Message(**message_data)
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    
    logger.info(f"Message created: {message.title} for user {current_user.email}")
    return db_message


@router.get("/", response_model=MessageList)
async def get_messages(
    skip: int = 0,
    limit: int = 100,
    message_type: Optional[MessageType] = None,
    status: Optional[MessageStatus] = None,
    is_read: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取消息列表"""
    query = db.query(Message).filter(Message.user_id == current_user.id)
    
    # 应用过滤条件
    if message_type:
        query = query.filter(Message.message_type == message_type)
    if status:
        query = query.filter(Message.status == status)
    if is_read is not None:
        query = query.filter(Message.is_read == is_read)
    
    total = query.count()
    unread_count = query.filter(Message.is_read == False).count()
    messages = query.order_by(Message.created_at.desc()).offset(skip).limit(limit).all()
    
    return MessageList(
        items=messages,
        total=total,
        page=skip // limit + 1,
        size=limit,
        unread_count=unread_count
    )


@router.get("/stats", response_model=MessageStats)
async def get_message_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取消息统计信息"""
    query = db.query(Message).filter(Message.user_id == current_user.id)
    
    total = query.count()
    unread = query.filter(Message.is_read == False).count()
    read = query.filter(Message.is_read == True).count()
    archived = query.filter(Message.status == MessageStatus.ARCHIVED).count()
    
    # 按类型统计
    by_type = {}
    for msg_type in MessageType:
        count = query.filter(Message.message_type == msg_type).count()
        by_type[msg_type.value] = count
    
    return MessageStats(
        total=total,
        unread=unread,
        read=read,
        archived=archived,
        by_type=by_type
    )


@router.get("/{message_id}", response_model=MessageResponse)
async def get_message(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取指定消息"""
    message = db.query(Message).filter(
        Message.id == message_id,
        Message.user_id == current_user.id
    ).first()
    
    if not message:
        raise NotFoundException("Message not found")
    
    return message


@router.put("/{message_id}", response_model=MessageResponse)
async def update_message(
    message_id: int,
    message_update: MessageUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新消息"""
    message = db.query(Message).filter(
        Message.id == message_id,
        Message.user_id == current_user.id
    ).first()
    
    if not message:
        raise NotFoundException("Message not found")
    
    update_data = message_update.dict(exclude_unset=True)
    
    # 如果标记为已读，设置阅读时间
    if "is_read" in update_data and update_data["is_read"] and not message.is_read:
        update_data["read_at"] = datetime.utcnow()
        update_data["status"] = MessageStatus.READ
    
    for key, value in update_data.items():
        setattr(message, key, value)
    
    db.commit()
    db.refresh(message)
    
    logger.info(f"Message updated: {message.title} by user {current_user.email}")
    return message


@router.put("/{message_id}/read")
async def mark_message_as_read(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """标记消息为已读"""
    message = db.query(Message).filter(
        Message.id == message_id,
        Message.user_id == current_user.id
    ).first()
    
    if not message:
        raise NotFoundException("Message not found")
    
    if not message.is_read:
        message.is_read = True
        message.status = MessageStatus.READ
        message.read_at = datetime.utcnow()
        db.commit()
        
        logger.info(f"Message marked as read: {message.title}")
    
    return {"message": "Message marked as read"}


@router.put("/read-all")
async def mark_all_messages_as_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """标记所有消息为已读"""
    updated_count = db.query(Message).filter(
        Message.user_id == current_user.id,
        Message.is_read == False
    ).update({
        "is_read": True,
        "status": MessageStatus.READ,
        "read_at": datetime.utcnow()
    })
    
    db.commit()
    
    logger.info(f"All messages marked as read for user {current_user.email}: {updated_count} messages")
    return {"message": f"{updated_count} messages marked as read"}


@router.delete("/{message_id}")
async def delete_message(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除消息"""
    message = db.query(Message).filter(
        Message.id == message_id,
        Message.user_id == current_user.id
    ).first()
    
    if not message:
        raise NotFoundException("Message not found")
    
    db.delete(message)
    db.commit()
    
    logger.info(f"Message deleted: {message.title} by user {current_user.email}")
    return {"message": "Message deleted successfully"}


@router.delete("/")
async def delete_read_messages(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除所有已读消息"""
    deleted_count = db.query(Message).filter(
        Message.user_id == current_user.id,
        Message.is_read == True
    ).delete()
    
    db.commit()
    
    logger.info(f"Read messages deleted for user {current_user.email}: {deleted_count} messages")
    return {"message": f"{deleted_count} read messages deleted"}