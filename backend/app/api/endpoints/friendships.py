"""好友关系管理端点"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import Optional

from app.db.database import get_db
from app.models.friendship import FriendshipStatus
from app.models.user import User
from app.schemas.friendship import (
    FriendshipCreate, FriendshipResponse
)
from app.schemas.user import UserResponse
from app.schemas.common import PaginationParams, PaginatedResponse
from app.core.security import get_current_active_user
from app.services.friendship_service import FriendshipService
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)

def get_friendship_service(db: Session = Depends(get_db)) -> FriendshipService:
    return FriendshipService(db)

@router.post("/", response_model=FriendshipResponse)
async def create_friend_request(
    friendship: FriendshipCreate,
    service: FriendshipService = Depends(get_friendship_service),
    current_user: User = Depends(get_current_active_user)
):
    """发送好友请求"""
    result = service.create_friend_request(current_user, friendship)
    logger.info(f"Friend request sent: {current_user.username} -> {friendship.friend_id}")
    return result


@router.get("/", response_model=PaginatedResponse[FriendshipResponse])
async def get_friendships(
    params: PaginationParams = Depends(),
    status: Optional[FriendshipStatus] = None,
    service: FriendshipService = Depends(get_friendship_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取好友关系列表"""
    friendships, total = service.get_friendships(current_user, params, status)
    return PaginatedResponse.create(friendships, total, params)


@router.get("/requests", response_model=PaginatedResponse[FriendshipResponse])
async def get_friend_requests(
    params: PaginationParams = Depends(),
    service: FriendshipService = Depends(get_friendship_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取待处理的好友请求"""
    requests, total = service.get_friend_requests(current_user, params)
    return PaginatedResponse.create(requests, total, params)


@router.get("/friends", response_model=PaginatedResponse[UserResponse])
async def get_friends(
    params: PaginationParams = Depends(),
    service: FriendshipService = Depends(get_friendship_service),
    current_user: User = Depends(get_current_active_user)
):
    """获取好友列表"""
    friends, total = service.get_friends(current_user, params)
    return PaginatedResponse.create(friends, total, params)


@router.put("/{friendship_id}/accept", response_model=FriendshipResponse)
async def accept_friend_request(
    friendship_id: int,
    service: FriendshipService = Depends(get_friendship_service),
    current_user: User = Depends(get_current_active_user)
):
    """接受好友请求"""
    friendship = service.accept_friend_request(current_user, friendship_id)
    logger.info(f"Friend request accepted: {friendship.id} by {current_user.username}")
    return friendship


@router.put("/{friendship_id}/reject", response_model=FriendshipResponse)
async def reject_friend_request(
    friendship_id: int,
    service: FriendshipService = Depends(get_friendship_service),
    current_user: User = Depends(get_current_active_user)
):
    """拒绝好友请求"""
    friendship = service.reject_friend_request(current_user, friendship_id)
    logger.info(f"Friend request rejected: {friendship.id} by {current_user.username}")
    return friendship


@router.delete("/{friendship_id}")
async def delete_friend(
    friendship_id: int,
    service: FriendshipService = Depends(get_friendship_service),
    current_user: User = Depends(get_current_active_user)
):
    """删除好友关系"""
    service.delete_friend(current_user, friendship_id)
    logger.info(f"Friendship deleted: {friendship_id}")
    return {"message": "Friend deleted successfully"}