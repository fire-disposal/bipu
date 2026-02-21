"""消息路由 - 重构版本"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.db.database import get_db
from app.models.user import User
from app.schemas.message import MessageCreate, MessageResponse, MessageListResponse
from app.schemas.favorite import FavoriteCreate, FavoriteResponse, FavoriteListResponse
from app.services.message_service import MessageService
from app.services.favorite_service import FavoriteService
from app.core.security import get_current_user
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.post("/", response_model=MessageResponse, status_code=status.HTTP_201_CREATED, tags=["消息"])
async def send_message(
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """发送消息

    支持：
    - 用户间传讯（receiver_id 为用户的 bipupu_id）
    - 向服务号发送消息（receiver_id 为服务号 ID，如 "cosmic.fortune"）
    """
    try:
        message = await MessageService.send_message(db, current_user, message_data)
        return message
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/", response_model=MessageListResponse, tags=["消息"])
async def get_messages(
    direction: Optional[str] = Query("received", description="sent 或 received"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取消息列表

    参数：
    - direction: sent（发件箱）或 received（收件箱）
    - page: 页码
    - page_size: 每页数量
    """
    if direction == "sent":
        messages, total = MessageService.get_sent_messages(db, current_user, page, page_size)
    else:
        messages, total = MessageService.get_received_messages(db, current_user, page, page_size)

    return {
        "messages": messages,
        "total": total,
        "page": page,
        "page_size": page_size
    }


@router.get("/favorites", response_model=FavoriteListResponse, tags=["消息"])
async def get_favorites(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取收藏消息列表"""
    favorites, total = FavoriteService.get_favorites(db, current_user, page, page_size)
    return {
        "favorites": favorites,
        "total": total,
        "page": page,
        "page_size": page_size
    }


@router.post("/{message_id}/favorite", response_model=FavoriteResponse, tags=["消息"])
async def add_favorite(
    message_id: int,
    favorite_data: Optional[FavoriteCreate] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """收藏消息"""
    try:
        note = favorite_data.note if favorite_data else None
        favorite = FavoriteService.add_favorite(db, current_user, message_id, note)
        return favorite
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.delete("/{message_id}/favorite", status_code=status.HTTP_204_NO_CONTENT, tags=["消息"])
async def remove_favorite(
    message_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """取消收藏"""
    success = FavoriteService.remove_favorite(db, current_user, message_id)
    if not success:
         raise HTTPException(status_code=404, detail="Favorite not found")
    return None


@router.delete("/{message_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["消息"])
async def delete_message(
    message_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """删除消息（只能删除收到的消息）"""
    success = MessageService.delete_message(db, message_id, current_user)

    if not success:
        raise HTTPException(status_code=404, detail="Message not found")

    return None
