from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from app.models.subscription import UserSubscription
from app.services.subscriptions.providers.weather import WeatherProvider
from .base import BaseSubscriptionHandler

class WeatherSubscriptionHandler(BaseSubscriptionHandler):
    def __init__(self):
        super().__init__("weather")
        self.provider = WeatherProvider()

    def generate_message_data(self, user_id: int, subscription: UserSubscription, db: Session) -> Optional[Dict[str, Any]]:
        # 1. 获取用户配置
        settings = subscription.custom_settings or {}
        city = settings.get("city", "北京")
        
        # 2. 获取数据
        weather_data = self.provider.get_data(city)
        
        # 3. 组装消息
        # 参考 Message 模型结构
        return {
            "title": f"{city}今日天气 - {weather_data['condition']}",
            "content": (
                f"当前温度: {weather_data['temperature']}℃\n"
                f"风向: {weather_data['wind_direction']} {weather_data['wind_speed']}级\n"
                f"湿度: {weather_data['humidity']}%\n"
                f"紫外线指数: {weather_data['uv_index']}"
            ),
            "pattern": {
                "type": "weather",
                "data": weather_data,
                "display_mode": "card"
            },
            "category": "weather"
        }
