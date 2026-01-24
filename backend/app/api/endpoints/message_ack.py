"""消息回执管理端点"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.models.messageackevent import MessageAckEvent
from app.models.user import User
from app.schemas.messageackevent import (
    MessageAckEventCreate, MessageAckEventResponse
)
from app.schemas.common import PaginatedResponse, PaginationParams
from app.core.security import get_current_active_user
from app.services.message_service import MessageService
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)

def get_message_service(db: Session = Depends(get_db)) -> MessageService:
    return MessageService(db)

@router.post("/", response_model=MessageAckEventResponse)
async def create_message_ack_event(
    ack_event: MessageAckEventCreate,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """创建消息回执事件"""
    result = service.create_ack_event(current_user, ack_event)
    logger.info(f"Message ack event created: {ack_event.event} for message {ack_event.message_id}")
    return result


@router.get("/message/{message_id}", response_model=PaginatedResponse[MessageAckEventResponse])
async def get_message_ack_events(
    message_id: int,
    params: PaginationParams = Depends(),
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取指定消息的所有回执事件"""
    events, total = service.get_ack_events(current_user, message_id, params)
    return PaginatedResponse.create(events, total, params)
