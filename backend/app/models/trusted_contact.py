"""联系人模型"""
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.base import Base


class TrustedContact(Base):
    """联系人模型"""
    __tablename__ = "trusted_contacts"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    contact_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    alias = Column(String(100), nullable=True)  # 备注名
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 关系
    owner = relationship("User", foreign_keys=[owner_id], back_populates="contacts")
    contact = relationship("User", foreign_keys=[contact_id])

    # 确保不重复添加同一联系人
    __table_args__ = (
        UniqueConstraint('owner_id', 'contact_id', name='unique_contact'),
    )

    def __repr__(self):
        return f"<TrustedContact(id={self.id}, owner={self.owner_id}, contact={self.contact_id})>"
