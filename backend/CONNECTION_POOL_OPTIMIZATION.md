# 数据库连接池优化方案

## 问题根本原因分析

### 1. **核心问题**
- **长轮询接口 (`/api/messages/poll`)** 在等待新消息期间长时间占用数据库连接（最长 30 秒）
- 当多个客户端同时发起长轮询请求时，连接池快速被占满
- 连接池配置：`pool_size=20, max_overflow=30`（总共最多 50 个连接）
- 超过连接限制的请求在 30 秒超时后抛出 `TimeoutError`

### 2. **问题链路**
```
长轮询请求到达
    ↓
get_current_user() 需要获取数据库连接（执行数据库查询）
    ↓
连接被占用，等待新消息（0-30秒）
    ↓
在此期间，连接始终被持有，不释放
    ↓
多个并发长轮询 → 连接池快速耗尽
    ↓
后续请求无法获取连接 → TimeoutError
```

### 3. **为什么 `/health` 和其他接口正常**
- `/health` 接口立即完成，不长时间持有连接
- 其他普通接口也是快速完成，连接快速释放

---

## 优化方案

### 方案一：缓存用户认证信息（推荐）
**目标：避免长轮询在整个等待期间持有数据库连接**

#### 实现步骤：
1. 将 `get_current_user()` 拆分为两个函数：
   - `validate_and_cache_token()` - 仅验证 token，从缓存获取用户信息
   - `get_current_user()` - 只在缓存缺失时查询数据库

2. 用户信息缓存策略：
   - 缓存有效期：用户信息缓存 1 小时
   - Cache Key: `user:{username}`
   - 在用户更新操作时清除缓存

