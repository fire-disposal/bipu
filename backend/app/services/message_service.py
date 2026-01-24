from typing import List, Optional, Dict, Any, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from datetime import datetime, timedelta

from app.models.message import Message, MessageType, MessageStatus
from app.models.user import User
from app.models.friendship import Friendship, FriendshipStatus
from app.models.messageackevent import MessageAckEvent
from app.models.message_favorite import MessageFavorite
from app.schemas.message import MessageCreate, MessageResponse
from app.schemas.messageackevent import MessageAckEventCreate
from app.schemas.common import PaginationParams
from app.schemas.user_settings import MessageStatsRequest, ExportMessagesRequest
from app.core.exceptions import NotFoundException, ValidationException
from app.services.redis_service import RedisService

class MessageService:
    def __init__(self, db: Session):
        self.db = db

    async def create_message(self, user: User, message: MessageCreate) -> Message:
        """创建消息"""
        # 验证接收者是否存在
        receiver = self.db.query(User).filter(User.id == message.receiver_id).first()
        if not receiver:
            raise NotFoundException("Receiver user not found")
        
        # 消息来源验证 - 支持多种来源类型
        if message.pattern and isinstance(message.pattern, dict):
            source_type = message.pattern.get("source_type")
            source_id = message.pattern.get("source_id")
            
            if source_type == "user":
                # 验证用户来源
                source_user = self.db.query(User).filter(User.id == source_id).first()
                if not source_user:
                    raise ValidationException("Source user not found")
        
        # 验证好友关系（如果是用户间消息）
        if message.message_type == MessageType.USER:
            friendship = self.db.query(Friendship).filter(
                or_(
                    (Friendship.user_id == user.id) & (Friendship.friend_id == message.receiver_id),
                    (Friendship.user_id == message.receiver_id) & (Friendship.friend_id == user.id)
                ),
                Friendship.status == FriendshipStatus.ACCEPTED
            ).first()
            
            if not friendship:
                raise ValidationException("Can only send messages to friends")
        
        # 创建消息
        message_data = message.dict()
        message_data["sender_id"] = user.id
        
        db_message = Message(**message_data)
        self.db.add(db_message)
        self.db.commit()
        self.db.refresh(db_message)
        
        # Redis集成：发布消息并更新未读计数
        await RedisService.publish_message(db_message)
        await RedisService.increment_unread_count(receiver.id)
        
        return db_message

    def get_messages(
        self, 
        user: User, 
        params: PaginationParams,
        message_type: Optional[MessageType] = None,
        status: Optional[MessageStatus] = None,
        is_read: Optional[bool] = None,
        sender_id: Optional[int] = None,
        receiver_id: Optional[int] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> Tuple[List[Message], int]:
        """获取消息列表"""
        query = self.db.query(Message).filter(
            (Message.sender_id == user.id) | (Message.receiver_id == user.id)
        )
        
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
        # Ensure consistent ordering
        messages = query.order_by(Message.created_at.desc()).offset(params.skip).limit(params.size).all()
        
        return messages, total

    def create_ack_event(self, user: User, ack_event: MessageAckEventCreate) -> MessageAckEvent:
        """创建消息回执事件"""
        message = self.db.query(Message).filter(
            Message.id == ack_event.message_id
        ).first()
        
        if not message:
            raise NotFoundException("Message not found")
        
        if message.receiver_id != user.id and message.sender_id != user.id:
            raise ValidationException("No permission to acknowledge this message")
        
        valid_events = ["delivered", "displayed", "deleted"]
        if ack_event.event not in valid_events:
            raise ValidationException(f"Invalid event type. Must be one of: {valid_events}")
        
        db_ack_event = MessageAckEvent(**ack_event.dict())
        self.db.add(db_ack_event)
        self.db.commit()
        self.db.refresh(db_ack_event)
        
        if ack_event.event == "displayed":
            message.is_read = True
            message.read_at = datetime.utcnow()
            self.db.commit()
        elif ack_event.event == "delivered":
            message.delivered_at = datetime.utcnow()
            self.db.commit()
            
        return db_ack_event

    def get_ack_events(self, user: User, message_id: int, params: PaginationParams) -> Tuple[List[MessageAckEvent], int]:
        """获取消息回执"""
        message = self.db.query(Message).filter(Message.id == message_id).first()
        if not message:
            raise NotFoundException("Message not found")
        
        if message.receiver_id != user.id and message.sender_id != user.id:
            raise ValidationException("No permission to view ack events for this message")
        
        query = self.db.query(MessageAckEvent).filter(
            MessageAckEvent.message_id == message_id
        )
        
        total = query.count()
        items = query.order_by(MessageAckEvent.timestamp.asc()).offset(params.skip).limit(params.size).all()
        
        return items, total

    def favorite_message(self, user: User, message_id: int) -> None:
        """收藏消息"""
        message = self.db.query(Message).filter(
            Message.id == message_id,
            (Message.sender_id == user.id) | (Message.receiver_id == user.id)
        ).first()
        
        if not message:
            raise NotFoundException("消息不存在或无权限访问")
        
        existing_favorite = self.db.query(MessageFavorite).filter(
            MessageFavorite.user_id == user.id,
            MessageFavorite.message_id == message_id
        ).first()
        
        if existing_favorite:
            raise ValidationException("消息已经收藏")
        
        favorite = MessageFavorite(
            user_id=user.id,
            message_id=message_id
        )
        self.db.add(favorite)
        self.db.commit()

    def unfavorite_message(self, user: User, message_id: int) -> None:
        """取消收藏消息"""
        favorite = self.db.query(MessageFavorite).filter(
            MessageFavorite.user_id == user.id,
            MessageFavorite.message_id == message_id
        ).first()
        
        if not favorite:
            raise NotFoundException("未找到收藏记录")
        
        self.db.delete(favorite)
        self.db.commit()

    def get_favorite_messages(self, user: User, params: PaginationParams) -> Tuple[List[Message], int]:
        """获取收藏的消息列表"""
        query = self.db.query(Message).join(
            MessageFavorite, Message.id == MessageFavorite.message_id
        ).filter(
            MessageFavorite.user_id == user.id
        )
        
        total = query.count()
        messages = query.order_by(MessageFavorite.created_at.desc()).offset(params.skip).limit(params.size).all()
        
        return messages, total

    def batch_delete_messages(self, user: User, message_ids: List[int]) -> int:
        """批量删除消息"""
        if not message_ids:
            raise ValidationException("消息ID列表不能为空")
        
        if len(message_ids) > 100:
            raise ValidationException("一次最多删除100条消息")
        
        messages = self.db.query(Message).filter(
            Message.id.in_(message_ids),
            (Message.sender_id == user.id) | (Message.receiver_id == user.id)
        ).all()
        
        if len(messages) != len(message_ids):
            raise ValidationException("部分消息不存在或无权限删除")
        
        deleted_count = self.db.query(Message).filter(
            Message.id.in_(message_ids)
        ).delete(synchronize_session=False)
        
        self.db.query(MessageFavorite).filter(
            MessageFavorite.message_id.in_(message_ids),
            MessageFavorite.user_id == user.id
        ).delete(synchronize_session=False)
        
        self.db.commit()
        return deleted_count

    def archive_message(self, user: User, message_id: int) -> None:
        """归档消息"""
        message = self.db.query(Message).filter(
            Message.id == message_id,
            (Message.sender_id == user.id) | (Message.receiver_id == user.id)
        ).first()
        
        if not message:
            raise NotFoundException("消息不存在或无权限访问")
        
        message.status = MessageStatus.ARCHIVED
        self.db.commit()

    def get_management_stats(self, user: User, stats_request: MessageStatsRequest) -> dict:
        """获取消息管理统计"""
        base_query = self.db.query(Message).filter(
            (Message.sender_id == user.id) | (Message.receiver_id == user.id)
        )
        
        if stats_request.date_from:
            base_query = base_query.filter(Message.created_at >= stats_request.date_from)
        if stats_request.date_to:
            base_query = base_query.filter(Message.created_at <= stats_request.date_to)
        
        total_sent = base_query.filter(Message.sender_id == user.id).count()
        total_received = base_query.filter(Message.receiver_id == user.id).count()
        total_favorites = self.db.query(MessageFavorite).filter(
            MessageFavorite.user_id == user.id
        ).count()
        
        by_type = {}
        for msg_type in ["system", "user", "alert", "notification"]:
            count = base_query.filter(Message.message_type == msg_type).count()
            by_type[msg_type] = count
            
        return {
            "total_sent": total_sent,
            "total_received": total_received,
            "total_favorites": total_favorites,
            "by_type": by_type,
            "by_date": {}
        }

    def export_messages_advanced(
        self, user: User, export_request: ExportMessagesRequest
    ) -> Dict[str, Any]:
        """高级消息导出功能"""
        query = self.db.query(Message).filter(
            (Message.sender_id == user.id) | (Message.receiver_id == user.id)
        )
        
        if export_request.message_type == "sent":
            query = query.filter(Message.sender_id == user.id)
        elif export_request.message_type == "received":
            query = query.filter(Message.receiver_id == user.id)
        
        if export_request.date_from:
            query = query.filter(Message.created_at >= export_request.date_from)
        if export_request.date_to:
            query = query.filter(Message.created_at <= export_request.date_to)
        
        messages = query.all()
        
        file_extension = export_request.format
        download_url = f"/api/v1/downloads/messages_export_{user.id}_{int(datetime.utcnow().timestamp())}.{file_extension}"
        
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
        
        return {
            "download_url": download_url,
            "file_size": file_size,
            "record_count": len(messages),
            "expires_at": datetime.utcnow() + timedelta(hours=24)
        }

    def search_messages(
        self,
        user: User,
        keyword: str,
        params: PaginationParams,
        message_type: Optional[str] = None,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None
    ) -> Tuple[List[Message], int]:
        """搜索消息"""
        if not keyword or len(keyword) < 2:
            raise ValidationException("搜索关键词至少需要2个字符")
        
        query = self.db.query(Message).filter(
            (Message.sender_id == user.id) | (Message.receiver_id == user.id),
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
        messages = query.order_by(Message.created_at.desc()).offset(params.skip).limit(params.size).all()
        
        return messages, total

    async def get_conversation_messages(
        self, user: User, friend_id: int, params: PaginationParams
    ) -> Tuple[List[Message], int]:
        """获取与指定用户的会话消息"""
        # 验证好友关系
        friendship = self.db.query(Friendship).filter(
            or_(
                (Friendship.user_id == user.id) & (Friendship.friend_id == friend_id),
                (Friendship.user_id == friend_id) & (Friendship.friend_id == user.id)
            ),
            Friendship.status == FriendshipStatus.ACCEPTED
        ).first()
        
        if not friendship:
            raise ValidationException("Can only view messages with friends")
        
        # 获取双方的消息
        query = self.db.query(Message).filter(
            ((Message.sender_id == user.id) & (Message.receiver_id == friend_id)) |
            ((Message.sender_id == friend_id) & (Message.receiver_id == user.id))
        )
        
        total = query.count()
        messages = query.order_by(Message.created_at.desc()).offset(params.skip).limit(params.size).all()
        
        # 标记未读消息为已读
        unread_messages = self.db.query(Message).filter(
            Message.sender_id == friend_id,
            Message.receiver_id == user.id,
            Message.is_read == False
        ).all()
        
        for msg in unread_messages:
            msg.is_read = True
            msg.status = MessageStatus.READ
            msg.read_at = datetime.utcnow()
        
        if unread_messages:
            self.db.commit()
            # 同步Redis未读计数
            total_unread = self.db.query(Message).filter(
                Message.receiver_id == user.id,
                Message.is_read == False
            ).count()
            await RedisService.set_unread_count(user.id, total_unread)
        
        return messages, total

    async def mark_all_as_read(self, user: User) -> int:
        """标记所有消息为已读"""
        updated_count = self.db.query(Message).filter(
            (Message.receiver_id == user.id),
            Message.is_read == False
        ).update({
            "is_read": True,
            "status": MessageStatus.READ,
            "read_at": datetime.utcnow()
        })
        
        if updated_count > 0:
            self.db.commit()
            await RedisService.set_unread_count(user.id, 0)
            
        return updated_count
