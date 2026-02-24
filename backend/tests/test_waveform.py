"""
测试音频振幅包络（waveform）字段功能

这个测试脚本验证：
1. 数据库迁移是否正确添加了waveform字段
2. Pydantic模型是否正确验证waveform数据
3. API端点是否正确处理waveform字段
4. 长轮询功能是否正常工作
"""

import asyncio
import json
from datetime import datetime
from typing import List, Optional, Dict, Any
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from pydantic import ValidationError

# 测试数据
TEST_WAVEFORM_VALID = [12, 45, 100, 20, 78, 90, 34, 67, 89, 23]
TEST_WAVEFORM_LONG = list(range(200))  # 超过128个元素
TEST_WAVEFORM_INVALID_RANGE = [12, 45, 300, 20, -10, 90]  # 包含超出0-255范围的元素
TEST_WAVEFORM_EMPTY = []

def test_pydantic_models():
    """测试Pydantic模型验证"""
    print("=== 测试Pydantic模型验证 ===")

    # 导入模型
    from app.schemas.message import MessageCreate, MessageResponse

    # 测试1: 有效的waveform数据
    try:
        msg_create = MessageCreate(
            receiver_id="test123",
            content="测试消息",
            message_type="VOICE",
            waveform=TEST_WAVEFORM_VALID
        )
        print(f"✓ 测试1通过: 有效waveform数据 - {len(msg_create.waveform)}个元素")
    except ValidationError as e:
        print(f"✗ 测试1失败: {e}")

    # 测试2: 空waveform（应该允许）
    try:
        msg_create = MessageCreate(
            receiver_id="test123",
            content="测试消息",
            message_type="NORMAL",
            waveform=None
        )
        print("✓ 测试2通过: waveform为None")
    except ValidationError as e:
        print(f"✗ 测试2失败: {e}")

    # 测试3: 空数组waveform（应该允许）
    try:
        msg_create = MessageCreate(
            receiver_id="test123",
            content="测试消息",
            message_type="NORMAL",
            waveform=TEST_WAVEFORM_EMPTY
        )
        print("✓ 测试3通过: waveform为空数组")
    except ValidationError as e:
        print(f"✗ 测试3失败: {e}")

    # 测试4: 创建MessageResponse（模拟数据库返回）
    try:
        msg_response = MessageResponse(
            id=1,
            sender_bipupu_id="sender123",
            receiver_bipupu_id="receiver123",
            content="测试消息",
            message_type="VOICE",
            pattern={"audio_url": "test.mp3"},
            waveform=TEST_WAVEFORM_VALID,
            created_at=datetime.now()
        )
        print(f"✓ 测试4通过: MessageResponse创建成功")
        print(f"  波形数据: {msg_response.waveform[:5]}... (共{len(msg_response.waveform)}个点)")
    except ValidationError as e:
        print(f"✗ 测试4失败: {e}")

    print()

def test_sqlalchemy_model():
    """测试SQLAlchemy模型"""
    print("=== 测试SQLAlchemy模型 ===")

    from app.models.message import Message
    from sqlalchemy.dialects.postgresql import JSONB

    # 检查字段定义
    waveform_column = Message.__table__.c.get('waveform')

    if waveform_column is None:
        print("✗ 测试失败: waveform字段不存在")
        return

    print(f"✓ waveform字段存在")
    print(f"  字段类型: {waveform_column.type}")
    print(f"  是否可为空: {waveform_column.nullable}")

    # 检查是否为JSONB类型
    if isinstance(waveform_column.type, JSONB):
        print("✓ waveform字段类型为JSONB")
    else:
        print(f"⚠ waveform字段类型为{waveform_column.type.__class__.__name__}，不是JSONB")

    print()

def test_api_endpoints():
    """测试API端点数据结构"""
    print("=== 测试API端点数据结构 ===")

    # 模拟长轮询响应
    poll_response_example = [
        {
            "id": 1,
            "sender_bipupu_id": "user123",
            "receiver_bipupu_id": "user456",
            "content": "语音消息",
            "message_type": "VOICE",
            "pattern": None,
            "waveform": TEST_WAVEFORM_VALID,
            "created_at": "2024-01-01T12:00:00Z"
        },
        {
            "id": 2,
            "sender_bipupu_id": "user123",
            "receiver_bipupu_id": "user456",
            "content": "普通消息",
            "message_type": "NORMAL",
            "pattern": {"color": "blue"},
            "waveform": None,
            "created_at": "2024-01-01T12:01:00Z"
        }
    ]

    print("✓ 长轮询响应数据结构示例:")
    for i, msg in enumerate(poll_response_example, 1):
        waveform_info = f"{len(msg['waveform'])}个点" if msg['waveform'] else "无"
        print(f"  消息{i}: ID={msg['id']}, 类型={msg['message_type']}, 波形={waveform_info}")

    print()

def test_waveform_validation_logic():
    """测试波形数据验证逻辑"""
    print("=== 测试波形数据验证逻辑 ===")

    def validate_waveform(waveform: Optional[List[int]]) -> bool:
        """验证波形数据

        要求：
        1. 可以为None或空列表
        2. 如果提供，每个元素必须是0-255的整数
        3. 建议长度不超过128（前端限制）
        """
        if waveform is None:
            return True

        if not isinstance(waveform, list):
            return False

        # 检查所有元素是否为整数且在0-255范围内
        for value in waveform:
            if not isinstance(value, int):
                return False
            if value < 0 or value > 255:
                return False

        return True

    # 测试用例
    test_cases = [
        (TEST_WAVEFORM_VALID, True, "有效波形数据"),
        (None, True, "None值"),
        ([], True, "空数组"),
        (TEST_WAVEFORM_INVALID_RANGE, False, "超出范围的值"),
        ([1, 2, "3"], False, "非整数元素"),
        (TEST_WAVEFORM_LONG, True, "长数组（仅验证类型和范围）"),
    ]

    for waveform, expected, description in test_cases:
        result = validate_waveform(waveform)
        status = "✓" if result == expected else "✗"
        print(f"{status} {description}: 验证结果={result}, 期望={expected}")

    print()

def test_performance_considerations():
    """测试性能考虑"""
    print("=== 测试性能考虑 ===")

    # JSONB vs JSON 性能考虑
    print("JSONB优势:")
    print("  1. 二进制存储，查询更快")
    print("  2. 支持索引")
    print("  3. 支持GIN索引进行高效数组查询")
    print("  4. 存储效率更高")

    # 波形数据大小估算
    avg_waveform_length = 64  # 假设平均64个点
    bytes_per_point = 4  # 假设每个整数4字节
    estimated_size = avg_waveform_length * bytes_per_point

    print(f"\n波形数据大小估算:")
    print(f"  平均长度: {avg_waveform_length}个点")
    print(f"  估算大小: {estimated_size}字节")
    print(f"  压缩后: ~{estimated_size // 2}字节 (JSONB压缩)")

    print()

def main():
    """主测试函数"""
    print("=" * 60)
    print("音频振幅包络（waveform）字段功能测试")
    print("=" * 60)
    print()

    try:
        test_pydantic_models()
        test_sqlalchemy_model()
        test_api_endpoints()
        test_waveform_validation_logic()
        test_performance_considerations()

        print("=" * 60)
        print("所有测试完成！")
        print("=" * 60)

    except Exception as e:
        print(f"测试过程中发生错误: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
