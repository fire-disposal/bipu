# 服务号推送时间设置系统

## 概述

本文档描述了BIPUPU服务号推送时间设置系统的设计与实现。该系统允许用户为每个服务号设置个性化的推送时间，并支持多时区处理。

## 系统架构

### 核心组件

1. **数据库模型增强**
   - `User` 模型：添加 `timezone` 和 `fortune_time` 字段
   - `ServiceAccount` 模型：添加 `default_push_time` 字段
   - `subscriptions` 关联表：添加 `push_time` 和 `is_enabled` 字段

2. **推送调度系统**
   - Celery 定时任务：每15分钟检查推送时间
   - 时区感知：支持全球任意时区
   - 个人化推送：每个用户可设置不同的推送时间

3. **API接口**
   - 用户推送设置管理
   - 服务号订阅设置管理
   - 推送时间查询与更新

## 数据库设计

### User 模型增强

```python
class User(Base):
    # ... 现有字段 ...
    timezone = Column(String(64), default='Asia/Shanghai', nullable=False)  # 用户时区
    fortune_time = Column(String(5), nullable=True)  # 运势推送时间，格式: "HH:MM"
```

### ServiceAccount 模型增强

```python
class ServiceAccount(Base):
    # ... 现有字段 ...
    default_push_time = Column(Time, nullable=True)  # 默认推送时间
```

### 订阅关联表增强

```python
subscription_table = Table('subscriptions', Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True),
    Column('service_account_id', Integer, ForeignKey('service_accounts.id'), primary_key=True),
    Column('push_time', Time, nullable=True),  # 推送时间，格式: HH:MM:SS
    Column('is_enabled', Boolean, default=True),  # 是否启用推送
    Column('created_at', DateTime(timezone=True), server_default=func.now()),
    Column('updated_at', DateTime(timezone=True), onupdate=func.now())
)
```

## 推送逻辑

### 推送时间检查算法

1. **每15分钟检查**：Celery任务每15分钟运行一次
2. **时区转换**：将UTC时间转换为用户本地时间
3. **时间匹配**：检查用户设置的推送时间是否在当前15分钟窗口内
4. **批量推送**：对匹配的用户进行批量消息推送

### 核心函数

```python
def get_users_for_push_time(db: Session, service_name: str, target_hour_utc: int, target_minute_utc: int) -> list:
    """获取在指定UTC时间应该接收推送的用户
    
    只考虑设置了个人化推送时间的用户
    移除默认推送时间逻辑，简化设计
    """
```

## API接口

### 用户推送设置 API

#### 1. 更新推送时间
```
PUT /api/profile/push-time
Content-Type: application/json

{
  "fortune_time": "09:00"
}
```

#### 2. 更新时区
```
PUT /api/profile/timezone
Content-Type: application/json

{
  "timezone": "America/New_York"
}
```

#### 3. 获取推送设置
```
GET /api/profile/push-settings
```

### 服务号订阅设置 API

#### 1. 获取用户订阅列表
```
GET /api/service_accounts/subscriptions/
```

#### 2. 获取指定服务号设置
```
GET /api/service_accounts/{name}/settings
```

#### 3. 更新订阅设置
```
PUT /api/service_accounts/{name}/settings
Content-Type: application/json

{
  "push_time": "08:30",
  "is_enabled": true
}
```

#### 4. 订阅服务号（带初始设置）
```
POST /api/service_accounts/{name}/subscribe
Content-Type: application/json

{
  "push_time": "09:00",
  "is_enabled": true
}
```

## 管理后台功能

### 服务号管理页面
- 查看所有服务号列表
- 设置服务号默认推送时间
- 更新服务号描述
- 上传服务号头像
- 广播消息功能

### 推送时间设置
- 每个服务号可设置默认推送时间
- 用户订阅时可覆盖默认时间
- 支持24小时制时间格式

## 内置服务号

### 1. 每日运势服务 (cosmic.fortune)
- 服务名称：`cosmic.fortune`
- 描述：每日运势推送服务
- 默认推送时间：09:00
- 内容：基于用户ID和日期生成的个性化运势

### 2. 天气预报服务 (weather.service)
- 服务名称：`weather.service`
- 描述：每日天气预报推送服务
- 默认推送时间：09:00
- 内容：随机生成的天气预报信息

## 初始化数据

### 幂等性保证
系统启动时自动初始化内置服务号，确保：
1. 如果服务号不存在，则创建
2. 如果服务号已存在，则更新必要字段
3. 不会因重复初始化而报错

### 初始化脚本
```python
# app/db/init_data.py
async def create_default_services(db: Session):
    """创建默认服务号（幂等性保证）"""
```

## 时区处理

### 支持的时区
- Asia/Shanghai (默认)
- America/New_York
- Europe/London
- UTC
- 所有pytz支持的时区

### 时区转换逻辑
1. 用户设置本地推送时间
2. 系统转换为UTC时间存储
3. 推送时根据用户时区反向转换
4. 15分钟窗口匹配

## 错误处理

### 时间格式验证
- 使用正则表达式验证 HH:MM 格式
- 小时范围：00-23
- 分钟范围：00-59

### 时区验证
- 使用pytz验证时区有效性
- 无效时区返回400错误

### 数据库事务
- 所有关键操作都有事务保护
- 异常时自动回滚
- 详细的错误日志

## 性能优化

### 批量处理
- 使用 `asyncio.gather` 并发发送消息
- 批量查询用户推送时间
- 减少数据库查询次数

### 缓存策略
- Redis缓存用户数据
- 头像ETag缓存
- HTTP缓存控制头

### 索引优化
- 用户ID索引
- 服务号名称索引
- 推送时间查询优化

## 测试脚本

### 功能测试
```bash
# 运行测试脚本
python test_push_time.py
```

### 测试内容
1. 用户创建与订阅
2. 推送时间设置与更新
3. 时区转换验证
4. 推送逻辑测试

## 部署说明

### 环境变量
```bash
# 时区设置
TIMEZONE=Asia/Shanghai

# Celery配置
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
```

### Celery调度配置
```python
# app/celery.py
beat_schedule={
    "subscriptions-check-push-times": {
        "task": "subscriptions.check_push_times",
        "schedule": crontab(minute="*/15"),
    },
}
```

## 监控与日志

### 关键指标
1. 推送成功率
2. 用户订阅数量
3. 推送时间分布
4. 时区分布统计

### 日志记录
- 推送任务执行日志
- 用户设置变更日志
- 错误和异常日志
- 性能监控日志

## 未来扩展

### 计划功能
1. **推送历史记录**：记录每次推送的时间和内容
2. **推送统计分析**：分析用户打开率和互动率
3. **智能推送优化**：根据用户活跃时间自动调整推送时间
4. **多语言支持**：支持不同语言的推送内容
5. **推送模板系统**：可配置的推送内容模板

### 技术优化
1. **推送队列优化**：使用消息队列提高推送性能
2. **实时推送**：支持即时消息推送
3. **推送分组**：按用户分组批量推送
4. **推送优先级**：支持不同优先级的推送

## 总结

服务号推送时间设置系统提供了灵活、可靠的推送服务，具有以下特点：

1. **用户友好**：支持个人化推送时间设置
2. **全球支持**：完整的多时区处理
3. **高性能**：批量处理和并发推送
4. **可靠稳定**：完善的错误处理和事务保护
5. **易于扩展**：模块化设计支持未来功能扩展

系统已为BIPUPU平台的服务号推送功能提供了坚实的基础架构。