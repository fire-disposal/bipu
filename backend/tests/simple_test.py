"""
简单的波形字段测试
这个测试不依赖项目结构，直接验证概念
"""

import json
from datetime import datetime
from typing import List, Optional

def test_waveform_concepts():
    """测试波形数据概念"""
    print("=" * 60)
    print("音频振幅包络（waveform）字段概念验证")
    print("=" * 60)
    print()

    # 1. 测试数据示例
    print("1. 波形数据示例:")
    waveform_examples = {
        "short_voice": [12, 45, 100, 20, 78, 90, 34, 67],
        "long_voice": list(range(0, 256, 4)),  # 64个点，0-255范围
        "silence": [0] * 32,  # 静音
        "peak": [10, 30, 100, 255, 100, 30, 10],  # 峰值
        "none": None,
        "empty": []
    }

    for name, data in waveform_examples.items():
        if data is None:
            print(f"  {name}: None")
        elif isinstance(data, list):
            if len(data) == 0:
                print(f"  {name}: 空数组 []")
            else:
                sample = data[:3] if len(data) > 3 else data
                print(f"  {name}: {sample}... (共{len(data)}个点)")

    print()

    # 2. JSON序列化测试
    print("2. JSON序列化测试:")
    test_message = {
        "id": 1,
        "sender_bipupu_id": "user123",
        "receiver_bipupu_id": "user456",
        "content": "语音消息测试",
        "message_type": "VOICE",
        "pattern": {"audio_url": "audio/test.mp3", "duration": 5.2},
        "waveform": waveform_examples["short_voice"],
        "created_at": datetime.now().isoformat()
    }

    json_str = json.dumps(test_message, ensure_ascii=False, indent=2)
    print("  消息JSON示例:")
    print(json_str[:200] + "..." if len(json_str) > 200 else json_str)
    print()

    # 3. 数据验证逻辑
    print("3. 数据验证逻辑:")

    def validate_waveform(waveform: Optional[List[int]]) -> tuple[bool, str]:
        """验证波形数据"""
        if waveform is None:
            return True, "有效: None值"

        if not isinstance(waveform, list):
            return False, "无效: 不是列表"

        # 检查元素类型和范围
        for i, value in enumerate(waveform):
            if not isinstance(value, int):
                return False, f"无效: 位置{i}的值{value}不是整数"
            if value < 0 or value > 255:
                return False, f"无效: 位置{i}的值{value}超出0-255范围"

        # 长度建议（非强制）
        if len(waveform) > 128:
            return True, f"有效但较长: {len(waveform)}个点（建议不超过128）"

        return True, f"有效: {len(waveform)}个点"

    # 测试验证函数
    test_cases = [
        ([12, 45, 100, 20], "正常数据"),
        ([0, 128, 255], "边界值"),
        ([10, 20, 300], "超出范围"),
        ([1, 2, "3"], "非整数"),
        (None, "None值"),
        ([], "空数组"),
        (list(range(200)), "长数组"),
    ]

    for data, description in test_cases:
        try:
            valid, message = validate_waveform(data)
            status = "✓" if valid else "✗"
            print(f"  {status} {description}: {message}")
        except Exception as e:
            print(f"  ✗ {description}: 验证错误 - {e}")

    print()

    # 4. 数据库存储考虑
    print("4. 数据库存储考虑:")
    print("  - 字段类型: JSONB (PostgreSQL)")
    print("  - 可为空: 是 (nullable=True)")
    print("  - 索引: 可添加GIN索引用于高效查询")
    print("  - 存储格式: 二进制JSON，支持压缩")

    # 5. API接口设计
    print()
    print("5. API接口设计:")
    print("  - 创建消息: POST /api/messages/")
    print("  - 字段: waveform (可选)")
    print("  - 类型: List[int]")
    print("  - 验证: 0-255整数")
    print("  - 长轮询: GET /api/messages/poll?last_msg_id=0")
    print("  - 返回: 包含waveform字段的消息列表")

    # 6. 前端使用示例
    print()
    print("6. 前端使用示例:")
    print("  ```javascript")
    print("  // 发送带波形数据的消息")
    print("  const message = {")
    print("    receiver_id: 'user456',")
    print("    content: '语音消息',")
    print("    message_type: 'VOICE',")
    print("    waveform: [12, 45, 100, 20, 78, 90, 34, 67]")
    print("  };")
    print("  ")
    print("  // 长轮询获取新消息")
    print("  async function pollMessages(lastId) {")
    print("    const response = await fetch(`/api/messages/poll?last_msg_id=${lastId}`);")
    print("    const messages = await response.json();")
    print("    messages.forEach(msg => {")
    print("      if (msg.waveform) {")
    print("        visualizeWaveform(msg.waveform);")
    print("      }")
    print("    });")
    print("    return messages;")
    print("  }")
    print("  ```")

    print()
    print("=" * 60)
    print("测试完成！")
    print("=" * 60)

if __name__ == "__main__":
    test_waveform_concepts()
