"""用户服务层 - 处理用户相关的业务逻辑"""

from sqlalchemy.orm import Session
from typing import Optional
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate, UserPasswordUpdate
from app.core.security import get_password_hash, verify_password
from app.core.exceptions import ValidationException, NotFoundException
import asyncio
from app.services.redis_service import RedisService
from app.core.user_utils import generate_bipupu_id
from app.models.user_block import UserBlock
from app.schemas.common import PaginationParams
from datetime import datetime


class UserService:
    """用户服务类"""

    @staticmethod
    def create_user(db: Session, user_create: UserCreate) -> User:
        """创建新用户"""
        # 检查用户是否已存在
        db_user = db.query(User).filter(User.username == user_create.username).first()
        if db_user:
            raise ValidationException("Username already registered")

        # 生成唯一的 bipupu_id
        bipupu_id = generate_bipupu_id(db)

        # 创建新用户
        user_data = {
            "username": user_create.username,
            "nickname": user_create.nickname or user_create.username,
            "hashed_password": get_password_hash(user_create.password),
            "bipupu_id": bipupu_id,
        }

        db_user = User(**user_data)
        db.add(db_user)
        db.commit()
        db.refresh(db_user)

        return db_user

    @staticmethod
    def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
        """根据ID获取用户"""
        return db.query(User).filter(User.id == user_id).first()

    @staticmethod
    def get_user_by_username(db: Session, username: str) -> Optional[User]:
        """根据用户名获取用户"""
        return db.query(User).filter(User.username == username).first()

    @staticmethod
    def get_user_by_email_or_username(db: Session, identifier: str) -> Optional[User]:
        """根据 username 或 email 查找用户（向后兼容）。

        说明：email 已降级为非关键字段，但为兼容旧登录行为仍保留此查找。
        优先按 username 查找，然后按 email 查找（如果存在）。
        """
        # 仅按 username 查找；email 字段已移除
        return db.query(User).filter(User.username == identifier).first()

    @staticmethod
    def update_user(db: Session, user: User, user_update: UserUpdate) -> User:
        """更新用户信息（仅限昵称和cosmic_profile）"""
        update_data = user_update.dict(exclude_unset=True)

        for key, value in update_data.items():
            setattr(user, key, value)

        db.commit()
        db.refresh(user)
        try:
            loop = asyncio.get_running_loop()
            loop.create_task(RedisService.invalidate_user_cache(user.id))
        except RuntimeError:
            pass
        return user

    @staticmethod
    def update_password(db: Session, user: User, password_update: UserPasswordUpdate) -> User:
        """更新用户密码"""
        if not verify_password(password_update.old_password, user.hashed_password):
            raise ValidationException("Incorrect old password")

        if password_update.old_password == password_update.new_password:
            raise ValidationException("New password must be different from the old password")

        user.hashed_password = get_password_hash(password_update.new_password)
        db.commit()
        db.refresh(user)
        try:
            loop = asyncio.get_running_loop()
            loop.create_task(RedisService.invalidate_user_cache(user.id))
        except RuntimeError:
            pass
        return user

    @staticmethod
    def delete_user(db: Session, user: User) -> bool:
        """删除用户"""
        db.delete(user)
        db.commit()
        try:
            loop = asyncio.get_running_loop()
            loop.create_task(RedisService.invalidate_user_cache(user.id))
        except RuntimeError:
            pass
        return True

    @staticmethod
    def block_user(db: Session, blocker: User, blocked_user_id: int) -> UserBlock:
        """将用户加入黑名单"""
        if blocker.id == blocked_user_id:
            raise ValidationException("Cannot block yourself")

        # 检查被拉黑用户是否存在
        blocked = db.query(User).filter(User.id == blocked_user_id).first()
        if not blocked:
            raise ValidationException("User to block not found")

        # 检查是否已存在
        existing = db.query(UserBlock).filter(
            UserBlock.blocker_id == blocker.id,
            UserBlock.blocked_id == blocked_user_id
        ).first()
        if existing:
            raise ValidationException("User already blocked")

        ub = UserBlock(blocker_id=blocker.id, blocked_id=blocked_user_id)
        db.add(ub)
        db.commit()
        db.refresh(ub)
        return ub

    @staticmethod
    def unblock_user(db: Session, blocker: User, blocked_user_id: int) -> bool:
        """从黑名单移除用户"""
        ub = db.query(UserBlock).filter(
            UserBlock.blocker_id == blocker.id,
            UserBlock.blocked_id == blocked_user_id
        ).first()
        if not ub:
            raise ValidationException("Block entry not found")

        db.delete(ub)
        db.commit()
        return True

    @staticmethod
    def get_blocked_users(db: Session, blocker: User, params: PaginationParams) -> tuple[list[tuple[User, datetime]], int]:
        """获取黑名单列表，返回 ([(user, blocked_at)], total)"""
        # 查询 UserBlock 并联结 User，以便返回被拉黑用户及时间
        query = db.query(User, UserBlock.created_at).join(UserBlock, User.id == UserBlock.blocked_id).filter(UserBlock.blocker_id == blocker.id)
        total = query.count()
        rows = query.offset(params.skip).limit(params.size).all()
        # rows 是 (User, created_at) 的列表
        return rows, total