"""消息管理端点 - 收藏、导出等高级功能"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from app.db.database import get_db
from app.models.user import User
from app.schemas.message import MessageResponse
from app.schemas.common import PaginationParams, PaginatedResponse
from app.schemas.user_settings import MessageStatsRequest, MessageStatsResponse, ExportMessagesRequest, ExportMessagesResponse
from app.core.security import get_current_active_user
from app.services.message_service import MessageService
from app.core.logging import get_logger
from pydantic import BaseModel

router = APIRouter()
logger = get_logger(__name__)

def get_message_service(db: Session = Depends(get_db)) -> MessageService:
    return MessageService(db)

class StatusResponse(BaseModel):
    message: str

@router.post("/messages/{message_id}/favorite", response_model=StatusResponse)
async def favorite_message(
    message_id: int,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """收藏消息"""
    service.favorite_message(current_user, message_id)
    logger.info(f"消息收藏: 用户 {current_user.username} 收藏消息 {message_id}")
    return {"message": "消息已收藏"}


@router.delete("/messages/{message_id}/favorite", response_model=StatusResponse)
async def unfavorite_message(
    message_id: int,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """取消收藏消息"""
    service.unfavorite_message(current_user, message_id)
    logger.info(f"取消消息收藏: 用户 {current_user.username} 取消收藏消息 {message_id}")
    return {"message": "已取消收藏"}


@router.get("/messages/favorites", response_model=PaginatedResponse[MessageResponse])
async def get_favorite_messages(
    params: PaginationParams = Depends(),
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取收藏的消息列表"""
    messages, total = service.get_favorite_messages(current_user, params)
    return PaginatedResponse.create(messages, total, params)


@router.delete("/messages/batch", response_model=StatusResponse)
async def batch_delete_messages(
    message_ids: List[int],
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """批量删除消息"""
    deleted_count = service.batch_delete_messages(current_user, message_ids)
    logger.info(f"批量删除消息: 用户 {current_user.username} 删除 {deleted_count} 条消息")
    return {"message": f"成功删除 {deleted_count} 条消息"}


@router.put("/messages/{message_id}/archive", response_model=StatusResponse)
async def archive_message(
    message_id: int,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """归档消息"""
    service.archive_message(current_user, message_id)
    logger.info(f"消息归档: 用户 {current_user.username} 归档消息 {message_id}")
    return {"message": "消息已归档"}


@router.get("/messages/stats", response_model=MessageStatsResponse)
async def get_message_management_stats(
    stats_request: MessageStatsRequest = Depends(),
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取消息管理统计"""
    result = service.get_management_stats(current_user, stats_request)
    return MessageStatsResponse(**result)


@router.post("/messages/export", response_model=ExportMessagesResponse)
async def export_messages_advanced(
    export_request: ExportMessagesRequest,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """高级消息导出功能"""
    result = service.export_messages_advanced(current_user, export_request)
    return ExportMessagesResponse(**result)


@router.get("/messages/search", response_model=PaginatedResponse[MessageResponse])
async def search_messages(
    keyword: str,
    params: PaginationParams = Depends(),
    message_type: Optional[str] = None,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    service: MessageService = Depends(get_message_service),
    current_user: User = Depends(get_current_active_user)
):
    """搜索消息"""
    messages, total = service.search_messages(
        current_user, keyword, params, message_type, date_from, date_to
    )
    # The original response included "keyword": keyword. PaginatedResponse excludes it.
    # However standard practice is to return uniform structure.
    # If client needs keyword, they know it.
    return PaginatedResponse.create(messages, total, params)