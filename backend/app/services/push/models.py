"""推送核心数据模型"""
from datetime import datetime
from typing import Optional, Dict, Any
from dataclasses import dataclass, field
from enum import Enum


class PushStatus(str, Enum):
    """推送状态"""
    PENDING = "pending"
    SENDING = "sending"
    SUCCESS = "success"
    FAILED = "failed"
    RETRYING = "retrying"


@dataclass
class PushMessage:
    """推送消息"""
    service_name: str        # 服务名称，如 "cosmic.fortune"
    receiver_id: str         # 接收者BIPUPU ID
    content: str             # 消息内容
    message_type: str = "SYSTEM"  # 消息类型
    priority: int = 1        # 优先级：1-高，2-中，3-低
    retry_count: int = 0     # 重试次数
    max_retries: int = 3     # 最大重试次数
    metadata: Dict[str, Any] = field(default_factory=dict)  # 最小化元数据


@dataclass
class PushResult:
    """推送结果"""
    message_id: Optional[int] = None
    status: PushStatus = PushStatus.PENDING
    sent_at: Optional[datetime] = None
    error_message: Optional[str] = None
    retry_count: int = 0
    delivery_latency_ms: Optional[int] = None
