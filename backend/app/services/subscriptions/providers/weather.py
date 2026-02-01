import random
from typing import Dict, Any
from .base import BaseDataProvider
from app.core.cache import cache

class WeatherProvider(BaseDataProvider):
    """天气数据提供者"""
    
    # 模拟数据
    WEATHER_CONDITIONS = ["晴天", "多云", "阴天", "小雨", "中雨", "雷阵雨"]
    TEMPERATURES = [15, 18, 20, 22, 25, 28, 30, 32]
    WIND_DIRECTIONS = ["东风", "南风", "西风", "北风", "东南风", "西南风", "西北风", "东北风"]

    def get_data(self, city: str, **kwargs) -> Dict[str, Any]:
        cache_key = f"weather:{city}"
        
        cached_data = cache.get(cache_key)
        if cached_data:
            return cached_data
        
        data = self._fetch_from_api(city)
        cache.set(cache_key, data, timeout=1800)  # 缓存30分钟
        
        return data

    def _fetch_from_api(self, city: str) -> Dict[str, Any]:
        """模拟从第三方 API 获取数据"""
        return {
            "city": city,
            "condition": random.choice(self.WEATHER_CONDITIONS),
            "temperature": random.choice(self.TEMPERATURES),
            "wind_direction": random.choice(self.WIND_DIRECTIONS),
            "wind_speed": random.randint(1, 5),
            "humidity": random.randint(40, 80),
            "uv_index": random.randint(3, 8)
        }
