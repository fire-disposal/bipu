"""订阅管理模型"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, JSON, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.base import Base


class SubscriptionType(Base):
    """订阅类型模型"""
    __tablename__ = "subscription_types"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)  # 订阅名称
    description = Column(String(500), nullable=True)  # 描述
    category = Column(String(50), nullable=False)  # 分类：cosmic_messaging, system_notifications, etc.
    is_active = Column(Boolean, default=True)
    default_settings = Column(JSON, default={})  # 默认设置
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 关系
    user_subscriptions = relationship("UserSubscription", back_populates="subscription_type")


class UserSubscription(Base):
    """用户订阅模型"""
    __tablename__ = "user_subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    subscription_type_id = Column(Integer, ForeignKey("subscription_types.id"), nullable=False)
    
    # 个性化设置
    is_enabled = Column(Boolean, default=True)
    custom_settings = Column(JSON, default={})  # 个性化设置
    notification_time_start = Column(String(5), default="09:00")  # 开始时间 (HH:MM)
    notification_time_end = Column(String(5), default="22:00")   # 结束时间 (HH:MM)
    timezone = Column(String(50), default="Asia/Shanghai")
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 关系
    user = relationship("User", back_populates="subscriptions")
    subscription_type = relationship("SubscriptionType", back_populates="user_subscriptions")

    def __repr__(self):
        return f"<UserSubscription(id={self.id}, user={self.user_id}, type={self.subscription_type_id}, enabled={self.is_enabled})>"