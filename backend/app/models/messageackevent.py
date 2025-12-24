from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.db.database import Base

class MessageAckEvent(Base):
    """消息回执事件模型"""
    __tablename__ = "messageackevents"

    id = Column(Integer, primary_key=True, index=True)
    message_id = Column(Integer, ForeignKey("messages.id"), nullable=False)
    event = Column(String(20), nullable=False)  # "delivered", "displayed", "deleted"
    timestamp = Column(DateTime(timezone=True), server_default=func.now())