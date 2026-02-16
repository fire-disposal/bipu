"""服务号注册表和处理器"""
from typing import Dict, Callable, Awaitable, Optional, List
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.message import Message
from app.models.service_account import ServiceAccount
from app.core.logging import get_logger
import random
import asyncio
from app.schemas.enums import MessageType

logger = get_logger(__name__)

# 服务号处理器函数签名
ServiceHandler = Callable[[Session, User, Message], Awaitable[None]]

# 服务号注册表
SERVICE_ACCOUNTS: Dict[str, ServiceHandler] = {}


def register_service(service_name: str):
    """注册服务号处理器的装饰器"""
    def decorator(handler: ServiceHandler):
        logger.info(f"注册服务号: {service_name}")
        SERVICE_ACCOUNTS[service_name] = handler
        return handler
    return decorator


async def handle_service_message(db: Session, sender: User, message: Message):
    """处理发往服务号的消息"""
    service_name = message.receiver_bipupu_id
    
    # 1. 优先检查是否有代码处理器
    handler = SERVICE_ACCOUNTS.get(service_name)
    if handler:
        logger.info(f"调用服务号 {service_name} 的处理器")
        await handler(db, sender, message)
        return

    # 2. 如果没有代码处理器，检查是否是数据库中存在的有效服务号
    # (有些服务号可能只是为了推送通知，没有交互逻辑)
    service_account = db.query(ServiceAccount).filter(ServiceAccount.name == service_name).first()
    if service_account:
        # 如果是已知服务号但无逻辑，可以使用通用回复或忽略
        # 这里回复一个通用提示，提升体验
        await send_reply(db, service_name, sender.bipupu_id, "收到您的消息，但该服务号目前不支持自动回复。")
    else:
        # 3. 如果连数据库里都没有，说明是无效的服务号地址 (虽然符合格式)
        # 提示用户
        await send_reply(db, "system.notification", sender.bipupu_id, f"消息投递失败：找不到服务号 '{service_name}'")


async def send_reply(
    db: Session,
    service_name: str,
    receiver_bipupu_id: str,
    content: str,
    pattern: Optional[dict] = None,
    message_type: MessageType = MessageType.SYSTEM,
):
    """发送回复消息 / 推送消息
    
    Args:
        db: 数据库会话
        service_name: 发送方服务号名称
        receiver_bipupu_id: 接收方用户 BIPUPU ID
        content: 消息内容
        pattern: 可选的 pupu 机显示/光效配置
    """
    # 避免循环导入
    from app.core.websocket import manager

    # 创建回复消息
    new_message = Message(
        sender_bipupu_id=service_name,
        receiver_bipupu_id=receiver_bipupu_id,
        content=content,
        message_type=message_type,
        pattern=pattern or {}
    )
    
    db.add(new_message)
    # 立即提交，确保有了ID
    db.commit()
    db.refresh(new_message)
    
    logger.info(f"Service reply/push sent: {service_name} -> {receiver_bipupu_id}")
    
    # 推送到 WebSocket (确保 receiver_bipupu_id 在线时能收到)
    try:
        ws_message = {
            "type": "new_message",
            "payload": {
                "id": new_message.id,
                "sender_id": new_message.sender_bipupu_id,
                "content": new_message.content,
                "message_type": new_message.message_type.value if new_message.message_type else None,
                "pattern": new_message.pattern,
                "created_at": new_message.created_at.isoformat()
            }
        }
        await manager.send_personal_message(ws_message, receiver_bipupu_id)
    except Exception as e:
        logger.warning(f"WebSocket push failed: {e}")


async def broadcast_message(
    db: Session, 
    service_name: str, 
    content: str, 
    pattern: Optional[dict] = None
) -> int:
    """向某服务号的所有订阅者广播消息
    
    Args:
        db: 数据库会话
        service_name: 服务号名称
        content: 消息内容
        pattern: 可选的 pupu 机配置
        
    Returns:
        int: 发送成功的订阅者数量
    """
    service = db.query(ServiceAccount).filter(ServiceAccount.name == service_name).first()
    if not service:
        logger.error(f"Cannot broadcast: Service {service_name} not found")
        return 0
        
    count = 0
    # 获取订阅者列表 (注意: 生产环境如果订阅者数量巨大，需要分批处理或使用任务队列)
    subscribers = service.subscribers
    logger.info(f"Broadcasting from {service_name} to {len(subscribers)} subscribers")
    
    for user in subscribers:
        await send_reply(db, service_name, user.bipupu_id, content, pattern)
        count += 1
        
    return count


