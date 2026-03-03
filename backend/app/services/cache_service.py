"""缓存服务 - 统一的缓存操作层

支持：
- 消息列表缓存（收件箱、发件箱）
- 缓存键生成
- 缓存失效管理
"""

from typing import Optional
from app.db.database import get_redis
from app.schemas.message import MessageListResponse
from app.core.logging import get_logger
import json

logger = get_logger(__name__)


class CacheService:
    """统一的缓存服务"""
    
    # 缓存TTL配置
    DEFAULT_MESSAGE_TTL = 300  # 消息列表缓存5分钟
    DEFAULT_UNREAD_TTL = 60    # 未读计数缓存1分钟
    
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
        """生成消息列表缓存键
        
        Args:
            user_id: 用户ID
            page: 页码
            page_size: 每页数量
            direction: 方向（inbox/sent）
        """
        if direction == "sent":
            return CacheService.generate_sent_cache_key(user_id, page, page_size)
        else:
            return CacheService.generate_inbox_cache_key(user_id, page, page_size)
    
    @staticmethod
    async def get_message_list(cache_key: str) -> Optional[MessageListResponse]:
        """从缓存获取消息列表
        
        Args:
            cache_key: 缓存键
            
        Returns:
            MessageListResponse 或 None（如果缓存未命中）
        """
        try:
            redis = await get_redis()
            cached_data = await redis.get(cache_key)
            
            if not cached_data:
                return None
            
            # 反序列化
            data = json.loads(cached_data) if isinstance(cached_data, str) else cached_data
            return MessageListResponse.model_validate(data)
            
        except Exception as e:
            logger.error(f"获取缓存失败: {e}")
            return None
    
    @staticmethod
    async def set_message_list(cache_key: str, response: MessageListResponse, 
                               ttl: int = DEFAULT_MESSAGE_TTL) -> bool:
        """将消息列表缓存到Redis
        
        Args:
            cache_key: 缓存键
            response: 消息列表响应
            ttl: 缓存过期时间（秒）
            
        Returns:
            是否成功缓存
        """
        try:
            redis = await get_redis()
            # 序列化为JSON
            data = json.dumps(response.model_dump(mode='json'), default=str)
            # 存储到Redis
            await redis.set(cache_key, data, ex=ttl)
            
            logger.debug(f"消息列表已缓存: {cache_key}, TTL={ttl}s")
            return True
            
        except Exception as e:
            logger.error(f"缓存消息列表失败: {e}")
            return False
    
    @staticmethod
    async def invalidate_user_message_cache(user_id: int) -> None:
        """清除用户的所有消息相关缓存
        
        Args:
            user_id: 用户ID
        """
        try:
            redis = await get_redis()
            # 删除所有与该用户相关的消息缓存
            pattern = f"*:user:{user_id}:*"
            keys = await redis.keys(pattern)
            
            if keys:
                await redis.delete(*keys)
                logger.debug(f"已清除用户 {user_id} 的消息缓存，共 {len(keys)} 个")
                
        except Exception as e:
            logger.error(f"清除用户缓存失败: {e}")
    
    @staticmethod
    async def invalidate_message_cache(cache_key: str) -> bool:
        """清除指定的消息缓存
        
        Args:
            cache_key: 缓存键
            
        Returns:
            是否成功清除
        """
        try:
            redis = await get_redis()
            result = await redis.delete(cache_key)
            
            if result > 0:
                logger.debug(f"已清除缓存: {cache_key}")
            return result > 0
            
        except Exception as e:
            logger.error(f"清除缓存失败: {e}")
            return False
    
    @staticmethod
    async def invalidate_user_inbox_cache(user_id: int) -> None:
        """清除用户的收件箱缓存
        
        Args:
            user_id: 用户ID
        """
        try:
            redis = await get_redis()
            pattern = f"inbox:user:{user_id}:*"
            keys = await redis.keys(pattern)
            
            if keys:
                await redis.delete(*keys)
                logger.debug(f"已清除用户 {user_id} 的收件箱缓存")
                
        except Exception as e:
            logger.error(f"清除收件箱缓存失败: {e}")
    
    @staticmethod
    async def invalidate_unread_cache(user_id: int) -> None:
        """清除用户的未读计数缓存
        
        Args:
            user_id: 用户ID
        """
        try:
            redis = await get_redis()
            cache_key = f"unread:user:{user_id}"
            await redis.delete(cache_key)
            logger.debug(f"已清除用户 {user_id} 的未读计数缓存")
            
        except Exception as e:
            logger.error(f"清除未读计数缓存失败: {e}")

