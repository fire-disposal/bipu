"""消息管理端点 - 收藏、导出等高级功能"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import List, Optional
from datetime import datetime, timedelta

from app.db.database import get_db
from app.models.user import User
from app.models.message import Message, MessageStatus
from app.models.message_favorite import MessageFavorite
from app.schemas.user_settings import (
    MessageStatsRequest, MessageStatsResponse, ExportMessagesRequest,
    ExportMessagesResponse
)
from app.core.security import get_current_active_user
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.post("/messages/{message_id}/favorite")
async def favorite_message(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """收藏消息"""
    # 检查消息是否存在且用户有权限访问
    message = db.query(Message).filter(
        Message.id == message_id,
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
    ).first()
    
    if not message:
        raise NotFoundException("消息不存在或无权限访问")
    
    # 检查是否已经收藏
    existing_favorite = db.query(MessageFavorite).filter(
        MessageFavorite.user_id == current_user.id,
        MessageFavorite.message_id == message_id
    ).first()
    
    if existing_favorite:
        raise ValidationException("消息已经收藏")
    
    # 创建收藏记录
    favorite = MessageFavorite(
        user_id=current_user.id,
        message_id=message_id
    )
    db.add(favorite)
    db.commit()
    
    logger.info(f"消息收藏: 用户 {current_user.username} 收藏消息 {message_id}")
    return {"message": "消息已收藏"}


@router.delete("/messages/{message_id}/favorite")
async def unfavorite_message(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """取消收藏消息"""
    favorite = db.query(MessageFavorite).filter(
        MessageFavorite.user_id == current_user.id,
        MessageFavorite.message_id == message_id
    ).first()
    
    if not favorite:
        raise NotFoundException("未找到收藏记录")
    
    db.delete(favorite)
    db.commit()
    
    logger.info(f"取消消息收藏: 用户 {current_user.username} 取消收藏消息 {message_id}")
    return {"message": "已取消收藏"}


@router.get("/messages/favorites")
async def get_favorite_messages(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取收藏的消息列表"""
    query = db.query(Message).join(
        MessageFavorite,
        and_(
            MessageFavorite.message_id == Message.id,
            MessageFavorite.user_id == current_user.id
        )
    )
    
    total = query.count()
    messages = query.order_by(MessageFavorite.created_at.desc()).offset(skip).limit(limit).all()
    
    return {
        "items": messages,
        "total": total,
        "page": skip // limit + 1,
        "size": limit
    }


