from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, JSON, Date
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.database import Base
from app.models.user_block import UserBlock
from app.models.message_favorite import MessageFavorite
from app.models.subscription import UserSubscription


class User(Base):
    """用户模型"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(50), unique=True, index=True, nullable=False)
    nickname = Column(String(50), nullable=True)
    full_name = Column(String(100), nullable=True)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    role = Column(String(20), default="user", nullable=False)  # "user" / "admin"
    last_active = Column(DateTime(timezone=True), server_default=func.now())

    # 个人资料扩展字段
    avatar_url = Column(String(500), nullable=True)  # 头像URL
    birth_date = Column(Date, nullable=True)  # 生日
    zodiac_sign = Column(String(20), nullable=True)  # 星座
    birth_chart = Column(JSON, nullable=True)  # 生辰八字 {"year": "", "month": "", "day": "", "hour": "", "element": "", "animal": ""}
    mbti_type = Column(String(10), nullable=True)  # MBTI类型
    cosmic_profile = Column(JSON, nullable=True)  # 宇宙传讯信息 {"energy_type": "", "life_path": "", "soul_urge": ""}
    
    # 隐私设置
    privacy_settings = Column(JSON, default={
        "profile_visibility": "friends",  # public, friends, private
        "message_protection": True,  # 消息保护
        "cooldown_enabled": True,  # 冷却功能
        "cooldown_duration": 300,  # 冷却时间（秒）
    })
    
    # 用户协议
    terms_accepted = Column(Boolean, default=False)
    terms_accepted_at = Column(DateTime(timezone=True), nullable=True)
    
    # 订阅设置
    subscription_settings = Column(JSON, default={
        "cosmic_messaging": True,  # 宇宙传讯服务
        "notification_time_start": "09:00",  # 接收开始时间
        "notification_time_end": "22:00",  # 接收结束时间
        "timezone": "Asia/Shanghai",
    })

    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 关系
    messages_sent = relationship(
        "Message",
        foreign_keys="[Message.sender_id]",
        back_populates="sender",
        cascade="all, delete-orphan"
    )
    messages_received = relationship(
        "Message",
        foreign_keys="[Message.receiver_id]",
        back_populates="receiver",
        cascade="all, delete-orphan"
    )
    
    # 黑名单关系
    blocked_users = relationship(
        "User",
        secondary="user_blocks",
        primaryjoin="User.id==UserBlock.blocker_id",
        secondaryjoin="User.id==UserBlock.blocked_id",
        backref="blocked_by"
    )
    
    # 收藏的消息
    favorite_messages = relationship(
        "MessageFavorite",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    
    # 订阅管理
    subscriptions = relationship(
        "UserSubscription",
        back_populates="user",
        cascade="all, delete-orphan"
    )

    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}', username='{self.username}', role='{self.role}')>"