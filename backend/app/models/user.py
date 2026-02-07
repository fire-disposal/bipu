from sqlalchemy import Column, Integer, String, DateTime, Boolean, LargeBinary
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.base import Base


class User(Base):
    """用户模型"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(50), unique=True, index=True, nullable=False)
    nickname = Column(String(50), nullable=True)
    avatar_data = Column(LargeBinary, nullable=True)  # 存储图像二进制数据
    avatar_filename = Column(String(255), nullable=True)  # 存储原始文件名
    avatar_mimetype = Column(String(50), nullable=True)  # 存储MIME类型
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    last_active = Column(DateTime(timezone=True), server_default=func.now())

    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 订阅关系
    subscriptions = relationship("UserSubscription", back_populates="user", cascade="all, delete-orphan")
    
    # 消息相关关系
    messages_sent = relationship("Message", foreign_keys="[Message.sender_id]", back_populates="sender", cascade="all, delete-orphan")
    messages_received = relationship("Message", foreign_keys="[Message.receiver_id]", back_populates="receiver", cascade="all, delete-orphan")
    favorite_messages = relationship("MessageFavorite", back_populates="user", cascade="all, delete-orphan")
    
    # 社交关系
    friendships_initiated = relationship("Friendship", foreign_keys="[Friendship.user_id]", back_populates="user", cascade="all, delete-orphan")
    friendships_received = relationship("Friendship", foreign_keys="[Friendship.friend_id]", back_populates="friend", cascade="all, delete-orphan")
    
    # 黑名单关系
    blocks_initiated = relationship("UserBlock", foreign_keys="[UserBlock.blocker_id]", back_populates="blocker", cascade="all, delete-orphan")
    blocked_by = relationship("UserBlock", foreign_keys="[UserBlock.blocked_id]", back_populates="blocked", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}', username='{self.username}', is_superuser={self.is_superuser})>"