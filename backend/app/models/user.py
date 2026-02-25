from sqlalchemy import Column, Integer, String, DateTime, Boolean, LargeBinary, Date, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from typing import Optional
from app.models.base import Base


class User(Base):
    """用户模型"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    bipupu_id = Column(String(8), unique=True, index=True, nullable=False)  # 8位纯数字ID
    username = Column(String(50), unique=True, index=True, nullable=False)
    nickname = Column(String(50), nullable=True)
    avatar_data = Column(LargeBinary, nullable=True)  # 存储图像二进制数据
    avatar_version = Column(Integer, default=0)  # 头像版本号，用于缓存失效
    hashed_password = Column(String(255), nullable=False)

    # CosmicProfile字段直接作为数据库字段
    birthday = Column(Date, nullable=True)  # 公历生日
    zodiac = Column(String(10), nullable=True)  # 西方星座
    age = Column(Integer, nullable=True)  # 年龄
    bazi = Column(String(50), nullable=True)  # 生辰八字
    gender = Column(String(10), nullable=True)  # 性别
    mbti = Column(String(4), nullable=True)  # MBTI类型
    birth_time = Column(String(10), nullable=True)  # 出生时间，格式: HH:MM
    birthplace = Column(String(100), nullable=True)  # 出生地

    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    last_active = Column(DateTime(timezone=True), server_default=func.now())

    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    timezone = Column(String(64), default='Asia/Shanghai', nullable=False)  # 用户时区

    # 黑名单关系
    blocks_initiated = relationship("UserBlock", foreign_keys="[UserBlock.blocker_id]", back_populates="blocker", cascade="all, delete-orphan")
    blocked_by = relationship("UserBlock", foreign_keys="[UserBlock.blocked_id]", back_populates="blocked", cascade="all, delete-orphan")

    # 联系人关系
    contacts = relationship("TrustedContact", foreign_keys="[TrustedContact.owner_id]", back_populates="owner", cascade="all, delete-orphan")

    # 订阅关系
    subscriptions = relationship(
        "ServiceAccount",
        secondary="subscriptions",
        back_populates="subscribers")

    # 收藏关系
    favorites = relationship("Favorite", back_populates="user", cascade="all, delete-orphan")

    # 唯一约束
    __table_args__ = (
        UniqueConstraint('bipupu_id', name='unique_bipupu_id'),
        UniqueConstraint('username', name='unique_username'),
    )

    def increment_avatar_version(self):
        """增加头像版本号"""
        self.avatar_version = (self.avatar_version or 0) + 1

    def update_last_active(self):
        """更新最后活跃时间"""
        from datetime import datetime, timezone
        self.last_active = datetime.now(timezone.utc)

    @property
    def avatar_url(self) -> Optional[str]:
        """获取头像URL"""
        if self.avatar_data:
            return f"/api/users/{self.bipupu_id}/avatar"
        return None
