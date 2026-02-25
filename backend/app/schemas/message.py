"""消息相关数据模型 - 优化版本

设计原则：
1. 精简：移除不必要的字段
2. 验证：添加类型和格式验证
3. 一致：统一字段命名规范
4. 实用：只包含实际使用的字段
"""

from pydantic import BaseModel, Field, field_validator
from datetime import datetime
from typing import Optional, List
from enum import Enum
from app.schemas.user import MessageType


class MessageCreate(BaseModel):
    """创建消息请求"""
    receiver_id: str = Field(..., min_length=1, max_length=100, description="接收者ID")
    content: str = Field(..., min_length=1, max_length=5000, description="消息内容")
    message_type: MessageType = Field(default=MessageType.NORMAL, description="消息类型")

    # 可选扩展字段
    pattern: Optional[dict] = Field(None, description="扩展模式数据")
    waveform: Optional[List[int]] = Field(
        None,
        description="音频波形数据",
        max_length=128  # 限制波形数据长度
    )

    @field_validator('waveform')
    @classmethod
    def validate_waveform(cls, v: Optional[List[int]]) -> Optional[List[int]]:
        """验证波形数据"""
        if v is None:
            return v

        if len(v) > 128:
            raise ValueError('波形数据长度不能超过128个点')

        for value in v:
            if not 0 <= value <= 255:
                raise ValueError('波形数据值必须在0-255之间')

        return v


class MessageResponse(BaseModel):
    """消息响应"""
    id: int
    sender_id: str = Field(..., description="发送者ID")
    receiver_id: str = Field(..., description="接收者ID")
    content: str
    message_type: MessageType
    pattern: Optional[dict] = None
    waveform: Optional[List[int]] = None
    created_at: datetime

    class Config:
        from_attributes = True


class MessageListResponse(BaseModel):
    """消息列表响应"""
    messages: List[MessageResponse]
    total: int
    page: int
    page_size: int


class MessagePollRequest(BaseModel):
    """轮询消息请求"""
    last_msg_id: int = Field(default=0, ge=0, description="最后收到的消息ID")
    timeout: int = Field(default=30, ge=1, le=120, description="轮询超时时间（秒）")


class MessagePollResponse(BaseModel):
    """轮询消息响应"""
    messages: List[MessageResponse]
    has_more: bool = Field(default=False, description="是否有更多消息")
