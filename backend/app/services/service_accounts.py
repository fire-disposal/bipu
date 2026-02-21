"""服务号推送服务 - 简化版本，只负责发送推送，不处理用户消息"""
from typing import Optional, List
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.message import Message
from app.models.service_account import ServiceAccount
from app.core.logging import get_logger
import asyncio

logger = get_logger(__name__)


async def send_push(
    db: Session,
    service_name: str,
    receiver_bipupu_id: str,
    content: str,
    pattern: Optional[dict] = None,
    message_type: str = "SYSTEM",
) -> Message:
    """向用户发送服务号推送消息

    Args:
        db: 数据库会话
        service_name: 发送方服务号名称
        receiver_bipupu_id: 接收方用户 BIPUPU ID
        content: 消息内容
        pattern: 可选的 pupu 机显示/光效配置
        message_type: 消息类型，默认为 SYSTEM

    Returns:
        Message: 创建的消息对象
    """
    from app.core.websocket import manager

    # 创建推送消息
    new_message = Message(
        sender_bipupu_id=service_name,
        receiver_bipupu_id=receiver_bipupu_id,
        content=content,
        message_type=message_type,
        pattern=pattern or {}
    )

    db.add(new_message)
    try:
        db.commit()
        db.refresh(new_message)
    except Exception:
        db.rollback()
        raise

    logger.info(f"Service push sent: {service_name} -> {receiver_bipupu_id}")

    # 推送到 WebSocket (确保 receiver_bipupu_id 在线时能收到)
    try:
        ws_message = {
            "type": "new_message",
            "payload": {
                "id": new_message.id,
                "sender_id": new_message.sender_bipupu_id,
                "content": new_message.content,
                "message_type": new_message.message_type if new_message.message_type else None,
                "pattern": new_message.pattern,
                "created_at": new_message.created_at.isoformat()
            }
        }
        await manager.send_personal_message(ws_message, receiver_bipupu_id)
    except Exception as e:
        logger.warning(f"WebSocket push failed: {e}")

    return new_message


async def broadcast_push(
    db: Session,
    service_name: str,
    content: str,
    pattern: Optional[dict] = None,
    message_type: str = "SYSTEM",
) -> int:
    """向某服务号的所有订阅者广播推送消息

    Args:
        db: 数据库会话
        service_name: 服务号名称
        content: 消息内容
        pattern: 可选的 pupu 机配置
        message_type: 消息类型，默认为 SYSTEM

    Returns:
        int: 发送成功的订阅者数量
    """
    service = db.query(ServiceAccount).filter(ServiceAccount.name == service_name).first()
    if not service:
        logger.error(f"Cannot broadcast: Service {service_name} not found")
        return 0

    count = 0
    subscribers = service.subscribers
    logger.info(f"Broadcasting from {service_name} to {len(subscribers)} subscribers")

    for user in subscribers:
        await send_push(db, service_name, user.bipupu_id, content, pattern, message_type)
        count += 1

    return count


async def broadcast_to_users(
    db: Session,
    service_name: str,
    user_ids: List[str],
    content: str,
    pattern: Optional[dict] = None,
    message_type: str = "SYSTEM",
) -> int:
    """向指定用户列表发送推送消息

    Args:
        db: 数据库会话
        service_name: 服务号名称
        user_ids: 接收用户BIPUPU ID列表
        content: 消息内容
        pattern: 可选的 pupu 机配置
        message_type: 消息类型，默认为 SYSTEM

    Returns:
        int: 发送成功的用户数量
    """
    from app.models.user import User

    count = 0
    logger.info(f"Batch pushing from {service_name} to {len(user_ids)} users")

    for bipupu_id in user_ids:
        user = db.query(User).filter(User.bipupu_id == bipupu_id).first()
        if user:
            await send_push(db, service_name, bipupu_id, content, pattern, message_type)
            count += 1
        else:
            logger.warning(f"User {bipupu_id} not found, skip push")

    return count


def get_subscribers(db: Session, service_name: str) -> List[User]:
    """获取服务号的所有订阅者

    Args:
        db: 数据库会话
        service_name: 服务号名称

    Returns:
        List[User]: 订阅者列表
    """
    service = db.query(ServiceAccount).filter(ServiceAccount.name == service_name).first()
    if not service:
        return []

    return service.subscribers


def get_subscriber_count(db: Session, service_name: str) -> int:
    """获取服务号的订阅者数量

    Args:
        db: 数据库会话
        service_name: 服务号名称

    Returns:
        int: 订阅者数量
    """
    service = db.query(ServiceAccount).filter(ServiceAccount.name == service_name).first()
    if not service:
        return 0

    return len(service.subscribers)


def service_exists(db: Session, service_name: str) -> bool:
    """检查服务号是否存在

    Args:
        db: 数据库会话
        service_name: 服务号名称

    Returns:
        bool: 服务号是否存在且活跃
    """
    service = db.query(ServiceAccount).filter(
        ServiceAccount.name == service_name,
        ServiceAccount.is_active == True
    ).first()

    return service is not None
