"""内置服务号实现"""
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.message import Message
from app.services.service_accounts import register_service
from app.services.message_service_new import MessageService
from app.schemas.message_new import MessageCreate
from app.schemas.enums import MessageType
from app.core.logging import get_logger
import redis.asyncio as redis
from app.db.database import redis_client

logger = get_logger(__name__)


@register_service("cosmic.fortune")
async def handle_cosmic_fortune(db: Session, sender: User, received_message: Message):
    """处理宇宙运势服务号的消息
    
    当用户发送 "TD" (退订) 时，取消订阅。
    否则，视为订阅，并回复一条欢迎消息。
    """
    content = received_message.content.strip().upper()
    subscriber_key = f"service:cosmic.fortune:subscribers"
    
    if content == "TD":
        # 取消订阅
        await redis_client.srem(subscriber_key, sender.bipupu_id)
        reply_content = "您已成功退订宇宙运势服务。"
        logger.info(f"用户 {sender.bipupu_id} 退订了 cosmic.fortune")
    else:
        # 订阅
        await redis_client.sadd(subscriber_key, sender.bipupu_id)
        reply_content = "欢迎订阅宇宙运势！每日将为您推送专属的心灵指引。回复 'TD' 可随时退订。"
        logger.info(f"用户 {sender.bipupu_id} 订阅了 cosmic.fortune")
    
    # 回复消息
    reply_message_data = MessageCreate(
        receiver_id=sender.bipupu_id,
        content=reply_content,
        message_type=MessageType.SYSTEM
    )
    
    # 创建一个虚拟的 "service" 用户来发送回复
    # 注意：这里不直接创建用户，而是模拟一个发送者
    class ServiceSender:
        bipupu_id = "cosmic.fortune"

    await MessageService.send_message(db, ServiceSender(), reply_message_data)


# 可以在这里添加更多的服务号
# @register_service("weather.service")
# async def handle_weather_service(db: Session, sender: User, received_message: Message):
#     # ...
#     pass
