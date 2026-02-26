"""服务号模型 - 增强版本，支持推送时间设置"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, LargeBinary, JSON, Table, ForeignKey, Time
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.models.base import Base

# 增强的订阅关联表 - 支持推送时间设置
subscription_table = Table('subscriptions', Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True),
    Column('service_account_id', Integer, ForeignKey('service_accounts.id'), primary_key=True),
    Column('push_time', Time, nullable=True),  # 推送时间，格式: HH:MM:SS
    Column('is_enabled', Boolean, default=True),  # 是否启用推送
    Column('created_at', DateTime(timezone=True), server_default=func.now()),
    Column('updated_at', DateTime(timezone=True), onupdate=func.now())
)

class ServiceAccount(Base):
    """服务号模型"""
    __tablename__ = "service_accounts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, index=True, nullable=False) # 全局唯一服务名，如 cosmic.fortune
    description = Column(String(255), nullable=True)
    avatar_data = Column(LargeBinary, nullable=True)
    bot_logic = Column(JSON, nullable=True)  # 存储bot逻辑的配置
    is_active = Column(Boolean, default=True)
    default_push_time = Column(Time, nullable=True)  # 默认推送时间

    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 订阅者关系（使用增强的关联表）
    subscribers = relationship(
        "User",
        secondary=subscription_table,
        back_populates="subscriptions"
    )

    @property
    def avatar_url(self):
        """生成头像URL"""
        if self.avatar_data:
            return f"/api/service_accounts/{self.name}/avatar"
        return None

    def get_subscription_settings(self, user_id: int):
        """获取用户的订阅设置"""
        from sqlalchemy import select
        from app.db.database import SessionLocal

        db = SessionLocal()
        try:
            result = db.execute(
                select(subscription_table.c.push_time, subscription_table.c.is_enabled)
                .where(
                    subscription_table.c.user_id == user_id,
                    subscription_table.c.service_account_id == self.id
                )
            ).first()

            if result:
                return {
                    "push_time": result.push_time,
                    "is_enabled": result.is_enabled
                }
            return None
        finally:
            db.close()

    def update_subscription_settings(self, user_id: int, push_time: str | None = None, is_enabled: bool | None = None):
        """更新用户的订阅设置"""
        from sqlalchemy import update
        from datetime import time
        from app.db.database import SessionLocal

        db = SessionLocal()
        try:
            update_data = {}

            if push_time is not None:
                # 解析时间字符串
                if isinstance(push_time, str):
                    hour, minute = map(int, push_time.split(':'))
                    update_data['push_time'] = time(hour, minute)
                elif isinstance(push_time, time):
                    update_data['push_time'] = push_time

            if is_enabled is not None:
                update_data['is_enabled'] = is_enabled

            if update_data:
                update_data['updated_at'] = func.now()

                stmt = (
                    update(subscription_table)
                    .where(
                        subscription_table.c.user_id == user_id,
                        subscription_table.c.service_account_id == self.id
                    )
                    .values(**update_data)
                )

                db.execute(stmt)
                db.commit()
                # 执行成功即返回True
                return True

            return False
        except Exception as e:
            db.rollback()
            raise
        finally:
            db.close()

    def __repr__(self):
        return f"<ServiceAccount(id={self.id}, name='{self.name}', is_active={self.is_active})>"
