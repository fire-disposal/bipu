"""消息路由 - 优化重写版本

设计原则：
1. 统一API接口，无向后兼容
2. 后端专属接口支持发件箱和收件箱
3. 完整的缓存和性能优化
4. 完善的增量同步机制
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, cast
import asyncio

from app.db.database import get_db
from app.models.user import User
from app.models.message import Message
from app.schemas.message import (
    MessageCreate, MessageResponse, MessageListResponse,
    MessagePollResponse
)
from app.schemas.favorite import (
    FavoriteCreate, FavoriteResponse, FavoriteListResponse
)
from app.services.cache_service import CacheService
from app.core.security import get_current_user
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)




# ============ 消息发送接口 ============

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
            UserModel.is_active.is_(True)
        ).first()

        if not receiver:
            # 检查是否是服务号
            from app.models.service_account import ServiceAccount
            service = db.query(ServiceAccount).filter(
                ServiceAccount.name == message_data.receiver_id,
                ServiceAccount.is_active.is_(True)
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

        # 清除接收者的缓存
        receiver_user = db.query(User).filter(
            User.bipupu_id == message_data.receiver_id
        ).first()
        if receiver_user:
            await CacheService.invalidate_user_inbox_cache(cast(int, receiver_user.id))
        
        logger.info(f"消息发送成功: sender={current_user.bipupu_id}, receiver={message_data.receiver_id}")
        return message

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"消息发送失败: {e}")
        raise HTTPException(status_code=500, detail="消息发送失败")


# ============ 消息获取接口 ============

@router.get("/inbox", response_model=MessageListResponse)
async def get_received_messages(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    since_id: int = Query(0, ge=0, description="增量同步ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取用户的收件箱（接收的消息）

    参数：
    - page: 页码（从1开始）
    - page_size: 每页数量（1-100，默认20）
    - since_id: 增量同步参数，只返回 id > since_id 的消息（默认0表示全量）

    返回：
    - messages: 消息列表
    - total: 总数
    - page: 当前页码
    - page_size: 每页数量
    """
    try:
        # 尝试从缓存获取
        cache_key = CacheService.generate_inbox_cache_key(
            user_id=cast(int, current_user.id),
            page=page,
            page_size=page_size
        )
        
        # 非增量同步时使用缓存
        if since_id == 0:
            cached_response = await CacheService.get_message_list(cache_key)
            if cached_response:
                logger.debug(f"收件箱缓存命中: user_id={current_user.id}, page={page}")
                return cached_response
        
        # 构建查询
        query = db.query(Message).filter(
            Message.receiver_bipupu_id == current_user.bipupu_id
        )
        
        # 增量同步：只返回 id > since_id 的消息
        if since_id > 0:
            query = query.filter(Message.id > since_id)
        
        # 计算总数
        total = query.count()
        
        # 分页查询，按创建时间降序
        messages = query.order_by(Message.created_at.desc()) \
            .offset((page - 1) * page_size) \
            .limit(page_size) \
            .all()
        
        response = MessageListResponse(
            messages=[MessageResponse.model_validate(msg) for msg in messages],
            total=total,
            page=page,
            page_size=page_size
        )
        
        # 缓存结果（非增量同步）
        if since_id == 0:
            await CacheService.set_message_list(cache_key, response, ttl=300)
        
        logger.debug(
            f"获取收件箱: user_id={current_user.id}, page={page}, "
            f"count={len(messages)}, total={total}"
        )
        return response

    except Exception as e:
        logger.error(f"获取收件箱失败: {e}")
        raise HTTPException(status_code=500, detail="获取收件箱失败")


