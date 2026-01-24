from typing import List, Optional, Dict, Any, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from datetime import datetime, timedelta

from app.models.user import User
from app.models.user_block import UserBlock
from app.models.message_favorite import MessageFavorite
from app.models.message import Message
from app.models.subscription import SubscriptionType, UserSubscription
from app.schemas.user_settings import (
    UserProfileUpdate, UserSettingsUpdate, PasswordChange,
    BlockUserRequest, ExportMessagesRequest, MessageStatsRequest
)
from app.core.security import get_password_hash, verify_password
from app.core.exceptions import NotFoundException, ValidationException
from app.schemas.common import PaginationParams

class UserSettingsService:
    def __init__(self, db: Session):
        self.db = db

    def update_profile(self, user: User, profile_update: UserProfileUpdate) -> User:
        """更新用户个人资料"""
        update_data = profile_update.dict(exclude_unset=True)
        
        for key, value in update_data.items():
            if hasattr(user, key):
                setattr(user, key, value)
        
        user.updated_at = datetime.utcnow()
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def update_settings(self, user: User, settings_update: UserSettingsUpdate) -> User:
        """更新用户设置"""
        update_data = settings_update.dict(exclude_unset=True)
        
        if "privacy_settings" in update_data:
            user.privacy_settings = update_data["privacy_settings"].dict()
        
        if "subscription_settings" in update_data:
            user.subscription_settings = update_data["subscription_settings"].dict()
        
        user.updated_at = datetime.utcnow()
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def change_password(self, user: User, password_change: PasswordChange) -> None:
        """修改密码"""
        if not verify_password(password_change.current_password, user.hashed_password):
            raise ValidationException("当前密码不正确")
        
        user.hashed_password = get_password_hash(password_change.new_password)
        user.updated_at = datetime.utcnow()
        self.db.add(user)
        self.db.commit()

    def accept_terms(self, user: User, accepted: bool) -> None:
        """接受用户协议"""
        user.terms_accepted = accepted
        user.terms_accepted_at = datetime.utcnow()
        user.updated_at = datetime.utcnow()
        self.db.add(user)
        self.db.commit()

    def block_user(self, user: User, block_request: BlockUserRequest) -> None:
        """拉黑用户"""
        if block_request.user_id == user.id:
            raise ValidationException("不能拉黑自己")
        
        # Check target user
        target_user = self.db.query(User).filter(User.id == block_request.user_id).first()
        if not target_user:
            raise NotFoundException("用户不存在")
        
        # Check existing block
        existing_block = self.db.query(UserBlock).filter(
            UserBlock.blocker_id == user.id,
            UserBlock.blocked_id == block_request.user_id
        ).first()
        
        if existing_block:
            raise ValidationException("已经拉黑该用户")
        
        # 检查黑名单数量限制
        block_count = self.db.query(UserBlock).filter(UserBlock.blocker_id == user.id).count()
        if block_count >= 50:
            raise ValidationException("黑名单已满，最多只能拉黑50个用户")

        user_block = UserBlock(
            blocker_id=user.id,
            blocked_id=block_request.user_id
        )
        self.db.add(user_block)
        self.db.commit()

    def unblock_user(self, user: User, blocked_user_id: int) -> None:
        """解除拉黑"""
        user_block = self.db.query(UserBlock).filter(
            UserBlock.blocker_id == user.id,
            UserBlock.blocked_id == blocked_user_id
        ).first()
        
        if not user_block:
            raise NotFoundException("未找到拉黑记录")
        
        self.db.delete(user_block)
        self.db.commit()

    def get_blocked_users(self, user: User, params: PaginationParams) -> Tuple[List[User], int]:
        """获取黑名单用户列表"""
        # 使用 JOIN 查询优化，避免 N+1 查询
        query = self.db.query(User, UserBlock.created_at).join(
            UserBlock, UserBlock.blocked_id == User.id
        ).filter(
            UserBlock.blocker_id == user.id
        )
        
        total = query.count()
        # 按拉黑时间倒序排列
        results = query.order_by(UserBlock.created_at.desc())\
            .offset(params.skip)\
            .limit(params.size)\
            .all()
            
        blocked_users = []
        for user_obj, blocked_at in results:
            user_obj.blocked_at = blocked_at
            blocked_users.append(user_obj)
        
        return blocked_users, total

    def export_messages(self, user: User, export_request: ExportMessagesRequest) -> Dict[str, Any]:
        """导出消息"""
        query = self.db.query(Message).filter(
            (Message.sender_id == user.id) | (Message.receiver_id == user.id)
        )
        
        if export_request.message_type == "sent":
            query = query.filter(Message.sender_id == user.id)
        elif export_request.message_type == "received":
            query = query.filter(Message.receiver_id == user.id)
        
        if export_request.date_from:
            query = query.filter(Message.created_at >= export_request.date_from)
        if export_request.date_to:
            query = query.filter(Message.created_at <= export_request.date_to)
        
        messages = query.all()
        
        download_url = f"/api/v1/downloads/messages_export_{user.id}_{int(datetime.utcnow().timestamp())}.json"
        
        return {
            "download_url": download_url,
            "file_size": len(str([msg.__dict__ for msg in messages])),
            "record_count": len(messages),
            "expires_at": datetime.utcnow() + timedelta(hours=24)
        }

    def get_message_stats(self, user: User, stats_request: MessageStatsRequest) -> Dict[str, Any]:
        """获取消息统计"""
        base_query = self.db.query(Message).filter(
            or_(Message.sender_id == user.id, Message.receiver_id == user.id)
        )
        
        if stats_request.date_from:
            base_query = base_query.filter(Message.created_at >= stats_request.date_from)
        if stats_request.date_to:
            base_query = base_query.filter(Message.created_at <= stats_request.date_to)
            
        # We need to clone query or be careful not to modify base_query if we reuse it, 
        # but here we just count on filters.
        # Ideally, we should construct fresh queries for counts if filters differ, 
        # but here the filter applies to all stats except favorites perhaps?
        # The original code applied date filters to `query` then counted.
        
        total_sent = base_query.filter(Message.sender_id == user.id).count()
        total_received = base_query.filter(Message.receiver_id == user.id).count()
        
        total_favorites = self.db.query(MessageFavorite).filter(
            MessageFavorite.user_id == user.id
        ).count()
        
        by_type = {}
        for msg_type in ["system", "user", "alert", "notification"]:
            count = base_query.filter(Message.message_type == msg_type).count()
            by_type[msg_type] = count
            
        by_date = {} # Placeholder as in original
        
        return {
            "total_sent": total_sent,
            "total_received": total_received,
            "total_favorites": total_favorites,
            "by_type": by_type,
            "by_date": by_date
        }

    def get_subscriptions(self, user: User) -> List[UserSubscription]:
        """获取用户订阅"""
        return self.db.query(UserSubscription).filter(
            UserSubscription.user_id == user.id
        ).all()

    def update_subscription(self, user: User, subscription_type_id: int, is_enabled: bool, custom_settings: Optional[Dict[str, Any]] = None) -> UserSubscription:
        """更新订阅设置"""
        subscription_type = self.db.query(SubscriptionType).filter(
            SubscriptionType.id == subscription_type_id
        ).first()
        
        if not subscription_type:
            raise NotFoundException("订阅类型不存在")
        
        user_subscription = self.db.query(UserSubscription).filter(
            UserSubscription.user_id == user.id,
            UserSubscription.subscription_type_id == subscription_type_id
        ).first()
        
        if not user_subscription:
            user_subscription = UserSubscription(
                user_id=user.id,
                subscription_type_id=subscription_type_id
            )
            self.db.add(user_subscription)
        
        user_subscription.is_enabled = is_enabled
        if custom_settings:
            user_subscription.custom_settings = custom_settings
        
        self.db.commit()
        self.db.refresh(user_subscription)
        return user_subscription
