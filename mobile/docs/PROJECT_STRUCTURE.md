# Bipupu 蓝牙协议 - 嵌入式项目结构

## 项目概述

本项目为嵌入式设备实现 Bipupu 蓝牙协议，支持与手机应用进行一对一蓝牙通信，实现文本消息转发和时间同步功能。

## 完整项目结构

```
bipupu-embedded-device/
├── 📁 docs/                          # 文档
│   ├── BLUETOOTH_PROTOCOL_EMBEDDED_GUIDE.md    # 完整协议指南
│   ├── BLUETOOTH_PROTOCOL_QUICK_REFERENCE.md   # 快速参考
│   ├── bluetooth_protocol_example.c            # C语言示例代码
│   ├── Makefile.example                        # Makefile示例
│   └── PROJECT_STRUCTURE.md                    # 本文档
│
├── 📁 inc/                          # 头文件
│   ├── bluetooth/
│   │   ├── protocol.h              # 协议定义
│   │   ├── utf8.h                  # UTF-8处理
│   │   └── ble_service.h           # 蓝牙服务
│   ├── drivers/
│   │   ├── uart.h                  # 串口驱动
│   │   ├── spi.h                   # SPI驱动
│   │   ├── i2c.h                   # I2C驱动
│   │   ├── rtc.h                   # RTC驱动
│   │   └── display.h               # 显示驱动
│   └── system/
│       ├── config.h                # 系统配置
│       ├── types.h                 # 类型定义
│       └── utils.h                 # 工具函数
│
├── 📁 src/                          # 源文件
│   ├── main.c                      # 主程序
│   ├── system.c                    # 系统初始化
│   ├── tasks.c                     # 任务调度
│   ├── 📁 bluetooth/               # 蓝牙协议实现
│   │   ├── protocol.c              # 协议解析
│   │   ├── utf8.c                  # UTF-8解码
│   │   └── ble_service.c           # 蓝牙服务
│   ├── 📁 drivers/                 # 驱动程序
│   │   ├── uart.c                  # 串口通信
│   │   ├── spi.c                   # SPI通信
│   │   ├── i2c.c                   # I2C通信
│   │   ├── rtc.c                   # 实时时钟
│   │   └── display.c               # 显示控制
│   └── 📁 app/                     # 应用层
│       ├── message_handler.c       # 消息处理
│       ├── time_manager.c          # 时间管理
│       └── ui_controller.c         # 界面控制
│
├── 📁 tests/                        # 测试文件
│   ├── test_protocol.c             # 协议测试
│   ├── test_utf8.c                 # UTF-8测试
│   ├── test_integration.c          # 集成测试
│   └── test_data.h                 # 测试数据
│
├── 📁 scripts/                      # 脚本工具
│   ├── build.sh                    # 构建脚本
│   ├── flash.sh                    # 烧录脚本
│   └── test.sh                     # 测试脚本
│
├── 📁 config/                       # 配置文件
│   ├── linker.ld                   # 链接脚本
│   ├── memory.map                  # 内存映射
│   └── board_config.h              # 板级配置
│
├── 📁 third_party/                  # 第三方库
│   └── README.md                   # 第三方库说明
│
├── Makefile                        # 主构建文件
├── README.md                       # 项目说明
├── LICENSE                         # 许可证
└── .gitignore                      # Git忽略文件
```

## 核心文件说明

### 1. 蓝牙协议核心文件

#### `inc/bluetooth/protocol.h`
```c
// 协议常量定义
#define PROTOCOL_HEADER 0xB0
#define MAX_DATA_LENGTH 240

// 消息类型枚举
typedef enum {
    MSG_TIME_SYNC = 0x01,
    MSG_TEXT = 0x02,
    MSG_ACK = 0x03
} MessageType;

// 数据结构定义
typedef struct {
    uint32_t timestamp;
    MessageType type;
    uint16_t data_length;
    uint8_t data[MAX_DATA_LENGTH];
    char text[MAX_DATA_LENGTH + 1];
    bool checksum_valid;
} ParsedPacket;

// 函数声明
bool parse_bluetooth_packet(const uint8_t* data, size_t length, ParsedPacket* result);
uint8_t calculate_checksum(const uint8_t* data, size_t length);
```