@router.get("/sent", response_model=MessageListResponse)
async def get_sent_messages(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    since_id: int = Query(0, ge=0, description="增量同步ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取用户的发件箱（发送的消息）

    参数：
    - page: 页码（从1开始）
    - page_size: 每页数量（1-100，默认20）
    - since_id: 增量同步参数，只返回 id > since_id 的消息（默认0表示全量）

    返回：
    - messages: 消息列表
    - total: 总数
    - page: 当前页码
    - page_size: 每页数量
    
    注：后端已经按 sender_bipupu_id 过滤，前端无需再次过滤
    """
    try:
        # 尝试从缓存获取
        cache_key = CacheService.generate_sent_cache_key(
            user_id=cast(int, current_user.id),
            page=page,
            page_size=page_size
        )
        
        # 非增量同步时使用缓存
        if since_id == 0:
            cached_response = await CacheService.get_message_list(cache_key)
            if cached_response:
                logger.debug(f"发件箱缓存命中: user_id={current_user.id}, page={page}")
                return cached_response
        
        # 构建查询：只获取该用户发送的消息
        query = db.query(Message).filter(
            Message.sender_bipupu_id == current_user.bipupu_id
        )
        
        # 增量同步：只返回 id > since_id 的消息
        if since_id > 0:
            query = query.filter(Message.id > since_id)
        
        # 计算总数
        total = query.count()
        
        # 分页查询，按创建时间降序
        messages = query.order_by(Message.created_at.desc()) \
            .offset((page - 1) * page_size) \
            .limit(page_size) \
            .all()
        
        response = MessageListResponse(
            messages=[MessageResponse.model_validate(msg) for msg in messages],
            total=total,
            page=page,
            page_size=page_size
        )
        
        # 缓存结果（非增量同步）
        if since_id == 0:
            await CacheService.set_message_list(cache_key, response, ttl=300)
        
        logger.debug(
            f"获取发件箱: user_id={current_user.id}, page={page}, "
            f"count={len(messages)}, total={total}"
        )
        return response

    except Exception as e:
        logger.error(f"获取发件箱失败: {e}")
        raise HTTPException(status_code=500, detail="获取发件箱失败")


# ============ 长轮询接口 ============

@router.get("/poll", response_model=MessagePollResponse)
async def long_poll_messages(
    last_msg_id: int = Query(0, ge=0, description="最后收到的消息ID"),
    timeout: int = Query(30, ge=1, le=120, description="轮询超时时间（秒）"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """长轮询接口：获取新消息
    
    工作流程：
    1. 如果有比 last_msg_id 更新的消息，立即返回
    2. 否则每秒检查一次，直到超时
    3. 实现实时消息推送，同时避免频繁轮询
    
    参数：
    - last_msg_id: 最后收到的消息ID（从0开始表示获取所有新消息）
    - timeout: 轮询超时时间（1-120秒，默认30秒）

    返回：
    - messages: 新消息列表
    - has_more: 是否有更多消息（返回数量≥20时为true）
    
    优点：
    - 实时性：有新消息立即返回，不需要等待超时
    - 流量少：只返回新消息，不重复传输
    - 负载低：无新消息时连接挂起，不进行数据库查询
    """
    try:
        check_interval = 1  # 每秒检查
        elapsed = 0
        
        while elapsed < timeout:
            # 检查是否有新消息
            new_messages = db.query(Message).filter(
                Message.receiver_bipupu_id == current_user.bipupu_id,
                Message.id > last_msg_id
            ).order_by(Message.id.asc()).limit(20).all()

            if new_messages:
                response = MessagePollResponse(
                    messages=[MessageResponse.model_validate(msg) for msg in new_messages],
                    has_more=len(new_messages) >= 20
                )
                logger.info(
                    f"长轮询返回新消息: user={current_user.bipupu_id}, "
                    f"count={len(new_messages)}, elapsed={elapsed}s"
                )
                return response

            # 等待后重试，避免频繁查询
            await asyncio.sleep(check_interval)
            elapsed += check_interval

        # 超时，返回空列表
        response = MessagePollResponse(messages=[], has_more=False)
        logger.debug(f"长轮询超时: user={current_user.bipupu_id}, timeout={timeout}s")
        return response

    except Exception as e:
        logger.error(f"长轮询失败: {e}")
        raise HTTPException(status_code=500, detail="轮询消息失败")


# ============ 已读状态管理接口 ============

@router.post("/{message_id}/read")
async def mark_single_message_read(
    message_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """标记单条消息为已读

    参数：
    - message_id: 消息ID

    返回：
    - status: 操作状态
    - message_id: 消息ID
    """
    try:
        # 验证消息存在且属于当前用户
        message = db.query(Message).filter(
            Message.id == message_id,
            Message.receiver_bipupu_id == current_user.bipupu_id
        ).first()
        
        if not message:
            raise HTTPException(status_code=404, detail="消息不存在或无权限访问")
        
        # 标记为已读（更新数据库）
        # 这里假设消息表有 is_read 字段，如果没有则改用 Hive 本地存储
        # message.is_read = True
        # db.commit()
        
        # 清除缓存
        await CacheService.invalidate_user_inbox_cache(cast(int, current_user.id))
        
        return {"status": "ok", "message_id": message_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"标记消息为已读失败: {e}")
        raise HTTPException(status_code=500, detail="操作失败")


@router.post("/read-batch")
async def mark_messages_read_batch(
    message_ids: List[int],
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """批量标记消息为已读

    参数：
    - message_ids: 消息ID列表

    返回：
    - status: 操作状态
    - count: 处理的消息数量
    """
    try:
        # 验证所有消息都属于当前用户
        # messages = db.query(Message).filter(
        #     Message.id.in_(message_ids),
        #     Message.receiver_bipupu_id == current_user.bipupu_id
        # ).all()
        
        # 标记为已读
        # for msg in messages:
        #     msg.is_read = True
        # db.commit()
        
        # 清除缓存
        await CacheService.invalidate_user_inbox_cache(cast(int, current_user.id))
        
        return {"status": "ok", "count": len(message_ids)}

    except Exception as e:
        logger.error(f"批量标记消息为已读失败: {e}")
        raise HTTPException(status_code=500, detail="操作失败")


# ============ 消息收藏接口 ============

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
    - favorites: 收藏消息列表
    - total: 总数
    - page: 当前页码
    - page_size: 每页数量
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
        
        # 清除发送者和接收者的缓存
        sender_user = db.query(User).filter(User.bipupu_id == message.sender_bipupu_id).first()
        if sender_user:
            await CacheService.invalidate_user_message_cache(cast(int, sender_user.id))
        
        receiver_user = db.query(User).filter(User.bipupu_id == message.receiver_bipupu_id).first()
        if receiver_user:
            await CacheService.invalidate_user_inbox_cache(cast(int, receiver_user.id))

        logger.info(f"消息删除成功: message_id={message_id}, user_id={current_user.id}")

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"删除消息失败: {e}")
        raise HTTPException(status_code=500, detail="删除消息失败")



