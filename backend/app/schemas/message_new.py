"""消息schemas - 重构版本"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, Dict, Any


class MessageCreate(BaseModel):
    """创建消息"""
    receiver_id: str = Field(..., description="接收者的 bipupu_id")
    content: str = Field(..., min_length=1, description="消息内容")
    msg_type: str = Field(default="USER_POSTCARD", description="消息类型：USER_POSTCARD, VOICE_TRANSCRIPT, COSMIC_BROADCAST")
    pattern: Optional[Dict[str, Any]] = Field(None, description="控制 pupu 机显示/光效/屏保等")


class MessageResponse(BaseModel):
    """消息响应"""
    id: int
    sender_bipupu_id: str
    receiver_bipupu_id: str
    content: str
    msg_type: str
    pattern: Optional[Dict[str, Any]] = None
    created_at: datetime

    class Config:
        from_attributes = True


class MessageListResponse(BaseModel):
    """消息列表响应"""
    messages: list[MessageResponse]
    total: int
    page: int
    page_size: int
