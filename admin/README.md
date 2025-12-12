# Admin Frontend - 系统管理端

这是一个基于Flutter的Web管理端应用，用于管理系统的后台功能。

## 功能特性

- 🎨 现代化的Material Design界面
- 📱 响应式设计，支持桌面和移动设备
- 🔐 用户认证和权限管理
- 📊 数据可视化和图表展示
- 🚀 高性能的Web应用

## 技术栈

- **Flutter** - UI框架
- **Dart** - 编程语言
- **Provider** - 状态管理
- **Dio** - HTTP客户端
- **GoRouter** - 路由管理
- **Shared Preferences** - 本地存储

## 快速开始

### 环境要求

- Flutter 3.16.0 或更高版本
- Dart 3.10.1 或更高版本

### 安装依赖

```bash
flutter pub get
```

### 开发运行

```bash
flutter run -d chrome
```

### 构建生产版本

```bash
flutter build web
```

构建产物将在 `build/web/` 目录中。

## 项目结构

```
admin_frontend/
├── lib/
│   ├── main.dart          # 应用入口
│   ├── models/            # 数据模型
│   ├── views/             # 页面视图
│   ├── widgets/           # 可复用组件
│   ├── services/          # API服务
│   ├── providers/         # 状态管理
│   └── utils/             # 工具类
├── test/                  # 测试文件
├── web/                   # Web相关文件
└── pubspec.yaml          # 项目配置
```

## 开发指南

### 添加新页面

1. 在 `lib/views/` 目录下创建新的页面文件
2. 在 `lib/services/` 中添加对应的API服务
3. 在 `lib/providers/` 中添加状态管理逻辑
4. 更新路由配置

### API集成

使用Dio进行HTTP请求，基础配置已设置：

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'http://localhost:8000/api',
  connectTimeout: Duration(seconds: 5),
  receiveTimeout: Duration(seconds: 3),
));
```

### 状态管理

使用Provider进行状态管理，主要状态类已创建：

- `AuthProvider` - 用户认证状态
- `UserProvider` - 用户管理状态
- `DashboardProvider` - 仪表板数据状态

## 部署

### Web部署

1. 构建生产版本：
   ```bash
   flutter build web --release
   ```

2. 将 `build/web/` 目录中的文件部署到Web服务器

3. 配置Web服务器以支持单页应用路由

### Docker部署

可以创建Dockerfile来容器化部署：

```dockerfile
FROM nginx:alpine
COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
```

## 贡献指南

1. Fork项目
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

## 许可证

此项目基于MIT许可证开源 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 支持

如有问题或建议，请提交Issue或联系开发团队。
