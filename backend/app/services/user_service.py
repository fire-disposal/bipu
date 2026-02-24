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
from app.core.user_utils import get_western_zodiac
from app.services.lunar_service import compute_bazi, compute_lunar_date
from app.models.user_block import UserBlock
from app.schemas.common import PaginationParams
from datetime import datetime


class UserService:
    """用户服务模块"""

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
        try:
            db.commit()
            db.refresh(db_user)
        except Exception:
            db.rollback()
            raise

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
        update_data = user_update.model_dump(exclude_unset=True)

        # 处理 cosmic_profile 的合并与派生字段填充
        if "cosmic_profile" in update_data:
            incoming = update_data.pop("cosmic_profile") or {}
            # 保证原有 profile 为 dict
            existing = user.cosmic_profile or {}
            # 合并字段（incoming 优先）
            # 确保 existing 是字典类型
            existing_dict = existing if isinstance(existing, dict) else {}
            merged = {**existing_dict, **incoming}

            # 如果提供 birthday，则尝试解析并填充 zodiac 与 age
            birthday = merged.get("birthday")
            if birthday:
                try:
                    from datetime import datetime, date
                    if isinstance(birthday, str):
                        try:
                            bdate = datetime.fromisoformat(birthday).date()
                        except Exception:
                            bdate = datetime.strptime(birthday, "%Y-%m-%d").date()
                    elif isinstance(birthday, datetime):
                        bdate = birthday.date()
                    elif isinstance(birthday, date):
                        bdate = birthday
                    else:
                        bdate = None

                    if bdate:
                        merged["birthday"] = bdate.isoformat()
                        merged["zodiac"] = get_western_zodiac(bdate)
                        # age 计算（整年）
                        today = date.today()
                        age = today.year - bdate.year - (
                            (today.month, today.day) < (bdate.month, bdate.day)
                        )
                        merged["age"] = age
                        # 如果用户未提供 bazi，可尝试用 lunar_service 生成（失败安全）
                        if not merged.get("bazi"):
                            birth_time = merged.get("birth_time")
                            try:
                                bazi_text = compute_bazi(merged["birthday"], birth_time)
                                if bazi_text:
                                    merged["bazi"] = bazi_text
                            except Exception:
                                pass
                        # 尝试填充农历信息
                        try:
                            lunar_info = compute_lunar_date(merged["birthday"])
                            if lunar_info:
                                merged.setdefault("lunar", {}).update(lunar_info)
                        except Exception:
                            pass
                except Exception:
                    # 不阻塞更新，仅记录/忽略错误
                    pass

            # 保持用户提供的生辰八字（bazi）和 mbti 等字段
            user.cosmic_profile = merged

        # 处理剩余普通字段
        for key, value in update_data.items():
            setattr(user, key, value)

        try:
            db.commit()
            db.refresh(user)
        except Exception:
            db.rollback()
            raise
        try:
            loop = asyncio.get_running_loop()
            loop.create_task(RedisService.invalidate_user_cache(int(str(user.id))))
        except RuntimeError:
            pass
        return user

    @staticmethod
    def update_password(db: Session, user: User, password_update: UserPasswordUpdate) -> User:
        """更新用户密码"""
        if not verify_password(password_update.old_password, str(user.hashed_password)):
            raise ValidationException("Incorrect old password")

        if password_update.old_password == password_update.new_password:
            raise ValidationException("New password must be different from the old password")

        user.hashed_password = get_password_hash(password_update.new_password)
        try:
            db.commit()
            db.refresh(user)
        except Exception:
            db.rollback()
            raise
        try:
            loop = asyncio.get_running_loop()
            loop.create_task(RedisService.invalidate_user_cache(int(str(user.id))))
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
            loop.create_task(RedisService.invalidate_user_cache(int(str(user.id))))
        except RuntimeError:
            pass
        return True

    @staticmethod
    def block_user(db: Session, blocker: User, blocked_user_id: int) -> UserBlock:
        """将用户加入黑名单

        参数：
        - db: 数据库会话
        - blocker: 执行拉黑的用户
        - blocked_user_id: 被拉黑用户的数据库ID

        返回：
        - UserBlock: 创建的黑名单记录

        异常：
        - ValidationException: 如果尝试拉黑自己、用户不存在或已拉黑
        """
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
        try:
            db.commit()
            db.refresh(ub)
            return ub
        except Exception as e:
            db.rollback()
            raise ValidationException(f"Failed to block user: {str(e)}")

    @staticmethod
    def unblock_user(db: Session, blocker: User, blocked_user_id: int) -> bool:
        """从黑名单移除用户

        参数：
        - db: 数据库会话
        - blocker: 执行解除拉黑的用户
        - blocked_user_id: 被解除拉黑用户的数据库ID

        返回：
        - bool: 操作是否成功

        异常：
        - ValidationException: 如果黑名单记录不存在
        """
        ub = db.query(UserBlock).filter(
            UserBlock.blocker_id == blocker.id,
            UserBlock.blocked_id == blocked_user_id
        ).first()
        if not ub:
            raise ValidationException("Block entry not found")

        db.delete(ub)
        try:
            db.commit()
            return True
        except Exception as e:
            db.rollback()
            raise ValidationException(f"Failed to unblock user: {str(e)}")

    @staticmethod
    def get_blocked_users(db: Session, blocker: User, params: PaginationParams) -> tuple[list[tuple[User, datetime]], int]:
        """获取黑名单列表，返回 ([(user, blocked_at)], total)

        参数：
        - db: 数据库会话
        - blocker: 查询黑名单的用户
        - params: 分页参数

        返回：
        - tuple[list[tuple[User, datetime]], int]: (用户列表及拉黑时间, 总数)
        """
        # 查询 UserBlock 并联结 User，以便返回被拉黑用户及时间
        query = db.query(User, UserBlock.created_at).join(
            UserBlock, User.id == UserBlock.blocked_id
        ).filter(
            UserBlock.blocker_id == blocker.id
        ).order_by(UserBlock.created_at.desc())

        total = query.count()
        rows = query.offset(params.skip).limit(params.size).all()

        # rows 是 Row 对象，需要转换为 (User, datetime) 元组
        result = []
        for row in rows:
            # row 是 Row 对象，包含 User 和 created_at
            user = row[0]
            blocked_at = row[1]
            result.append((user, blocked_at))
        return result, total

    @staticmethod
    def is_user_blocked(db: Session, blocker_id: int, blocked_id: int) -> bool:
        """检查用户是否被拉黑

        参数：
        - db: 数据库会话
        - blocker_id: 检查是否执行拉黑的用户ID
        - blocked_id: 检查是否被拉黑的用户ID

        返回：
        - bool: 如果 blocker_id 拉黑了 blocked_id 则返回 True
        """
        return db.query(UserBlock).filter(
            UserBlock.blocker_id == blocker_id,
            UserBlock.blocked_id == blocked_id
        ).first() is not None

    @staticmethod
    def get_block_status(db: Session, user1_id: int, user2_id: int) -> dict:
        """获取两个用户之间的拉黑关系状态

        参数：
        - db: 数据库会话
        - user1_id: 第一个用户ID
        - user2_id: 第二个用户ID

        返回：
        - dict: 包含拉黑状态信息的字典
        """
        user1_blocks_user2 = UserService.is_user_blocked(db, user1_id, user2_id)
        user2_blocks_user1 = UserService.is_user_blocked(db, user2_id, user1_id)

        return {
            "user1_blocks_user2": user1_blocks_user2,
            "user2_blocks_user1": user2_blocks_user1,
            "mutual_block": user1_blocks_user2 and user2_blocks_user1,
            "any_block": user1_blocks_user2 or user2_blocks_user1
        }

    @staticmethod
    def search_blocked_users(db: Session, blocker: User, keyword: str, limit: int = 10) -> list[tuple[User, datetime]]:
        """在黑名单中搜索用户

        参数：
        - db: 数据库会话
        - blocker: 执行搜索的用户
        - keyword: 搜索关键词
        - limit: 结果数量限制

        返回：
        - list[tuple[User, datetime]]: 匹配的用户列表及拉黑时间
        """
        from sqlalchemy import or_

        search_pattern = f"%{keyword}%"

        query = db.query(User, UserBlock.created_at).join(
            UserBlock, User.id == UserBlock.blocked_id
        ).filter(
            UserBlock.blocker_id == blocker.id,
            or_(
                User.username.ilike(search_pattern),
                User.nickname.ilike(search_pattern),
                User.bipupu_id.ilike(search_pattern)
            )
        ).order_by(UserBlock.created_at.desc()).limit(limit)

        rows = query.all()

        result = []
        for row in rows:
            user = row[0]
            blocked_at = row[1]
            result.append((user, blocked_at))

        return result

    @staticmethod
    def get_block_statistics(db: Session, user_id: int) -> dict:
        """获取用户的拉黑统计信息

        参数：
        - db: 数据库会话
        - user_id: 用户ID

        返回：
        - dict: 包含统计信息的字典
        """
        # 我拉黑的用户总数
        total_blocks = db.query(UserBlock).filter(
            UserBlock.blocker_id == user_id
        ).count()

        # 拉黑我的用户总数
        total_blocked_by = db.query(UserBlock).filter(
            UserBlock.blocked_id == user_id
        ).count()

        # 互相拉黑的用户数
        mutual_blocks_query = db.query(UserBlock).filter(
            UserBlock.blocker_id == user_id,
            UserBlock.blocked_id.in_(
                db.query(UserBlock.blocker_id).filter(
                    UserBlock.blocked_id == user_id
                )
            )
        )
        mutual_blocks = mutual_blocks_query.count()

        return {
            "total_blocks": total_blocks,
            "total_blocked_by": total_blocked_by,
            "mutual_blocks": mutual_blocks
        }

    @staticmethod
    def toggle_user_status(db: Session, user_id: int) -> User:
        """切换用户激活状态（启用/禁用）"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise NotFoundException("User not found")

        # 切换状态
        user.is_active = not user.is_active

        try:
            db.commit()
            db.refresh(user)
        except Exception:
            db.rollback()
            raise

        # 清除用户缓存
        try:
            loop = asyncio.get_running_loop()
            loop.create_task(RedisService.invalidate_user_cache(int(str(user.id))))
        except RuntimeError:
            pass

        return user
