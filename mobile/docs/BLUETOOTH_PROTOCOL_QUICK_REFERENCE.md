# Bipupu 蓝牙协议 - 快速参考指南

## 🎯 协议概览

| 项目 | 值 | 说明 |
|------|-----|------|
| **版本** | 1.2 | 支持安全UTF-8截断 |
| **协议头** | `0xB0` | B代表Bipupu |
| **服务UUID** | `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` | Nordic UART Service |
| **TX特征值** | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | 手机→设备 |
| **最大数据** | 240字节 | 蓝牙MTU限制 |
| **校验和** | XOR | 防止比特翻转 |

## 📦 数据包格式

### 字节布局
```
[0xB0][时间戳4B][类型1B][长度2B][数据N字节][校验和1B]
```

### 详细结构
```
偏移  长度  字段       说明          字节序
0     1     协议头     固定0xB0      -
1-4   4     时间戳     Unix秒数     小端序
5     1     消息类型   见下表        -
6-7   2     数据长度   0-240       小端序
8+    N     数据       消息内容     -
最后  1     校验和     XOR校验      -
```

## 📨 消息类型

| 值 | 名称 | 数据内容 | 用途 |
|----|------|----------|------|
| `0x01` | 时间同步 | 通常为空 | 连接时同步RTC时钟 |
| `0x02` | 文本消息 | UTF-8文本 | 转发消息到设备 |
| `0x03` | 确认响应 | 预留 | 消息确认机制 |

## 🔧 嵌入式端C代码模板

### 数据结构
```c
#include <stdint.h>
#include <stdbool.h>

#define PROTOCOL_HEADER 0xB0
#define MAX_DATA_LENGTH 240
#define HEADER_LENGTH 8
#define MIN_PACKET_LENGTH 9  // 8+1

typedef enum {
    MSG_TIME_SYNC = 0x01,
    MSG_TEXT = 0x02,
    MSG_ACK = 0x03
} MessageType;

typedef struct {
    uint32_t timestamp;
    MessageType type;
    uint16_t data_length;
    uint8_t data[MAX_DATA_LENGTH];
    char text[MAX_DATA_LENGTH + 1];
    bool checksum_valid;
} ParsedPacket;
```

### 校验和计算
```c
uint8_t calculate_checksum(const uint8_t* data, size_t length) {
    uint8_t checksum = 0;
    for (size_t i = 0; i < length; i++) {
        checksum ^= data[i];
    }
    return checksum;
}
```

### 协议解析（简化版）
```c
bool parse_packet(const uint8_t* data, size_t length, ParsedPacket* result) {
    // 基本检查
    if (length < MIN_PACKET_LENGTH || data[0] != PROTOCOL_HEADER) {
        return false;
    }
    
    // 解析固定字段
    result->timestamp = *(uint32_t*)(data + 1);  // 小端序
    result->type = (MessageType)data[5];
    result->data_length = *(uint16_t*)(data + 6);  // 小端序
    
    // 长度检查
    if (result->data_length > MAX_DATA_LENGTH) {
        return false;
    }
    
    // 校验和验证
    uint8_t calc_checksum = calculate_checksum(data, length - 1);
    result->checksum_valid = (calc_checksum == data[length - 1]);
    
    if (!result->checksum_valid) {
        return false;
    }
    
    // 提取数据
    if (result->data_length > 0) {
        memcpy(result->data, data + HEADER_LENGTH, result->data_length);
    }
    
    // UTF-8解码（安全）
    decode_utf8_safe(result->data, result->data_length, result->text);
    
    return true;
}
```

### 安全UTF-8解码
```c
void decode_utf8_safe(const uint8_t* data, size_t length, char* output) {
    size_t i = 0, j = 0;
    
    while (i < length && j < MAX_DATA_LENGTH) {
        uint8_t b = data[i];
        
        if ((b & 0x80) == 0x00) {           // ASCII
            output[j++] = b;
            i += 1;
        } else if ((b & 0xE0) == 0xC0 && i+1 < length) {  // 2字节
            output[j++] = b;
            output[j++] = data[i+1];
            i += 2;
        } else if ((b & 0xF0) == 0xE0 && i+2 < length) {  // 3字节（中文）
            output[j++] = b;
            output[j++] = data[i+1];
            output[j++] = data[i+2];
            i += 3;
        } else if ((b & 0xF8) == 0xF0 && i+3 < length) {  // 4字节（Emoji）
            output[j++] = b;
            output[j++] = data[i+1];
            output[j++] = data[i+2];
            output[j++] = data[i+3];
            i += 4;
        } else {
            i++;  // 跳过无效字节
            output[j++] = '?';
        }
    }
    
    output[j] = '\0';  // 确保null结尾
}
```

## 🚀 快速开始步骤

