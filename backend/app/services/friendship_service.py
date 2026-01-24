from typing import List, Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from datetime import datetime

from app.models.friendship import Friendship, FriendshipStatus
from app.models.user import User
from app.schemas.friendship import FriendshipCreate
from app.schemas.common import PaginationParams
from app.core.exceptions import NotFoundException, ValidationException

class FriendshipService:
    def __init__(self, db: Session):
        self.db = db

    def create_friend_request(self, user: User, friendship: FriendshipCreate) -> Friendship:
        """发送好友请求"""
        if friendship.friend_id == user.id:
            raise ValidationException("Cannot send friend request to yourself")
        
        friend = self.db.query(User).filter(User.id == friendship.friend_id).first()
        if not friend:
            raise NotFoundException("Target user not found")
        
        existing_friendship = self.db.query(Friendship).filter(
            or_(
                (Friendship.user_id == user.id) & (Friendship.friend_id == friendship.friend_id),
                (Friendship.user_id == friendship.friend_id) & (Friendship.friend_id == user.id)
            )
        ).first()
        
        if existing_friendship:
            if existing_friendship.status == FriendshipStatus.ACCEPTED:
                raise ValidationException("Already friends")
            elif existing_friendship.status == FriendshipStatus.PENDING:
                raise ValidationException("Friend request already sent")
            elif existing_friendship.status == FriendshipStatus.BLOCKED:
                raise ValidationException("Cannot send friend request to blocked user")
        
        friend_request = Friendship(
            user_id=user.id,
            friend_id=friendship.friend_id,
            status=FriendshipStatus.PENDING
        )
        self.db.add(friend_request)
        self.db.commit()
        self.db.refresh(friend_request)
        return friend_request

    def get_friendships(self, user: User, params: PaginationParams, status: Optional[FriendshipStatus] = None) -> Tuple[List[Friendship], int]:
        """获取好友关系列表"""
        query = self.db.query(Friendship).filter(
            or_(Friendship.user_id == user.id, Friendship.friend_id == user.id)
        )
        
        if status:
            query = query.filter(Friendship.status == status)
        
        total = query.count()
        friendships = query.offset(params.skip).limit(params.size).all()
        return friendships, total

    def get_friend_requests(self, user: User, params: PaginationParams) -> Tuple[List[Friendship], int]:
        """获取待处理的好友请求"""
        query = self.db.query(Friendship).filter(
            Friendship.friend_id == user.id,
            Friendship.status == FriendshipStatus.PENDING
        )
        
        total = query.count()
        requests = query.offset(params.skip).limit(params.size).all()
        return requests, total

    def get_friends(self, user: User, params: PaginationParams) -> Tuple[List[User], int]:
        """获取好友列表 (优化版: 使用 Union 查询)"""
        # Friends where user is sender
        q1 = self.db.query(User).join(
            Friendship, User.id == Friendship.friend_id
        ).filter(
            Friendship.user_id == user.id,
            Friendship.status == FriendshipStatus.ACCEPTED
        )
        
        # Friends where user is receiver
        q2 = self.db.query(User).join(
            Friendship, User.id == Friendship.user_id
        ).filter(
            Friendship.friend_id == user.id,
            Friendship.status == FriendshipStatus.ACCEPTED
        )
        
        # Union the queries
        query = q1.union(q2)
        
        total = query.count()
        friends = query.offset(params.skip).limit(params.size).all()
        
        return friends, total

    def accept_friend_request(self, user: User, friendship_id: int) -> Friendship:
        """接受好友请求"""
        friendship = self.db.query(Friendship).filter(
            Friendship.id == friendship_id,
            Friendship.friend_id == user.id,
            Friendship.status == FriendshipStatus.PENDING
        ).first()
        
        if not friendship:
            raise NotFoundException("Friend request not found or not authorized")
        
        friendship.status = FriendshipStatus.ACCEPTED
        friendship.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(friendship)
        return friendship

    def reject_friend_request(self, user: User, friendship_id: int) -> Friendship:
        """拒绝好友请求"""
        friendship = self.db.query(Friendship).filter(
            Friendship.id == friendship_id,
            Friendship.friend_id == user.id,
            Friendship.status == FriendshipStatus.PENDING
        ).first()
        
        if not friendship:
            raise NotFoundException("Friend request not found or not authorized")
        
        friendship.status = FriendshipStatus.BLOCKED
        friendship.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(friendship)
        return friendship

    def delete_friend(self, user: User, friendship_id: int) -> None:
        """删除好友关系"""
        friendship = self.db.query(Friendship).filter(
            Friendship.id == friendship_id,
            or_(Friendship.user_id == user.id, Friendship.friend_id == user.id),
            Friendship.status == FriendshipStatus.ACCEPTED
        ).first()
        
        if not friendship:
            raise NotFoundException("Friendship not found or not authorized")
        
        self.db.delete(friendship)
        self.db.commit()
