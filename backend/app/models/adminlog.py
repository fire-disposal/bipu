from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, JSON
from sqlalchemy.sql import func
from app.models.base import Base

class AdminLog(Base):
    """管理员操作日志模型"""
    __tablename__ = "admin_logs"

    id = Column(Integer, primary_key=True, index=True)
    admin_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    action = Column(String(100), nullable=False)
    detail = Column(JSON, nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())