#### 代码位置：
- [app/core/security.py](app/core/security.py#L121) - `get_current_user()` 函数

#### 好处：
- ✅ 大幅减少数据库查询
- ✅ 长轮询在验证后立即释放连接
- ✅ 用户信息 1 小时内不变，缓存命中率高

---

### 方案二：使用后台任务异步检查新消息
**目标：让长轮询不持有数据库连接**

#### 实现思路：
1. 长轮询入口不查询消息，只检查内存缓存的消息列表
2. 后台任务定期检查新消息，更新 Redis 缓存
3. 客户端建立 WebSocket 或轮询连接，但不持有数据库连接

#### 缺点：
- 实现复杂度高
- 需要 Redis 或消息队列
- 消息有一定延迟（取决于后台任务频率）

#### 好处：
- ✅ 完全释放数据库连接
- ✅ 可扩展性最好

---

### 方案三：增加连接池大小 + 超时优化
**目标：提高连接池容量，缓解压力**

#### 配置调整：
```python
pool_size=50         # 增加到 50
max_overflow=100     # 增加到 100
pool_timeout=60      # 增加到 60 秒
connect_timeout=30   # 连接超时 30 秒
```

#### 缺点：
- ❌ 只是延缓问题，不解决根本原因
- ❌ 增加数据库压力
- ❌ 不适合生产环境大并发场景

#### 适用场景：
- 临时应急方案
- 并发用户不超过 200 的中小型应用

---

### 方案四：实现连接池监控和告警
**目标：及时发现连接泄漏**

#### 实现内容：
1. 添加中间件监控活跃连接数
2. 记录长时间占用连接的请求
3. 自动清理超时连接

#### 代码位置：
- [app/main.py](app/main.py) - 添加生命周期中间件

#### 好处：
- ✅ 早期发现问题
- ✅ 可与其他方案结合

---

## 优先实施顺序

### 第 1 优先级（立即实施）
1. **方案一**：缓存用户认证信息
   - 实现成本低
   - 效果显著
   - 改进时间：30-60 分钟

2. **方案四**：连接池监控
   - 早期发现问题
   - 配合第 1 步
   - 改进时间：20-30 分钟

### 第 2 优先级（短期优化）
3. **方案三**：增加连接池大小（临时措施）
   - 只在长期方案前的过渡方案
   - 改进时间：5 分钟

### 第 3 优先级（长期解决）
4. **方案二**：后台任务 + Redis
   - 实现复杂度高
   - 需要架构调整
   - 改进时间：2-3 天

---

## 实现步骤详解

### 步骤 1：修改 get_current_user() 支持缓存

**文件**：`backend/app/core/security.py`

```python
async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """获取当前用户 - 优化版本（支持缓存）"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无效的认证凭据",
        headers={"WWW-Authenticate": "Bearer"},
    )

    token = credentials.credentials

    # 检查令牌是否在黑名单中
    if await RedisService.is_token_blacklisted(token):
        logger.warning("Token is blacklisted")
        raise credentials_exception

    payload = decode_token(token)
    if payload is None:
        raise credentials_exception

    # 检查令牌类型
    token_type = payload.get("type")
    if token_type != "access":
        logger.warning(f"Invalid token type: {token_type}")
        raise credentials_exception

    # 获取用户名
    username = payload.get("sub")
    if username is None:
        logger.warning("Token missing sub claim")
        raise credentials_exception

    # 🆕 优先从缓存获取用户信息（避免数据库查询）
    cache_key = f"user:{username}"
    cache_service = await get_cache_service()
    cached_user = await cache_service.get(cache_key)
    
    if cached_user:
        logger.debug(f"User from cache: {username}")
        return User(**cached_user)

    # 缓存未命中，从数据库查询
    user = db.query(User).filter(
        User.username == username,
        User.is_active
    ).first()

    if user is None:
        logger.warning(f"User not found: {username}")
        raise credentials_exception

    # 🆕 缓存用户信息 1 小时
    await cache_service.set(
        cache_key,
        user.to_dict(),  # 需要实现 to_dict() 方法
        ex=3600  # 1 小时
    )

    return user
```

### 步骤 2：优化长轮询接口 - 立即释放连接

**文件**：`backend/app/api/routes/messages.py`

```python
@router.get("/poll", response_model=MessagePollResponse)
async def long_poll_messages(
    last_msg_id: int = Query(0, ge=0, description="最后收到的消息ID"),
    timeout: int = Query(30, ge=1, le=120, description="轮询超时时间（秒）"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """长轮询接口 - 优化版本
    
    关键改进：在获得用户信息后立即关闭数据库连接
    """
    try:
        # 👇 关键改进：获取初始消息后，立即释放连接
        initial_messages = db.query(Message).filter(
            Message.receiver_bipupu_id == current_user.bipupu_id,
            Message.id > last_msg_id
        ).order_by(Message.id.asc()).limit(20).all()
        
        # 🆕 转换为 schema 对象（无需 db 会话）
        initial_responses = [MessageResponse.model_validate(msg) for msg in initial_messages]
        
        if initial_messages:
            return MessagePollResponse(
                messages=initial_responses,
                has_more=len(initial_messages) >= 20
            )
        
        # 🆕 关键：在此处释放 db 连接，后续等待不占用连接
        db.close()
        
        # 等待新消息，使用 Redis 而非数据库查询
        check_interval = 1  # 每秒检查
        elapsed = 0
        cache_service = await get_cache_service()
        
        while elapsed < timeout:
            # 🆕 从缓存获取消息列表，避免重复查询数据库
            message_key = f"messages:{current_user.bipupu_id}:latest"
            cached_messages = await cache_service.get(message_key)
            
            if cached_messages:
                return MessagePollResponse(
                    messages=cached_messages,
                    has_more=len(cached_messages) >= 20
                )
            
            await asyncio.sleep(check_interval)
            elapsed += check_interval

        # 超时，返回空列表
        return MessagePollResponse(messages=[], has_more=False)

    except Exception as e:
        logger.error(f"长轮询失败: {e}")
        raise HTTPException(status_code=500, detail="长轮询失败")
```

### 步骤 3：增加连接池监控中间件

**文件**：`backend/app/main.py` （新增中间件）

```python
from app.middleware.connection_monitor import ConnectionMonitorMiddleware

# 在应用创建后添加
app.add_middleware(ConnectionMonitorMiddleware)
```

**文件**：`backend/app/middleware/connection_monitor.py` （新建文件）

```python
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from app.core.logging import get_logger
from app.db.database import engine
import time

logger = get_logger(__name__)

class ConnectionMonitorMiddleware(BaseHTTPMiddleware):
    """监控数据库连接池使用情况"""
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        # 获取连接池状态
        pool = engine.pool
        before_size = pool.size()
        
        response = await call_next(request)
        
        elapsed = time.time() - start_time
        after_size = pool.size()
        
        # 记录长时间占用连接的请求
        if elapsed > 5:  # 超过 5 秒
            logger.warning(
                f"Long-running request: {request.method} {request.url.path} "
                f"took {elapsed:.2f}s, pool_size: {after_size}"
            )
        
        # 连接泄漏告警
        if after_size > before_size + 5:
            logger.error(
                f"Possible connection leak: pool_size increased by {after_size - before_size}, "
                f"request: {request.method} {request.url.path}"
            )
        
        return response
```

### 步骤 4：调整连接池配置（可选升级）

**文件**：`backend/app/db/database.py`

```python
engine = create_engine(
    settings.DATABASE_URL,
    pool_size=50,              # 从 20 增加到 50（临时升级）
    max_overflow=100,          # 从 30 增加到 100
    pool_pre_ping=True,        # 保持现有设置
    pool_recycle=3600,         # 🆕 1 小时回收连接，防止超时
    echo=False,
)
```

---

## 预期效果

| 指标 | 优化前 | 优化后 |
|------|-------|-------|
| 并发长轮询承载能力 | ~20 个 | 500+ 个 |
| 数据库查询数 (QPS) | 每个请求 2-3 次 | 1 次 + 缓存命中 0 次 |
| 连接占用时间 | 30 秒 | <1 秒 |
| 其他接口响应时间 | 受连接池压力影响 | 稳定 |

---

## 监控指标

### 实施后需监控的指标：
1. **连接池利用率** - 应 < 70%
2. **长轮询响应时间** - 应 < 1 秒（无新消息除外）
3. **数据库查询数** - 应明显下降
4. **缓存命中率** - 目标 > 90%

### 告警阈值：
- ⚠️ 连接池使用 > 80%
- ❌ 单次请求 > 30 秒
- ❌ 连接超时错误率 > 1%

---

## 总结

1. **立即实施**：方案一（缓存用户信息）+ 方案四（连接监控）
2. **短期调整**：方案三（增加连接池大小）
3. **长期优化**：方案二（异步消息架构）

预期能将并发承载能力提升 **20 倍以上**，同时保持系统稳定性。
