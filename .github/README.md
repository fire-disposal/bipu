# GitHub Actions CI/CD 配置指南

本目录包含项目的 CI/CD 自动化部署配置。

## 必需的 GitHub Secrets

在项目的 **Settings** -> **Secrets and variables** -> **Actions** 中，请配置以下 Secrets 以确保自动部署正常运行：

- **`SERVER_HOST`**: 部署服务器地址 (例: `123.45.67.89`)
- **`SERVER_USER`**: SSH 用户名 (例: `root`)
- **`SERVER_SSH_KEY`**: SSH 私钥 (OpenSSH 格式)
- **`SECRET_KEY`**: FastAPI 密钥 (生产环境)
- **`ADMIN_PASSWORD`**: 默认管理员密码
- **`ADMIN_USERNAME`**: 默认管理员用户名

### 数据库配置

数据库使用固定的默认配置：
- 用户名: `postgres`
- 密码: `postgres`  
- 数据库名: `bipupu`
- 端口: 仅内网访问，不暴露公网



