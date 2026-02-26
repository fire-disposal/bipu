"""消息路由 - 优化版本

设计原则：
1. 精简：使用优化后的数据模型
2. 安全：严格的权限验证
3. 实用：提供核心消息功能
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional, List
import asyncio

from app.db.database import get_db
from app.models.user import User
from app.models.message import Message
from app.schemas.message import (
    MessageCreate, MessageResponse, MessageListResponse,
    MessagePollRequest, MessagePollResponse
)
from app.schemas.favorite import (
    FavoriteCreate, FavoriteResponse, FavoriteListResponse
)
from app.schemas.common import SuccessResponse
from app.services.message_service import MessageService
from app.services.favorite_service import FavoriteService
from app.core.security import get_current_user
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.post("/", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def send_message(
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """发送消息

    支持：
    - 用户间传讯（receiver_id 为用户的 bipupu_id）
    - 向服务号发送消息（receiver_id 为服务号 ID）

    参数：
    - receiver_id: 接收者ID
    - content: 消息内容（1-5000字符）
    - message_type: 消息类型（NORMAL, VOICE, SYSTEM）
    - pattern: 扩展模式数据（可选）
    - waveform: 音频波形数据（可选，0-255整数数组，最多128个点）

    返回：
    - 成功：返回创建的消息
    - 失败：400（参数错误）或404（接收者不存在）
    """
    try:
        # 检查接收者是否存在
        from app.models.user import User as UserModel
        receiver = db.query(UserModel).filter(
            UserModel.bipupu_id == message_data.receiver_id,
            UserModel.is_active == True
        ).first()

        if not receiver:
            # 检查是否是服务号
            from app.models.service_account import ServiceAccount
            service = db.query(ServiceAccount).filter(
                ServiceAccount.name == message_data.receiver_id,
                ServiceAccount.is_active == True
            ).first()

            if not service:
                raise HTTPException(
                    status_code=404,
                    detail="接收者不存在"
                )

        # 创建消息
        message = Message(
            sender_bipupu_id=current_user.bipupu_id,
            receiver_bipupu_id=message_data.receiver_id,
            content=message_data.content,
            message_type=message_data.message_type.value,
            pattern=message_data.pattern,
            waveform=message_data.waveform
        )

        db.add(message)
        db.commit()
        db.refresh(message)

        logger.info(f"消息发送成功: sender={current_user.bipupu_id}, receiver={message_data.receiver_id}")
        return message

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"消息发送失败: {e}")
        raise HTTPException(status_code=500, detail="消息发送失败")


@router.get("/", response_model=MessageListResponse)
async def get_messages(
    direction: str = Query("received", description="sent 或 received"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取消息列表

    参数：
    - direction: sent（发件箱）或 received（收件箱）
    - page: 页码（从1开始）
    - page_size: 每页数量（1-100）

    返回：
    - 成功：返回消息列表
    - 失败：400（参数错误）
    """
    try:
        if direction == "sent":
            # 获取发送的消息
            query = db.query(Message).filter(
                Message.sender_bipupu_id == current_user.bipupu_id
            )
        else:
            # 获取接收的消息
            query = db.query(Message).filter(
                Message.receiver_bipupu_id == current_user.bipupu_id
            )

        # 计算总数
        total = query.count()

        # 分页查询
        messages = query.order_by(Message.created_at.desc()) \
            .offset((page - 1) * page_size) \
            .limit(page_size) \
            .all()

        return MessageListResponse(
            messages=[MessageResponse.model_validate(msg) for msg in messages],
            total=total,
            page=page,
            page_size=page_size
        )

    except Exception as e:
        logger.error(f"获取消息列表失败: {e}")
        raise HTTPException(status_code=500, detail="获取消息列表失败")


