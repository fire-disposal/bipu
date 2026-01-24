"""用户黑名单模型"""
from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.base import Base


class UserBlock(Base):
    """用户黑名单模型"""
    __tablename__ = "user_blocks"

    id = Column(Integer, primary_key=True, index=True)
    blocker_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    blocked_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 关系
    blocker = relationship("User", foreign_keys=[blocker_id], back_populates="blocks_initiated")
    blocked = relationship("User", foreign_keys=[blocked_id], back_populates="blocked_by")

    # 确保用户不能重复拉黑同一个人
    __table_args__ = (
        UniqueConstraint('blocker_id', 'blocked_id', name='unique_user_block'),
    )

    def __repr__(self):
        return f"<UserBlock(id={self.id}, blocker={self.blocker_id}, blocked={self.blocked_id})>"