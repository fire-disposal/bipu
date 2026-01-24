from pydantic import BaseModel
from typing import Optional, Any
from datetime import datetime


class AdminLogBase(BaseModel):
    action: str
    details: Optional[dict[str, Any]] = None


class AdminLogCreate(AdminLogBase):
    admin_id: Optional[int] = None


class AdminLogResponse(AdminLogBase):
    id: int
    admin_id: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True