@router.get("/poll", response_model=MessagePollResponse)
async def poll_messages(
    last_msg_id: int = Query(0, ge=0, description="最后收到的消息ID"),
    timeout: int = Query(30, ge=1, le=120, description="轮询超时时间（秒）"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    长轮询接口：
    如果数据库有比 last_msg_id 更新的消息，立即返回。
    如果没有，则异步等待直到有新消息或超时。

    参数：
    - last_msg_id: 最后收到的消息ID
    - timeout: 轮询超时时间（1-120秒）

    返回：
    - 成功：返回新消息列表和是否有更多消息的标志
    - 失败：400（参数错误）
    """
    try:
        for _ in range(timeout):
            # 检查数据库是否有新消息
            new_messages = db.query(Message).filter(
                Message.receiver_bipupu_id == current_user.bipupu_id,
                Message.id > last_msg_id
            ).order_by(Message.created_at.asc()).all()

            if new_messages:
                return MessagePollResponse(
                    messages=[MessageResponse.model_validate(msg) for msg in new_messages],
                    has_more=len(new_messages) >= 20  # 假设每批最多20条
                )

            # 如果没有新消息，挂起 1 秒再检查
            await asyncio.sleep(1)

        # 超时返回空列表
        return MessagePollResponse(messages=[], has_more=False)

    except Exception as e:
        logger.error(f"轮询消息失败: {e}")
        raise HTTPException(status_code=500, detail="轮询消息失败")


@router.get("/favorites", response_model=FavoriteListResponse)
async def get_favorites(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取收藏消息列表

    参数：
    - page: 页码（从1开始）
    - page_size: 每页数量（1-100）

    返回：
    - 成功：返回收藏消息列表
    - 失败：400（参数错误）
    """
    try:
        from app.models.favorite import Favorite

        # 查询收藏
        query = db.query(Favorite).filter(Favorite.user_id == current_user.id)

        # 计算总数
        total = query.count()

        # 分页查询
        favorites = query.order_by(Favorite.created_at.desc()) \
            .offset((page - 1) * page_size) \
            .limit(page_size) \
            .all()

        # 构建响应
        favorite_responses = []
        for fav in favorites:
            # 获取关联的消息
            message = db.query(Message).filter(Message.id == fav.message_id).first()
            if message:
                favorite_responses.append(FavoriteResponse.model_validate({
                    "id": fav.id,
                    "message_id": fav.message_id,
                    "note": fav.note,
                    "created_at": fav.created_at,
                    "message_content": message.content,
                    "message_sender": message.sender_bipupu_id,
                    "message_created_at": message.created_at
                }))

        return FavoriteListResponse(
            favorites=favorite_responses,
            total=total,
            page=page,
            page_size=page_size
        )

    except Exception as e:
        logger.error(f"获取收藏列表失败: {e}")
        raise HTTPException(status_code=500, detail="获取收藏列表失败")


@router.post("/{message_id}/favorite", response_model=FavoriteResponse)
async def add_favorite(
    message_id: int,
    favorite_data: FavoriteCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """收藏消息

    参数：
    - message_id: 消息ID
    - note: 备注（可选，最多200字符）

    返回：
    - 成功：返回创建的收藏
    - 失败：404（消息不存在）或409（已收藏）
    """
    try:
        # 检查消息是否存在
        message = db.query(Message).filter(Message.id == message_id).first()
        if not message:
            raise HTTPException(status_code=404, detail="消息不存在")

        # 检查是否已收藏
        from app.models.favorite import Favorite
        existing = db.query(Favorite).filter(
            Favorite.user_id == current_user.id,
            Favorite.message_id == message_id
        ).first()

        if existing:
            raise HTTPException(status_code=409, detail="消息已收藏")

        # 创建收藏
        favorite = Favorite(
            user_id=current_user.id,
            message_id=message_id,
            note=favorite_data.note
        )

        db.add(favorite)
        db.commit()
        db.refresh(favorite)

        logger.info(f"消息收藏成功: user_id={current_user.id}, message_id={message_id}")
        return FavoriteResponse.model_validate({
            "id": favorite.id,
            "message_id": favorite.message_id,
            "note": favorite.note,
            "created_at": favorite.created_at,
            "message_content": message.content,
            "message_sender": message.sender_bipupu_id,
            "message_created_at": message.created_at
        })

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"收藏消息失败: {e}")
        raise HTTPException(status_code=500, detail="收藏消息失败")


@router.delete("/{message_id}/favorite", status_code=status.HTTP_204_NO_CONTENT)
async def remove_favorite(
    message_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """取消收藏消息

    参数：
    - message_id: 消息ID

    返回：
    - 成功：204 No Content
    - 失败：404（收藏不存在）
    """
    try:
        from app.models.favorite import Favorite

        # 查找收藏
        favorite = db.query(Favorite).filter(
            Favorite.user_id == current_user.id,
            Favorite.message_id == message_id
        ).first()

        if not favorite:
            raise HTTPException(status_code=404, detail="收藏不存在")

        # 删除收藏
        db.delete(favorite)
        db.commit()

        logger.info(f"取消收藏成功: user_id={current_user.id}, message_id={message_id}")

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"取消收藏失败: {e}")
        raise HTTPException(status_code=500, detail="取消收藏失败")


@router.delete("/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_message(
    message_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """删除消息（仅限发送者）

    参数：
    - message_id: 消息ID

    返回：
    - 成功：204 No Content
    - 失败：404（消息不存在）或403（无权限）
    """
    try:
        # 查找消息
        message = db.query(Message).filter(Message.id == message_id).first()
        if not message:
            raise HTTPException(status_code=404, detail="消息不存在")

        # 检查权限（只能删除自己发送的消息）
        if message.sender_bipupu_id != current_user.bipupu_id:
            raise HTTPException(status_code=403, detail="无权删除此消息")

        # 删除消息
        db.delete(message)
        db.commit()

        logger.info(f"消息删除成功: message_id={message_id}, user_id={current_user.id}")

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"删除消息失败: {e}")
        raise HTTPException(status_code=500, detail="删除消息失败")
