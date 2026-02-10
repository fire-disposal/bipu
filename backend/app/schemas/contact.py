"""联系人schemas"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class ContactCreate(BaseModel):
    """添加联系人"""
    contact_id: str = Field(..., description="联系人的 bipupu_id")
    alias: Optional[str] = Field(None, description="备注名")


class ContactUpdate(BaseModel):
    """更新联系人"""
    alias: Optional[str] = Field(None, description="备注名")


class ContactResponse(BaseModel):
    """联系人响应"""
    id: int
    contact_id: int  # 内部ID
    contact_bipupu_id: str  # bipupu_id
    contact_username: str
    contact_nickname: Optional[str]
    alias: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class ContactListResponse(BaseModel):
    """联系人列表响应"""
    contacts: list[ContactResponse]
    total: int
