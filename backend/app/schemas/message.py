"""消息相关模式"""
from pydantic import BaseModel, Field, validator
from datetime import datetime
from typing import Optional
from enum import Enum


class MessageType(str, Enum):
    """消息类型"""
    SYSTEM = "system"
    DEVICE = "device"
    USER = "user"
    ALERT = "alert"
    NOTIFICATION = "notification"


class MessageStatus(str, Enum):
    """消息状态"""
    UNREAD = "unread"
    READ = "read"
    ARCHIVED = "archived"


class MessageBase(BaseModel):
    """消息基础模式 - 支持复合信息"""
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1)
    message_type: MessageType
    priority: int = Field(default=0, ge=0, le=10)
    pattern: Optional[dict] = None  # 复合信息格式：{"vibe": {...}, "screen": {...}, "source_type": "user", "source_id": 123, "cosmic_data": {...}}
    sender_id: Optional[int] = None
    receiver_id: Optional[int] = None


class MessageCreate(MessageBase):
    """创建消息模式"""
    
    @validator('pattern')
    def validate_pattern(cls, v):
        """验证复合信息格式"""
        if v is not None and isinstance(v, dict):
            # 验证震动格式
            if 'vibe' in v and isinstance(v['vibe'], dict):
                vibe = v['vibe']
                if 'intensity' in vibe and not (0 <= vibe['intensity'] <= 100):
                    raise ValueError('震动强度必须在0-100之间')
                if 'duration' in vibe and vibe['duration'] < 0:
                    raise ValueError('震动时长不能为负数')
            
            # 验证屏幕信息
            if 'screen' in v and isinstance(v['screen'], dict):
                screen = v['screen']
                if 'text' in screen and len(screen['text']) > 1000:
                    raise ValueError('屏幕文本内容过长（最大1000字符）')
            
            # 验证来源信息
            if 'source_type' in v and v['source_type'] not in ['user', 'system', 'cosmic', 'device']:
                raise ValueError('来源类型必须是 user, system, cosmic, device 之一')
            
            # 验证宇宙传讯数据
            if 'cosmic_data' in v and isinstance(v['cosmic_data'], dict):
                cosmic = v['cosmic_data']
                if 'energy_level' in cosmic and not (1 <= cosmic['energy_level'] <= 10):
                    raise ValueError('能量等级必须在1-10之间')
                if 'zodiac_sign' in cosmic and cosmic['zodiac_sign'] not in [
                    'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
                    'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces'
                ]:
                    raise ValueError('星座信息无效')
        
        return v


class MessageUpdate(BaseModel):
    """更新消息模式"""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = Field(None, min_length=1)
    message_type: Optional[MessageType] = None
    priority: Optional[int] = Field(None, ge=0, le=10)
    status: Optional[MessageStatus] = None
    is_read: Optional[bool] = None


class MessageResponse(MessageBase):
    """消息响应模式"""
    id: int
    sender_id: int
    receiver_id: int
    status: MessageStatus
    is_read: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    read_at: Optional[datetime] = None
    pattern: Optional[dict] = None  # 扩展为包含来源信息的复合信息

    class Config:
        from_attributes = True


class MessageList(BaseModel):
    """消息列表响应模式"""
    items: list[MessageResponse]
    total: int
    page: int
    size: int
    unread_count: int


class MessageStats(BaseModel):
    """消息统计信息"""
    total: int
    unread: int
    read: int
    archived: int
    by_type: dict