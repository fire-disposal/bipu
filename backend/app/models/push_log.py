from sqlalchemy import Column, Integer, String, DateTime, Text, Index, Enum
from sqlalchemy.dialects.postgresql import JSONB  # 针对 PG 的优化
from sqlalchemy.sql import func
from app.models.base import Base
import enum

class PushStatus(str, enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    SUCCESS = "success"
    FAILED = "failed"
    SKIPPED = "skipped"

class PushLog(Base):
    __tablename__ = "push_logs"

    id = Column(Integer, primary_key=True)

    # 推送基本信息
    service_name = Column(String(100), nullable=False) # 移除 index=True，由复合索引涵盖
    receiver_bipupu_id = Column(String(50), nullable=False) # 移除 index=True，由复合索引涵盖
    
    # 推送内容预览
    content_preview = Column(String(255), nullable=True) # Text 改为 String 限制长度更规范
    
    # 推送状态 - 关键：添加 name 参数
    status = Column(
        Enum(PushStatus, name="push_status_enum"), 
        nullable=False, 
        default=PushStatus.PENDING
    )
    
    error_message = Column(Text, nullable=True)
    retry_count = Column(Integer, server_default="0", nullable=False) # 建议使用 server_default
    max_retries = Column(Integer, server_default="3", nullable=False)
    
    # Celery任务信息
    task_id = Column(String(100), nullable=True)
    task_name = Column(String(100), nullable=True)
    
    # 使用 JSONB 以获得更好的 PG 性能
    extra_data = Column(JSONB, nullable=True) 
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    started_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    
    __table_args__ = (
        # 1. 查找某个服务的推送历史
        Index('idx_push_service_created', 'service_name', 'created_at'),
        # 2. 查找某个用户的推送记录
        Index('idx_push_receiver_created', 'receiver_bipupu_id', 'created_at'),
        # 3. 监控：查找失败或处理中的任务
        Index('idx_push_status_created', 'status', 'created_at'),
        # 4. 根据任务 ID 精确查找
        Index('idx_push_task_id', 'task_id'),
    )

    def __repr__(self):
        return f"<PushLog(id={self.id}, service='{self.service_name}', status='{self.status}')>"