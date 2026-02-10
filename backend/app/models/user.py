from sqlalchemy import Column, Integer, String, DateTime, Boolean, LargeBinary, JSON, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.base import Base


class User(Base):
    """用户模型"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    bipupu_id = Column(String(8), unique=True, index=True, nullable=False)  # 8位纯数字ID
    username = Column(String(50), unique=True, index=True, nullable=False)
    nickname = Column(String(50), nullable=True)
    avatar_data = Column(LargeBinary, nullable=True)  # 存储图像二进制数据
    avatar_filename = Column(String(255), nullable=True)  # 存储原始文件名
    avatar_mimetype = Column(String(50), nullable=True)  # 存储MIME类型
    hashed_password = Column(String(255), nullable=False)
    cosmic_profile = Column(JSON, nullable=True)  # 生日、八字、MBTI等
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    last_active = Column(DateTime(timezone=True), server_default=func.now())

    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

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
    
    @property
    def avatar_url(self):
        """生成头像URL"""
        if self.avatar_data:
            # 返回API端点，用于获取头像
            return f"/api/users/{self.bipupu_id}/avatar"
        return None

    def __repr__(self):
        return f"<User(id={self.id}, bipupu_id='{self.bipupu_id}', username='{self.username}', is_superuser={self.is_superuser})>"