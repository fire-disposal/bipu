"""Token 管理工具 - 统一处理 Token 的黑名单和生命周期

提供以下功能：
1. 统一的 Token 黑名单处理
2. Token 过期时间计算
3. Token 有效性验证
"""

import time
from typing import Dict, Any, Optional
from app.core.logging import get_logger
from app.core.security import decode_token
from app.services.redis_service import RedisService

logger = get_logger(__name__)


class TokenUtils:
    """Token 工具类"""

    @staticmethod
    async def blacklist_token(token: str) -> bool:
        """将 Token 加入黑名单
        
        参数：
        - token: JWT 令牌
        
        返回：
        - 成功返回 True，失败返回 False
        
        说明：
        - 自动计算 TTL（剩余有效期）
        - 使用 Redis 存储黑名单
        - 过期时间自动清除
        """
        try:
            payload = decode_token(token)
            if not payload:
                logger.warning("无法解码令牌")
                return False

            # 计算正确的 TTL（剩余有效期）
            token_exp = payload.get("exp", 0)  # Unix 时间戳（秒）
            current_timestamp = int(time.time())
            ttl = max(0, token_exp - current_timestamp)

            # 将令牌加入黑名单
            await RedisService.add_token_to_blacklist(token, ttl)
            logger.info(f"令牌已加入黑名单，TTL={ttl}秒")
            return True

        except Exception as e:
            logger.error(f"加入黑名单失败: {e}")
            return False

    @staticmethod
    async def is_token_blacklisted(token: str) -> bool:
        """检查 Token 是否在黑名单中
        
        参数：
        - token: JWT 令牌
        
        返回：
        - 在黑名单中返回 True，否则返回 False
        """
        try:
            return await RedisService.is_token_blacklisted(token)
        except Exception as e:
            logger.error(f"检查黑名单失败: {e}")
            return False

    @staticmethod
    def get_token_remaining_time(token: str) -> Optional[int]:
        """获取 Token 剩余有效期（秒）
        
        参数：
        - token: JWT 令牌
        
        返回：
        - 剩余秒数，如果无效返回 None
        """
        try:
            payload = decode_token(token)
            if not payload:
                return None

            token_exp = payload.get("exp", 0)
            current_timestamp = int(time.time())
            remaining = token_exp - current_timestamp

            return max(0, remaining)

        except Exception as e:
            logger.error(f"获取剩余时间失败: {e}")
            return None

    @staticmethod
    def is_token_expired(token: str) -> bool:
        """检查 Token 是否已过期
        
        参数：
        - token: JWT 令牌
        
        返回：
        - 已过期返回 True，未过期返回 False
        """
        remaining_time = TokenUtils.get_token_remaining_time(token)
        return remaining_time is None or remaining_time <= 0

    @staticmethod
    def get_token_payload(token: str) -> Optional[Dict[str, Any]]:
        """获取 Token 的载荷（payload）
        
        参数：
        - token: JWT 令牌
        
        返回：
        - Token 载荷字典，如果无效返回 None
        """
        try:
            return decode_token(token)
        except Exception as e:
            logger.error(f"解码令牌失败: {e}")
            return None
