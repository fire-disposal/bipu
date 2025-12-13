"""通知模型"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text, Enum, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from app.db.database import Base


class NotificationType(str, enum.Enum):
    """通知类型"""
    PUSH = "push"
    EMAIL = "email"
    SMS = "sms"
    WEBHOOK = "webhook"


class NotificationStatus(str, enum.Enum):
    """通知状态"""
    PENDING = "pending"
    SENT = "sent"
    FAILED = "failed"
    CANCELLED = "cancelled"


class Notification(Base):
    """通知模型"""
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    notification_type = Column(Enum(NotificationType), nullable=False)
    status = Column(Enum(NotificationStatus), default=NotificationStatus.PENDING)
    priority = Column(Integer, default=0)  # 优先级，数字越大优先级越高
    retry_count = Column(Integer, default=0)  # 重试次数
    max_retries = Column(Integer, default=3)  # 最大重试次数
    
    # 通知配置
    target = Column(String(500), nullable=False)  # 通知目标（邮箱、手机号、设备token等）
    config = Column(JSON, nullable=True)  # 通知配置（如邮件模板、推送配置等）
    
    # 外键
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message_id = Column(Integer, ForeignKey("messages.id"), nullable=True)  # 关联消息
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    scheduled_at = Column(DateTime(timezone=True), nullable=True)  # 计划发送时间
    sent_at = Column(DateTime(timezone=True), nullable=True)  # 实际发送时间
    
    # 结果信息
    result = Column(Text, nullable=True)  # 发送结果
    error_message = Column(Text, nullable=True)  # 错误信息
    
    # 关系
    user = relationship("User", back_populates="notifications")
    message = relationship("Message", back_populates="notifications")
    
    def __repr__(self):
        return f"<Notification(id={self.id}, title='{self.title}', type='{self.notification_type}')>"