import json
from typing import Optional, Any
from app.db.database import get_redis
from app.models.message import Message
from app.core.logging import get_logger

logger = get_logger(__name__)

class RedisService:
    """Redis服务类，封装Redis操作"""
    
    @staticmethod
    async def publish_message(message: Message):
        """发布新消息通知"""
        try:
            redis = await get_redis()
            # 为接收者发布消息
            channel = f"user:{message.receiver_id}:messages"
            
            # 构建消息数据
            data = {
                "event": "new_message",
                "data": {
                    "id": message.id,
                    "sender_id": message.sender_id,
                    "receiver_id": message.receiver_id,
                    "title": message.title,
                    "content": message.content,
                    "message_type": message.message_type,
                    "created_at": message.created_at.isoformat() if message.created_at else None,
                    "pattern": message.pattern
                }
            }
            
            await redis.publish(channel, json.dumps(data))
            logger.info(f"Published message {message.id} to channel {channel}")
            
            # 同时也为发送者发布（用于多端同步）
            sender_channel = f"user:{message.sender_id}:messages"
            await redis.publish(sender_channel, json.dumps(data))
            
        except Exception as e:
            logger.error(f"Failed to publish message to Redis: {e}")

    @staticmethod
    async def cache_user_status(user_id: int, status: str, expire: int = 300):
        """缓存用户在线状态"""
        try:
            redis = await get_redis()
            key = f"user:{user_id}:status"
            await redis.set(key, status, ex=expire)
        except Exception as e:
            logger.error(f"Failed to cache user status: {e}")

    @staticmethod
    async def get_user_status(user_id: int) -> Optional[str]:
        """获取用户在线状态"""
        try:
            redis = await get_redis()
            key = f"user:{user_id}:status"
            return await redis.get(key)
        except Exception as e:
            logger.error(f"Failed to get user status: {e}")
            return None

    @staticmethod
    async def increment_unread_count(user_id: int):
        """增加未读消息计数"""
        try:
            redis = await get_redis()
            key = f"user:{user_id}:unread_count"
            await redis.incr(key)
        except Exception as e:
            logger.error(f"Failed to increment unread count: {e}")

    @staticmethod
    async def get_unread_count(user_id: int) -> int:
        """获取未读消息计数"""
        try:
            redis = await get_redis()
            key = f"user:{user_id}:unread_count"
            count = await redis.get(key)
            return int(count) if count else 0
        except Exception as e:
            logger.error(f"Failed to get unread count: {e}")
            return 0

    @staticmethod
    async def set_unread_count(user_id: int, count: int):
        """设置未读消息计数"""
        try:
            redis = await get_redis()
            key = f"user:{user_id}:unread_count"
            await redis.set(key, count)
        except Exception as e:
            logger.error(f"Failed to set unread count: {e}")

    @staticmethod
    async def reset_unread_count(user_id: int):
        """重置未读消息计数"""
        try:
            redis = await get_redis()
            key = f"user:{user_id}:unread_count"
            await redis.set(key, 0)
        except Exception as e:
            logger.error(f"Failed to reset unread count: {e}")
