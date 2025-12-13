"""设备模型"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.database import Base


class Device(Base):
    """设备模型"""
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    device_type = Column(String(50), nullable=False)  # 设备类型
    device_id = Column(String(100), unique=True, nullable=False)  # 设备唯一标识
    description = Column(Text, nullable=True)
    status = Column(String(20), default="offline")  # online, offline, error, maintenance
    config = Column(JSON, nullable=True)  # 设备配置信息
    location = Column(String(200), nullable=True)  # 设备位置
    is_active = Column(Boolean, default=True)
    
    # 外键
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_seen_at = Column(DateTime(timezone=True), nullable=True)  # 最后在线时间
    
    # 关系
    user = relationship("User", back_populates="devices")
    messages = relationship("Message", back_populates="device", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Device(id={self.id}, name='{self.name}', device_id='{self.device_id}')>"