@router.get("/messages/sent")
async def get_sent_messages(
    skip: int = 0,
    limit: int = 100,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取已发送消息"""
    query = db.query(Message).filter(Message.sender_id == current_user.id)
    
    if date_from:
        query = query.filter(Message.created_at >= date_from)
    if date_to:
        query = query.filter(Message.created_at <= date_to)
    
    total = query.count()
    messages = query.order_by(Message.created_at.desc()).offset(skip).limit(limit).all()
    
    return {
        "items": messages,
        "total": total,
        "page": skip // limit + 1,
        "size": limit
    }


@router.get("/messages/received")
async def get_received_messages(
    skip: int = 0,
    limit: int = 100,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取已接收消息"""
    query = db.query(Message).filter(Message.receiver_id == current_user.id)
    
    if date_from:
        query = query.filter(Message.created_at >= date_from)
    if date_to:
        query = query.filter(Message.created_at <= date_to)
    
    total = query.count()
    messages = query.order_by(Message.created_at.desc()).offset(skip).limit(limit).all()
    
    return {
        "items": messages,
        "total": total,
        "page": skip // limit + 1,
        "size": limit
    }


@router.delete("/messages/batch")
async def batch_delete_messages(
    message_ids: List[int],
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """批量删除消息"""
    if not message_ids:
        raise ValidationException("消息ID列表不能为空")
    
    if len(message_ids) > 100:
        raise ValidationException("一次最多删除100条消息")
    
    # 检查消息权限
    messages = db.query(Message).filter(
        Message.id.in_(message_ids),
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
    ).all()
    
    if len(messages) != len(message_ids):
        raise ValidationException("部分消息不存在或无权限删除")
    
    # 删除消息
    deleted_count = db.query(Message).filter(
        Message.id.in_(message_ids)
    ).delete(synchronize_session=False)
    
    # 同时删除相关的收藏记录
    db.query(MessageFavorite).filter(
        MessageFavorite.message_id.in_(message_ids),
        MessageFavorite.user_id == current_user.id
    ).delete(synchronize_session=False)
    
    db.commit()
    
    logger.info(f"批量删除消息: 用户 {current_user.username} 删除 {deleted_count} 条消息")
    return {"message": f"成功删除 {deleted_count} 条消息"}


@router.put("/messages/{message_id}/archive")
async def archive_message(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """归档消息"""
    message = db.query(Message).filter(
        Message.id == message_id,
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
    ).first()
    
    if not message:
        raise NotFoundException("消息不存在或无权限访问")
    
    message.status = MessageStatus.ARCHIVED
    db.commit()
    
    logger.info(f"消息归档: 用户 {current_user.username} 归档消息 {message_id}")
    return {"message": "消息已归档"}


@router.get("/messages/stats", response_model=MessageStatsResponse)
async def get_message_management_stats(
    stats_request: MessageStatsRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取消息管理统计"""
    # 基础查询
    base_query = db.query(Message).filter(
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
    )
    
    if stats_request.date_from:
        base_query = base_query.filter(Message.created_at >= stats_request.date_from)
    if stats_request.date_to:
        base_query = base_query.filter(Message.created_at <= stats_request.date_to)
    
    # 统计信息
    total_sent = base_query.filter(Message.sender_id == current_user.id).count()
    total_received = base_query.filter(Message.receiver_id == current_user.id).count()
    total_favorites = db.query(MessageFavorite).filter(
        MessageFavorite.user_id == current_user.id
    ).count()
    
    # 按类型统计
    by_type = {}
    for msg_type in ["system", "user", "alert", "notification"]:
        count = base_query.filter(Message.message_type == msg_type).count()
        by_type[msg_type] = count
    
    # 按日期统计（简化版）
    by_date = {}
    # 这里可以根据 stats_request.group_by 实现更复杂的日期分组
    
    return MessageStatsResponse(
        total_sent=total_sent,
        total_received=total_received,
        total_favorites=total_favorites,
        by_type=by_type,
        by_date=by_date
    )


@router.post("/messages/export", response_model=ExportMessagesResponse)
async def export_messages_advanced(
    export_request: ExportMessagesRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """高级消息导出功能"""
    # 构建查询
    query = db.query(Message).filter(
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id)
    )
    
    # 应用过滤条件
    if export_request.message_type == "sent":
        query = query.filter(Message.sender_id == current_user.id)
    elif export_request.message_type == "received":
        query = query.filter(Message.receiver_id == current_user.id)
    
    if export_request.date_from:
        query = query.filter(Message.created_at >= export_request.date_from)
    if export_request.date_to:
        query = query.filter(Message.created_at <= export_request.date_to)
    
    messages = query.all()
    
    # 这里可以实现实际的文件导出逻辑
    # 根据 format 参数生成不同格式的文件
    file_extension = export_request.format
    download_url = f"/api/v1/downloads/messages_export_{current_user.id}_{int(datetime.utcnow().timestamp())}.{file_extension}"
    
    # 模拟文件大小计算
    export_data = []
    for msg in messages:
        msg_data = {
            "id": msg.id,
            "title": msg.title,
            "content": msg.content if export_request.include_content else "[内容已隐藏]",
            "message_type": msg.message_type,
            "sender_id": msg.sender_id,
            "receiver_id": msg.receiver_id,
            "created_at": msg.created_at.isoformat() if export_request.include_metadata else None,
            "is_read": msg.is_read if export_request.include_metadata else None,
        }
        export_data.append(msg_data)
    
    file_size = len(str(export_data).encode('utf-8'))
    
    return ExportMessagesResponse(
        download_url=download_url,
        file_size=file_size,
        record_count=len(messages),
        expires_at=datetime.utcnow() + timedelta(hours=24)
    )


@router.get("/messages/search")
async def search_messages(
    keyword: str,
    message_type: Optional[str] = None,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """搜索消息"""
    if not keyword or len(keyword) < 2:
        raise ValidationException("搜索关键词至少需要2个字符")
    
    query = db.query(Message).filter(
        (Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id),
        or_(
            Message.title.contains(keyword),
            Message.content.contains(keyword)
        )
    )
    
    if message_type:
        query = query.filter(Message.message_type == message_type)
    if date_from:
        query = query.filter(Message.created_at >= date_from)
    if date_to:
        query = query.filter(Message.created_at <= date_to)
    
    total = query.count()
    messages = query.order_by(Message.created_at.desc()).offset(skip).limit(limit).all()
    
    return {
        "items": messages,
        "total": total,
        "page": skip // limit + 1,
        "size": limit,
        "keyword": keyword
    }