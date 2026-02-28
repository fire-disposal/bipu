# Bipupu 蓝牙协议 - 嵌入式设备对接指南

## 概述

本文档详细描述了 Bipupu 应用的蓝牙通信协议，供嵌入式设备开发者参考实现。该协议设计用于一对一蓝牙连接，支持文本消息转发和时间同步功能。

## 协议版本

- **当前版本**: 1.2
- **协议头**: `0xB0`
- **设计目标**: 简单、高效、可靠，支持中文文本安全传输

## 蓝牙服务配置

### Nordic UART Service (NUS)

嵌入式设备需要实现标准的 Nordic UART Service：

| 项目 | UUID | 描述 |
|------|------|------|
| 服务 | `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` | NUS 服务 |
| TX 特征值 | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | 手机 → 设备（写） |
| RX 特征值 | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | 设备 → 手机（通知） |

**注意**: 本协议只使用 TX 特征值（手机发送到设备），RX 特征值可选实现。

## 协议格式

### 数据包结构

```
[协议头(1字节)][时间戳(4字节)][消息类型(1字节)][数据长度(2字节)][数据(N字节)][校验和(1字节)]
```

### 字节布局详解

| 偏移 | 长度 | 字段 | 描述 | 字节序 |
|------|------|------|------|--------|
| 0 | 1 | 协议头 | 固定值 `0xB0` (B代表Bipupu) | - |
| 1-4 | 4 | 时间戳 | Unix时间戳（秒） | 小端序 |
| 5 | 1 | 消息类型 | 见消息类型定义 | - |
| 6-7 | 2 | 数据长度 | 数据部分的字节数 (0-240) | 小端序 |
| 8+ | N | 数据 | 消息数据内容 | - |
| 8+N | 1 | 校验和 | 异或校验和 | - |

### 消息类型定义

| 类型值 | 名称 | 描述 |
|--------|------|------|
| 0x01 | 时间同步 | 用于同步设备RTC时钟，数据部分通常为空 |
| 0x02 | 文本消息 | 包含UTF-8编码的文本内容 |
| 0x03 | 确认响应 | 预留，用于消息确认机制 |

### 校验和计算

校验和是对协议头到数据内容的所有字节进行异或运算：

```c
uint8_t calculate_checksum(const uint8_t* data, size_t length) {
    uint8_t checksum = 0;
    for (size_t i = 0; i < length; i++) {
        checksum ^= data[i];
    }
    return checksum;
}
```

**验证方法**: 计算前 `length-1` 字节的校验和，与最后一个字节比较。

## 协议限制

| 项目 | 限制 | 说明 |
|------|------|------|
| 最大数据长度 | 240 字节 | 受蓝牙MTU限制 |
| 最小数据包长度 | 9 字节 | 头部8字节 + 校验和1字节 |
| 最大文本长度 | ~80 字符 | 考虑UTF-8编码（中文字符3字节） |
| 时间戳范围 | Unix时间戳 | 1970-01-01 至今的秒数 |

## 消息处理流程

### 1. 连接建立流程

```
手机端                             嵌入式设备
  |                                    |
  |--- 扫描并连接设备 ----------------->|
  |                                    |
  |<--- 连接成功 -----------------------|
  |                                    |
  |--- 发现NUS服务 -------------------->|
  |                                    |
  |--- 查找TX特征值 ------------------->|
  |                                    |
  |--- 发送时间同步(0x01) ------------->|
  |                                    | 1. 解析时间戳
  |                                    | 2. 更新RTC时钟
  |                                    | 3. 记录连接时间
  |                                    |
  |--- 准备就绪 ----------------------->|
```

### 2. 消息转发流程

