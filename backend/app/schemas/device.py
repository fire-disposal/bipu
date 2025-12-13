"""设备相关模式"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, Dict, Any


class DeviceBase(BaseModel):
    """设备基础模式"""
    name: str = Field(..., min_length=1, max_length=100)
    device_type: str = Field(..., min_length=1, max_length=50)
    device_id: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    status: str = Field(default="offline", regex="^(online|offline|error|maintenance)$")
    config: Optional[Dict[str, Any]] = None
    location: Optional[str] = Field(None, max_length=200)
    is_active: bool = True


class DeviceCreate(DeviceBase):
    """创建设备模式"""
    pass


class DeviceUpdate(BaseModel):
    """更新设备模式"""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    device_type: Optional[str] = Field(None, min_length=1, max_length=50)
    device_id: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    status: Optional[str] = Field(None, regex="^(online|offline|error|maintenance)$")
    config: Optional[Dict[str, Any]] = None
    location: Optional[str] = Field(None, max_length=200)
    is_active: Optional[bool] = None
    last_seen_at: Optional[datetime] = None


class DeviceResponse(DeviceBase):
    """设备响应模式"""
    id: int
    user_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    last_seen_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class DeviceList(BaseModel):
    """设备列表响应模式"""
    items: list[DeviceResponse]
    total: int
    page: int
    size: int


class DeviceStats(BaseModel):
    """设备统计信息"""
    total: int
    online: int
    offline: int
    error: int
    maintenance: int