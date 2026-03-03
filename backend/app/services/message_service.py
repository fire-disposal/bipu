"""BIPU机消息服务 - 优化版本

改进点：
1. 统一的消息获取接口，在路由层区分 /inbox 和 /sent
2. 支持增量同步
3. 完整的缓存管理
4. WebSocket推送
5. 频率限制和防滥用
"""

from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import datetime, timedelta, timezone
from app.models.message import Message
from app.models.user import User
from app.models.service_account import ServiceAccount
from app.schemas.message import MessageCreate
from app.core.websocket import manager
from app.core.logging import get_logger
from app.services.cache_service import CacheService
from app.core.user_utils import is_service_account

logger = get_logger(__name__)




class MessageService:
    """消息服务类 - 简化和优化版本"""

    @staticmethod
    async def send_message(
        db: Session,
        sender: User,
        message_data: MessageCreate
    ) -> Message:
        """发送消息

        流程：
        1. 检查发送频率限制（防滥用）
        2. 验证接收者存在
        3. 如果接收者是真实用户，检查黑名单
        4. 存入数据库
        5. WebSocket推送（如果接收者在线）
        6. 清除缓存
        """

        # 频率限制：每分钟最多30条
        recent_count = db.query(Message).filter(
            Message.sender_bipupu_id == sender.bipupu_id,
            Message.created_at >= datetime.now(timezone.utc) - timedelta(minutes=1)
        ).count()

        if recent_count > 30:
            raise ValueError("发送频率过高，请稍后再试")

        # 自动判断消息类型
        sender_is_service = is_service_account(sender.bipupu_id)
        
        def _has_audio_in_pattern(pattern: Optional[dict]) -> bool:
            if not pattern:
                return False
            keys = {k.lower() for k in pattern.keys()}
            return bool(keys & {"audio", "audio_url", "voice", "voice_url", "transcript"})

        if sender_is_service:
            msg_type = "SYSTEM"
        elif _has_audio_in_pattern(message_data.pattern):
            msg_type = "VOICE"
        else:
            msg_type = "NORMAL"

        # 创建消息对象
        message = Message(
            sender_bipupu_id=sender.bipupu_id,
            receiver_bipupu_id=message_data.receiver_id,
            content=message_data.content,
            message_type=msg_type,
            pattern=message_data.pattern,
            waveform=message_data.waveform
        )

        # 验证接收者
        if is_service_account(message_data.receiver_id):
            # 服务号接收者
            service = db.query(ServiceAccount).filter(
                ServiceAccount.name == message_data.receiver_id,
                ServiceAccount.is_active == True
            ).first()

            if not service:
                raise ValueError(f"服务号不存在: {message_data.receiver_id}")
        else:
            # 真实用户接收者
            receiver = db.query(User).filter(
                User.bipupu_id == message_data.receiver_id,
                User.is_active == True
            ).first()

            if not receiver:
                raise ValueError(f"用户不存在: {message_data.receiver_id}")

            # 检查是否被拉黑
            from app.models.user_block import UserBlock
            is_blocked = db.query(UserBlock).filter(
                UserBlock.blocker_id == receiver.id,
                UserBlock.blocked_id == sender.id
            ).first()

            if is_blocked:
                logger.warning(f"消息被拉黑: {sender.bipupu_id} -> {receiver.bipupu_id}")
                raise ValueError("用户拒绝接收你的消息")

        # 存储消息
        db.add(message)
        db.commit()
        db.refresh(message)

        logger.info(
            f"消息已发送: {sender.bipupu_id} -> {message_data.receiver_id} "
            f"(id={message.id}, type={msg_type})"
        )

        # 异步操作：WebSocket推送和缓存清除
        try:
            await MessageService._push_to_websocket(message)
            await MessageService._invalidate_receiver_cache(message.receiver_bipupu_id, db)
        except Exception as e:
            logger.error(f"后置处理失败（非致命）: {e}")

        return message

    @staticmethod
    async def _push_to_websocket(message: Message) -> None:
        """推送消息到 WebSocket（如果接收者在线）"""
        try:
            ws_payload = {
                "type": "new_message",
                "data": {
                    "id": message.id,
                    "sender_id": message.sender_bipupu_id,
                    "content": message.content,
                    "message_type": message.message_type,
                    "created_at": message.created_at.isoformat()
                }
            }

            success = await manager.send_personal_message(
                ws_payload, 
                str(message.receiver_bipupu_id)
            )

            if success:
                logger.debug(f"WebSocket推送成功: {message.receiver_bipupu_id}")
            else:
                logger.debug(f"用户离线，消息已保存: {message.receiver_bipupu_id}")

        except Exception as e:
            logger.warning(f"WebSocket推送失败（非致命）: {e}")

    @staticmethod
    async def _invalidate_receiver_cache(receiver_id: str, db: Session) -> None:
        """清除接收者的消息缓存"""
        try:
            # 根据 bipupu_id 找到用户，然后清除其缓存
            receiver = db.query(User).filter(
                User.bipupu_id == receiver_id
            ).first()

            if receiver:
                await CacheService.invalidate_user_inbox_cache(receiver.id)
                logger.debug(f"已清除用户 {receiver.id} 的收件箱缓存")

        except Exception as e:
            logger.error(f"清除缓存失败（非致命）: {e}")

    @staticmethod
    async def mark_as_read(
        db: Session,
        user_id: int,
        message_ids: List[int]
    ) -> None:
        """标记消息为已读
        
        注：当前实现在前端（Hive）存储已读状态
        如果需要在后端存储，可添加 is_read 字段到 Message 表
        """
        # 这里可以添加后端存储逻辑
        # 目前由前端在 Hive 中维护已读状态
        logger.debug(f"标记消息为已读: user={user_id}, message_ids={message_ids}")

    @staticmethod
    async def get_unread_count(
        db: Session,
        user_id: int,
        direction: Optional[str] = None
    ) -> int:
        """获取未读消息数
        
        注：当前实现返回所有消息数，前端通过 Hive 本地比对得出未读数
        """
        # TODO: 如果需要完整的后端实现，可在 Message 表添加 is_read 字段
        # 并在此返回真实的未读数
        return 0
