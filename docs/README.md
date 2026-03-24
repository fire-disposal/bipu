# Bipupu 文档索引

本文档提供 Bipupu 项目所有文档的快速导航。

---

## 📚 核心文档

| 文档 | 说明 | 路径 |
|------|------|------|
| [项目总览](../README.md) | 项目介绍、快速开始 | `/README.md` |
| [部署指南](./DEPLOYMENT.md) | 完整部署流程 | `/docs/DEPLOYMENT.md` |
| [架构设计](./ARCHITECTURE.md) | 系统架构设计 | `/docs/ARCHITECTURE.md` |
| [API 文档](./API.md) | 完整 API 参考 | `/docs/API.md` |
| [WebSocket API](./WEBSOCKET_API.md) | WebSocket 接口文档 | `/docs/WEBSOCKET_API.md` |

---

## 🔧 后端文档

### 开发文档

| 文档 | 说明 | 路径 |
|------|------|------|
| [代码审查报告](../backend/BACKEND_CODE_REVIEW.md) | 代码质量评估 | `/backend/BACKEND_CODE_REVIEW.md` |
| [API Schema 修复报告](../backend/API_SCHEMA_FIX_REPORT.md) | Schema 修复记录 | `/backend/API_SCHEMA_FIX_REPORT.md` |
| [Schema 优化报告](../backend/SCHEMA_OPTIMIZATION_REPORT.md) | Schema 优化方案 | `/backend/SCHEMA_OPTIMIZATION_REPORT.md` |

### 性能优化

| 文档 | 说明 | 路径 |
|------|------|------|
| [连接池优化](../backend/CONNECTION_POOL_OPTIMIZATION.md) | 数据库连接池优化 | `/backend/CONNECTION_POOL_OPTIMIZATION.md` |
| [轮询优化报告](../backend/POLLING_OPTIMIZATION_REPORT.md) | 消息轮询优化 | `/backend/POLLING_OPTIMIZATION_REPORT.md` |

### API 文档

| 文档 | 说明 | 路径 |
|------|------|------|
| [黑名单 API](../backend/docs/BLOCKS_API.md) | 黑名单接口文档 | `/backend/docs/BLOCKS_API.md` |
| [服务号推送时间](../backend/docs/service_account_push_time.md) | 推送时间配置 | `/backend/docs/service_account_push_time.md` |

### 配置参考

| 文件 | 说明 | 路径 |
|------|------|------|
| [OpenAPI 规范](../backend/openapi.json) | OpenAPI/Swagger 定义 | `/backend/openapi.json` |
| [环境变量模板](../backend/.env.example) | 环境变量配置模板 | `/backend/.env.example` |
| [Docker Compose](../backend/docker/docker-compose.yml) | Docker 部署配置 | `/backend/docker/docker-compose.yml` |

---

## 📱 移动端文档

### iOS 打包

| 文档 | 说明 | 路径 |
|------|------|------|
| [iOS 打包检测报告](../mobile/IOS_BUILD_REPORT.md) | 完整适配性检测 | `/mobile/IOS_BUILD_REPORT.md` |
| [远程 Mac 打包指南](../mobile/REMOTE_MAC_SETUP_GUIDE.md) | 远程打包操作指南 | `/mobile/REMOTE_MAC_SETUP_GUIDE.md` |
| [快速参考](../mobile/QUICK_REFERENCE.md) | 快速参考卡片 | `/mobile/QUICK_REFERENCE.md` |
| [优化总结](../mobile/OPTIMIZATION_SUMMARY.md) | iOS 优化总结 | `/mobile/OPTIMIZATION_SUMMARY.md` |
| [临时账户打包指南](../mobile/ios/TEMPORARY_ACCOUNT_BUILD_GUIDE.md) | 详细打包步骤 | `/mobile/ios/TEMPORARY_ACCOUNT_BUILD_GUIDE.md` |

### 蓝牙协议

