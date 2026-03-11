"""缓存服务 - 统一的缓存操作层（1C1G 优化版）

支持：
- 消息列表缓存（收件箱、发件箱）
- 缓存键生成
- 缓存失效管理
- 使用 SCAN 替代 KEYS（防止 Redis 阻塞）
"""

from typing import Optional
from app.db.redis import get_redis
from app.schemas.message import MessageListResponse
from app.core.logging import get_logger
import json

logger = get_logger(__name__)


class CacheService:
    """统一的缓存服务"""
    
    # 缓存 TTL 配置（1C1G 优化）
    DEFAULT_MESSAGE_TTL = 300  # 消息列表缓存 5 分钟
    DEFAULT_UNREAD_TTL = 60    # 未读计数缓存 1 分钟
    
    @staticmethod
    def generate_inbox_cache_key(user_id: int, page: int, page_size: int) -> str:
        """生成收件箱缓存键"""
        return f"inbox:user:{user_id}:page{page}:size{page_size}"
    
    @staticmethod
    def generate_sent_cache_key(user_id: int, page: int, page_size: int) -> str:
        """生成发件箱缓存键"""
        return f"sent:user:{user_id}:page{page}:size{page_size}"
    
    @staticmethod
    def generate_message_cache_key(user_id: int, page: int, page_size: int, 
                                   direction: str = "inbox") -> str:
        """生成消息列表缓存键"""
        if direction == "sent":
            return CacheService.generate_sent_cache_key(user_id, page, page_size)
        else:
            return CacheService.generate_inbox_cache_key(user_id, page, page_size)
    
    @staticmethod
    async def get_message_list(cache_key: str) -> Optional[MessageListResponse]:
        """从缓存获取消息列表"""
        try:
            redis = await get_redis()
            cached_data = await redis.get(cache_key)
            
            if not cached_data:
                return None
            
            # 反序列化
            data = json.loads(cached_data) if isinstance(cached_data, str) else cached_data
            return MessageListResponse.model_validate(data)
            
        except Exception as e:
            logger.error(f"获取缓存失败：{e}")
            return None
    
    @staticmethod
    async def set_message_list(cache_key: str, response: MessageListResponse, 
                               ttl: int = DEFAULT_MESSAGE_TTL) -> bool:
        """将消息列表缓存到 Redis"""
        try:
            redis = await get_redis()
            # 序列化为 JSON
            data = json.dumps(response.model_dump(mode='json'), default=str)
            # 存储到 Redis
            await redis.set(cache_key, data, ex=ttl)
            
            logger.debug(f"消息列表已缓存：{cache_key}, TTL={ttl}s")
            return True
            
        except Exception as e:
            logger.error(f"缓存消息列表失败：{e}")
            return False
    
    @staticmethod
    async def invalidate_user_message_cache(user_id: int) -> None:
        """清除用户的所有消息相关缓存 - 使用 SCAN 避免阻塞
        
        Args:
            user_id: 用户 ID
        """
        try:
            redis = await get_redis()
            pattern = f"*:user:{user_id}:*"
            
            # ✅ 使用 SCAN 迭代扫描（1C1G 下每次 50 个键）
            cursor = 0
            deleted_count = 0
            
            while True:
                cursor, keys = await redis.scan(
                    cursor=cursor,
                    match=pattern,
                    count=50
                )
                
                if keys:
                    await redis.delete(*keys)
                    deleted_count += len(keys)
                
                if cursor == 0:  # 扫描完成
                    break
            
            if deleted_count > 0:
                logger.debug(f"已清除用户 {user_id} 的消息缓存，共 {deleted_count} 个")
                
        except Exception as e:
            logger.error(f"清除用户缓存失败：{e}")
    
    @staticmethod
    async def invalidate_message_cache(cache_key: str) -> bool:
        """清除指定的消息缓存"""
        try:
            redis = await get_redis()
            result = await redis.delete(cache_key)
            
            if result > 0:
                logger.debug(f"已清除缓存：{cache_key}")
            return result > 0
            
        except Exception as e:
            logger.error(f"清除缓存失败：{e}")
            return False
    
    @staticmethod
    async def invalidate_user_inbox_cache(user_id: int) -> None:
        """清除用户的收件箱缓存 - 使用 SCAN 避免阻塞"""
        try:
            redis = await get_redis()
            pattern = f"inbox:user:{user_id}:*"
            
            # ✅ 使用 SCAN 迭代扫描
            cursor = 0
            deleted_count = 0
            
            while True:
                cursor, keys = await redis.scan(
                    cursor=cursor,
                    match=pattern,
                    count=50
                )
                
                if keys:
                    await redis.delete(*keys)
                    deleted_count += len(keys)
                
                if cursor == 0:
                    break
            
            if deleted_count > 0:
                logger.debug(f"已清除用户 {user_id} 的收件箱缓存")
                
        except Exception as e:
            logger.error(f"清除收件箱缓存失败：{e}")
    
    @staticmethod
    async def invalidate_unread_cache(user_id: int) -> None:
        """清除用户的未读计数缓存"""
        try:
            redis = await get_redis()
            cache_key = f"unread:user:{user_id}"
            await redis.delete(cache_key)
            logger.debug(f"已清除用户 {user_id} 的未读计数缓存")
            
        except Exception as e:
            logger.error(f"清除未读计数缓存失败：{e}")
