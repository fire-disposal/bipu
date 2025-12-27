"""好友关系管理端点"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional
from datetime import datetime

from app.db.database import get_db
from app.models.friendship import Friendship, FriendshipStatus
from app.models.user import User
from app.schemas.friendship import (
    FriendshipCreate, FriendshipUpdate, FriendshipResponse
)
from app.schemas.common import PaginatedResponse
from app.core.security import get_current_active_user
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger
from app.schemas.user import UserResponse
import math

router = APIRouter()
logger = get_logger(__name__)


@router.post("/", response_model=FriendshipResponse)
async def create_friend_request(
    friendship: FriendshipCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """发送好友请求"""
    # 不能添加自己为好友
    if friendship.friend_id == current_user.id:
        raise ValidationException("Cannot send friend request to yourself")
    
    # 检查目标用户是否存在
    friend = db.query(User).filter(User.id == friendship.friend_id).first()
    if not friend:
        raise NotFoundException("Target user not found")
    
    # 检查是否已经是好友
    existing_friendship = db.query(Friendship).filter(
        or_(
            (Friendship.user_id == current_user.id) & (Friendship.friend_id == friendship.friend_id),
            (Friendship.user_id == friendship.friend_id) & (Friendship.friend_id == current_user.id)
        )
    ).first()
    
    if existing_friendship:
        if existing_friendship.status == FriendshipStatus.ACCEPTED:
            raise ValidationException("Already friends")
        elif existing_friendship.status == FriendshipStatus.PENDING:
            raise ValidationException("Friend request already sent")
        elif existing_friendship.status == FriendshipStatus.BLOCKED:
            raise ValidationException("Cannot send friend request to blocked user")
    
    # 创建好友请求
    friend_request = Friendship(
        user_id=current_user.id,
        friend_id=friendship.friend_id,
        status=FriendshipStatus.PENDING
    )
    db.add(friend_request)
    db.commit()
    db.refresh(friend_request)
    
    logger.info(f"Friend request sent: {current_user.username} -> {friend.username}")
    return friend_request


@router.get("/", response_model=PaginatedResponse[FriendshipResponse])
async def get_friendships(
    page: int = 1,
    size: int = 20,
    status: Optional[FriendshipStatus] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取好友关系列表"""
    skip = (page - 1) * size
    query = db.query(Friendship).filter(
        or_(Friendship.user_id == current_user.id, Friendship.friend_id == current_user.id)
    )
    
    if status:
        query = query.filter(Friendship.status == status)
    
    total = query.count()
    friendships = query.offset(skip).limit(size).all()
    pages = math.ceil(total / size) if size > 0 else 0
    
    return {
        "items": friendships,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    }


@router.get("/requests", response_model=PaginatedResponse[FriendshipResponse])
async def get_friend_requests(
    page: int = 1,
    size: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取待处理的好友请求"""
    skip = (page - 1) * size
    query = db.query(Friendship).filter(
        Friendship.friend_id == current_user.id,
        Friendship.status == FriendshipStatus.PENDING
    )
    
    total = query.count()
    requests = query.offset(skip).limit(size).all()
    pages = math.ceil(total / size) if size > 0 else 0
    
    return {
        "items": requests,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    }


@router.get("/friends", response_model=PaginatedResponse[UserResponse])
async def get_friends(
    page: int = 1,
    size: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取好友列表"""
    # 获取用户作为请求方的好友
    sent_friends = db.query(User).join(
        Friendship, User.id == Friendship.friend_id
    ).filter(
        Friendship.user_id == current_user.id,
        Friendship.status == FriendshipStatus.ACCEPTED
    ).all()
    
    # 获取用户作为接收方的好友
    received_friends = db.query(User).join(
        Friendship, User.id == Friendship.user_id
    ).filter(
        Friendship.friend_id == current_user.id,
        Friendship.status == FriendshipStatus.ACCEPTED
    ).all()
    
    # 合并并去重
    all_friends = list(set(sent_friends + received_friends))
    
    # 手动分页
    total = len(all_friends)
    start = (page - 1) * size
    end = start + size
    items = all_friends[start:end]
    pages = math.ceil(total / size) if size > 0 else 0
    
    return {
        "items": items,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    }


@router.put("/{friendship_id}/accept", response_model=FriendshipResponse)
async def accept_friend_request(
    friendship_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """接受好友请求"""
    friendship = db.query(Friendship).filter(
        Friendship.id == friendship_id,
        Friendship.friend_id == current_user.id,
        Friendship.status == FriendshipStatus.PENDING
    ).first()
    
    if not friendship:
        raise NotFoundException("Friend request not found or not authorized")
    
    friendship.status = FriendshipStatus.ACCEPTED
    friendship.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(friendship)
    
    logger.info(f"Friend request accepted: {friendship.user.username} -> {current_user.username}")
    return friendship


@router.put("/{friendship_id}/reject", response_model=FriendshipResponse)
async def reject_friend_request(
    friendship_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """拒绝好友请求"""
    friendship = db.query(Friendship).filter(
        Friendship.id == friendship_id,
        Friendship.friend_id == current_user.id,
        Friendship.status == FriendshipStatus.PENDING
    ).first()
    
    if not friendship:
        raise NotFoundException("Friend request not found or not authorized")
    
    friendship.status = FriendshipStatus.BLOCKED
    friendship.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(friendship)
    
    logger.info(f"Friend request rejected: {friendship.user.username} -> {current_user.username}")
    return friendship


@router.delete("/{friendship_id}")
async def delete_friend(
    friendship_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除好友关系"""
    friendship = db.query(Friendship).filter(
        Friendship.id == friendship_id,
        or_(Friendship.user_id == current_user.id, Friendship.friend_id == current_user.id),
        Friendship.status == FriendshipStatus.ACCEPTED
    ).first()
    
    if not friendship:
        raise NotFoundException("Friendship not found or not authorized")
    
    db.delete(friendship)
    db.commit()
    
    logger.info(f"Friendship deleted: {friendship_id}")
    return {"message": "Friend deleted successfully"}


# 管理端API
@router.get("/admin/all", response_model=PaginatedResponse[FriendshipResponse])
async def admin_get_all_friendships(
    page: int = 1,
    size: int = 20,
    status: Optional[FriendshipStatus] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """管理端：获取所有好友关系（需要超级用户权限）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    skip = (page - 1) * size
    query = db.query(Friendship)
    if status:
        query = query.filter(Friendship.status == status)
    
    total = query.count()
    friendships = query.offset(skip).limit(size).all()
    pages = math.ceil(total / size) if size > 0 else 0
    
    return {
        "items": friendships,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    }


@router.delete("/admin/{friendship_id}")
async def admin_delete_friendship(
    friendship_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """管理端：删除好友关系（需要超级用户权限）"""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    friendship = db.query(Friendship).filter(Friendship.id == friendship_id).first()
    if not friendship:
        raise NotFoundException("Friendship not found")
    
    db.delete(friendship)
    db.commit()
    
    logger.info(f"Admin deleted friendship: {friendship_id}")
    return {"message": "Friendship deleted by admin"}