import json
import pickle
from typing import Optional, Any, Union
from app.db.redis import get_redis
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
            # 为接收者发布消息（使用 bipupu_id 作为 channel 识别）
            channel = f"user:{message.receiver_bipupu_id}:messages"

            # 构建消息数据
            data = {
                "event": "new_message",
                "data": {
                    "id": message.id,
                    "sender_id": message.sender_bipupu_id,
                    "receiver_id": message.receiver_bipupu_id,
                    "content": message.content,
                    "message_type": str(message.message_type) if message.message_type is not None else None,
                    "created_at": message.created_at.isoformat() if message.created_at is not None else None,
                    "pattern": message.pattern
                }
            }

            await redis.publish(channel, json.dumps(data))
            logger.info(f"Published message {message.id} to channel {channel}")

            # 同时也为发送者发布（用于多端同步）
            sender_channel = f"user:{message.sender_bipupu_id}:messages"
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
            # 确保 expire > 0，防止 Redis setex 失败
            if expire <= 0:
                expire = 60  # 默认 60 秒
            await redis.setex(f"blacklist:{token}", expire, "1")
            return True
        except Exception as e:
            logger.error(f"Failed to add token to blacklist: {e}")
            return False  # 失败时返回 False，但不阻断流程
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

    @staticmethod
    async def delete_keys_by_pattern(pattern: str) -> int:
        """按模式删除多个key（使用SCAN迭代，避免阻塞）

        用途: 缓存失效时按pattern删除多个相关key
        示例: delete_keys_by_pattern("user:123:messages:*")
        """
        try:
            redis = await get_redis()
            deleted_count = 0
            cursor = 0

            while True:
                cursor, keys = await redis.scan(cursor, match=pattern, count=100)
                if keys:
                    deleted_count += await redis.delete(*keys)
                if cursor == 0:
                    break

            if deleted_count > 0:
                logger.debug(f"Deleted {deleted_count} keys matching pattern {pattern}")
            return deleted_count
        except Exception as e:
            logger.error(f"Failed to delete keys by pattern {pattern}: {e}")
            return 0

    @staticmethod
    async def set_cache_json(key: str, obj: Any, expire: int = 3600) -> bool:
        """设置缓存（JSON序列化）- 用于消息列表等复杂对象"""
        try:
            redis = await get_redis()
            serialized = json.dumps(obj, default=str)
            await redis.setex(key, expire, serialized)
            return True
        except Exception as e:
            logger.error(f"Failed to set JSON cache {key}: {e}")
            return False

    @staticmethod
    async def get_cache_json(key: str) -> Optional[Any]:
        """获取缓存（JSON反序列化）"""
        try:
            redis = await get_redis()
            value = await redis.get(key)
            if value:
                if isinstance(value, bytes):
                    value = value.decode('utf-8')
                return json.loads(value)
            return None
        except Exception as e:
            logger.error(f"Failed to get JSON cache {key}: {e}")
            return None
