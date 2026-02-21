"""BIPU机消息服务 - 可靠健壮的消息传递"""
from sqlalchemy.orm import Session
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from app.models.message import Message
from app.models.user import User
from app.models.service_account import ServiceAccount
from app.schemas.message import MessageCreate
from app.core.websocket import manager
from app.core.logging import get_logger
from app.core.user_utils import is_service_account

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
        1. 检查发送频率限制
        2. 验证接收者存在或为服务号
        3. 如果是普通用户消息，检查黑名单和隐私设置
        4. 决定消息类型
        5. 存入数据库
        6. 通过 WebSocket 推送（如果在线）
        """

        # 基本频率限制（防止滥用）
        recent_count = db.query(Message).filter(
            Message.sender_bipupu_id == sender.bipupu_id,
            Message.created_at >= datetime.now(datetime.timezone.utc) - timedelta(minutes=1)
        ).count()

        if recent_count > 30:  # 每分钟最多30条
            raise ValueError("发送频率过高，请稍后再试")

        # 决定消息类型：优先由发送方/内容决定
        # 规则：
        # - 如果发送者是服务号 => SYSTEM
        # - 否则如果包含音频相关信息（pattern 中含 audio/voice 字段） => VOICE
        # - 否则（无额外 pattern） => NORMAL
        sender_is_service = is_service_account(getattr(sender, "bipupu_id", ""))

        def _pattern_has_audio(pat: Optional[Dict[str, Any]]) -> bool:
            if not pat:
                return False
            keys = set(k.lower() for k in pat.keys())
            audio_keys = {"audio", "audio_url", "voice", "voice_url", "transcript", "audio_path"}
            return len(keys & audio_keys) > 0

        if sender_is_service:
            mt = "SYSTEM"
        elif _pattern_has_audio(message_data.pattern):
            mt = "VOICE"
        else:
            mt = "NORMAL"

        new_message = Message(
            sender_bipupu_id=sender.bipupu_id,
            receiver_bipupu_id=message_data.receiver_id,
            content=message_data.content,
            message_type=mt,
            pattern=message_data.pattern
        )

        # 如果是发往服务号，检查服务号是否存在
        if is_service_account(message_data.receiver_id):
            # 验证服务号是否存在
            service_account = db.query(ServiceAccount).filter(
                ServiceAccount.name == message_data.receiver_id
            ).first()

            if not service_account:
                raise ValueError(f"Service account '{message_data.receiver_id}' not found")

            # 检查服务号是否活跃
            if not service_account.is_active:
                logger.warning(f"Service account '{message_data.receiver_id}' is not active")
                # 仍然存储消息，但记录警告

            db.add(new_message)
            try:
                db.commit()
                db.refresh(new_message)
            except Exception:
                db.rollback()
                raise

            logger.info(f"Message to service stored: {sender.bipupu_id} -> {message_data.receiver_id}")

            # 尝试推送 WebSocket（服务号通常不会在线，但保留逻辑）
            await MessageService._push_to_websocket(new_message)
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
        try:
            db.commit()
            db.refresh(new_message)
        except Exception:
            db.rollback()
            raise

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
                "message_type": message.message_type if message.message_type else None,
                "pattern": message.pattern,
                "created_at": message.created_at.isoformat()
            }
        }

        success = await manager.send_personal_message(ws_message, str(message.receiver_bipupu_id))
        if success:
            logger.debug(f"Message pushed via WebSocket to {str(message.receiver_bipupu_id)}")
        else:
            logger.debug(f"User {str(message.receiver_bipupu_id)} offline, message stored for later retrieval")

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
        try:
            db.commit()
            return True
        except Exception:
            db.rollback()
            raise

        logger.info(f"Message {message_id} deleted by {user.bipupu_id}")
        return True
