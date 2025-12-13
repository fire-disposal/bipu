# 项目分阶段 TODO 列表与数据库结构设计初稿

## 第一阶段：基础架构与核心功能

- [x] 明确各端技术选型与接口规范
- [ ] 设计数据库结构（见下方初稿 ER 设计）
- [ ] 设计并实现后端用户认证、设备绑定、基础 API（见 [`backend/app/api/`](backend/app/api/)）
- [ ] App 端实现注册/登录、设备绑定、基础资料管理（见 [`mobile/`](mobile/)）
- [ ] 物理终端通信协议设计与基础收发实现
- [ ] 服务器端文字转写、消息同步基础功能

## 第二阶段：功能完善与体验优化

- [ ] App 端完善个人资料、隐私设置、消息管理、语音输入
- [ ] 物理终端显示、发光、语音本地识别、预设语音导引
- [ ] 服务器端 AI 运算、宇宙传讯推送、消息推送
- [ ] 信息输出模板设计与导出/打印功能

## 第三阶段：安全、性能与多端联调

- [ ] 完善密码管理、黑名单、冷却机制等安全功能
- [ ] 多端联调与压力测试
- [ ] 完善文档与用户协议
- [ ] 上线准备与持续集成部署

---

## 技术路线建议

- 后端建议继续采用 Python（FastAPI/Celery），接口 RESTful，支持 WebSocket。
- App 端建议 Flutter 跨平台开发，便于多端适配。
- 物理终端建议采用嵌入式 C/C++/MicroPython，MQTT/HTTP 通信。
- 语音转写、AI 运算可用第三方云服务或自研模型。
- 持续集成可用 GitHub Actions + Docker。

---

## 数据库结构设计初稿（ER 关系简述）

### 用户（User）
- id (PK)
- username
- password_hash
- email
- phone
- avatar_url
- birthday
- constellation
- mbti
- ba_zi
- created_at
- updated_at

### 设备（Device）
- id (PK)
- device_sn
- bipupu_id
- user_id (FK)
- bind_time
- status

### 消息（Message）
- id (PK)
- sender_id (FK)
- receiver_id (FK)
- device_id (FK, 可选)
- content
- content_type (text/voice)
- is_favorite
- is_deleted
- created_at

### 宇宙传讯订阅（Subscription）
- id (PK)
- user_id (FK)
- enabled
- receive_time
- created_at

### 黑名单（Blacklist）
- id (PK)
- user_id (FK)
- blocked_user_id (FK)
- created_at

### 消息收藏（Favorite）
- id (PK)
- user_id (FK)
- message_id (FK)
- created_at

### 语音转写（Transcription）
- id (PK)
- message_id (FK)
- text
- created_at

### 终端日志（DeviceLog）
- id (PK)
- device_id (FK)
- log_type
- content
- created_at

---

> 后续可根据业务细化字段与表结构，建议用 ER 图工具进一步完善。