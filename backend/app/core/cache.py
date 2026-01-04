import redis
from typing import Optional, Any
import json
from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

class RedisCache:
    _instance = None
    _client: Optional[redis.Redis] = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(RedisCache, cls).__new__(cls)
        return cls._instance

    @property
    def client(self) -> redis.Redis:
        if self._client is None:
            try:
                self._client = redis.from_url(
                    settings.REDIS_URL,
                    decode_responses=True,
                    socket_timeout=5.0
                )
                self._client.ping()
                logger.info("Redis connection established")
            except Exception as e:
                logger.error(f"Failed to connect to Redis: {e}")
                raise
        return self._client

    def get(self, key: str) -> Optional[Any]:
        try:
            data = self.client.get(key)
            if data:
                return json.loads(data)
            return None
        except Exception as e:
            logger.error(f"Redis get error for key {key}: {e}")
            return None

    def set(self, key: str, value: Any, timeout: int = 3600) -> bool:
        try:
            return self.client.setex(key, timeout, json.dumps(value))
        except Exception as e:
            logger.error(f"Redis set error for key {key}: {e}")
            return False

    def delete(self, key: str) -> bool:
        try:
            return bool(self.client.delete(key))
        except Exception as e:
            logger.error(f"Redis delete error for key {key}: {e}")
            return False

# Global instance
cache = RedisCache()