async def check_subscription_command(
    db: Session, 
    sender: User, 
    message: Message, 
    service_name: str,
    subscribe_keywords: Optional[List[str]] = None,
    unsubscribe_keywords: Optional[List[str]] = None,
    messages: Optional[Dict[str, str]] = None
) -> bool:
    """检查并处理订阅/退订命令
    返回 True 如果是命令并已处理，False 否则
    
    Args:
        subscribe_keywords: 订阅触发词列表 (默认: ["订阅", "subscribe"])
        unsubscribe_keywords: 退订触发词列表 (默认: ["解除订阅", "退订", "unsubscribe"])
        messages: 自定义回复文本字典 (key: sub_success, sub_exists, unsub_success, unsub_not_exists, service_not_found)
    """
    # 默认值
    subscribe_keywords = [k.lower() for k in (subscribe_keywords or ["订阅", "subscribe"])]
    unsubscribe_keywords = [k.lower() for k in (unsubscribe_keywords or ["解除订阅", "退订", "unsubscribe"])]
    
    msgs = {
        "sub_success": f"【{service_name}】订阅成功！",
        "sub_exists": f"您已订阅【{service_name}】。",
        "unsub_success": f"【{service_name}】退订成功。",
        "unsub_not_exists": f"您尚未订阅【{service_name}】。",
        "service_not_found": "系统错误：服务号不存在"
    }
    if messages:
        msgs.update(messages)

    content = message.content.strip()
    content_lower = content.lower()
    
    is_sub = content_lower in subscribe_keywords
    is_unsub = content_lower in unsubscribe_keywords
    
    if not (is_sub or is_unsub):
        return False
        
    service_account = db.query(ServiceAccount).filter(ServiceAccount.name == service_name).first()
    if not service_account:
        await send_reply(db, service_name, sender.bipupu_id, msgs["service_not_found"])
        return True

    if is_sub:
        if sender not in service_account.subscribers:
            service_account.subscribers.append(sender)
            db.commit()
            await send_reply(db, service_name, sender.bipupu_id, msgs["sub_success"])
        else:
            await send_reply(db, service_name, sender.bipupu_id, msgs["sub_exists"])
    
    elif is_unsub:
        if sender in service_account.subscribers:
            service_account.subscribers.remove(sender)
            db.commit()
            await send_reply(db, service_name, sender.bipupu_id, msgs["unsub_success"])
        else:
            await send_reply(db, service_name, sender.bipupu_id, msgs["unsub_not_exists"])
            
    return True


# --- 具体服务号实现 ---

@register_service("weather.service")
async def weather_bot(db: Session, sender: User, message: Message):
    """天气服务号逻辑"""
    service_name = "weather.service"
    
    # 1. 检查订阅命令 (使用自定义配置)
    if await check_subscription_command(
        db, sender, message, service_name,
        subscribe_keywords=["订阅", "订阅天气", "subscribe"],
        messages={
            "sub_success": "🌤️ 天气服务订阅成功！每天清晨为您播报。",
            "sub_exists": "您已经订阅过天气服务啦。",
            "unsub_success": "天气服务已退订。",
        }
    ):
        return

    # 2. 业务逻辑
    if "天气" in message.content:
        weathers = ["晴朗 ☀️", "多云 ☁️", "小雨 🌧️", "雷阵雨 ⛈️", "大风 🌬️"]
        reply = f"今日天气：{random.choice(weathers)}，气温 {random.randint(15, 30)}°C。"
        pattern = {"led": "blue", "animation": "rain" if "雨" in reply else "sun"}
        await send_reply(db, service_name, sender.bipupu_id, reply, pattern)
    else:
        reply = "发送‘天气’查看今日气象，发送‘订阅’获取每日推送。"
        await send_reply(db, service_name, sender.bipupu_id, reply)


@register_service("cosmic.fortune")
async def fortune_bot(db: Session, sender: User, message: Message):
    """今日运势服务号逻辑"""
    service_name = "cosmic.fortune"
    
    # 1. 检查订阅命令 (使用自定义配置)
    if await check_subscription_command(
        db, sender, message, service_name,
        subscribe_keywords=["订阅", "订阅运势", "开启好运"],
        messages={
            "sub_success": "🔮 命运之轮开始转动... 订阅成功！",
            "sub_exists": "星星告诉我，您已经订阅过了。",
        }
    ):
        return

    # 2. 业务逻辑
    if "运势" in message.content:
        fortunes = ["大吉 🌟", "中吉 ⭐", "小吉 ✨", "平 😐", "凶 ⚠️"]
        lucky_items = ["红色外套", "笔记本电脑", "咖啡", "耳机", "Pupu机"]
        reply = f"今日运势：{random.choice(fortunes)}。\n幸运物：{random.choice(lucky_items)}"
        await send_reply(db, service_name, sender.bipupu_id, reply)
    else:
        reply = "发送‘运势’查看今日运程，发送‘订阅’开启每日运势。"
        await send_reply(db, service_name, sender.bipupu_id, reply)
