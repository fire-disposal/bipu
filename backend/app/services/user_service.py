"""用户服务层 - 优化版本

设计原则：
1. 精简：移除cosmic_profile相关逻辑
2. 安全：安全的密码处理和用户管理
3. 实用：提供核心用户服务功能
"""

from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime, timezone
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate, UserPasswordUpdate
from app.core.security import verify_password, get_password_hash
from app.core.logging import get_logger

logger = get_logger(__name__)


class UserService:
    """用户服务类"""

    @staticmethod
    def create_user(db: Session, user_data: UserCreate) -> User:
        """创建用户"""
        try:
            # 生成bipupu_id（8位数字）
            import random
            bipupu_id = str(random.randint(10000000, 99999999))

            # 创建用户对象
            user = User(
                username=user_data.username,
                hashed_password=get_password_hash(user_data.password),
                nickname=user_data.nickname,
                bipupu_id=bipupu_id,
                is_active=True,
                is_superuser=False
            )

            db.add(user)
            db.commit()
            db.refresh(user)

            logger.info(f"用户创建成功: username={user.username}, id={user.id}")
            return user

        except Exception as e:
            db.rollback()
            logger.error(f"创建用户失败: {e}")
            raise

    @staticmethod
    def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
        """通过ID获取用户"""
        return db.query(User).filter(User.id == user_id).first()

    @staticmethod
    def get_user_by_username(db: Session, username: str) -> Optional[User]:
        """通过用户名获取用户"""
        return db.query(User).filter(User.username == username).first()

    @staticmethod
    def get_user_by_bipupu_id(db: Session, bipupu_id: str) -> Optional[User]:
        """通过bipupu_id获取用户"""
        return db.query(User).filter(User.bipupu_id == bipupu_id).first()

    @staticmethod
    def update_user(db: Session, user: User, user_update: UserUpdate) -> User:
        """更新用户信息"""
        try:
            update_data = user_update.model_dump(exclude_unset=True)

            # 更新用户字段
            for key, value in update_data.items():
                setattr(user, key, value)

            # 更新更新时间
            user.updated_at = datetime.now(timezone.utc)

            db.add(user)
            db.commit()
            db.refresh(user)

            logger.info(f"用户信息更新成功: user_id={user.id}")
            return user

        except Exception as e:
            db.rollback()
            logger.error(f"更新用户信息失败: {e}")
            raise

    @staticmethod
    def update_password(db: Session, user: User, password_data: UserPasswordUpdate) -> bool:
        """更新用户密码"""
        try:
            # 验证原密码
            if not verify_password(password_data.old_password, str(user.hashed_password)):
                return False

            # 更新密码
            user.hashed_password = get_password_hash(password_data.new_password)
            user.updated_at = datetime.now(timezone.utc)

            db.add(user)
            db.commit()

            logger.info(f"用户密码更新成功: user_id={user.id}")
            return True

        except Exception as e:
            db.rollback()
            logger.error(f"更新用户密码失败: {e}")
            raise

    @staticmethod
    def delete_user(db: Session, user_id: int) -> bool:
        """删除用户"""
        try:
            user = db.query(User).filter(User.id == user_id).first()
            if not user:
                return False

            db.delete(user)
            db.commit()

            logger.info(f"用户删除成功: user_id={user_id}")
            return True

        except Exception as e:
            db.rollback()
            logger.error(f"删除用户失败: {e}")
            raise

    @staticmethod
    def deactivate_user(db: Session, user_id: int) -> bool:
        """停用用户"""
        try:
            user = db.query(User).filter(User.id == user_id).first()
            if not user:
                return False

            user.is_active = False
            user.updated_at = datetime.now(timezone.utc)

            db.add(user)
            db.commit()

            logger.info(f"用户停用成功: user_id={user_id}")
            return True

        except Exception as e:
            db.rollback()
            logger.error(f"停用用户失败: {e}")
            raise

    @staticmethod
    def activate_user(db: Session, user_id: int) -> bool:
        """激活用户"""
        try:
            user = db.query(User).filter(User.id == user_id).first()
            if not user:
                return False

            user.is_active = True
            user.updated_at = datetime.now(timezone.utc)

            db.add(user)
            db.commit()

            logger.info(f"用户激活成功: user_id={user_id}")
            return True

        except Exception as e:
            db.rollback()
            logger.error(f"激活用户失败: {e}")
            raise

    @staticmethod
    def toggle_user_status(db: Session, user_id: int) -> User:
        """切换用户激活状态"""
        try:
            user = db.query(User).filter(User.id == user_id).first()
            if not user:
                from app.core.exceptions import NotFoundException
                raise NotFoundException(f"用户不存在: user_id={user_id}")

            user.is_active = not user.is_active
            user.updated_at = datetime.now(timezone.utc)

            db.add(user)
            db.commit()
            db.refresh(user)

            logger.info(f"用户状态切换成功: user_id={user_id}, is_active={user.is_active}")
            return user

        except Exception as e:
            db.rollback()
            logger.error(f"切换用户状态失败: {e}")
            raise

    @staticmethod
    def update_last_active(db: Session, user: User) -> None:
        """更新用户最后活跃时间"""
        try:
            user.update_last_active()
            db.add(user)
            db.commit()
        except Exception as e:
            db.rollback()
            logger.error(f"更新最后活跃时间失败: {e}")

    @staticmethod
    def get_active_users(db: Session, skip: int = 0, limit: int = 100) -> list[User]:
        """获取活跃用户列表"""
        return db.query(User).filter(
            User.is_active
        ).offset(skip).limit(limit).all()

    @staticmethod
    def search_users(db: Session, query: str, skip: int = 0, limit: int = 100) -> list[User]:
        """搜索用户"""
        search_pattern = f"%{query}%"
        return db.query(User).filter(
            User.is_active,
            (User.username.ilike(search_pattern) | User.nickname.ilike(search_pattern))
        ).offset(skip).limit(limit).all()

    @staticmethod
    def count_users(db: Session) -> int:
        """统计用户总数"""
        return db.query(User).count()

    @staticmethod
    def count_active_users(db: Session) -> int:
        """统计活跃用户数"""
        return db.query(User).filter(User.is_active).count()
