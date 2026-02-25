# 头像修复部署检查清单

## 部署前检查

### 代码审查 ✅
- [ ] `app/services/storage_service.py` - 头像处理核心逻辑
- [ ] `app/api/routes/profile.py` - 用户头像上传API
- [ ] `app/api/routes/admin_web.py` - 服务号头像上传API
- [ ] `templates/test_profile.html` - 前端头像验证
- [ ] `tests/verify_avatar_fixes.py` - 测试验证脚本

### 依赖检查 ✅
- [ ] Pillow/PIL 库已安装且版本兼容
- [ ] FastAPI 依赖无冲突
- [ ] 所有导入语句正确

### 配置验证 ✅
- [ ] 头像最大尺寸：100px
- [ ] 头像最小尺寸：50px
- [ ] 最大文件大小：5MB
- [ ] JPEG质量：70%
- [ ] 宽高比容差：10%

## 部署步骤

### 1. 备份当前版本
```bash
# 备份相关文件
cp app/services/storage_service.py app/services/storage_service.py.backup
cp app/api/routes/profile.py app/api/routes/profile.py.backup
cp app/api/routes/admin_web.py app/api/routes/admin_web.py.backup
cp templates/test_profile.html templates/test_profile.html.backup
```

### 2. 部署新代码
```bash
# 确保所有修复文件已就位
ls -la app/services/storage_service.py
ls -la app/api/routes/profile.py
ls -la app/api/routes/admin_web.py
ls -la templates/test_profile.html
```

### 3. 运行语法检查
```bash
python -m py_compile app/services/storage_service.py
python -m py_compile app/api/routes/profile.py
python -m py_compile app/api/routes/admin_web.py
```

### 4. 运行测试验证
```bash
cd tests && python verify_avatar_fixes.py
```
预期输出：所有测试通过

### 5. 重启服务
```bash
# 根据部署方式重启服务
# Docker部署
docker-compose restart backend

# 或直接重启
sudo systemctl restart bipupu-backend
```

## 部署后验证

### API 功能测试
```bash
# 测试1: 正常正方形图片上传
curl -X POST http://localhost:8000/api/profile/avatar \
  -H "Authorization: Bearer <token>" \
  -F "file=@test_avatar.jpg"

# 测试2: 长方形图片上传（应自动裁剪）
curl -X POST http://localhost:8000/api/profile/avatar \
  -H "Authorization: Bearer <token>" \
  -F "file=@rectangular.jpg"

# 测试3: 超大文件上传（应被拒绝）
curl -X POST http://localhost:8000/api/profile/avatar \
  -H "Authorization: Bearer <token>" \
  -F "file=@large_file.jpg"
```

### 前端功能测试
1. [ ] 访问 `/admin/test_profile`
2. [ ] 上传正方形图片 - 应成功
3. [ ] 上传长方形图片 - 应提示并自动裁剪
4. [ ] 上传超过5MB文件 - 应被拒绝
5. [ ] 上传非图片文件 - 应被拒绝
6. [ ] 删除头像 - 应成功

### 日志监控
检查服务日志：
```bash
# 查看头像相关日志
tail -f logs/app.log | grep -i "avatar"
```
预期看到：
- "头像处理完成: 原始=...KB, 压缩后=...KB, 尺寸=...x..."
- "头像宽高比不符合1:1要求"（当上传非正方形图片时）
- 详细的错误信息（当上传失败时）

## 回滚方案

### 情况1：发现严重问题
```bash
# 立即回滚到备份版本
cp app/services/storage_service.py.backup app/services/storage_service.py
cp app/api/routes/profile.py.backup app/api/routes/profile.py
cp app/api/routes/admin_web.py.backup app/api/routes/admin_web.py
cp templates/test_profile.html.backup templates/test_profile.html

# 重启服务
docker-compose restart backend
```

### 情况2：部分功能问题
根据具体问题选择性回滚：
1. 如果头像处理有问题：只回滚 `storage_service.py`
2. 如果API有问题：回滚对应的API文件
3. 如果前端有问题：回滚 `test_profile.html`

## 监控指标

### 实时监控（部署后24小时）
- [ ] 头像上传成功率 > 95%
- [ ] 平均处理时间 < 2秒
- [ ] 错误率 < 5%
- [ ] 内存使用稳定

### 业务指标
- [ ] 用户头像上传次数
- [ ] 服务号头像上传次数
- [ ] 自动裁剪触发次数
- [ ] 文件大小拒绝次数

## 常见问题处理

### 问题1：头像上传失败
**症状**：返回400或500错误
**检查**：
1. 查看日志中的具体错误信息
2. 验证文件大小和格式
3. 检查PIL库是否正常工作

### 问题2：头像显示变形
**症状**：前端显示的头像不是正方形
**检查**：
1. 确认 `_crop_to_square` 函数正常工作
2. 验证图片处理后的尺寸
3. 检查前端CSS是否正确

### 问题3：性能问题
**症状**：头像上传处理缓慢
**检查**：
1. 监控内存使用情况
2. 检查图片尺寸是否过大
3. 验证压缩算法效率

## 沟通计划

### 部署前通知
- [ ] 通知开发团队部署时间
- [ ] 通知运维团队监控重点
- [ ] 更新相关文档

### 部署后通知
- [ ] 通知测试团队验证功能
- [ ] 更新API文档（如有变更）
- [ ] 记录部署结果和问题

## 成功标准

### 技术标准 ✅
- [ ] 所有测试通过
- [ ] 无语法错误
- [ ] 服务正常启动
- [ ] API响应正常

### 业务标准 ✅
- [ ] 用户可正常上传头像
- [ ] 头像始终显示为正方形
- [ ] 文件大小限制生效
- [ ] 错误信息明确易懂

### 性能标准 ✅
- [ ] 处理时间在可接受范围内
- [ ] 内存使用稳定
- [ ] 无内存泄漏

---

**部署负责人**：____________________

**部署时间**：____________________

**部署结果**：____________________

**备注**：____________________