### 1. 配置蓝牙服务
```c
// 实现Nordic UART Service
// UUID: 6E400001-B5A3-F393-E0A9-E50E24DCCA9E
// TX特征值: 6E400002-B5A3-F393-E0A9-E50E24DCCA9E
```

### 2. 接收数据处理
```c
void ble_data_received(uint8_t* data, uint16_t length) {
    ParsedPacket packet;
    
    if (parse_packet(data, length, &packet)) {
        switch (packet.type) {
            case MSG_TIME_SYNC:
                // 更新RTC时钟
                rtc_set_time(packet.timestamp);
                printf("时间同步: %u\n", packet.timestamp);
                break;
                
            case MSG_TEXT:
                // 显示消息
                printf("收到消息: %s\n", packet.text);
                display_message(packet.text, packet.timestamp);
                break;
                
            default:
                printf("未知消息类型: 0x%02X\n", packet.type);
                break;
        }
    } else {
        printf("无效数据包\n");
    }
}
```

### 3. 主循环示例
```c
void main_loop(void) {
    while (1) {
        // 等待蓝牙数据
        if (ble_has_data()) {
            uint8_t buffer[512];
            uint16_t length = ble_read_data(buffer, sizeof(buffer));
            
            if (length > 0) {
                ble_data_received(buffer, length);
            }
        }
        
        // 其他任务...
        delay_ms(10);
    }
}
```

## ⚠️ 重要注意事项

### 1. 时间戳处理
- 时间戳是Unix时间戳（1970年以来的秒数）
- 需要转换为本地时间显示
- 连接成功时会收到时间同步消息

### 2. 文本消息格式
- 消息格式：`发送者: 消息内容`
- 示例：`张三: 你好，设备测试`
- 系统消息和用户消息统一格式

### 3. 安全截断
- 手机端已实现安全UTF-8截断
- 设备端仍需容错解码（使用`decode_utf8_safe`）
- 遇到无效UTF-8序列用'?'替换

## 🔍 调试技巧

### 1. 打印接收的原始数据
```c
printf("原始数据(%d字节): ", length);
for (int i = 0; i < length && i < 16; i++) {
    printf("%02X ", data[i]);
}
printf("\n");
```

### 2. 验证数据包
```c
// 检查点
1. 长度 >= 9字节
2. 第一个字节 == 0xB0
3. 数据长度 <= 240字节
4. 校验和正确
5. 消息类型已知(0x01-0x03)
```

### 3. 测试数据
```c
// 测试包：时间同步
uint8_t test_time_sync[] = {
    0xB0,             // 协议头
    0x00, 0x00, 0x00, 0x00,  // 时间戳
    0x01,             // 时间同步
    0x00, 0x00,       // 数据长度0
    0xB1              // 校验和(示例)
};

// 测试包：文本消息 "Test"
uint8_t test_text[] = {
    0xB0,             // 协议头
    0x00, 0x00, 0x00, 0x00,  // 时间戳
    0x02,             // 文本消息
    0x04, 0x00,       // 数据长度4
    0x54, 0x65, 0x73, 0x74,  // "Test"
    0x??              // 需要计算校验和
};
```

## 📞 故障排除

| 症状 | 可能原因 | 解决方案 |
|------|----------|----------|
| 收不到数据 | 服务UUID不匹配 | 确认NUS服务UUID正确 |
| 解析失败 | 协议头错误 | 检查第一个字节是否为0xB0 |
| 中文乱码 | UTF-8解码问题 | 使用安全解码函数 |
| 校验和错误 | 数据传输错误 | 检查蓝牙信号质量 |
| 时间戳错误 | 字节序问题 | 确认使用小端序解析 |

## 📋 版本兼容性

| 手机App版本 | 协议版本 | 特性 |
|-------------|----------|------|
| ≥ 1.0 | 1.0 | 基础协议 |
| ≥ 1.1 | 1.1 | 添加校验和 |
| ≥ 1.2 | 1.2 | 安全UTF-8截断 |

## 🎪 示例场景

### 场景1：设备启动并连接
```
1. 设备启动，初始化蓝牙
2. 广播NUS服务
3. 手机连接设备
4. 收到时间同步消息(0x01)
5. 更新RTC时钟
6. 准备接收消息
```

### 场景2：收到新消息
```
1. 手机收到IM消息
2. 创建文本数据包(0x02)
3. 通过蓝牙发送
4. 设备解析并显示
5. (可选)更新时间戳
```

### 场景3：连接断开重连
```
1. 蓝牙连接断开
2. 手机尝试自动重连(最多3次)
3. 连接成功后发送时间同步
4. 恢复消息转发
```

---
**文档版本**: 1.0  
**最后更新**: 2024年2月28日  
**参考完整文档**: `BLUETOOTH_PROTOCOL_EMBEDDED_GUIDE.md`
