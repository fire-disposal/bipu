"""消息收藏模型"""
from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.base import Base


class MessageFavorite(Base):
    """消息收藏模型"""
    __tablename__ = "message_favorites"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message_id = Column(Integer, ForeignKey("messages.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 关系 - 使用字符串延迟解析避免循环依赖
    user = relationship("User", back_populates="favorite_messages")
    message = relationship("Message", back_populates="favorited_by", lazy="select")
    
    # 确保用户不能重复收藏同一条消息
    __table_args__ = (
        UniqueConstraint('user_id', 'message_id', name='unique_user_message_favorite'),
    )

    def __repr__(self):
        return f"<MessageFavorite(id={self.id}, user={self.user_id}, message={self.message_id})>"