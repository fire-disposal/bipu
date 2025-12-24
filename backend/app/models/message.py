"""消息模型"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text, Enum, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from app.db.database import Base


class MessageType(str, enum.Enum):
    """消息类型"""
    SYSTEM = "system"
    DEVICE = "device"
    USER = "user"
    ALERT = "alert"
    NOTIFICATION = "notification"


class MessageStatus(str, enum.Enum):
    """消息状态"""
    UNREAD = "unread"
    READ = "read"
    ARCHIVED = "archived"


class Message(Base):
    """消息模型"""
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    message_type = Column(Enum(MessageType), nullable=False)
    status = Column(Enum(MessageStatus), default=MessageStatus.UNREAD)
    priority = Column(Integer, default=0)  # 优先级，数字越大优先级越高
    is_read = Column(Boolean, default=False)
    pattern = Column(JSON, nullable=True)  # {"vibe": {...}, "rgb": {...}, "screen": {...}}

    # 外键
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    device_id = Column(Integer, ForeignKey("devices.id"), nullable=True)  # 可选，关联设备

    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    delivered_at = Column(DateTime(timezone=True), nullable=True)
    read_at = Column(DateTime(timezone=True), nullable=True)  # 阅读时间

    # 关系
    sender = relationship(
        "User",
        foreign_keys=[sender_id],
        back_populates="messages_sent"
    )
    receiver = relationship(
        "User",
        foreign_keys=[receiver_id],
        back_populates="messages_received"
    )
    device = relationship("Device", back_populates="messages")
    notifications = relationship("Notification", back_populates="message", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Message(id={self.id}, title='{self.title}', type='{self.message_type}', sender={self.sender_id}, receiver={self.receiver_id})>"