```
手机端                             嵌入式设备
  |                                    |
  |--- 收到新消息 --------------------->|
  |                                    |
  |--- 创建文本数据包(0x02) ----------->|
  |                                    | 1. 验证协议头(0xB0)
  |                                    | 2. 验证校验和
  |                                    | 3. 解析时间戳
  |                                    | 4. 解析消息类型
  |                                    | 5. 提取文本数据
  |                                    | 6. UTF-8解码
  |                                    | 7. 显示/存储消息
  |                                    |
  |--- (可选)发送时间同步 ------------->|
  |                                    | 更新RTC时钟
```

## C语言实现参考

### 数据结构定义

```c
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

// 协议常量
#define PROTOCOL_HEADER 0xB0
#define MAX_DATA_LENGTH 240
#define HEADER_LENGTH 8
#define CHECKSUM_LENGTH 1
#define MIN_PACKET_LENGTH (HEADER_LENGTH + CHECKSUM_LENGTH)

// 消息类型
typedef enum {
    MESSAGE_TYPE_TIME_SYNC = 0x01,
    MESSAGE_TYPE_TEXT = 0x02,
    MESSAGE_TYPE_ACKNOWLEDGEMENT = 0x03
} MessageType;

// 解析结果结构
typedef struct {
    uint8_t header;
    uint32_t timestamp;
    MessageType message_type;
    uint16_t data_length;
    uint8_t data[MAX_DATA_LENGTH];
    uint8_t checksum;
    bool checksum_valid;
    char text[MAX_DATA_LENGTH + 1]; // UTF-8文本（以null结尾）
} ParsedPacket;
```

### 协议解析函数

```c
/**
 * 解析蓝牙数据包
 * 
 * @param data 接收到的原始数据
 * @param length 数据长度
 * @param result 解析结果输出
 * @return true 解析成功，false 解析失败
 */
bool parse_bluetooth_packet(const uint8_t* data, size_t length, ParsedPacket* result) {
    // 基本验证
    if (data == NULL || result == NULL || length < MIN_PACKET_LENGTH) {
        return false;
    }
    
    // 检查协议头
    if (data[0] != PROTOCOL_HEADER) {
        return false;
    }
    
    // 解析时间戳（小端序）
    result->timestamp = (uint32_t)data[1] |
                       ((uint32_t)data[2] << 8) |
                       ((uint32_t)data[3] << 16) |
                       ((uint32_t)data[4] << 24);
    
    // 解析消息类型
    result->message_type = (MessageType)data[5];
    
    // 解析数据长度（小端序）
    result->data_length = (uint16_t)data[6] | ((uint16_t)data[7] << 8);
    
    // 验证数据长度
    if (result->data_length > MAX_DATA_LENGTH) {
        return false;
    }
    
    // 验证总长度
    size_t expected_length = HEADER_LENGTH + result->data_length + CHECKSUM_LENGTH;
    if (length != expected_length) {
        return false;
    }
    
    // 提取数据
    if (result->data_length > 0) {
        memcpy(result->data, &data[HEADER_LENGTH], result->data_length);
    }
    
    // 提取校验和
    result->checksum = data[length - 1];
    
    // 计算并验证校验和
    uint8_t calculated_checksum = 0;
    for (size_t i = 0; i < length - 1; i++) {
        calculated_checksum ^= data[i];
    }
    result->checksum_valid = (calculated_checksum == result->checksum);
    
    if (!result->checksum_valid) {
        return false;
    }
    
    // 根据消息类型处理数据
    switch (result->message_type) {
        case MESSAGE_TYPE_TEXT:
            // UTF-8解码文本
            decode_utf8_safe(result->data, result->data_length, result->text);
            break;
            
        case MESSAGE_TYPE_TIME_SYNC:
            // 时间同步消息，数据通常为空
            result->text[0] = '\0';
            break;
            
        default:
            // 未知消息类型
            snprintf(result->text, sizeof(result->text), "[未知消息类型: 0x%02X]", result->message_type);
            break;
    }
    
    return true;
}
```

### 安全的UTF-8解码函数

