"""消息模型 - 重构版本"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, JSON, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.base import Base


class Message(Base):
    """消息模型 - 传讯式设计
    
    核心理念：
    - 用户间传讯（非聊天）
    - 服务号消息（订阅推送）
    - 系统通知
    
    关键字段说明：
    - sender_id: 发送者的bipupu_id或服务号ID（如"cosmic.fortune"）
    - receiver_id: 接收者的bipupu_id
    - msg_type: 消息类型（USER_POSTCARD, VOICE_TRANSCRIPT, COSMIC_BROADCAST）
    - pattern: 控制pupu机显示/光效/屏保等的JSON配置
    """
    __tablename__ = "messages"

    # 主键
    id = Column(Integer, primary_key=True, index=True)

    # 消息内容
    content = Column(Text, nullable=False)
    
    # 消息类型
    msg_type = Column(String(50), nullable=False, index=True)  # USER_POSTCARD, VOICE_TRANSCRIPT, COSMIC_BROADCAST
    
    # sender_id和receiver_id现在存储bipupu_id（字符串）或服务号ID
    # 为了兼容性，暂时保留Integer类型，但会添加字符串字段
    sender_bipupu_id = Column(String(50), nullable=False, index=True)  # bipupu_id 或 服务号 ID
    receiver_bipupu_id = Column(String(50), nullable=False, index=True)  # 必须是真实用户的 bipupu_id
    
    # 复合信息（控制 pupu 机显示/光效/屏保等）
    pattern = Column(JSON, nullable=True)
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)

    # 复合索引 - 优化查询
    __table_args__ = (
        Index('idx_receiver_created', 'receiver_bipupu_id', 'created_at'),
        Index('idx_sender_created', 'sender_bipupu_id', 'created_at'),
        Index('idx_msg_type', 'msg_type', 'created_at'),
    )

    def __repr__(self):
        return f"<Message(id={self.id}, sender='{self.sender_bipupu_id}', receiver='{self.receiver_bipupu_id}', type='{self.msg_type}')>"
