# 蓝牙扫描无设备问题诊断 - 快速检查报告

## 🔍 问题症状
**扫描不到设备** - 点击扫描时无法发现 ESP 设备

---

## 📱 移动端代码分析

### 1. 扫描初始化 ✅
**文件**: bluetooth_scan_page.dart L102-122

```dart
Future<void> _startScan() async {
  if (_adapterState != BluetoothAdapterState.on) {
    // ✅ 蓝牙检查
    // ✅ 自动开启蓝牙（Android）
  }
  
  try {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  } catch (e) {
    // ✅ 错误处理
  }
}
```

**检查项**:
- [x] 蓝牙适配器状态检查
- [x] 自动开启蓝牙
- [x] 15秒超时设置
- [x] 异常捕获

### 2. 设备识别过滤 ⚠️
**文件**: bluetooth_scan_page.dart L138-144

```dart
bool _isPagerDevice(BluetoothDevice device) {
  final name = device.platformName.toLowerCase();
  return name.contains('pager') ||
      name.contains('beeper') ||
      name.contains('bp-') ||
      name.contains('Bipupu') ||
      name.startsWith('bp') ||
      name.startsWith('pg');
}
```

**问题点**:
```
❌ 关键问题：如果 ESP 设备的蓝牙广播名称不匹配这些模式，会被过滤掉！
```

### 3. 权限检查 ✅
**文件**: bluetooth_scan_page.dart L68-81

```dart
Future<void> _checkPermissions() async {
  if (Platform.isAndroid) {
    var scanPermission = await Permission.bluetoothScan.request();
    var connectPermission = await Permission.bluetoothConnect.request();
    var locationPermission = await Permission.location.request();
  }
}
```

**检查项**:
- [x] BLUETOOTH_SCAN
- [x] BLUETOOTH_CONNECT
- [x] LOCATION (必需，用于蓝牙扫描)

---

## 🖥️ ESP 端配置需求

### 需要验证的项目
1. **蓝牙广播名称** - 必须包含以下之一:
   - `pager`
   - `beeper`
   - `bp-`
   - `bipupu`
   - 以 `bp` 开头
   - 以 `pg` 开头

2. **BLE 广播配置**
   - 应启用广播
   - 广播间隔合理（20ms-100ms）
   - 广播功率足够

3. **GAP 配置**
   - 设备名称 (LOCAL_NAME)
   - 可发现模式
   - 可连接模式

---

## 🔧 快速诊断步骤

### 步骤 1: 检查蓝牙权限
```
设置 → 应用 → 应用权限 → 检查蓝牙/位置权限
```

### 步骤 2: 使用通用蓝牙扫描应用
```
下载: nRF Connect / BLE Scanner
目的: 验证 ESP 是否真的在广播
```

### 步骤 3: 获取实际设备名称
```
如果 nRF Connect 能扫到，记下设备的完整名称
然后在代码中添加新的识别模式
```

### 步骤 4: 验证 ESP 蓝牙配置
```
检查: components/ble 配置
确认: 
  - 设备名称设置正确
  - 广播已启用
  - 功率足够（POWER >= 0dBm）
```

---

## 💡 常见原因及解决方案

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| **扫描显示"未找到"** | 设备名称不匹配 | 修改 `_isPagerDevice()` 或 ESP 的广播名称 |
| **扫描超时无结果** | ESP 未广播 | 检查 ESP 蓝牙初始化 |
| **权限提示** | 位置权限未授予 | 在设置中手动授予位置权限 |
| **连接后立即断开** | 协议不兼容 | 检查 GATT 服务配置 |
| **扫描到但连接失败** | 密钥/安全性问题 | 检查安全设置 |

---

## 🎯 立即行动清单

### 优先级 1 (必做)
- [ ] 用 nRF Connect 扫描，确认 ESP 在广播
- [ ] 记录 ESP 的实际蓝牙设备名称
- [ ] 确认移动端权限已授予

### 优先级 2 (快速修复)
- [ ] 如设备名称不匹配，修改 `_isPagerDevice()` 函数
- [ ] 添加 DEBUG 日志打印所有扫描到的设备

### 优先级 3 (深度检查)
- [ ] 检查 ESP 蓝牙功率设置
- [ ] 验证广播间隔配置
- [ ] 检查天线/信号问题

---

## 🐛 添加临时 DEBUG 日志

修改 bluetooth_scan_page.dart 中的 `_startScan()`:

```dart
void _setupListeners() {
  // ... 其他代码 ...
  
  _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
    // ✅ 添加这行用于调试
    for (var result in results) {
      debugPrint('[BLE] 扫描到设备: ${result.device.platformName} (${result.device.remoteId})');
    }
    
    results.sort((a, b) => b.rssi.compareTo(a.rssi));
    _scanResults = results;
    if (mounted) setState(() {});
  });
}
```

查看日志，找出 ESP 的实际名称。

---

## 📞 联系支持

如果按以上步骤仍无法解决:
1. 提供 nRF Connect 中看到的 ESP 设备名称
2. 提供 logcat 的 BLE 相关输出
3. 检查 ESP 的 components/ble 配置文件

---

**预计解决时间**: 5-15 分钟  
**更新时间**: 2026-03-09  
**状态**: 🔴 待诊断
