"""消息相关数据模型 - 优化版本

设计原则：
1. 精简：移除不必要的字段
2. 验证：添加类型和格式验证
3. 一致：统一字段命名规范
4. 实用：只包含实际使用的字段
5. 清晰：OpenAPI schema 定义规范
"""

from pydantic import BaseModel, Field, field_validator, ConfigDict
from datetime import datetime
from typing import List
from app.schemas.user import MessageType


class MessageCreate(BaseModel):
    """创建消息请求
    
    支持：
    - 用户间传讯（receiver_id 为用户的 bipupu_id）
    - 向服务号发送消息（receiver_id 为服务号 ID）
    """
    # 必需字段
    receiver_id: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="接收者ID（用户的bipupu_id或服务号ID）"
    )
    content: str = Field(
        ...,
        min_length=1,
        max_length=5000,
        description="消息内容"
    )
    
    # 可选字段 - 使用 = None 明确表示可选，避免 anyOf
    message_type: MessageType = Field(
        default=MessageType.NORMAL,
        description="消息类型（NORMAL, VOICE, SYSTEM）"
    )
    pattern: dict | None = Field(
        default=None,
        description="扩展模式数据"
    )
    waveform: List[int] | None = Field(
        default=None,
        description="音频波形数据（0-255整数数组，最多128个点）"
    )

    model_config = ConfigDict(json_schema_extra={
        "example": {
            "receiver_id": "user123",
            "content": "你好，这是一条测试消息",
            "message_type": "NORMAL",
            "pattern": None,
            "waveform": [0, 10, 20, 30, 40, 50]
        }
    })

    @field_validator('waveform')
    @classmethod
    def validate_waveform(cls, v: List[int] | None) -> List[int] | None:
        """验证波形数据的有效性"""
        if v is None:
            return v

        if not isinstance(v, list):
            raise ValueError('波形数据必须是整数列表')

        if len(v) > 128:
            raise ValueError('波形数据长度不能超过128个点')

        for idx, value in enumerate(v):
            if not isinstance(value, int):
                raise ValueError(f'波形数据[{idx}]必须是整数')
            if not 0 <= value <= 255:
                raise ValueError(f'波形数据值必须在0-255之间，第{idx}个值为{value}')

        return v


class MessageResponse(BaseModel):
    """消息响应"""
    # 必需字段
    id: int = Field(..., description="消息ID")
    sender_bipupu_id: str = Field(..., description="发送者的bipupu_id")
    receiver_bipupu_id: str = Field(..., description="接收者的bipupu_id")
    content: str = Field(..., description="消息内容")
    message_type: MessageType = Field(..., description="消息类型")
    created_at: datetime = Field(..., description="消息创建时间")
    
    # 可选字段
    pattern: dict | None = Field(default=None, description="扩展模式数据")
    waveform: List[int] | None = Field(default=None, description="音频波形数据")

    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "id": 1,
                "sender_bipupu_id": "user123",
                "receiver_bipupu_id": "user456",
                "content": "你好",
                "message_type": "NORMAL",
                "created_at": "2024-01-01T12:00:00Z",
                "pattern": None,
                "waveform": None
            }
        }
    )


class MessageListResponse(BaseModel):
    """消息列表响应"""
    messages: List[MessageResponse] = Field(..., description="消息列表")
    total: int = Field(..., ge=0, description="总消息数")
    page: int = Field(..., ge=1, description="当前页码")
    page_size: int = Field(..., ge=1, description="每页数量")
    
    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "messages": [],
                "total": 100,
                "page": 1,
                "page_size": 20
            }
        }
    )


class MessagePollRequest(BaseModel):
    """轮询消息请求
    
    用于长轮询获取新消息
    """
    last_msg_id: int = Field(
        default=0,
        ge=0,
        description="最后收到的消息ID，轮询将返回ID大于此值的新消息"
    )
    timeout: int = Field(
        default=30,
        ge=1,
        le=120,
        description="轮询超时时间（秒），服务器将等待最多此时间后返回"
    )
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "last_msg_id": 100,
                "timeout": 30
            }
        }
    )


class MessagePollResponse(BaseModel):
    """轮询消息响应
    
    包含自上次轮询后收到的新消息
    """
    messages: List[MessageResponse] = Field(..., description="新消息列表")
    has_more: bool = Field(
        default=False,
        description="是否有更多消息未返回（超过限制）"
    )
    
    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "messages": [],
                "has_more": False
            }
        }
    )


class MessageIncrementalSyncRequest(BaseModel):
    """增量同步请求
    
    用于增量获取消息变化
    """
    since_id: int = Field(
        default=0,
        ge=0,
        description="参考点消息ID，仅返回ID大于此值的消息"
    )
    direction: str = Field(
        default="received",
        description="消息方向：'sent'(发送的消息) 或 'received'(接收的消息)"
    )
    page_size: int = Field(
        default=20,
        ge=1,
        le=100,
        description="每次返回的最大消息数"
    )
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "since_id": 0,
                "direction": "received",
                "page_size": 20
            }
        }
    )


class MessageIncrementalSyncResponse(BaseModel):
    """增量同步响应
    
    包含增量变化的消息
    """
    messages: List[MessageResponse] = Field(..., description="消息列表")
    has_more: bool = Field(
        default=False,
        description="是否有更多消息未返回"
    )
    last_id: int = Field(
        default=0,
        ge=0,
        description="本次返回的最大消息ID，用于下次同步的since_id"
    )
    
    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "messages": [],
                "has_more": False,
                "last_id": 100
            }
        }
    )