```c
/**
 * 安全的UTF-8解码函数（容错实现）
 * 
 * @param data UTF-8编码的字节数组
 * @param length 数据长度
 * @param output 输出缓冲区（确保足够大，建议MAX_DATA_LENGTH+1）
 */
void decode_utf8_safe(const uint8_t* data, size_t length, char* output) {
    size_t i = 0, j = 0;
    
    while (i < length && j < MAX_DATA_LENGTH) {
        uint8_t first_byte = data[i];
        
        if ((first_byte & 0x80) == 0x00) {
            // ASCII字符 (0xxxxxxx)
            output[j++] = (char)first_byte;
            i += 1;
        }
        else if ((first_byte & 0xE0) == 0xC0 && i + 1 < length) {
            // 2字节字符 (110xxxxx)
            output[j++] = (char)first_byte;
            output[j++] = (char)data[i + 1];
            i += 2;
        }
        else if ((first_byte & 0xF0) == 0xE0 && i + 2 < length) {
            // 3字节字符 (1110xxxx) - 大部分中文字符
            output[j++] = (char)first_byte;
            output[j++] = (char)data[i + 1];
            output[j++] = (char)data[i + 2];
            i += 3;
        }
        else if ((first_byte & 0xF8) == 0xF0 && i + 3 < length) {
            // 4字节字符 (11110xxx) - Emoji等
            output[j++] = (char)first_byte;
            output[j++] = (char)data[i + 1];
            output[j++] = (char)data[i + 2];
            output[j++] = (char)data[i + 3];
            i += 4;
        }
        else {
            // 无效的UTF-8序列，跳过或替换
            i++;
            output[j++] = '?';
        }
    }
    
    output[j] = '\0'; // 确保以null结尾
}
```

### 时间同步处理

```c
/**
 * 处理时间同步消息
 * 
 * @param timestamp Unix时间戳（秒）
 */
void handle_time_sync(uint32_t timestamp) {
    // 将Unix时间戳转换为设备RTC时间
    // 注意：timestamp是UTC时间，可能需要根据时区调整
    
    printf("收到时间同步: %u\n", timestamp);
    printf("对应时间: %04d-%02d-%02d %02d:%02d:%02d\n",
           // 这里需要实现时间戳到年月日时分秒的转换
           // 可以使用标准库或自己实现
           year, month, day, hour, minute, second);
    
    // 更新设备RTC时钟
    // rtc_set_time(year, month, day, hour, minute, second);
}
```

### 主处理循环示例

```c
#include <stdio.h>
#include <string.h>

// 假设的蓝牙接收函数
extern bool ble_receive_data(uint8_t* buffer, size_t* length);

void main_processing_loop(void) {
    uint8_t rx_buffer[512];
    size_t data_length;
    ParsedPacket packet;
    
    while (1) {
        // 等待蓝牙数据
        if (ble_receive_data(rx_buffer, &data_length)) {
            // 解析数据包
            if (parse_bluetooth_packet(rx_buffer, data_length, &packet)) {
                printf("收到有效数据包:\n");
                printf("  时间戳: %u\n", packet.timestamp);
                printf("  消息类型: 0x%02X\n", packet.message_type);
                printf("  数据长度: %u\n", packet.data_length);
                printf("  校验和: %s\n", packet.checksum_valid ? "有效" : "无效");
                
                // 根据消息类型处理
                switch (packet.message_type) {
                    case MESSAGE_TYPE_TIME_SYNC:
                        printf("  类型: 时间同步\n");
                        handle_time_sync(packet.timestamp);
                        break;
                        
                    case MESSAGE_TYPE_TEXT:
                        printf("  类型: 文本消息\n");
                        printf("  内容: %s\n", packet.text);
                        
                        // 这里可以显示消息、存储到Flash等
                        // display_message(packet.text, packet.timestamp);
                        break;
                        
                    default:
                        printf("  类型: 未知\n");
                        break;
                }
            } else {
                printf("收到无效数据包，已丢弃\n");
            }
        }
        
        // 其他处理...
        // sleep_ms(10);
    }
}
```

## 安全注意事项

### 1. UTF-8安全截断

