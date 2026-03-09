# 蓝牙扫描诊断 - 使用指南

## 🚀 快速诊断步骤

### 步骤 1: 启用诊断模式
1. 打开蓝牙扫描页面
2. 点击右上角的 **虫子图标** 🐛（诊断模式开关）
3. AppBar 会显示所有扫描到的蓝牙设备（不仅仅是寻呼机）

### 步骤 2: 查看调试日志
```bash
adb logcat | grep BLE_DEBUG
```

会看到类似的输出：
```
[BLE_DEBUG] 蓝牙适配器状态: BluetoothAdapterState.on
[BLE_DEBUG] 开始扫描...
[BLE_DEBUG] 扫描设备: 名称=BIPUPU_PAGER, ID=XX:XX:XX:XX:XX:XX, RSSI=-45, 是寻呼机=true
[BLE_DEBUG] 扫描设备: 名称=Phone, ID=YY:YY:YY:YY:YY:YY, RSSI=-50, 是寻呼机=false
[BLE_DEBUG] 扫描完成
```

### 步骤 3: 识别 ESP 设备
- 找出你的 ESP 设备的实际名称（例如 `BIPUPU_PAGER`）
- 检查名称是否包含识别模式之一：
  ```
  - pager
  - beeper
  - bp-
  - bipupu
  - 以 bp 开头
  - 以 pg 开头
  ```

### 步骤 4: 修复或报告
**如果设备名称不匹配**:
1. 修改 bluetooth_scan_page.dart 中的 `_isPagerDevice()` 函数
2. 添加新的识别模式
3. 重新编译并测试

**如果扫描不到任何设备**:
1. 检查蓝牙权限
2. 尝试用 nRF Connect 扫描
3. 检查 ESP 是否确实在广播

---

## 📊 诊断模式信息解读

### RSSI 信号强度
```
≥ -50 dBm   : 强信号 (接近)
-50 ~ -70   : 中等信号
< -70 dBm   : 弱信号 (远离)
```

### 状态指示
- **是寻呼机=true** : ✅ 会显示在列表中
- **是寻呼机=false** : ❌ 会被过滤掉

---

## 🔧 常见问题修复

### 问题 1: 扫描不到 ESP 设备

**检查清单**:
- [ ] 蓝牙已启用
- [ ] 位置权限已授予
- [ ] ESP 已上电并开启蓝牙
- [ ] ESP 的蓝牙名称包含识别关键词

**诊断步骤**:
```
1. 启用诊断模式
2. 查看日志输出
3. 如果看不到 ESP，说明设备没有广播
   → 检查 ESP 蓝牙初始化代码
```

### 问题 2: 扫描到很多其他设备

**可能原因**:
- 附近有很多蓝牙设备 (正常现象)
- ESP 的蓝牙名称被其他设备的名称覆盖

**解决方案**:
- 在诊断模式中查看所有设备的 MAC 地址
- 逐一尝试连接找出是哪个

### 问题 3: 扫描到 ESP 但连接失败

**可能原因**:
- 协议不兼容
- 安全认证失败
- GATT 服务配置错误

**诊断**:
```
1. 检查日志中是否有连接错误信息
2. 查看 ESP 端的蓝牙连接回调
3. 验证 GATT 服务 UUID 是否正确
```

---

## 🐛 调试日志详解

### 日志格式
```
[BLE_DEBUG] <操作> : <详细信息>
```

### 关键日志点
| 日志 | 含义 | 正常值 |
|------|------|--------|
| 蓝牙适配器状态 | 蓝牙硬件状态 | `on` |
| 开始扫描 | 扫描命令发出 | 应该立即出现 |
| 扫描设备: 名称=... | 发现的设备 | 至少应有 ESP 设备 |
| 扫描完成 | 扫描超时或手动停止 | 15秒后 |

---

## 📝 提交故障报告时需要提供

如果问题持续，请提供：

1. **诊断日志**
```bash
adb logcat | grep BLE_DEBUG > ble_debug.log
# 然后提交 ble_debug.log
```

2. **ESP 设备信息**
- 实际蓝牙名称
- MAC 地址
- 信号强度 (RSSI)

3. **ESP 配置**
- 蓝牙初始化代码
- 广播参数设置
- GATT 服务配置

4. **环境信息**
- 手机型号和 Android 版本
- ESP 芯片型号
- 距离和障碍物

---

## 💡 高级调试

### 方案 A: 修改设备识别规则

编辑 `bluetooth_scan_page.dart`:
```dart
bool _isPagerDevice(BluetoothDevice device) {
  final name = device.platformName.toLowerCase();
  final id = device.remoteId.str;
  
  // 方案 1: 按名称
  if (name.contains('你的实际设备名')) return true;
  
  // 方案 2: 按 MAC 地址（临时）
  if (id == 'XX:XX:XX:XX:XX:XX') return true;
  
  // 原有规则
  return name.contains('pager') || /* ... */;
}
```

### 方案 B: 跳过过滤直接连接

```dart
// 在诊断模式下允许连接任何设备
onTap: (_showAllDevices || !isConnecting) 
    ? () => _connectToDevice(result.device)
    : null,
```

### 方案 C: 详细的 GATT 调试

```dart
Future<void> _connectToDevice(BluetoothDevice device) async {
  try {
    await device.connect();
    
    // ✅ 打印所有 GATT 服务
    final services = await device.discoverServices();
    for (var service in services) {
      debugPrint('[GATT] 服务: ${service.uuid}');
      for (var char in service.characteristics) {
        debugPrint('[GATT]   特征: ${char.uuid}');
      }
    }
  } catch (e) {
    debugPrint('[BLE_ERROR] 连接异常: $e');
  }
}
```

---

## ✅ 完整检查清单

- [ ] 手机蓝牙已启用
- [ ] 蓝牙和位置权限已授予
- [ ] ESP 已上电
- [ ] ESP 蓝牙已启用
- [ ] 诊断模式中看到 ESP 设备
- [ ] 设备名称包含识别关键词或已添加新规则
- [ ] 可以成功连接
- [ ] 可以发送/接收数据

---

**最后更新**: 2026-03-09  
**适用版本**: 1.0.0+  
**状态**: ✅ 已验证
