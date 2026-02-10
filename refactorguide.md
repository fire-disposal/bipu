- 彻底抛弃旧订阅系统  
- 用户使用唯一 8 位纯数字 ID（bipupu_id）作为核心标识，废弃 email  
- 登录用「用户名 + 密码」即可（用户名 ≠ bipupu_id）  
- 保留用户间“传讯式”社交（非 IM 聊天）  
- 采用 WebSocket 替代长轮询，用于实时推送新消息到 App  

我们重新设计一套轻量、仪式感强、契合 BIPI 机灵魂的后端与 App 接口体系。

🔑 一、用户模型重构（核心身份体系）

✅ 目标：
- bipupu_id：8 位纯数字，全局唯一、不可变、注册时分配（如 00123456）
- 登录用 username（可自定义，如 “星语者_7”）+ password
- 所有对外交互（发信、展示）优先用 bipupu_id

class User(Base):
    id: UUID                 # 内部主键（不暴露）
    bipupu_id: str           # 唯一 8 位数字 ID，如 "00123456"
    username: str            # 登录用，唯一
    hashed_password: str
    nickname: str            # 显示名
    avatar_url: Optional[str]
    cosmic_profile: JSON     # 生日、八字、MBTI 等
    is_active: bool = True
    created_at: datetime

    __table_args__ = (
        UniqueConstraint('bipupu_id'),
        UniqueConstraint('username'),
    )

💡 注册时，服务端生成 bipupu_id = f"{next_seq:08d}"（从 00000001 开始），用户无法选择。
💡 管理员账户也应该自动生成完整的相应内容，同时管理员账户需要保持对后端管理页面的访问。

📬 二、消息模型（统一传讯通道）

class Message(Base):
    id: UUID
    sender_id: str           # bipupu_id 或 服务号 ID（如 "cosmic.fortune"）
    receiver_id: str         # 必须是真实用户的 bipupu_id
    content: str
    msg_type: Literal[
        "USER_POSTCARD",     # 用户投递
        "VOICE_TRANSCRIPT",  # 语音转写
        "COSMIC_BROADCAST"   # 系统传讯
    ]
    pattern: JSON            # 控制 pupu 机显示/光效/屏保等
    created_at: datetime

❌ 无 status、无 conversation_id、无 is_read（由客户端管理）

👥 三、联系人 & 隐私模型（替代好友）

class TrustedContact(Base):
    owner_id: str            # 我的 bipupu_id
    contact_id: str          # 对方 bipupu_id
    alias: Optional[str]     # 备注名
    created_at: datetime
    __table_args__ = (UniqueConstraint('owner_id', 'contact_id'),)

class UserBlock(Base):
    blocker_id: str          # 拉黑者 bipupu_id
    blocked_id: str          # 被拉黑者 bipupu_id
    __table_args__ = (UniqueConstraint('blocker_id', 'blocked_id'),)

🌐 四、WebSocket 协议设计（轻量、安全、够用）

✅ 为什么现在可以用 WS？
- 不是为了“聊天”，而是为了 “新消息实时推送到 App”
- 消息频率低（日均 
3. 服务端验证 token → 绑定 bipupu_id 到 WebSocket 连接
4. 此后，所有发给该用户的 Message 都通过此连接推送

📦 WebSocket 消息格式（JSON）

{
  "type": "new_message",
  "payload": {
    "id": "uuid...",
    "sender_id": "00123456",
    "content": "今日宜表白",
    "msg_type": "COSMIC_BROADCAST",
    "pattern": { "led_color": "#FF69B4", "font": "neon" },
    "created_at": "2026-02-10T16:00:00Z"
  }
}

⚠️ 仅推送 new_message。已读、删除等操作仍走 REST。

❤️ 心跳与重连
- 客户端每 30s 发 { "type": "ping" }
- 服务端回 { "type": "pong" }
- 断线后，App 用 access_token 重连，自动补拉断线期间的消息（通过 /messages?since=last_seen_id）

📡 五、RESTful API 精简清单（仅必要接口）

🔐 认证
- POST /auth/register  
    { "username": "xxx", "password": "yyy", "nickname": "zzz" }
  → 返回 { "bipupu_id": "00123456", "access_token": "...", "refresh_token": "..." }
  
- POST /auth/login → { "username", "password" } → token + bipupu_id
- POST /auth/refresh

👤 用户
- GET /me → 返回当前用户信息（含 bipupu_id, cosmic_profile 等）
- PUT /me → 更新资料（不能改 bipupu_id）

📮 消息
- POST /messages  
    { "receiver_id": "00789012", "content": "...", "msg_type": "USER_POSTCARD" }
  
- GET /messages → 分页列表（支持 ?direction=sent/received）
- DELETE /messages/{id}

👥 联系人
- POST /contacts → { "contact_id": "00789012", "alias": "小星星" }
- GET /contacts → 列表
- DELETE /contacts/{contact_id}

🚫 黑名单
- POST /blocks → { "blocked_id": "00789012" }
- GET /blocks
- DELETE /blocks/{blocked_id}

🌌 服务号交互（取代订阅）
- 用户向服务号发消息即订阅：
    POST /messages
  { "receiver_id": "cosmic.fortune", "content": "TD" }
  
- 系统自动解析并回复（也是一条 Message）

❌ 不再有 /subscriptions 接口

🧪 六、关键业务流程示例

场景：用户 A 给用户 B 发信
1. A 在 App 输入 B 的 bipupu_id（或从联系人选）
2. A 发送 → POST /messages（receiver_id=B.bipupu_id）
3. 服务端：
   - 检查 B 是否存在
   - 检查 A 是否被 B 拉黑 → 是则丢弃
   - 检查 B 的隐私设置（是否只收联系人消息）→ 若 A 不在 B 的 TrustedContact 且设置为“仅联系人”，则丢弃或限频
   - 存入 DB
   - 若 B 的 App 在线（WS 连接活跃）→ 推送 new_message
4. B 的 App 收到 WS 消息 → 播放提示音 + pupu 机蓝牙同步

场景：用户订阅运势
1. 用户发送消息：receiver_id="cosmic.fortune", content="TD"
2. 服务端识别 → 将用户加入“运势订阅者”集合（可用 Redis Set）
3. 每日凌晨，任务遍历订阅者 → 生成 Message(sender_id="cosmic.fortune", receiver_id=user.bipupu_id, ...)
4. 消息存入 DB，并尝试 WS 推送（若离线，下次 App 启动时拉取）

🧹 七、废弃内容清单（可安全删除）
模块   原因
email 字段   登录用 username 即可

Friendship 模型   用 TrustedContact 替代

独立订阅系统（SubscriptionType, UserSubscription）   用服务号消息交互替代

消息 status / is_read 字段   由客户端本地管理

/conversations/ API   无会话概念

WebSocket 以外的实时方案   长轮询可删

✅ 总结：新架构核心原则
维度   设计
身份   8 位 bipupu_id 为宇宙座席号，不可变

社交   传讯式投递，非对话；联系人 = 通信白名单

订阅   向服务号发消息（如 "TD"）即订阅

实时性   WebSocket 仅用于新消息推送，轻量可靠

UI 隐喻   信箱（收件箱/发件箱），非聊天窗口

pupu 机   所有消息通过 pattern 控制其显示/光效

这套设计既满足甲方对“好友”“订阅”“语音”“隐私”的需求，又彻底剥离了 IM 负担，回归 BIPI 机的本质：一个接收宇宙与人心低语的神圣终端。

如需 OpenAPI spec 片段或 WebSocket 协议状态机图，我可继续细化。