手机端实现了安全的UTF-8截断，但嵌入式设备仍应实现容错解码：

- 使用 `decode_utf8_safe()` 函数处理文本
- 遇到无效UTF-8序列时用'?'替换
- 确保输出缓冲区以null结尾

### 2. 数据验证

每次接收数据都应验证：
- 协议头 (`0xB0`)
- 数据长度（不超过240字节）
- 校验和（异或校验）
- 消息类型（已知类型）

### 3. 缓冲区安全

- 使用固定大小的缓冲区（建议512字节）
- 检查数组边界，防止溢出
- 验证数据长度后再进行内存操作

## 调试建议

### 1. 日志输出

建议在关键位置添加日志输出：

```c
#define DEBUG_ENABLED 1

#if DEBUG_ENABLED
    #define LOG_DEBUG(fmt, ...) printf("[DEBUG] " fmt "\n", ##__VA_ARGS__)
#else
    #define LOG_DEBUG(fmt, ...)
#endif

// 使用示例
LOG_DEBUG("收到数据包，长度: %u", data_length);
LOG_DEBUG("时间戳: %u", packet.timestamp);
LOG_DEBUG("文本内容: %s", packet.text);
```

### 2. 测试数据

可以使用以下测试数据验证解析逻辑：

```c
// 测试数据：文本消息 "Hello 世界"
uint8_t test_packet[] = {
    0xB0,                         // 协议头
    0xDC, 0x9B, 0x69, 0x69,       // 时间戳 0x69699BDC (秒)
    0x02,                         // 消息类型: 文本
    0x0C, 0x00,                   // 数据长度: 12字节
    // 数据: "Hello 世界" 的UTF-8编码
    0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20,           // "Hello "
    0xE4, 0xB8, 0x96, 0xE7, 0x95, 0x8C,           // "世界"
    0x??                          // 校验和（需要计算）
};

// 计算校验和
test_packet[sizeof(test_packet)-1] = calculate_checksum(test_packet, sizeof(test_packet)-1);
```

### 3. 常见问题排查

| 问题 | 可能原因 | 解决方案 |
|------|----------|----------|
| 解析失败 | 协议头不匹配 | 检查数据第一个字节是否为 `0xB0` |
| 校验和错误 | 数据传输错误 | 检查蓝牙连接质量，重发数据 |
| UTF-8解码乱码 | 截断在多字节字符中间 | 使用安全的UTF-8解码函数 |
| 时间戳错误 | 字节序问题 | 确认使用小端序解析 |
| 连接不稳定 | 信号干扰 | 检查设备距离，避免干扰源 |

## 性能优化建议

### 1. 内存优化

- 使用静态缓冲区避免动态内存分配
- 复用解析结构体减少内存碎片
- 合理设置缓冲区大小（512字节足够）

### 2. 处理优化

- 先验证协议头和长度，再解析完整数据
- 使用查表法优化UTF-8解码（如果需要）
- 批量处理消息，减少上下文切换

### 3. 功耗优化

- 合理设置蓝牙连接参数
- 在无数据时进入低功耗模式
- 使用中断驱动而非轮询

## 附录

### A. 协议版本历史

| 版本 | 日期 | 变更说明 |
|------|------|----------|
| 1.0 | 2024-01 | 初始版本 |
| 1.1 | 2024-02 | 添加校验和 |
| 1.2 | 2024-02 | 添加安全UTF-8截断 |

### B. 参考实现

完整的参考实现可在以下位置找到：
- 手机端Dart实现: `mobile/lib/core/services/unified_bluetooth_protocol.dart`
- 手机端服务: `mobile/lib/core/services/bluetooth_device_service.dart`

### C. 联系支持

如有协议相关问题，请联系：
- 协议设计: [联系人/团队]
- 技术问题: [技术支持邮箱]
- 问题反馈: [GitHub Issues链接]

---

**文档版本**: 1.0  
**最后更新**: 2024年2月28日  
**适用协议版本**: