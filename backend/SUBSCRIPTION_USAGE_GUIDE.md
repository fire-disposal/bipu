# 改进后的订阅模块使用指南

## 📚 概述

重构后的订阅模块采用模块化架构，具有更好的可维护性、扩展性和可测试性。

## 🏗️ 架构组成

### 1. 基础处理器 (`base.py`)
```python
from app.tasks.subscriptions.base import BaseSubscriptionHandler

class MySubscriptionHandler(BaseSubscriptionHandler):
    def __init__(self):
        super().__init__("我的订阅类型")
    
    def generate_message_data(self, user_id, subscription, db):
        return {
            "title": "标题",
            "content": "内容",
            "priority": 5,
            "pattern": {...}
        }
```

**主要方法：**
- `is_within_notification_window()` - 检查通知时间
- `process_subscriptions()` - 处理订阅列表
- `generate_message_data()` - 生成消息数据（抽象）

### 2. 消息构建器 (`notification_sender.py`)
```python
from app.tasks.subscriptions.notification_sender import NotificationMessageBuilder

message = NotificationMessageBuilder.build(
    title="今日天气",
    content="晴天，气温 25°C",
    receiver_id=123,
    subscription_type="weather",
    subscription_id=456,
    priority=3,
    rgb={"r": 100, "g": 150, "b": 200},
    vibe={"intensity": 30, "duration": 1500}
)
```

**特点：**
- ✅ 内置验证
- ✅ 标准化 pattern 结构
- ✅ 灵活的自定义数据

### 3. 具体处理器
- **天气处理器** (`weather.py`) - WeatherSubscriptionHandler
- **运势处理器** (`fortune.py`) - FortuneSubscriptionHandler

### 4. 验证器 (`validators.py`)
```python
from app.tasks.subscriptions.validators import MessageValidator

try:
    MessageValidator.validate_message(
        title="标题",
        content="内容",
        priority=5
    )
except ValueError as e:
    print(f"验证失败: {e}")
```

**验证项：**
- 标题长度（1-200 字符）
- 内容长度（1-5000 字符）
- 优先级范围（0-10）
- Pattern 结构
- XSS 防护

### 5. 工具函数 (`utils.py`)
```python
from app.tasks.subscriptions.utils import (
    parse_time_string,
    is_time_in_range,
    calculate_priority_from_importance
)

current_time = datetime.now().time()
start = parse_time_string("09:00")
end = parse_time_string("22:00")
is_in_range = is_time_in_range(current_time, start, end)
```

---

## 🚀 快速开始

### 添加新的订阅类型

#### 步骤 1：创建新的处理器
```python
# backend/app/tasks/subscriptions/cosmic_messaging.py
from .base import BaseSubscriptionHandler
from app.models.subscription import UserSubscription
from sqlalchemy.orm import Session
from typing import Dict, Any

class CosmicMessagingSubscriptionHandler(BaseSubscriptionHandler):
    """宇宙传讯订阅处理器"""
    
    def __init__(self):
        super().__init__("宇宙传讯")
    
    def generate_message_data(
        self,
        user_id: int,
        subscription: UserSubscription,
        db: Session
    ) -> Dict[str, Any]:
        """生成宇宙传讯消息"""
        # 获取用户信息
        user = db.query(User).filter(User.id == user_id).first()
        
        # 生成宇宙传讯数据
        cosmic_message = {
            "frequency": random.randint(1, 9),
            "energy_color": random.choice(["紫罗兰", "金色", "蓝色", "绿色"]),
            "guidance": "您的宇宙指引..."
        }
        
        title = f"宇宙传讯 - {cosmic_message['energy_color']}能量"
        content = f"频率：{cosmic_message['frequency']}\n{cosmic_message['guidance']}"
        
        return {
            "title": title,
            "content": content,
            "priority": 5,
            "pattern": {
                "cosmic_data": cosmic_message,
                "rgb": {"r": 200, "g": 100, "b": 255},
                "vibe": {"intensity": 50, "duration": 2000}
            }
        }
```

#### 步骤 2：在主任务中添加任务
```python
# backend/app/tasks/subscription_new.py

@shared_task
def generate_cosmic_messaging_subscription():
    """生成宇宙传讯订阅消息"""
    db = SessionLocal()
    try:
        cosmic_subscriptions = db.query(UserSubscription).join(
            SubscriptionType,
            UserSubscription.subscription_type_id == SubscriptionType.id
        ).filter(
            SubscriptionType.name == "宇宙传讯",
            UserSubscription.is_enabled == True
        ).all()
        
        if not cosmic_subscriptions:
            return {"created_count": 0, "failed_count": 0, "total_processed": 0}
        
        handler = CosmicMessagingSubscriptionHandler()
        result = handler.process_subscriptions(cosmic_subscriptions, db)
        
        logger.info(f"宇宙传讯消息生成完成: {result}")
        return result
        
    finally:
        db.close()
```

#### 步骤 3：更新 `__init__.py`
```python
# backend/app/tasks/subscriptions/__init__.py

from .cosmic_messaging import CosmicMessagingSubscriptionHandler

__all__ = [
    "BaseSubscriptionHandler",
    "NotificationMessageBuilder",
    "WeatherSubscriptionHandler",
    "FortuneSubscriptionHandler",
    "CosmicMessagingSubscriptionHandler",  # 新增
]
```

---

## 🧪 测试示例

### 单元测试
```python
# backend/tests/test_subscriptions.py
import pytest
from app.tasks.subscriptions.weather import WeatherSubscriptionHandler
from app.tasks.subscriptions.validators import MessageValidator
from app.db.database import SessionLocal

def test_weather_handler():
    """测试天气处理器"""
    handler = WeatherSubscriptionHandler()
    assert handler.subscription_type_name == "天气推送"

def test_time_window():
    """测试时间窗口检查"""
    from unittest.mock import Mock
    subscription = Mock()
    subscription.notification_time_start = "09:00"
    subscription.notification_time_end = "22:00"
    
    handler = WeatherSubscriptionHandler()
    # 在工作时间，应该返回 True（模拟 14:00）
    result = handler.is_within_notification_window(subscription)
    # 实际需要 mock datetime.now()

def test_message_validator():
    """测试消息验证器"""
    # 有效的消息
    assert MessageValidator.validate_message(
        title="有效标题",
        content="有效内容" * 10,
        priority=5
    ) == True
    
    # 无效的优先级
    with pytest.raises(ValueError):
        MessageValidator.validate_message(
            title="标题",
            content="内容",
            priority=15  # 超出范围
        )
    
    # 包含 XSS 内容
    with pytest.raises(ValueError):
        MessageValidator.validate_message(
            title="标题",
            content="<script>alert('xss')</script>",
            priority=5
        )

def test_message_builder():
    """测试消息构建器"""
    from app.tasks.subscriptions.notification_sender import NotificationMessageBuilder
    
    message = NotificationMessageBuilder.build(
        title="测试标题",
        content="测试内容",
        receiver_id=1,
        subscription_type="test",
        subscription_id=1,
        priority=5
    )
    
    assert message.title == "测试标题"
    assert message.content == "测试内容"
    assert message.priority == 5
    assert message.pattern["subscription_type"] == "test"
```

### 集成测试
```python
# backend/tests/test_subscription_tasks.py
from app.tasks.subscription_new import generate_weather_subscription
from app.models.subscription import SubscriptionType, UserSubscription
from app.models.user import User
from app.db.database import SessionLocal

def test_generate_weather_subscription(db_session):
    """测试天气订阅任务"""
    # 创建测试用户和订阅
    user = User(username="testuser", email="test@example.com", hashed_password="xxx")
    db_session.add(user)
    db_session.flush()
    
    sub_type = SubscriptionType(
        name="天气推送",
        category="notifications",
        is_active=True
    )
    db_session.add(sub_type)
    db_session.flush()
    
    subscription = UserSubscription(
        user_id=user.id,
        subscription_type_id=sub_type.id,
        is_enabled=True
    )
    db_session.add(subscription)
    db_session.commit()
    
    # 执行任务
    result = generate_weather_subscription()
    
    # 验证结果
    assert result["created_count"] >= 0
    assert result["failed_count"] >= 0
```

---

## ⚙️ 配置和扩展

### 自定义订阅处理器模板
```python
# backend/app/tasks/subscriptions/template.py
"""订阅处理器模板"""
from typing import Dict, Any
from sqlalchemy.orm import Session
from app.models.subscription import UserSubscription
from .base import BaseSubscriptionHandler

class CustomSubscriptionHandler(BaseSubscriptionHandler):
    """自定义订阅处理器"""
    
    def __init__(self, subscription_type_name: str = "自定义订阅"):
        super().__init__(subscription_type_name)
    
    def generate_message_data(
        self,
        user_id: int,
        subscription: UserSubscription,
        db: Session
    ) -> Dict[str, Any]:
        """实现具体的消息生成逻辑"""
        # 1. 检查用户设置
        custom_settings = subscription.custom_settings or {}
        
        # 2. 生成消息数据
        message_data = {
            "title": "您的消息标题",
            "content": "您的消息内容",
            "priority": 3,
            "pattern": {
                "custom_field": custom_settings.get("custom_field", "default_value"),
                "rgb": {"r": 100, "g": 150, "b": 200},
                "vibe": {"intensity": 30, "duration": 1500}
            }
        }
        
        return message_data
```

