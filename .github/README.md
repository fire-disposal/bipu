# GitHub Actions CI/CD 配置指南

本目录包含项目的 CI/CD 自动化部署配置。

## 必需的 GitHub Secrets

在项目的 **Settings** -> **Secrets and variables** -> **Actions** 中，请配置以下 Secrets 以确保自动部署正常运行：

- **`SERVER_HOST`**: 部署服务器地址 (例: `123.45.67.89`)
- **`SERVER_USER`**: SSH 用户名 (例: `root`)
- **`SERVER_SSH_KEY`**: SSH 私钥 (OpenSSH 格式)
- **`SECRET_KEY`**: FastAPI 密钥 (生产环境)

### 推荐配置 (增强安全性)

未配置时将使用默认值，建议生产环境配置：

- **`POSTGRES_PASSWORD`**: 数据库密码
- **`ADMIN_EMAIL`**: 默认管理员邮箱 (默认: adminemail@qq.com)
- **`ADMIN_PASSWORD`**: 默认管理员密码 (默认: admin123)
- **`ADMIN_USERNAME`**: 默认管理员用户名 (默认: admin)
- **`DEBUG`**: 调试模式 (默认 `false`)



