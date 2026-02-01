"""用户服务层 - 处理用户相关的业务逻辑"""

from sqlalchemy.orm import Session
from typing import Optional
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate
from app.core.security import get_password_hash
from app.core.exceptions import ValidationException
from app.services.redis_service import RedisService


class UserService:
    """用户服务类"""
    
    @staticmethod
    def create_user(db: Session, user_create: UserCreate) -> User:
        """创建新用户"""
        # 检查用户是否已存在
        db_user = db.query(User).filter(
            (User.email == user_create.email) | (User.username == user_create.username)
        ).first()
        if db_user:
            raise ValidationException("Email or username already registered")
        
        # 创建新用户
        user_data = user_create.dict(exclude={"password"})
        user_data["hashed_password"] = get_password_hash(user_create.password)
        # 支持nickname字段
        if hasattr(user_create, "nickname"):
            user_data["nickname"] = user_create.nickname
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
    def get_user_by_email_or_username(db: Session, identifier: str) -> Optional[User]:
        """根据邮箱或用户名获取用户"""
        return db.query(User).filter(
            (User.email == identifier) | (User.username == identifier)
        ).first()
    
    @staticmethod
    def update_user(
        db: Session, 
        user: User, 
        user_update: UserUpdate,
        current_user: User  # 传入当前用户以进行权限检查
    ) -> User:
        """更新用户信息"""
        update_data = user_update.dict(exclude_unset=True)
        
        # 唯一性校验
        if "email" in update_data:
            exists = db.query(User.id).filter(
                User.email == update_data["email"],
                User.id != user.id
            ).first()
            if exists:
                raise ValidationException("Email already registered")
        if "username" in update_data:
            exists = db.query(User.id).filter(
                User.username == update_data["username"],
                User.id != user.id
            ).first()
            if exists:
                raise ValidationException("Username already registered")
        
        # 如果更新密码
        if "password" in update_data:
            update_data["hashed_password"] = get_password_hash(update_data["password"])
            del update_data["password"]
        
        # 支持nickname字段
        if "nickname" in update_data:
            user.nickname = update_data["nickname"]
            del update_data["nickname"]
        
        for key, value in update_data.items():
            setattr(user, key, value)
        
        db.commit()
        db.refresh(user)
        
        # 使用户缓存失效
        RedisService.invalidate_user_cache(user.id)
        
        return user
    
    @staticmethod
    def delete_user(db: Session, user: User) -> bool:
        """删除用户"""
        db.delete(user)
        db.commit()
        
        # 使用户缓存失效
        RedisService.invalidate_user_cache(user.id)
        
        return True
    
    @staticmethod
    def update_user_status(db: Session, user: User, is_active: bool) -> User:
        """更新用户状态"""
        user.is_active = is_active
        db.commit()
        db.refresh(user)
        
        # 使用户缓存失效
        RedisService.invalidate_user_cache(user.id)
        
        return user