# GitHub Actions CI/CD 配置指南

本目录包含项目的 CI/CD 自动化部署配置。

## 必需的 GitHub Secrets

在项目的 **Settings** -> **Secrets and variables** -> **Actions** 中，请配置以下 Secrets 以确保自动部署正常运行：

| Secret 名称 | 描述 | 示例值 |
|---|---|---|
| `SERVER_HOST` | 部署服务器地址 | `123.45.67.89` |
| `SERVER_USER` | SSH 用户名 | `root` |
| `SERVER_SSH_KEY` | SSH 私钥 (OpenSSH 格式) | `-----BEGIN OPENSSH...` |
| `SECRET_KEY` | FastAPI 密钥 (生产环境) | `your-secure-key` |

### 推荐配置 (增强安全性)

未配置时将使用默认弱密码
建议生产环境配置强密码：

| Secret 名称 | 描述 |
|---|---|
| `POSTGRES_PASSWORD` | 数据库密码 |
| `REDIS_PASSWORD` | Redis 密码 |
| `DEBUG` | 调试模式 (默认 `false`) |



