"""消息模型改进版本"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text, Enum, JSON, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from app.models.base import Base


class MessageType(str, enum.Enum):
    """消息类型"""
    SYSTEM = "system"
    USER = "user"
    ALERT = "alert"
    NOTIFICATION = "notification"


class MessageStatus(str, enum.Enum):
    """消息状态"""
    UNREAD = "unread"
    READ = "read"
    ARCHIVED = "archived"


class Message(Base):
    """消息模型 - 改进版本
    
    支持多种消息类型：
    - IM 用户间消息（user_message）
    - 系统通知（system_broadcast）
    - 订阅推送（weather_subscription, fortune_subscription 等）
    - 设备消息（device_alert）
    - 警报消息（alert）
    
    关键字段说明：
    - pattern: 复合信息 JSON，包含 RGB、振动、屏幕、宇宙传讯数据等
    - category: 快速分类字段，用于高效查询特定类型消息
    - is_deleted: 软删除标记，支持数据恢复和审计
    """
    __tablename__ = "messages"

    # 主键
    id = Column(Integer, primary_key=True, index=True)
    
    # 标题
    title = Column(String(200), nullable=False, index=True)

    # 消息内容
    content = Column(Text, nullable=False)
    
    # 消息类型
    message_type = Column(Enum(MessageType), nullable=False, index=True)
    
    # 消息状态
    status = Column(Enum(MessageStatus), default=MessageStatus.UNREAD, index=True)
    is_read = Column(Boolean, default=False, index=True)
    
    # 删除状态（软删除）
    is_deleted = Column(Boolean, default=False, index=True, server_default='false')
    
    # 优先级（0-10，数字越大优先级越高）
    priority = Column(Integer, default=0)
    
    # 复合信息（灵活扩展字段）
    # 支持的字段：
    # {
    #   "source_type": "subscription|system|user|device",  // 必需
    #   "source_id": 123,  // 必需
    #   "subscription_type": "weather|fortune|...",  // 可选
    #   "rgb": {"r": 255, "g": 100, "b": 100},  // 可选
    #   "vibe": {"intensity": 50, "duration": 2000},  // 可选
    #   "screen": {"text": "显示文本", "duration": 3000},  // 可选
    #   "cosmic_data": {"energy_level": 5, "zodiac_sign": "aries", ...},  // 可选
    #   ... 其他自定义数据
    # }
    pattern = Column(JSON, nullable=True)
    
    # 外键
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    receiver_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    # 审计字段
    deleted_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    deleted_reason = Column(String(255), nullable=True)
    
    # 时间戳 - 追踪消息生命周期
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), nullable=False)
    delivered_at = Column(DateTime(timezone=True), nullable=True, index=True)
    read_at = Column(DateTime(timezone=True), nullable=True, index=True)
    deleted_at = Column(DateTime(timezone=True), nullable=True, index=True)

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
    
    favorited_by = relationship("MessageFavorite", back_populates="message", cascade="all, delete-orphan")
    ack_events = relationship("MessageAckEvent", back_populates="message", cascade="all, delete-orphan")

    deleted_by_user = relationship(
        "User",
        foreign_keys=[deleted_by],
        primaryjoin="Message.deleted_by == User.id"
    )

    def __repr__(self):
        return f"<Message id={self.id} sender={self.sender_id} receiver={self.receiver_id}>"

    # 复合索引 - 优化常见查询场景
    __table_args__ = (
        # 获取用户未读消息 - 关键性能查询
        Index('idx_receiver_is_read', 'receiver_id', 'is_read'),
        
        # 获取用户的所有消息，按创建时间排序
        Index('idx_receiver_created_at', 'receiver_id', 'created_at', 'is_deleted'),
        Index('idx_sender_created_at', 'sender_id', 'created_at', 'is_deleted'),
        
        # 获取会话消息
        Index('idx_receiver_sender_created', 'receiver_id', 'sender_id', 'created_at', 'is_deleted'),
        
        # 按类型和状态查询
        Index('idx_type_status', 'message_type', 'status', 'is_deleted'),
        
        # 时间范围查询
        Index('idx_created_range', 'created_at', 'is_deleted'),
        
        # 删除审计
        Index('idx_deleted_at', 'deleted_at'),
        
        # 综合查询 - 获取用户接收的未读消息，按时间倒序
        Index('idx_receiver_is_read_created', 'receiver_id', 'is_read', 'created_at', 'is_deleted'),
    )

    def __repr__(self):
        return (
            f"<Message(id={self.id}, title='{self.title}', type='{self.message_type}', "
            f"sender={self.sender_id}, receiver={self.receiver_id}, "
            f"is_read={self.is_read}, is_deleted={self.is_deleted})>"
        )
    
    def mark_as_read(self):
        """标记为已读"""
        if not self.is_read:
            self.is_read = True
            self.status = MessageStatus.READ
            self.read_at = func.now()
    
    def mark_as_delivered(self):
        """标记为已投递"""
        if not self.delivered_at:
            self.delivered_at = func.now()
    
    def soft_delete(self, deleted_by_id: int = None, reason: str = None):
        """软删除 - 标记为删除但保留数据用于审计"""
        self.is_deleted = True
        self.deleted_at = func.now()
        if deleted_by_id:
            self.deleted_by = deleted_by_id
        if reason:
            self.deleted_reason = reason
    
    def restore(self):
        """恢复已软删除的消息"""
        self.is_deleted = False
        self.deleted_at = None
        self.deleted_by = None
        self.deleted_reason = None
