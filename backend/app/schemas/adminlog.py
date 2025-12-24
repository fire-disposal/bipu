"""管理员操作日志模式"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, Dict, Any

class AdminLogBase(BaseModel):
    """管理员操作日志基础模式"""
    admin_id: int = Field(..., description="管理员ID")
    action: str = Field(..., description="操作类型")
    detail: Optional[Dict[str, Any]] = Field(None, description="操作详情（JSON）")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="操作时间")

class AdminLogCreate(AdminLogBase):
    """创建管理员操作日志模式"""
    pass

class AdminLogResponse(AdminLogBase):
    """管理员操作日志响应模式"""
    id: int

    class Config:
        from_attributes = True