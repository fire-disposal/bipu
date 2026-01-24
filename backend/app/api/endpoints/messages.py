"""消息管理端点 - IM系统核心功能"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
import math

from app.db.database import get_db
from app.models.message import Message, MessageType, MessageStatus
from app.models.user import User
from app.schemas.message import MessageCreate, MessageResponse, MessageUpdate, MessageStats
from app.schemas.common import PaginationParams, PaginatedResponse
from app.core.security import get_current_active_user
from app.services.message_service import MessageService
from app.services.redis_service import RedisService
from app.core.exceptions import NotFoundException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)

def get_message_service(db: Session = Depends(get_db)) -> MessageService:
    return MessageService(db)

@router.post("/", response_model=MessageResponse)
async def create_message(
    message: MessageCreate,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """创建消息 - IM核心功能"""
    created_message = await service.create_message(current_user, message)
    logger.info(f"IM消息创建: {message.title} 从 {current_user.username} 到 {message.receiver_id}")
    return created_message


@router.get("/", response_model=PaginatedResponse[MessageResponse])
async def get_messages(
    params: PaginationParams = Depends(),
    message_type: Optional[MessageType] = None,
    status: Optional[MessageStatus] = None,
    is_read: Optional[bool] = None,
    sender_id: Optional[int] = None,
    receiver_id: Optional[int] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取消息列表 - 支持IM会话查询"""
    messages, total = service.get_messages(
        current_user, params, message_type, status, is_read, sender_id, receiver_id, start_date, end_date
    )
    return PaginatedResponse.create(messages, total, params)


@router.get("/conversations/{user_id}", response_model=PaginatedResponse[MessageResponse])
async def get_conversation_messages(
    user_id: int,
    params: PaginationParams = Depends(),
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取与指定用户的会话消息 - IM核心功能"""
    messages, total = await service.get_conversation_messages(current_user, user_id, params)
    return PaginatedResponse.create(messages, total, params)


@router.get("/unread/count", response_model=int)
async def get_unread_count(
    current_user: User = Depends(get_current_active_user)
):
    """获取未读消息数量 - Redis缓存"""
    return await RedisService.get_unread_count(current_user.id)


@router.get("/stats", response_model=MessageStats)
async def get_message_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取消息统计信息"""
    query = db.query(Message).filter(
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
    )
    
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
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
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
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
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
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """标记所有消息为已读"""
    updated_count = await service.mark_all_as_read(current_user)
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
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
    ).first()
    
    if not message:
        raise NotFoundException("Message not found")
    
    db.delete(message)
    db.commit()
    
    logger.info(f"Message deleted: {message.title} by user {current_user.email}")
    return {"message": "Message deleted successfully"}


# 管理端API
@router.get("/admin/all", response_model=PaginatedResponse[MessageResponse])
async def admin_get_all_messages(
    params: PaginationParams = Depends(),
    message_type: Optional[MessageType] = None,
    status: Optional[MessageStatus] = None,
    sender_id: Optional[int] = None,
    receiver_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """管理端：获取所有消息（需要超级用户权限）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    query = db.query(Message)
    
    if message_type:
        query = query.filter(Message.message_type == message_type)
    if status:
        query = query.filter(Message.status == status)
    if sender_id:
        query = query.filter(Message.sender_id == sender_id)
    if receiver_id:
        query = query.filter(Message.receiver_id == receiver_id)
    
    total = query.count()
    messages = query.order_by(Message.created_at.desc()).offset(params.skip).limit(params.size).all()
    
    return PaginatedResponse.create(messages, total, params)


@router.delete("/admin/{message_id}")
async def admin_delete_message(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """管理端：删除消息（需要超级用户权限）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    message = db.query(Message).filter(Message.id == message_id).first()
    if not message:
        raise NotFoundException("Message not found")
    
    db.delete(message)
    db.commit()
    
    logger.info(f"Admin deleted message: {message_id} by {current_user.username}")
    return {"message": "Message deleted by admin"}


@router.get("/admin/stats")
async def admin_get_message_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """管理端：获取系统消息统计（需要超级用户权限）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    total_messages = db.query(Message).count()
    unread_messages = db.query(Message).filter(Message.is_read == False).count()
    read_messages = db.query(Message).filter(Message.is_read == True).count()
    
    # 按类型统计
    by_type = {}
    for msg_type in MessageType:
        count = db.query(Message).filter(Message.message_type == msg_type).count()
        by_type[msg_type.value] = count
    
    # 按状态统计
    by_status = {}
    for msg_status in MessageStatus:
        count = db.query(Message).filter(Message.status == msg_status).count()
        by_status[msg_status.value] = count
    
    # 今日消息统计
    today = datetime.utcnow().date()
    today_messages = db.query(Message).filter(
        func.date(Message.created_at) == today
    ).count()
    
    return {
        "total_messages": total_messages,
        "unread_messages": unread_messages,
        "read_messages": read_messages,
        "today_messages": today_messages,
        "by_type": by_type,
        "by_status": by_status,
        "read_rate": read_messages / total_messages if total_messages > 0 else 0
    }