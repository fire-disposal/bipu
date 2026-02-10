from sqlalchemy import Column, Integer, String, DateTime, Boolean, LargeBinary, JSON, Table, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.base import Base

# 订阅关联表
subscription_table = Table('subscriptions', Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True),
    Column('service_account_id', Integer, ForeignKey('service_accounts.id'), primary_key=True)
)

class ServiceAccount(Base):
    """服务号模型"""
    __tablename__ = "service_accounts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, index=True, nullable=False) # 全局唯一服务名，如 cosmic.fortune
    description = Column(String(255), nullable=True)
    avatar_data = Column(LargeBinary, nullable=True)
    avatar_filename = Column(String(255), nullable=True)
    avatar_mimetype = Column(String(50), nullable=True)
    bot_logic = Column(JSON, nullable=True)  # 存储bot逻辑的配置
    is_active = Column(Boolean, default=True)
    
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 订阅者关系
    subscribers = relationship(
        "User",
        secondary=subscription_table,
        back_populates="subscriptions")

    @property
    def avatar_url(self):
        """生成头像URL"""
        if self.avatar_data:
            return f"/api/service_accounts/{self.name}/avatar"
        return None

    def __repr__(self):
        return f"<ServiceAccount(id={self.id}, name='{self.name}')>"
