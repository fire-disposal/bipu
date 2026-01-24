"""消息回执事件模式"""
from pydantic import BaseModel, Field
from datetime import datetime

class MessageAckEventBase(BaseModel):
    """消息回执事件基础模式"""
    message_id: int = Field(..., description="消息ID")
    event: str = Field(..., description="事件类型（delivered/displayed/deleted）")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="事件时间")

class MessageAckEventCreate(MessageAckEventBase):
    """创建消息回执事件模式"""
    pass

class MessageAckEventResponse(MessageAckEventBase):
    """消息回执事件响应模式"""
    id: int

    class Config:
        from_attributes = True