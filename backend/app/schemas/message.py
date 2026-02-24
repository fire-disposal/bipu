"""BIPU机消息系统 Schema - 可靠健壮的物理设备消息传递

BIPU机消息系统设计原则：
1. 可靠传递：消息一旦发送，确保最终到达接收设备
2. 无需已读回执：系统不提供显式"已读"状态，传递即确认
3. 不可撤回：消息一旦发出，永久存储在系统中
4. 不可转发：消息仅在发送方和接收方之间传递
5. 不可编辑：消息内容一经发送，无法修改
6. 物理设备优先：为BIPU物理设备优化的消息格式
"""
from pydantic import BaseModel, Field, conlist
from datetime import datetime
from typing import Optional, Dict, Any, List


class MessageCreate(BaseModel):
    """创建消息 - BIPU机消息发送格式"""
    receiver_id: str = Field(..., description="接收者的 bipupu_id")
    content: str = Field(..., min_length=1, description="消息内容")
    # 使用字符串表示类型，避免全局枚举依赖。可选值: "NORMAL", "VOICE", "SYSTEM"
    message_type: str = Field(default="NORMAL", description="消息类型：NORMAL, VOICE, SYSTEM")
    pattern: Optional[Dict[str, Any]] = Field(None, description="json扩展字段")
    # 音频振幅包络 - 限制数组元素为0-255的整数，长度不超过128
    waveform: Optional[List[int]] = Field(None, description="音频振幅包络数组，0-255整数")


class MessageResponse(BaseModel):
    """消息响应 - BIPU机消息完整信息"""
    id: int
    sender_bipupu_id: str
    receiver_bipupu_id: str
    content: str
    message_type: str
    pattern: Optional[Dict[str, Any]] = None
    waveform: Optional[List[int]] = Field(None, description="音频振幅包络数组，0-255整数")
    created_at: datetime

    class Config:
        from_attributes = True


class MessageListResponse(BaseModel):
    """消息列表响应 - BIPU机消息分页查询"""
    messages: list[MessageResponse]
    total: int
    page: int
    page_size: int