#### `src/bluetooth/protocol.c`
- 协议解析实现
- 校验和计算
- 数据验证逻辑

#### `src/bluetooth/utf8.c`
- 安全的UTF-8解码
- 容错处理机制
- 字符边界检查

#### `src/bluetooth/ble_service.c`
- Nordic UART Service实现
- 蓝牙连接管理
- 数据收发处理

### 2. 驱动程序文件

#### `src/drivers/rtc.c`
- 实时时钟驱动
- 时间戳转换
- 时间同步处理

#### `src/drivers/display.c`
- 显示驱动
- 消息显示逻辑
- 界面更新

### 3. 应用层文件

#### `src/app/message_handler.c`
```c
// 消息处理回调
void handle_text_message(const char* text, uint32_t timestamp) {
    // 1. 存储消息到Flash
    // 2. 更新显示
    // 3. 可选：发送确认响应
}

// 时间同步处理
void handle_time_sync(uint32_t timestamp) {
    // 1. 转换为本地时间
    // 2. 更新RTC时钟
    // 3. 记录同步时间
}
```

#### `src/app/time_manager.c`
- 时间管理
- 定时任务
- 超时处理

### 4. 主程序文件

#### `src/main.c`
```c
int main(void) {
    // 1. 系统初始化
    system_init();
    
    // 2. 外设初始化
    uart_init();
    rtc_init();
    display_init();
    ble_init();
    
    // 3. 启动蓝牙服务
    ble_start_advertising();
    
    // 4. 主循环
    while (1) {
        // 处理蓝牙数据
        ble_process_events();
        
        // 处理显示更新
        display_update();
        
        // 低功耗处理
        system_enter_low_power();
    }
    
    return 0;
}
```

## 构建系统

### Makefile 主要目标

```makefile
# 主要构建目标
all: firmware.bin firmware.hex

# 编译
firmware.elf: $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(OBJS)

# 生成二进制文件
firmware.bin: firmware.elf
	$(OBJCOPY) -O binary $< $@

# 测试
test: test_protocol test_utf8 test_integration

# 清理
clean:
	rm -rf build/*.o build/*.elf build/*.bin build/*.hex
```

### 构建步骤

```bash
# 1. 克隆项目
git clone https://github.com/your-org/bipupu-embedded.git
cd bipupu-embedded

# 2. 配置编译环境
# 安装ARM GCC工具链
# 配置板级支持包

# 3. 构建项目
make all

# 4. 运行测试
make test

# 5. 烧录固件
make flash
```

## 开发流程

### 1. 环境搭建
- 安装ARM GCC工具链
- 配置OpenOCD或J-Link
- 设置串口调试工具

### 2. 代码开发
```bash
# 创建新功能分支
git checkout -b feature/new-display

# 编写代码
# 实现显示驱动和消息显示逻辑

# 运行测试
make test

# 提交代码
git add .
git commit -m "添加消息显示功能"
```

### 3. 测试验证
```bash
# 单元测试
make test_unit

# 集成测试
make test_integration

# 硬件测试
make flash && monitor_serial
```

### 4. 代码审查
- 静态代码分析：`make analyze`
- 代码格式化：`make format`
- 内存检查：`make size`

## 配置说明

### 内存配置 (`config/memory.map`)
```
Memory Layout:
  FLASH: 0x08000000 - 0x0803FFFF (256KB)
    .text:    代码段
    .rodata:  只读数据
    .data:    初始化数据
  
  RAM: 0x20000000 - 0x2000BFFF (48KB)
    .data:    数据段
    .bss:     未初始化数据
    .stack:   栈空间
    .heap:    堆空间
```