### 性能优化建议

1. **批量处理**
```python
# 修改 base.py 中的 process_subscriptions 方法
BATCH_SIZE = 100

def process_subscriptions_batched(self, subscriptions, db):
    for i in range(0, len(subscriptions), BATCH_SIZE):
        batch = subscriptions[i:i+BATCH_SIZE]
        # 处理 batch
        db.commit()  # 每个 batch 提交一次
```

2. **并行处理**
```python
# 使用 Celery 的 group 特性
from celery import group

@shared_task
def process_batch(subscription_ids):
    # 处理一个 batch
    pass

# 分组处理多个 batch
job = group(
    process_batch.s(batch_ids)
    for batch_ids in chunks(all_subscription_ids, BATCH_SIZE)
)
```

3. **缓存常见数据**
```python
# 在处理器中缓存用户数据
from functools import lru_cache

@lru_cache(maxsize=128)
def get_user_zodiac(user_id):
    # 获取用户星座
    pass
```

---

## 📊 迁移检查表

- [ ] 创建 `subscriptions/` 文件夹结构
- [ ] 实现基础处理器 (`base.py`)
- [ ] 实现消息构建器 (`notification_sender.py`)
- [ ] 迁移天气处理器 (`weather.py`)
- [ ] 迁移运势处理器 (`fortune.py`)
- [ ] 实现验证器 (`validators.py`)
- [ ] 实现工具函数 (`utils.py`)
- [ ] 更新主任务文件 (`subscription.py`)
- [ ] 编写单元测试
- [ ] 编写集成测试
- [ ] 更新 Celery 定时任务配置
- [ ] 更新文档
- [ ] 在测试环境验证
- [ ] 逐步灰度上线

---

## 🔍 故障排查

### 问题 1：消息未生成
**症状：** 任务运行完成但没有创建消息

**检查步骤：**
1. 确认订阅已启用：`UserSubscription.is_enabled == True`
2. 检查时间范围：比较 `notification_time_start` 和 `notification_time_end`
3. 查看日志：检查是否有错误或跳过的订阅

### 问题 2：验证失败
**症状：** 消息创建时抛出 ValueError

**解决方案：**
```python
# 在构建消息前验证
from app.tasks.subscriptions.validators import MessageValidator

try:
    MessageValidator.validate_message(title, content, priority)
    # 创建消息
except ValueError as e:
    logger.error(f"消息验证失败: {e}")
    # 处理错误
```

### 问题 3：性能问题
**症状：** 任务运行缓慢

**优化方案：**
1. 使用批量查询：`.options(joinedload(...))`
2. 减少数据库查询：缓存用户信息
3. 使用索引：为 `UserSubscription` 添加索引
4. 启用异步处理：使用 Celery 的 chord/group

---

## 📝 API 参考

### BaseSubscriptionHandler
```python
class BaseSubscriptionHandler(ABC):
    def is_within_notification_window(subscription: UserSubscription) -> bool
    def process_subscriptions(subscriptions: List[UserSubscription], db: Session) -> Dict
    def generate_message_data(user_id: int, subscription: UserSubscription, db: Session) -> Dict  # 抽象
```

### NotificationMessageBuilder
```python
class NotificationMessageBuilder:
    @staticmethod
    def build(
        title: str,
        content: str,
        receiver_id: int,
        subscription_type: str,
        subscription_id: int,
        priority: int = 3,
        rgb: Optional[Dict] = None,
        vibe: Optional[Dict] = None,
        custom_data: Optional[Dict] = None
    ) -> Message
```

### MessageValidator
```python
class MessageValidator:
    @classmethod
    def validate_title(title: str) -> bool
    @classmethod
    def validate_content(content: str) -> bool
    @classmethod
    def validate_priority(priority: int) -> bool
    @classmethod
    def validate_pattern(pattern: Optional[Dict]) -> bool
    @classmethod
    def validate_message(title: str, content: str, priority: int, pattern: Optional[Dict]) -> bool
```

---

## 📚 相关资源

- [FastAPI 文档](https://fastapi.tiangolo.com/)
- [SQLAlchemy 文档](https://docs.sqlalchemy.org/)
- [Celery 文档](https://docs.celeryproject.org/)
- [项目架构审查](./ARCHITECTURE_REVIEW.md)
