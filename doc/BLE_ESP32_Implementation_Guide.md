# Bipupu 设备端 (ESP32) 蓝牙实现指南

本文档详细描述了 Bipupu 蓝牙 BP 机设备端（ESP32）需要实现的蓝牙低功耗（BLE）协议细节，包括 GATT 服务定义、数据包结构以及标准电池服务的集成。

## 1. 蓝牙 GATT 服务定义

设备需作为 **GATT Server** 运行，并广播以下服务。

### 1.1 私有通信服务 (Bipupu Service)

用于 App 向设备发送富消息指令及设备状态回传。

*   **Service UUID**: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`

| 特征 (Characteristic) | UUID | 属性 (Properties) | 说明 |
| :--- | :--- | :--- | :--- |
| **Command Input** | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | Write / WriteWithoutResponse | App 向设备发送指令数据包 |
| **Status Output** | `6E400004-B5A3-F393-E0A9-E50E24DCCA9E` | Notify | 设备向 App 推送状态或确认信息 |

### 1.2 标准电池服务 (Battery Service)

为了让手机系统原生显示设备电量，必须实现蓝牙技术联盟（SIG）定义的标准电池服务。

*   **Service UUID**: `0x180F` (16-bit UUID)

| 特征 (Characteristic) | UUID | 属性 (Properties) | 数据格式 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| **Battery Level** | `0x2A19` | Read / Notify | `uint8` (0-100) | 当前电量百分比 |

> **实现注意**:
> *   当电量变化时，设备应主动通过 Notify 推送新值。
> *   值范围必须在 0 到 100 之间。

---

## 2. 私有协议数据包结构

App 写入 `Command Input` 特征的数据包遵循以下格式。所有多字节字段均采用 **小端序 (Little Endian)**。

### 2.1 数据包格式

| 偏移 (Offset) | 字段名 | 长度 (Bytes) | 类型 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| 0 | **Protocol Version** | 1 | `uint8` | 固定值 `0x01` |
| 1 | **Command Type** | 1 | `uint8` | 固定值 `0x01` (Message) |
| 2 | **Sequence Number** | 2 | `uint16` | 包序号，用于去重或乱序处理 |
| 4 | **Color Count** (N) | 1 | `uint8` | RGB 颜色数量 (建议限制 ≤ 20) |
| 5 | **RGB Colors** | 3 * N | `bytes` | 颜色数据序列，格式为 `[R, G, B, R, G, B, ...]` |
| 5 + 3N | **Vibration Mode** | 1 | `uint8` | 震动模式 ID (见下文枚举) |
| 6 + 3N | **Vibration Strength**| 1 | `uint8` | 震动强度 (固定 `0x01`) |
| 7 + 3N | **Text Length** (L) | 1 | `uint8` | 文本内容的字节长度 (Max 64) |
| 8 + 3N | **Text Content** | L | `bytes` | UTF-8 编码的文本内容 |
| 8 + 3N + L | **Screen Effect** | 1 | `uint8` | 屏幕特效 ID (见下文枚举) |
| 9 + 3N + L | **Checksum** | 1 | `uint8` | 校验和 (前文所有字节累加和 & 0xFF) |

### 2.2 字段详解与枚举

#### Command Type
目前仅支持一种指令类型：
*   `0x01`: **Message** (富消息通知)

#### Vibration Mode (震动模式)
设备端需根据此 ID 实现对应的震动波形：
*   `0x00`: **None** (不震动)
*   `0x01`: **Standard** (标准震动)
*   `0x02`: **Urgent** (急促/紧急震动)
*   `0x03`: **Gentle** (轻柔震动)
*   `0x04`: **Notification** (短促通知震动)

#### Screen Effect (屏幕特效)
设备端需根据此 ID 实现对应的屏幕显示效果：
*   `0x00`: **None** (无特效/静态显示)
*   `0x01`: **Scroll** (滚动显示)
*   `0x02`: **Blink** (闪烁)
*   `0x03`: **Breathing** (呼吸灯效)

#### Checksum 算法示例 (C语言)
```c
uint8_t calculate_checksum(uint8_t *data, size_t len) {
    uint8_t sum = 0;
    for (size_t i = 0; i < len; i++) {
        sum += data[i];
    }
    return sum;
}
// 校验时：计算包内除最后一个字节外的所有字节之和，对比最后一个字节。
```

---

## 3. 设备端实现逻辑建议

1.  **广播 (Advertising)**:
    *   广播包中应包含设备名称 (如 "Bipupu Device")。
    *   广播包中建议包含 128-bit Service UUID (`6E40...`) 或 16-bit Battery Service UUID (`0x180F`) 以便 App 快速过滤。

2.  **连接与订阅**:
    *   当 App 连接后，设备应接受 MTU 协商（建议支持较大 MTU 以减少分包）。
    *   当 App 订阅 `Status Output` 或 `Battery Level` 的 Notify 时，设备应记录订阅状态。

3.  **指令处理**:
    *   收到 `Command Input` 写入数据后：
        1.  验证 **Checksum**。
        2.  验证 **Protocol Version** 是否为 `0x01`。
        3.  解析 **Text Content** 并显示在屏幕上。
        4.  解析 **RGB Colors** 并控制 LED 灯光。
        5.  解析 **Vibration Mode** 并触发马达震动。
        6.  执行动作持续 **Duration** 毫秒后自动停止（或等待用户操作停止）。

4.  **电量管理**:
    *   定时读取电池电压并转换为百分比 (0-100)。
    *   当百分比变化时，更新 `Battery Level` 特征值，并发送 Notify。

## 4. 示例数据包

**场景**: 发送文本 "Hello", 红色灯光, 标准震动, 持续 1000ms。

*   **Protocol**: `0x01`
*   **Command**: `0x01`
*   **Seq**: `0x0001` -> `01 00`
*   **Color Count**: `1`
*   **RGB**: Red(255, 0, 0) -> `FF 00 00`
*   **Vib Mode**: Standard -> `0x01`
*   **Vib Strength**: `0x01`
*   **Text Len**: 5
*   **Text**: "Hello" -> `48 65 6C 6C 6F`
*   **Screen Effect**: Scroll -> `0x01`
*   **Checksum**: (Sum of above) & 0xFF

**Hex Stream**:
`01 01 01 00 01 FF 00 00 01 01 05 48 65 6C 6C 6F 01 [CS]`
