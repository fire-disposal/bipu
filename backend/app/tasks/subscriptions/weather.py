"""天气订阅处理器"""
import random
from typing import Dict, Any
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.subscription import UserSubscription
from .base import BaseSubscriptionHandler


class WeatherSubscriptionHandler(BaseSubscriptionHandler):
    """天气订阅处理器
    
    负责生成和发送天气推送消息。
    """
    
    # 天气情况
    WEATHER_CONDITIONS = ["晴天", "多云", "阴天", "小雨", "中雨", "雷阵雨"]
    # 温度范围（摄氏度）
    TEMPERATURES = [15, 18, 20, 22, 25, 28, 30, 32]
    # 风向
    WIND_DIRECTIONS = ["东风", "南风", "西风", "北风", "东南风", "西南风", "西北风", "东北风"]
    
    def __init__(self):
        """初始化天气订阅处理器"""
        super().__init__("天气推送")
    
    def generate_message_data(
        self,
        user_id: int,
        subscription: UserSubscription,
        db: Session
    ) -> Dict[str, Any]:
        """生成天气消息数据
        
        Args:
            user_id: 用户 ID
            subscription: 用户订阅对象
            db: 数据库会话
            
        Returns:
            dict: 消息数据
        """
        # 生成模拟天气数据
        weather_data = {
            "condition": random.choice(self.WEATHER_CONDITIONS),
            "temperature": random.choice(self.TEMPERATURES),
            "wind_direction": random.choice(self.WIND_DIRECTIONS),
            "wind_speed": random.randint(1, 5),
            "humidity": random.randint(40, 80),
            "uv_index": random.randint(3, 8)
        }
        
        # 构建消息标题
        title = f"今日天气 - {weather_data['condition']}"
        
        # 构建消息内容
        content = self._build_content(weather_data)
        
        # 根据天气数据设置 RGB 颜色
        rgb = self._calculate_rgb(weather_data)
        
        # 根据紫外线指数设置振动
        vibe = {
            "intensity": min(weather_data['uv_index'] * 10, 80),
            "duration": 2000
        }
        
        return {
            "title": title,
            "content": content,
            "priority": 3,
            "pattern": {
                "weather_data": weather_data,
                "rgb": rgb,
                "vibe": vibe
            }
        }
    
    @staticmethod
    def _build_content(weather_data: Dict[str, Any]) -> str:
        """构建消息内容
        
        Args:
            weather_data: 天气数据
            
        Returns:
            str: 消息内容
        """
        return f"""今日天气概况：
🌤️ 天气状况：{weather_data['condition']}
🌡️ 当前温度：{weather_data['temperature']}°C
💨 风向风速：{weather_data['wind_direction']} {weather_data['wind_speed']}级
💧 湿度：{weather_data['humidity']}%
☀️ 紫外线指数：{weather_data['uv_index']}

温馨提示：根据今日天气情况，建议适当增减衣物，注意防晒或携带雨具。"""
    
    @staticmethod
    def _calculate_rgb(weather_data: Dict[str, Any]) -> Dict[str, int]:
        """根据天气数据计算 RGB 颜色
        
        Args:
            weather_data: 天气数据
            
        Returns:
            dict: RGB 颜色字典 {"r": int, "g": int, "b": int}
        """
        temperature = weather_data['temperature']
        condition = weather_data['condition']
        
        # 温度越高，红色越深
        r = 135 if temperature > 25 else 70
        # 晴天绿色更深
        g = 206 if condition == "晴天" else 130
        # 晴天蓝色更深
        b = 235 if condition == "晴天" else 180
        
        return {"r": r, "g": g, "b": b}