| 文档 | 说明 | 路径 |
|------|------|------|
| [蓝牙协议快速参考](../mobile/docs/BLUETOOTH_PROTOCOL_QUICK_REFERENCE.md) | 协议快速参考 | `/mobile/docs/BLUETOOTH_PROTOCOL_QUICK_REFERENCE.md` |
| [蓝牙协议完整指南](../mobile/docs/BLUETOOTH_PROTOCOL_EMBEDDED_GUIDE.md) | 嵌入式协议指南 | `/mobile/docs/BLUETOOTH_PROTOCOL_EMBEDDED_GUIDE.md` |
| [项目结构](../mobile/docs/PROJECT_STRUCTURE.md) | 嵌入式项目结构 | `/mobile/docs/PROJECT_STRUCTURE.md` |

### 开发文档

| 文档 | 说明 | 路径 |
|------|------|------|
| [移动端 README](../mobile/README.md) | 移动端项目说明 | `/mobile/README.md` |
| [网络层文档](../mobile/lib/core/network/README.md) | 网络层设计 | `/mobile/lib/core/network/README.md` |

---

## 🔄 CI/CD 文档

| 文档 | 说明 | 路径 |
|------|------|------|
| [GitHub Actions 配置](../.github/README.md) | CI/CD 配置指南 | `/.github/README.md` |
| [后端部署工作流](../.github/workflows/deploy-fastapi-backend.yml) | 后端部署流程 | `/.github/workflows/deploy-fastapi-backend.yml` |
| [移动端发布工作流](../.github/workflows/deploy-flutter-user.yml) | APK 发布流程 | `/.github/workflows/deploy-flutter-user.yml` |

---

## 🎯 快速导航

### 按场景分类

#### 部署上线
1. [部署指南](./DEPLOYMENT.md) - 完整部署流程
2. [架构设计](./ARCHITECTURE.md) - 了解系统架构
3. [GitHub Actions 配置](../.github/README.md) - 配置 CI/CD

#### 开发调试
1. [API 文档](./API.md) - API 接口参考
2. [WebSocket API](./WEBSOCKET_API.md) - 实时通信接口
3. [代码审查报告](../backend/BACKEND_CODE_REVIEW.md) - 代码规范

#### iOS 打包
1. [快速参考](../mobile/QUICK_REFERENCE.md) - 快速查阅
2. [远程 Mac 打包指南](../mobile/REMOTE_MAC_SETUP_GUIDE.md) - 远程操作
3. [iOS 打包检测报告](../mobile/IOS_BUILD_REPORT.md) - 完整检测

#### 蓝牙开发
1. [蓝牙协议快速参考](../mobile/docs/BLUETOOTH_PROTOCOL_QUICK_REFERENCE.md)
2. [蓝牙协议完整指南](../mobile/docs/BLUETOOTH_PROTOCOL_EMBEDDED_GUIDE.md)
3. [项目结构](../mobile/docs/PROJECT_STRUCTURE.md)

#### 性能优化
1. [连接池优化](../backend/CONNECTION_POOL_OPTIMIZATION.md)
2. [轮询优化报告](../backend/POLLING_OPTIMIZATION_REPORT.md)
3. [Schema 优化报告](../backend/SCHEMA_OPTIMIZATION_REPORT.md)

---

## 📝 文档维护

### 更新记录

| 日期 | 文档 | 更新内容 |
|------|------|----------|
| 2026-03-24 | README.md | 重写项目总览文档 |
| 2026-03-24 | DEPLOYMENT.md | 创建部署指南 |
| 2026-03-24 | ARCHITECTURE.md | 创建架构设计文档 |
| 2026-03-24 | API.md | 创建完整 API 文档 |

### 文档规范

1. **文件命名**: 使用大写字母和下划线，如 `DEPLOYMENT.md`
2. **编码格式**: UTF-8
3. **换行符**: LF (Unix 风格)
4. **图片路径**: 使用相对路径，如 `../assets/image.png`
5. **代码块**: 标注语言类型，如 ```python

---

## 💡 贡献文档

欢迎提交文档改进：

1. Fork 本仓库
2. 修改或添加文档
3. 提交 Pull Request
4. 等待审核合并

---

**最后更新**: 2026年3月24日
**文档版本**: 1.0