### 板级配置 (`config/board_config.h`)
```c
// 硬件引脚定义
#define LED_PIN          GPIO_PIN_13
#define BUTTON_PIN       GPIO_PIN_0
#define DISPLAY_CS_PIN   GPIO_PIN_4
#define DISPLAY_DC_PIN   GPIO_PIN_5
#define DISPLAY_RST_PIN  GPIO_PIN_6

// 系统时钟
#define SYSTEM_CLOCK     16000000  // 16MHz
#define RTC_CLOCK        32768     // 32.768kHz

// 蓝牙配置
#define BLE_DEVICE_NAME  "Bipupu-Device"
#define BLE_TX_POWER     4         // +4dBm
#define BLE_CONN_INTERVAL 30       // 30ms
```

## 测试策略

### 1. 单元测试
```c
// tests/test_protocol.c
void test_parse_valid_packet(void) {
    uint8_t test_data[] = {0xB0, 0x00, 0x00, 0x00, 0x00, 0x02, 0x04, 0x00, 
                           'T', 'e', 's', 't', 0xXX}; // 校验和
    ParsedPacket packet;
    
    assert(parse_bluetooth_packet(test_data, sizeof(test_data), &packet));
    assert(packet.checksum_valid);
    assert(strcmp(packet.text, "Test") == 0);
}
```

### 2. 集成测试
- 蓝牙连接测试
- 消息转发测试
- 时间同步测试
- 功耗测试

### 3. 硬件测试
- 信号质量测试
- 传输距离测试
- 抗干扰测试
- 长时间稳定性测试

## 部署流程

### 1. 生产构建
```bash
# 发布版本构建
make RELEASE=1 all

# 生成发布包
make dist

# 输出文件:
# - firmware.bin: 二进制文件
# - firmware.hex: HEX文件
# - checksum.txt: 文件校验和
# - version.txt: 版本信息
```

### 2. 固件升级
```c
// 支持OTA升级
bool firmware_update(const uint8_t* data, size_t length) {
    // 1. 验证固件头
    // 2. 检查CRC
    // 3. 写入Flash
    // 4. 重启设备
}
```

### 3. 现场部署
1. 烧录初始固件
2. 配置设备参数
3. 进行功能测试
4. 记录设备信息

## 维护指南

### 1. 问题排查
```bash
# 查看日志
tail -f /dev/ttyUSB0

# 内存使用分析
make size

# 性能分析
make profile
```

### 2. 版本管理
```
版本号格式: v主版本.次版本.修订版本
示例: v1.2.3

版本记录:
- v1.0.0: 初始版本，基础功能
- v1.1.0: 添加校验和
- v1.2.0: 添加安全UTF-8截断
```

### 3. 文档更新
- API变更时更新头文件注释
- 添加新功能时更新使用示例
- 修复问题时更新故障排除指南

## 贡献指南

### 1. 代码规范
- 使用4空格缩进
- 函数命名：`lowercase_with_underscores`
- 变量命名：有意义的英文名称
- 添加必要的注释

### 2. 提交规范
```
类型(范围): 描述

详细说明（可选）

关联问题: #123
```

类型包括：
- feat: 新功能
- fix: 修复问题
- docs: 文档更新
- test: 测试相关
- refactor: 重构代码

### 3. 审查流程
1. 创建Pull Request
2. 通过CI测试
3. 代码审查
4. 合并到主分支

## 许可证

本项目采用 MIT 许可证。详见 LICENSE 文件。

## 支持与联系

- 问题反馈: GitHub Issues
- 文档更新: Pull Requests
- 技术讨论: Discord/Slack频道
- 紧急支持: support@example.com

---

**最后更新**: 2024年2月28日  
**协议版本**: 1.2  
**硬件平台**: ARM Cortex-M系列  
**编译器**: ARM GCC 10.3+