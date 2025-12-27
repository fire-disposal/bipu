"""今日运势订阅处理器"""
import random
from typing import Dict, Any
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.subscription import UserSubscription
from .base import BaseSubscriptionHandler


class FortuneSubscriptionHandler(BaseSubscriptionHandler):
    """今日运势订阅处理器
    
    负责生成和发送今日运势消息。
    """
    
    # 运势方面
    FORTUNE_ASPECTS = ["爱情", "事业", "财运", "健康", "人际关系"]
    # 运势等级
    FORTUNE_LEVELS = ["大吉", "中吉", "小吉", "平", "小凶", "大凶"]
    # 幸运颜色
    LUCKY_COLORS = ["红色", "蓝色", "绿色", "黄色", "紫色", "白色", "黑色"]
    # 幸运数字
    LUCKY_NUMBERS = [1, 3, 5, 6, 7, 8, 9]
    # 十二生肖
    ZODIAC_ANIMALS = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
    # 西方星座
    WESTERN_ZODIAC = [
        "白羊座", "金牛座", "双子座", "巨蟹座", "狮子座", "处女座",
        "天秤座", "天蝎座", "射手座", "摩羯座", "水瓶座", "双鱼座"
    ]
    
    def __init__(self):
        """初始化运势订阅处理器"""
        super().__init__("今日运势")
    
    def generate_message_data(
        self,
        user_id: int,
        subscription: UserSubscription,
        db: Session
    ) -> Dict[str, Any]:
        """生成运势消息数据
        
        Args:
            user_id: 用户 ID
            subscription: 用户订阅对象
            db: 数据库会话
            
        Returns:
            dict: 消息数据
            
        Raises:
            ValueError: 如果用户不存在
        """
        # 获取用户信息
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError(f"用户 {user_id} 不存在")
        
        # 生成运势数据
        fortune_data = {
            "overall": random.choice(self.FORTUNE_LEVELS),
            "aspects": {},
            "lucky_color": random.choice(self.LUCKY_COLORS),
            "lucky_number": random.choice(self.LUCKY_NUMBERS),
            "lucky_zodiac": random.choice(self.ZODIAC_ANIMALS)
        }
        
        # 为每个方面生成运势
        for aspect in random.sample(self.FORTUNE_ASPECTS, 3):
            fortune_data["aspects"][aspect] = random.choice(self.FORTUNE_LEVELS)
        
        # 生成建议
        fortune_data["advice"] = self._generate_advice(fortune_data["overall"])
        
        # 获取用户星座
        user_zodiac = user.zodiac_sign or random.choice(self.WESTERN_ZODIAC)
        
        # 构建消息标题
        title = f"今日运势 - {user_zodiac}"
        
        # 构建消息内容
        content = self._build_content(user, user_zodiac, fortune_data)
        
        # 根据运势等级设置 RGB 颜色
        rgb = self._calculate_rgb(fortune_data["overall"])
        
        # 设置振动
        vibe = {
            "intensity": random.randint(20, 60),
            "duration": 1500
        }
        
        return {
            "title": title,
            "content": content,
            "priority": 4,
            "pattern": {
                "fortune_data": fortune_data,
                "zodiac_sign": user_zodiac,
                "rgb": rgb,
                "vibe": vibe
            }
        }
    
    @staticmethod
    def _build_content(user: User, zodiac: str, fortune_data: Dict[str, Any]) -> str:
        """构建消息内容
        
        Args:
            user: 用户对象
            zodiac: 星座
            fortune_data: 运势数据
            
        Returns:
            str: 消息内容
        """
        user_name = user.nickname or user.username
        aspects_text = "\n".join([
            f"• {aspect}：{level}" for aspect, level in fortune_data['aspects'].items()
        ])
        
        return f"""亲爱的 {user_name}，

今日您的整体运势：{fortune_data['overall']}

📊 各方面运势：
{aspects_text}

🌈 幸运颜色：{fortune_data['lucky_color']}
🔢 幸运数字：{fortune_data['lucky_number']}
🐾 贵人属相：{fortune_data['lucky_zodiac']}

💡 今日建议：{fortune_data['advice']}

愿您今日一切顺利！✨"""
    
    @staticmethod
    def _generate_advice(fortune_level: str) -> str:
        """根据运势等级生成建议
        
        Args:
            fortune_level: 运势等级
            
        Returns:
            str: 建议文本
        """
        advice_map = {
            "大吉": "今日运势不错，适合主动出击，把握机会！",
            "中吉": "运势良好，继续保持积极心态，好运继续！",
            "小吉": "运势平稳，保持积极心态，好事自然来。",
            "平": "今日宜静不宜动，适合思考和规划。",
            "小凶": "今日需谨慎行事，避免重大决策。",
            "大凶": "今日建议低调行动，等待时机。"
        }
        return advice_map.get(fortune_level, "祝您今日好运！")
    
    @staticmethod
    def _calculate_rgb(fortune_level: str) -> Dict[str, int]:
        """根据运势等级计算 RGB 颜色
        
        Args:
            fortune_level: 运势等级
            
        Returns:
            dict: RGB 颜色字典 {"r": int, "g": int, "b": int}
        """
        if fortune_level in ["大吉", "中吉"]:
            # 吉利：金色系
            return {"r": 255, "g": 215, "b": 0}
        elif fortune_level in ["小吉"]:
            # 小吉：绿色系
            return {"r": 100, "g": 200, "b": 100}
        elif fortune_level == "平":
            # 平：蓝色系
            return {"r": 100, "g": 150, "b": 255}
        else:
            # 凶：紫红色系
            return {"r": 200, "g": 50, "b": 150}
