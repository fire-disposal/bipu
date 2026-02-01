import random
from typing import Dict, Any
from .base import BaseDataProvider
from app.core.cache import cache

class FortuneProvider(BaseDataProvider):
    """运势数据提供者"""
    
    FORTUNE_LEVELS = ["大吉", "中吉", "小吉", "平", "凶"]
    LUCKY_COLORS = ["红色", "蓝色", "绿色", "金色", "紫色"]
    LUCKY_NUMBERS = [1, 3, 5, 7, 8, 9]

    def get_data(self, zodiac: str, **kwargs) -> Dict[str, Any]:
        cache_key = f"fortune:{zodiac}"
        
        cached_data = cache.get(cache_key)
        if cached_data:
            return cached_data
            
        data = self._fetch_from_api(zodiac)
        cache.set(cache_key, data, timeout=86400)  # 缓存24小时
        
        return data

    def _fetch_from_api(self, zodiac: str) -> Dict[str, Any]:
        return {
            "zodiac": zodiac,
            "overall": random.choice(self.FORTUNE_LEVELS),
            "love": random.randint(60, 100),
            "career": random.randint(60, 100),
            "wealth": random.randint(60, 100),
            "lucky_color": random.choice(self.LUCKY_COLORS),
            "lucky_number": random.choice(self.LUCKY_NUMBERS),
            "advice": "今日宜静不宜动，适合思考人生。"
        }
