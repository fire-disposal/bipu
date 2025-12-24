"""站内信模型"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text, Enum, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from app.db.database import Base


class NotificationStatus(str, enum.Enum):
    """站内信状态"""
    UNREAD = "unread"
    READ = "read"
    DELETED = "deleted"


class Notification(Base):
    """站内信模型"""
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    status = Column(Enum(NotificationStatus), default=NotificationStatus.UNREAD)
    priority = Column(Integer, default=0)  # 优先级，数字越大优先级越高
    
    # 外键
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message_id = Column(Integer, ForeignKey("messages.id"), nullable=True)  # 关联消息
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    read_at = Column(DateTime(timezone=True), nullable=True)  # 阅读时间
    
    # 关系
    user = relationship("User", back_populates="notifications")
    message = relationship("Message", back_populates="notifications")
    
    def __repr__(self):
        return f"<Notification(id={self.id}, title='{self.title}', status='{self.status}')>"