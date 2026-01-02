"""消息管理端点 - IM系统核心功能"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import List, Optional
from datetime import datetime, timedelta

from app.db.database import get_db
from app.models.message import Message, MessageType, MessageStatus
from app.models.user import User
from app.models.friendship import Friendship, FriendshipStatus
from app.schemas.message import (
    MessageCreate, MessageUpdate, MessageResponse, MessageStats
)
from app.schemas.common import PaginatedResponse
from app.core.security import get_current_active_user
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger
from app.services.redis_service import RedisService
import math

router = APIRouter()
logger = get_logger(__name__)


@router.post("/", response_model=MessageResponse)
async def create_message(
    message: MessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """创建消息 - IM核心功能"""
    # 验证接收者是否存在
    receiver = db.query(User).filter(User.id == message.receiver_id).first()
    if not receiver:
        raise NotFoundException("Receiver user not found")
    
    # 消息来源验证 - 支持多种来源类型
    if message.pattern and isinstance(message.pattern, dict):
        source_type = message.pattern.get("source_type")
        source_id = message.pattern.get("source_id")
        
        if source_type == "user":
            # 验证用户来源
            source_user = db.query(User).filter(User.id == source_id).first()
            if not source_user:
                raise ValidationException("Source user not found")
        # 可以扩展其他来源类型验证
    
    # 验证好友关系（如果是用户间消息）
    if message.message_type == MessageType.USER:
        friendship = db.query(Friendship).filter(
            or_(
                (Friendship.user_id == current_user.id) & (Friendship.friend_id == message.receiver_id),
                (Friendship.user_id == message.receiver_id) & (Friendship.friend_id == current_user.id)
            ),
            Friendship.status == FriendshipStatus.ACCEPTED
        ).first()
        
        if not friendship:
            raise ValidationException("Can only send messages to friends")
    
    # 创建消息
    message_data = message.dict()
    message_data["sender_id"] = current_user.id
    
    db_message = Message(**message_data)
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    
    # Redis集成：发布消息并更新未读计数
    await RedisService.publish_message(db_message)
    await RedisService.increment_unread_count(receiver.id)
    
    logger.info(f"IM消息创建: {message.title} 从 {current_user.username} 到 {receiver.username}")
    return db_message


@router.get("/", response_model=PaginatedResponse[MessageResponse])
async def get_messages(
    page: int = 1,
    size: int = 20,
    message_type: Optional[MessageType] = None,
    status: Optional[MessageStatus] = None,
    is_read: Optional[bool] = None,
    sender_id: Optional[int] = None,
    receiver_id: Optional[int] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取消息列表 - 支持IM会话查询"""
    skip = (page - 1) * size
    # 用户只能查看自己发送或接收的消息
    query = db.query(Message).filter(
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
    )
    
    # 应用过滤条件
    if message_type:
        query = query.filter(Message.message_type == message_type)
    if status:
        query = query.filter(Message.status == status)
    if is_read is not None:
        query = query.filter(Message.is_read == is_read)
    if sender_id:
        query = query.filter(Message.sender_id == sender_id)
    if receiver_id:
        query = query.filter(Message.receiver_id == receiver_id)
    if start_date:
        query = query.filter(Message.created_at >= start_date)
    if end_date:
        query = query.filter(Message.created_at <= end_date)
    
    total = query.count()
    messages = query.order_by(Message.created_at.desc()).offset(skip).limit(size).all()
    pages = math.ceil(total / size) if size > 0 else 0
    
    return {
        "items": messages,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    }


@router.get("/conversations/{user_id}", response_model=PaginatedResponse[MessageResponse])
async def get_conversation_messages(
    user_id: int,
    page: int = 1,
    size: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取与指定用户的会话消息 - IM核心功能"""
    skip = (page - 1) * size
    # 验证好友关系
    friendship = db.query(Friendship).filter(
        or_(
            (Friendship.user_id == current_user.id) & (Friendship.friend_id == user_id),
            (Friendship.user_id == user_id) & (Friendship.friend_id == current_user.id)
        ),
        Friendship.status == FriendshipStatus.ACCEPTED
    ).first()
    
    if not friendship:
        raise ValidationException("Can only view messages with friends")
    
    # 获取双方的消息
    query = db.query(Message).filter(
        ((Message.sender_id == current_user.id) & (Message.receiver_id == user_id)) |
        ((Message.sender_id == user_id) & (Message.receiver_id == current_user.id))
    )
    
    total = query.count()
    messages = query.order_by(Message.created_at.desc()).offset(skip).limit(size).all()
    pages = math.ceil(total / size) if size > 0 else 0
    
    # 标记未读消息为已读
    unread_messages = db.query(Message).filter(
        Message.sender_id == user_id,
        Message.receiver_id == current_user.id,
        Message.is_read == False
    ).all()
    
    for msg in unread_messages:
        msg.is_read = True
        msg.status = MessageStatus.READ
        msg.read_at = datetime.utcnow()
    
    if unread_messages:
        db.commit()
        # 同步Redis未读计数
        # 为了保证准确性，从数据库重新计算
        total_unread = db.query(Message).filter(
            Message.receiver_id == current_user.id,
            Message.is_read == False
        ).count()
        await RedisService.set_unread_count(current_user.id, total_unread)
    
    return {
        "items": messages,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    }


@router.get("/unread/count", response_model=int)
async def get_unread_count(
    current_user: User = Depends(get_current_active_user)
):
    """获取未读消息数量 - Redis缓存"""
    return await RedisService.get_unread_count(current_user.id)


@router.get("/unread", response_model=PaginatedResponse[MessageResponse])
async def get_unread_messages(
    page: int = 1,
    size: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取未读消息 - IM轮询接口"""
    skip = (page - 1) * size
    query = db.query(Message).filter(
        Message.receiver_id == current_user.id,
        Message.is_read == False
    )
    
    total = query.count()
    messages = query.order_by(Message.created_at.desc()).offset(skip).limit(size).all()
    pages = math.ceil(total / size) if size > 0 else 0
    
    return {
        "items": messages,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    }


@router.get("/recent", response_model=PaginatedResponse[MessageResponse])
async def get_recent_messages(
    hours: int = 24,
    page: int = 1,
    size: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取最近消息 - IM实时同步"""
    skip = (page - 1) * size
    since = datetime.utcnow() - timedelta(hours=hours)
    
    query = db.query(Message).filter(
        ((Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)) &
        (Message.created_at >= since)
    )
    
    total = query.count()
    messages = query.order_by(Message.created_at.desc()).offset(skip).limit(size).all()
    pages = math.ceil(total / size) if size > 0 else 0
    
    return {
        "items": messages,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    }


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
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """标记所有消息为已读"""
    updated_count = db.query(Message).filter(
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id),
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
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
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
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id),
        Message.is_read == True
    ).delete()
    
    db.commit()
    
    logger.info(f"Read messages deleted for user {current_user.email}: {deleted_count} messages")
    return {"message": f"{deleted_count} read messages deleted"}


# 管理端API
@router.get("/admin/all", response_model=PaginatedResponse[MessageResponse])
async def admin_get_all_messages(
    page: int = 1,
    size: int = 20,
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
    
    skip = (page - 1) * size
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
    messages = query.order_by(Message.created_at.desc()).offset(skip).limit(size).all()
    pages = math.ceil(total / size) if size > 0 else 0
    
    return {
        "items": messages,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    }


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