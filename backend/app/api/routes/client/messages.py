"""客户端消息API路由 - 用户业务功能，无需管理员权限"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel

from app.db.database import get_db
from app.models.message import Message, MessageType, MessageStatus
from app.models.messageackevent import MessageAckEvent
from app.models.user import User
from app.schemas.message import MessageCreate, MessageResponse, MessageUpdate, MessageStats
from app.schemas.messageackevent import MessageAckEventCreate, MessageAckEventResponse
from app.schemas.common import PaginationParams, PaginatedResponse, StatusResponse
from app.schemas.user_settings import MessageStatsRequest, MessageStatsResponse, ExportMessagesRequest, ExportMessagesResponse
from app.core.security import get_current_active_user
from app.services.message_service import MessageService
from app.services.redis_service import RedisService
from app.core.exceptions import NotFoundException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)

def get_message_service(db: Session = Depends(get_db)) -> MessageService:
    return MessageService(db)

 

# 基础消息功能
@router.post("/", response_model=MessageResponse, tags=["Messages"])
async def create_message(
    message: MessageCreate,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """创建消息 - IM核心功能"""
    created_message = await service.create_message(current_user, message)
    logger.info(f"IM消息创建: {message.title} 从 {current_user.username} 到 {message.receiver_id}")
    return created_message


@router.get("/", response_model=PaginatedResponse[MessageResponse], tags=["Messages"])
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
    messages, total = await service.get_messages(
        current_user, params, message_type, status, is_read, sender_id, receiver_id, start_date, end_date
    )
    return PaginatedResponse.create(messages, total, params)


@router.get("/conversations/{user_id}", response_model=PaginatedResponse[MessageResponse], tags=["Messages"])
async def get_conversation_messages(
    user_id: int,
    params: PaginationParams = Depends(),
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取与指定用户的会话消息 - IM核心功能"""
    messages, total = await service.get_conversation_messages(current_user, user_id, params)
    return PaginatedResponse.create(messages, total, params)


@router.get("/unread/count", response_model=int, tags=["Messages"])
async def get_unread_count(
    current_user: User = Depends(get_current_active_user)
):
    """获取未读消息数量 - Redis缓存"""
    return await RedisService.get_unread_count(current_user.id)


@router.get("/stats", response_model=MessageStats, tags=["Messages"])
async def get_message_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取消息统计信息 - 带Redis缓存"""
    # 尝试从缓存获取统计信息
    cache_key = f"message_stats:user:{current_user.id}"
    cached_stats = await RedisService.get_cached_api_response(cache_key)
    if cached_stats is not None:
        return MessageStats(**cached_stats)
    
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
    
    stats = MessageStats(
        total=total,
        unread=unread,
        read=read,
        archived=archived,
        by_type=by_type
    )
    
    # 缓存统计信息，设置较短的过期时间
    await RedisService.cache_api_response(cache_key, stats.dict(), expire=300)  # 5分钟缓存
    
    return stats


@router.get("/{message_id}", response_model=MessageResponse, tags=["Messages"])
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


@router.put("/{message_id}", response_model=MessageResponse, tags=["Messages"])
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


@router.put("/{message_id}/read", response_model=StatusResponse, tags=["Messages"])
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


@router.put("/read-all", response_model=StatusResponse, tags=["Messages"])
async def mark_all_messages_as_read(
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """标记所有消息为已读"""
    updated_count = await service.mark_all_as_read(current_user)
    logger.info(f"All messages marked as read for user {current_user.email}: {updated_count} messages")
    return {"message": f"{updated_count} messages marked as read"}


@router.delete("/{message_id}", response_model=StatusResponse, tags=["Messages"])
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

# 消息回执功能
@router.post("/ack", response_model=MessageAckEventResponse, tags=["Messages"])
async def create_message_ack_event(
    ack_event: MessageAckEventCreate,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """创建消息回执事件"""
    result = service.create_ack_event(current_user, ack_event)
    logger.info(f"Message ack event created: {ack_event.event} for message {ack_event.message_id}")
    return result


@router.get("/ack/message/{message_id}", response_model=PaginatedResponse[MessageAckEventResponse], tags=["Messages"])
async def get_message_ack_events(
    message_id: int,
    params: PaginationParams = Depends(),
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取指定消息的所有回执事件"""
    events, total = service.get_ack_events(current_user, message_id, params)
    return PaginatedResponse.create(events, total, params)

# 消息管理功能
@router.post("/{message_id}/favorite", response_model=StatusResponse, tags=["Messages"])
async def favorite_message(
    message_id: int,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """收藏消息"""
    service.favorite_message(current_user, message_id)
    logger.info(f"消息收藏: 用户 {current_user.username} 收藏消息 {message_id}")
    return {"message": "消息已收藏"}


@router.delete("/{message_id}/favorite", response_model=StatusResponse, tags=["Messages"])
async def unfavorite_message(
    message_id: int,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """取消收藏消息"""
    service.unfavorite_message(current_user, message_id)
    logger.info(f"取消消息收藏: 用户 {current_user.username} 取消收藏消息 {message_id}")
    return {"message": "已取消收藏"}


@router.get("/favorites", response_model=PaginatedResponse[MessageResponse], tags=["Messages"])
async def get_favorite_messages(
    params: PaginationParams = Depends(),
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取收藏的消息列表"""
    messages, total = service.get_favorite_messages(current_user, params)
    return PaginatedResponse.create(messages, total, params)


@router.delete("/batch", response_model=StatusResponse, tags=["Messages"])
async def batch_delete_messages(
    message_ids: List[int],
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """批量删除消息"""
    deleted_count = service.batch_delete_messages(current_user, message_ids)
    logger.info(f"批量删除消息: 用户 {current_user.username} 删除 {deleted_count} 条消息")
    return {"message": f"成功删除 {deleted_count} 条消息"}


@router.put("/{message_id}/archive", response_model=StatusResponse, tags=["Messages"])
async def archive_message(
    message_id: int,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """归档消息"""
    service.archive_message(current_user, message_id)
    logger.info(f"消息归档: 用户 {current_user.username} 归档消息 {message_id}")
    return {"message": "消息已归档"}


@router.get("/management/stats", response_model=MessageStatsResponse, tags=["Messages"])
async def get_message_management_stats(
    stats_request: MessageStatsRequest = Depends(),
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取消息管理统计"""
    result = service.get_management_stats(current_user, stats_request)
    return MessageStatsResponse(**result)


@router.post("/export", response_model=ExportMessagesResponse, tags=["Messages"])
async def export_messages_advanced(
    export_request: ExportMessagesRequest,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """高级消息导出功能"""
    result = service.export_messages_advanced(current_user, export_request)
    return ExportMessagesResponse(**result)


@router.get("/search", response_model=PaginatedResponse[MessageResponse], tags=["Messages"])
async def search_messages(
    keyword: str,
    params: PaginationParams = Depends(),
    message_type: Optional[str] = None,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """搜索消息"""
    messages, total = service.search_messages(
        current_user, keyword, params, message_type, date_from, date_to
    )
    return PaginatedResponse.create(messages, total, params)