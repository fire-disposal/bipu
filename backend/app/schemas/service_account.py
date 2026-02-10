from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class ServiceAccountBase(BaseModel):
    name: str
    description: Optional[str] = None
    avatar_url: Optional[str] = None
    is_active: bool = True

class ServiceAccountResponse(ServiceAccountBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    # 是否已订阅（需要结合当前用户上下文，这里先只返回基础信息，
    # 或者前端自己判断用户订阅列表中是否有此号）
    
    class Config:
        from_attributes = True

class ServiceAccountList(BaseModel):
    items: List[ServiceAccountResponse]
    total: int
