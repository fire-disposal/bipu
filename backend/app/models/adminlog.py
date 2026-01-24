from sqlalchemy import Column, Integer, String, DateTime, JSON, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.base import Base


class AdminLog(Base):
    """管理员操作日志（精简版）"""
    __tablename__ = "admin_logs"

    id = Column(Integer, primary_key=True, index=True)
    admin_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), index=True, nullable=True)
    action = Column(String(100), nullable=False)
    details = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # 关系
    admin = relationship("User", foreign_keys=[admin_id])

    def __repr__(self):
        return f"<AdminLog(id={self.id}, admin_id={self.admin_id}, action='{self.action}')>"
