"""消息服务 - 重构版本"""
from sqlalchemy.orm import Session
from typing import Optional, List
from app.models.message import Message
from app.models.user import User
from app.schemas.message_new import MessageCreate
from app.core.websocket import manager
from app.core.logging import get_logger
from app.core.user_utils import is_service_account
from app.services.service_accounts import handle_service_message

logger = get_logger(__name__)


class MessageService:
    """消息服务类"""
    
    @staticmethod
    async def send_message(
        db: Session,
        sender: User,
        message_data: MessageCreate
    ) -> Message:
        """发送消息
        
        流程：
        1. 验证接收者存在或为服务号
        2. 检查黑名单
        3. 检查隐私设置（仅联系人可发消息）
        4. 存入数据库
        5. 如果是服务号消息，调用处理器
        6. 如果是普通消息，通过 WebSocket 推送（如果在线）
        """
        
        # 创建消息对象（不立即存入DB）
        new_message = Message(
            sender_bipupu_id=sender.bipupu_id,
            receiver_bipupu_id=message_data.receiver_id,
            content=message_data.content,
            msg_type=message_data.msg_type,
            pattern=message_data.pattern
        )
        
        # 如果是发往服务号
        if is_service_account(message_data.receiver_id):
            db.add(new_message)
            db.commit()
            db.refresh(new_message)
            await handle_service_message(db, sender, new_message)
            return new_message

        # --- 以下是普通用户间消息 ---
        
        # 查找接收者
        receiver = db.query(User).filter(User.bipupu_id == message_data.receiver_id).first()
        if not receiver:
            raise ValueError("Receiver not found")
        
        # 检查是否被拉黑
        from app.models.user_block import UserBlock
        is_blocked = db.query(UserBlock).filter(
            UserBlock.blocker_id == receiver.id,
            UserBlock.blocked_id == sender.id
        ).first()
        
        if is_blocked:
            # 静默丢弃消息，不告知发送者
            logger.info(f"Message blocked: {sender.bipupu_id} -> {receiver.bipupu_id}")
            raise ValueError("Cannot send message to this user")
        
        # TODO: 检查隐私设置（是否只接收联系人消息）
        # 这里可以扩展，根据用户设置决定是否允许非联系人发消息
        
        db.add(new_message)
        db.commit()
        db.refresh(new_message)
        
        logger.info(f"Message sent: {sender.bipupu_id} -> {receiver.bipupu_id}")
        
        # 推送到 WebSocket（如果接收者在线）
        await MessageService._push_to_websocket(new_message)
        
        return new_message
    
    @staticmethod
    async def _push_to_websocket(message: Message):
        """推送消息到 WebSocket"""
        ws_message = {
            "type": "new_message",
            "payload": {
                "id": message.id,
                "sender_id": message.sender_bipupu_id,
                "content": message.content,
                "msg_type": message.msg_type,
                "pattern": message.pattern,
                "created_at": message.created_at.isoformat()
            }
        }
        
        success = await manager.send_personal_message(ws_message, message.receiver_bipupu_id)
        if success:
            logger.debug(f"Message pushed via WebSocket to {message.receiver_bipupu_id}")
        else:
            logger.debug(f"User {message.receiver_bipupu_id} offline, message stored for later retrieval")
    
    @staticmethod
    def get_received_messages(
        db: Session,
        user: User,
        page: int = 1,
        page_size: int = 20
    ) -> tuple[List[Message], int]:
        """获取接收的消息"""
        query = db.query(Message).filter(
            Message.receiver_bipupu_id == user.bipupu_id
        ).order_by(Message.created_at.desc())
        
        total = query.count()
        messages = query.offset((page - 1) * page_size).limit(page_size).all()
        
        return messages, total
    
    @staticmethod
    def get_sent_messages(
        db: Session,
        user: User,
        page: int = 1,
        page_size: int = 20
    ) -> tuple[List[Message], int]:
        """获取发送的消息"""
        query = db.query(Message).filter(
            Message.sender_bipupu_id == user.bipupu_id
        ).order_by(Message.created_at.desc())
        
        total = query.count()
        messages = query.offset((page - 1) * page_size).limit(page_size).all()
        
        return messages, total
    
    @staticmethod
    def delete_message(db: Session, message_id: int, user: User) -> bool:
        """删除消息（只能删除自己接收的消息）"""
        message = db.query(Message).filter(
            Message.id == message_id,
            Message.receiver_bipupu_id == user.bipupu_id
        ).first()
        
        if not message:
            return False
        
        db.delete(message)
        db.commit()
        
        logger.info(f"Message {message_id} deleted by {user.bipupu_id}")
        return True
