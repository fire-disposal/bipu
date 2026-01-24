from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from app.models.subscription import UserSubscription
from app.services.subscriptions.providers.fortune import FortuneProvider
from .base import BaseSubscriptionHandler

class FortuneSubscriptionHandler(BaseSubscriptionHandler):
    def __init__(self):
        super().__init__("fortune")
        self.provider = FortuneProvider()

    def generate_message_data(self, user_id: int, subscription: UserSubscription, db: Session) -> Optional[Dict[str, Any]]:
        settings = subscription.custom_settings or {}
        zodiac = settings.get("zodiac", "白羊座")
        
        data = self.provider.get_data(zodiac)
        
        return {
            "title": f"{zodiac}今日运势 - {data['overall']}",
            "content": (
                f"综合运势: {data['overall']}\n"
                f"爱情指数: {data['love']}\n"
                f"事业指数: {data['career']}\n"
                f"财运指数: {data['wealth']}\n"
                f"幸运色: {data['lucky_color']}\n"
                f"建议: {data['advice']}"
            ),
            "pattern": {
                "type": "fortune",
                "data": data,
                "display_mode": "card"
            },
            "category": "fortune_subscription"
        }
