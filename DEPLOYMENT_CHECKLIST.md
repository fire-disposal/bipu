# Bipupu 域名绑定配置检查清单

## 概述
本项目已配置为使用以下域名：
- 管理端网页入口：`https://bipupu.205716.xyz` (转发8080端口)
- 后端API：`https://api.205716.xyz` (转发8000端口)

## 配置更改总结

### 1. 后端配置 (backend/app/core/config.py)
- ✅ 更新 `ALLOWED_HOSTS` 配置，包含具体的域名而不是通配符
- ✅ 添加的域名：`https://api.205716.xyz`, `https://bipupu.205716.xyz`
- ✅ 保留开发环境地址：`http://localhost:3000`, `http://localhost:8080`

### 2. 后端安全头配置 (backend/app/main.py)
- ✅ 增强安全头中间件，添加HTTPS支持
- ✅ 添加 `Strict-Transport-Security` 头
- ✅ 添加 `Referrer-Policy` 头
- ✅ 添加 `Content-Security-Policy` 头，限制资源加载

### 3. Flutter Admin配置 (flutter_admin/lib/main.dart)
- ✅ 更新API基础URL从 `http://38.147.187.207:8000/api` 到 `https://api.205716.xyz/api`
- ✅ 保持连接超时设置不变

### 4. Web前端优化 (flutter_admin/web/index.html)
- ✅ 更新页面标题为 "Bipupu Admin"
- ✅ 更新页面描述为 "Bipupu Admin Management System"
- ✅ 更新iOS应用标题为 "Bipupu Admin"

### 5. 环境变量配置 (backend/.env.example)
- ✅ 更新示例配置，说明生产环境应使用具体域名
- ✅ 添加管理员账户配置说明

## CORS政策检查

### 当前CORS配置
- **允许的来源**：具体的域名列表，不再使用通配符
- **允许的凭证**：支持cookies和认证头
- **允许的方法**：所有HTTP方法
- **允许的头**：所有请求头

### 安全建议
1. **生产环境验证**：确保`SECRET_KEY`不是默认值
2. **HTTPS强制**：考虑在反向代理层面强制HTTPS重定向
3. **域名验证**：确认两个域名都能正常访问
4. **SSL证书**：确保HTTPS证书有效且未过期

## 部署验证步骤

1. **后端服务验证**
   ```bash
   curl -H "Origin: https://bipupu.205716.xyz" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type" \
        -X OPTIONS \
        https://api.205716.xyz/api/docs
   ```

2. **管理端访问验证**
   - 访问 `https://bipupu.205716.xyz`
   - 检查是否能正常加载登录页面
   - 验证API调用是否成功

3. **API文档访问**
   - 访问 `https://api.205716.xyz/api/docs`
   - 确认Swagger文档能正常显示

4. **跨域请求测试**
   - 从管理端发起API请求
   - 检查浏览器控制台是否有CORS错误

## 故障排除

### 常见CORS问题
1. **403 Forbidden**：检查`ALLOWED_HOSTS`是否包含正确的域名
2. **CORS preflight failed**：确认OPTIONS请求能正常响应
3. **SSL证书错误**：检查HTTPS证书配置

### 日志检查
- 后端日志：`docker logs bipupu-backend`
- 管理端日志：浏览器开发者工具控制台

## 后续建议

1. **监控设置**：考虑添加应用性能监控
2. **日志收集**：配置集中式日志收集
3. **备份策略**：制定数据库和文件备份计划
4. **安全扫描**：定期进行安全漏洞扫描