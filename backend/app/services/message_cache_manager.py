"""消息缓存管理器 - 统一处理消息列表的缓存操作"""

from typing import Optional, List, Dict, Any
from app.services.redis_service import RedisService
from app.core.logging import get_logger

logger = get_logger(__name__)


class MessageCacheManager:
    """消息缓存管理器 - 封装消息相关的缓存操作"""
    
    # 缓存配置
    MESSAGE_CACHE_EXPIRE = 300  # 消息列表缓存5分钟
    FAVORITE_CACHE_EXPIRE = 600  # 收藏消息缓存10分钟
    SERVICE_CACHE_EXPIRE = 86400  # 服务号信息缓存24小时
    
    @staticmethod
    def make_message_cache_key(user_id: int, direction: str, page: int, page_size: int) -> str:
        """构造消息缓存key
        
        Args:
            user_id: 用户ID
            direction: 方向 ('received', 'sent')
            page: 页码
            page_size: 每页数量
        """
        return f"user:{user_id}:messages:{direction}:p{page}:ps{page_size}"
    
    @staticmethod
    def make_favorites_cache_key(user_id: int, page: int, page_size: int) -> str:
        """构造收藏消息缓存key"""
        return f"user:{user_id}:favorites:p{page}:ps{page_size}"
    
    @staticmethod
    def make_service_info_cache_key(service_name: str) -> str:
        """构造服务号信息缓存key"""
        return f"service:{service_name}:info"
    
    @staticmethod
    async def get_messages_from_cache(
        user_id: int,
        direction: str,
        page: int,
        page_size: int,
    ) -> Optional[Dict[str, Any]]:
        """从缓存获取消息列表
        
        Returns:
            {
                'messages': [消息数据],
                'total': 总数,
                'timestamp': 缓存时间戳
            }
        """
        cache_key = MessageCacheManager.make_message_cache_key(
            user_id, direction, page, page_size
        )
        cached_data = await RedisService.get_cache_json(cache_key)
        
        if cached_data:
            logger.debug(f"Message cache hit: {cache_key}")
        
        return cached_data
    
    @staticmethod
    async def set_messages_cache(
        user_id: int,
        direction: str,
        page: int,
        page_size: int,
        messages: List[Dict[str, Any]],
        total: int,
    ) -> bool:
        """将消息列表存入缓存"""
        cache_key = MessageCacheManager.make_message_cache_key(
            user_id, direction, page, page_size
        )
        
        from datetime import datetime, timezone
        cache_data = {
            'messages': messages,
            'total': total,
            'timestamp': datetime.now(timezone.utc).isoformat(),
        }
        
        success = await RedisService.set_cache_json(
            cache_key,
            cache_data,
            expire=MessageCacheManager.MESSAGE_CACHE_EXPIRE,
        )
        
        if success:
            logger.debug(f"Message cache set: {cache_key}")
        
        return success
    
    @staticmethod
    async def get_favorites_from_cache(
        user_id: int,
        page: int,
        page_size: int,
    ) -> Optional[Dict[str, Any]]:
        """从缓存获取收藏消息"""
        cache_key = MessageCacheManager.make_favorites_cache_key(user_id, page, page_size)
        return await RedisService.get_cache_json(cache_key)
    
    @staticmethod
    async def set_favorites_cache(
        user_id: int,
        page: int,
        page_size: int,
        favorites: List[Dict[str, Any]],
        total: int,
    ) -> bool:
        """将收藏消息存入缓存"""
        cache_key = MessageCacheManager.make_favorites_cache_key(user_id, page, page_size)
        
        from datetime import datetime, timezone
        cache_data = {
            'favorites': favorites,
            'total': total,
            'timestamp': datetime.now(timezone.utc).isoformat(),
        }
        
        return await RedisService.set_cache_json(
            cache_key,
            cache_data,
            expire=MessageCacheManager.FAVORITE_CACHE_EXPIRE,
        )
    
    @staticmethod
    async def get_service_info_from_cache(service_name: str) -> Optional[Dict[str, Any]]:
        """从缓存获取服务号信息"""
        cache_key = MessageCacheManager.make_service_info_cache_key(service_name)
        return await RedisService.get_cache_json(cache_key)
    
    @staticmethod
    async def set_service_info_cache(
        service_name: str,
        service_info: Dict[str, Any],
    ) -> bool:
        """将服务号信息存入缓存"""
        cache_key = MessageCacheManager.make_service_info_cache_key(service_name)
        return await RedisService.set_cache_json(
            cache_key,
            service_info,
            expire=MessageCacheManager.SERVICE_CACHE_EXPIRE,
        )
    
    @staticmethod
    async def invalidate_message_cache(user_id: int, direction: Optional[str] = None) -> int:
        """失效消息缓存
        
        Args:
            user_id: 用户ID
            direction: 方向，如果为None则失效所有方向的消息缓存
        """
        if direction:
            pattern = f"user:{user_id}:messages:{direction}:*"
        else:
            pattern = f"user:{user_id}:messages:*"
        
        deleted_count = await RedisService.delete_keys_by_pattern(pattern)
        
        if deleted_count > 0:
            logger.info(f"Invalidated {deleted_count} message caches for user {user_id}")
        
        return deleted_count
    
    @staticmethod
    async def invalidate_favorites_cache(user_id: int) -> int:
        """失效用户的所有收藏缓存"""
        pattern = f"user:{user_id}:favorites:*"
        return await RedisService.delete_keys_by_pattern(pattern)
    
    @staticmethod
    async def invalidate_service_cache(service_name: Optional[str] = None) -> int:
        """失效服务号缓存"""
        if service_name:
            pattern = f"service:{service_name}:info"
        else:
            pattern = "service:*:info"
        
        return await RedisService.delete_keys_by_pattern(pattern)
