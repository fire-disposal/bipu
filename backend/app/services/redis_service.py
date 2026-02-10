import json
import pickle
from typing import Optional, Any, Union
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

    # 通用缓存方法
    @staticmethod
    async def set_cache(key: str, value: Any, expire: Optional[int] = 3600) -> bool:
        """设置缓存"""
        try:
            redis = await get_redis()
            serialized_value = pickle.dumps(value) if not isinstance(value, (str, int, float)) else value
            await redis.set(key, serialized_value, ex=expire)
            return True
        except Exception as e:
            logger.error(f"Failed to set cache: {e}")
            return False

    @staticmethod
    async def get_cache(key: str) -> Optional[Any]:
        """获取缓存"""
        try:
            redis = await get_redis()
            value = await redis.get(key)
            if value is None:
                return None
            
            # 尝试反序列化，如果失败则返回原始值
            try:
                return pickle.loads(value) if isinstance(value, bytes) else value
            except:
                return value
        except Exception as e:
            logger.error(f"Failed to get cache: {e}")
            return None

    @staticmethod
    async def delete_cache(key: str) -> bool:
        """删除缓存"""
        try:
            redis = await get_redis()
            result = await redis.delete(key)
            return result > 0
        except Exception as e:
            logger.error(f"Failed to delete cache: {e}")
            return False

    @staticmethod
    async def cache_user_data(user_id: int, data: dict, expire: int = 1800) -> bool:
        """缓存用户数据"""
        try:
            key = f"user:{user_id}:data"
            return await RedisService.set_cache(key, data, expire)
        except Exception as e:
            logger.error(f"Failed to cache user data: {e}")
            return False

    @staticmethod
    async def get_cached_user_data(user_id: int) -> Optional[dict]:
        """获取缓存的用户数据"""
        try:
            key = f"user:{user_id}:data"
            return await RedisService.get_cache(key)
        except Exception as e:
            logger.error(f"Failed to get cached user data: {e}")
            return None

    @staticmethod
    async def cache_api_response(key: str, response: Any, expire: int = 600) -> bool:
        """缓存API响应"""
        try:
            return await RedisService.set_cache(key, response, expire)
        except Exception as e:
            logger.error(f"Failed to cache API response: {e}")
            return False

    @staticmethod
    async def get_cached_api_response(key: str) -> Optional[Any]:
        """获取缓存的API响应"""
        try:
            return await RedisService.get_cache(key)
        except Exception as e:
            logger.error(f"Failed to get cached API response: {e}")
            return None

    @staticmethod
    async def invalidate_user_cache(user_id: int):
        """使用户相关缓存失效"""
        try:
            redis = await get_redis()
            # 删除用户数据缓存
            await redis.delete(f"user:{user_id}:data")
            # 删除用户状态缓存
            await redis.delete(f"user:{user_id}:status")
            # 删除用户未读消息计数
            await redis.delete(f"user:{user_id}:unread_count")
        except Exception as e:
            logger.error(f"Failed to invalidate user cache: {e}")

    @staticmethod
    async def increment_counter(key: str, expire: Optional[int] = 3600) -> int:
        """增加计数器"""
        try:
            redis = await get_redis()
            value = await redis.incr(key)
            if expire:
                await redis.expire(key, expire)
            return value
        except Exception as e:
            logger.error(f"Failed to increment counter: {e}")
            return 0

    @staticmethod
    async def rate_limit(key: str, limit: int, window: int) -> tuple[bool, int]:
        """
        速率限制
        返回: (是否允许, 剩余次数)
        """
        try:
            redis = await get_redis()
            current = await redis.get(key)
            if current is None:
                await redis.setex(key, window, 1)
                return True, limit - 1
            else:
                current = int(current)
                if current >= limit:
                    ttl = await redis.ttl(key)
                    return False, 0
                else:
                    await redis.incr(key)
                    ttl = await redis.ttl(key)
                    remaining = limit - current - 1
                    return True, remaining
        except Exception as e:
            logger.error(f"Failed to check rate limit: {e}")
            return True, limit  # 发生错误时允许请求

    @staticmethod
    async def add_token_to_blacklist(token: str, expire: int) -> bool:
        """将令牌添加到黑名单"""
        try:
            redis = await get_redis()
            # 使用令牌作为键，值为1，设置过期时间为令牌的剩余有效期
            await redis.setex(f"blacklist:{token}", expire, "1")
            return True
        except Exception as e:
            logger.error(f"Failed to add token to blacklist: {e}")
            return False

    @staticmethod
    async def is_token_blacklisted(token: str) -> bool:
        """检查令牌是否在黑名单中"""
        try:
            redis = await get_redis()
            result = await redis.get(f"blacklist:{token}")
            return result is not None
        except Exception as e:
            logger.error(f"Failed to check token blacklist: {e}")
            return False
