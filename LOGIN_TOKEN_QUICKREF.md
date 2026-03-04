# 登录 Token 改进快速参考

## 📁 修改的文件清单

### 后端文件
| 文件 | 修改内容 | 优先级 |
|-----|--------|--------|
| `backend/app/api/routes/public.py` | 修复 Token 黑名单 TTL 计算，添加 `time` 导入 | 🔴 P0 |
| `backend/app/core/token_utils.py` | 新建文件：Token 管理工具类 | 🟡 P1 |

### 前端文件
| 文件 | 修改内容 | 优先级 |
|-----|--------|--------|
| `mobile/lib/core/config/app_config.dart` | 新建文件：应用配置管理 | 🔴 P0 |
| `mobile/lib/core/network/api_client.dart` | 使用 AppConfig，移除 _getBaseUrl | 🔴 P0 |
| `mobile/lib/core/network/api_interceptor.dart` | 改进 Token 刷新，使用配置和超时 | 🔴 P0 |
| `mobile/lib/core/utils/error_message_mapper.dart` | 新建文件：统一错误消息映射 | 🟡 P1 |
| `mobile/lib/pages/auth/login_page.dart` | 改进 UI，添加错误显示和密码切换 | 🟡 P1 |

## 🔧 关键改进点

### 1. Token 黑名单 TTL 计算
```python
# 之前：❌ 错误
token_exp = payload.get("exp", 0)
current_time = timedelta(seconds=token_exp)  # 错误！
await RedisService.add_token_to_blacklist(token, int(current_time.total_seconds()))

# 之后：✅ 正确
import time
token_exp = payload.get("exp", 0)
current_timestamp = int(time.time())
ttl = max(0, token_exp - current_timestamp)
await RedisService.add_token_to_blacklist(token, ttl)
```

### 2. Base URL 配置
```dart
// 之前：❌ 硬编码
const baseUrl = 'https://api.205716.xyz';

// 之后：✅ 配置管理
import 'package:app/core/config/app_config.dart';
final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

// 部署时：
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

### 3. 错误消息统一
```dart
// 之前：❌ 多种处理方式
if (e is AuthException) { /* ... */ }
else if (e is NetworkException) { /* ... */ }
// 分散在各个地方

// 之后：✅ 集中管理
import 'package:app/core/utils/error_message_mapper.dart';
final message = ErrorMessageMapper.getMessage(exception);
```

### 4. Token 刷新改进
```dart
// 之前：❌ 可能无限等待
await completer.future;

// 之后：✅ 有超时控制
_refreshTimeoutTimer = Timer(AppConfig.tokenRefreshTimeout, () {
  if (!completer.isCompleted) {
    completer.completeError(Exception('Timeout'));
  }
});
```

### 5. 登录 UI 改进
```dart
// 之前：❌ 无错误反馈，无加载状态
_isLoading = false;

// 之后：✅ 清晰的错误和加载反馈
String? _errorMessage;
bool _showPassword = false;
// 显示错误框、加载动画、密码切换
```

## 🚀 快速开始

### 部署步骤

#### 1. 后端部署
```bash
# 确保已安装依赖
cd backend

# 运行迁移（如有）
alembic upgrade head

# 启动服务
python -m uvicorn app.main:app --reload
```

#### 2. 前端运行（开发）
```bash
cd mobile

# 开发环境
flutter run --dart-define=API_BASE_URL=http://localhost:8000

# 生产环境
flutter build apk --dart-define=API_BASE_URL=https://api.205716.xyz --release
```

## ✅ 验证清单

- [ ] 后端登出后，Token 在 Redis 中的 TTL 正确（~900秒）
- [ ] 前端可以通过 --dart-define 改变 API URL
- [ ] Token 刷新失败 3 次后自动清除认证
- [ ] 登录失败显示中文错误提示
- [ ] 密码输入框可以切换显示/隐藏
- [ ] 登录时显示加载动画，防止重复提交

## 🐛 常见问题排查

| 症状 | 可能原因 | 解决方案 |
|-----|--------|--------|
| Token 刷新后仍显示 401 | Base URL 配置错误 | 检查 `--dart-define=API_BASE_URL` |
| Redis 中 Token 保留时间过长 | TTL 计算错误 | 检查 `token_utils.py` 的 TTL 计算 |
| 登录失败显示英文 | 错误映射不完整 | 更新 `error_message_mapper.dart` |
| Token 刷新无响应 | 超时设置过短或网络慢 | 增加 `tokenRefreshTimeout` 到 15 秒 |

## 📊 性能影响

| 指标 | 改进前 | 改进后 | 变化 |
|-----|-------|-------|------|
| Token 刷新响应时间 | 不确定 | < 10秒 | ✅ 更快 |
| 登录页面加载 | 不清晰 | 清晰反馈 | ✅ 改进 |
| 错误恢复时间 | 长 | 自动恢复 | ✅ 改进 |
| 代码复杂度 | 分散 | 集中 | ✅ 降低 |

## 🔐 安全检查

- [x] Token 过期时间合理（Access: 15分钟，Refresh: 7天）
- [x] 登出后 Token 立即黑名单化
- [x] Token 刷新请求使用独立的 Dio 实例（避免循环拦截）
- [x] 敏感信息不在日志中显示（仅显示前 20 字符）
- [x] Base URL 支持环境变量配置（不硬编码）

## 📞 需要帮助？

- 查看详细文档：[LOGIN_TOKEN_IMPROVEMENTS.md](./LOGIN_TOKEN_IMPROVEMENTS.md)
- 查看分析报告：[LOGIN_TOKEN_ANALYSIS.md](./LOGIN_TOKEN_ANALYSIS.md)
- 检查代码：各文件中的注释和文档字符串

---

**最后更新**: 2026-03-04
