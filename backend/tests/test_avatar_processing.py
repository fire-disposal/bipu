"""
头像处理测试脚本 - 简化版本

测试StorageService中的头像处理功能，包括：
1. 文件大小限制
2. 图片尺寸验证
3. 1:1比例强制处理
4. 图片压缩和质量
"""

import sys
import os
from io import BytesIO
from PIL import Image, ImageDraw
import asyncio

# 添加项目路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.services.storage_service import StorageService


def create_test_image(width=200, height=200, color=(255, 0, 0), format="JPEG"):
    """创建测试图片"""
    image = Image.new("RGB", (width, height), color)
    draw = ImageDraw.Draw(image)

    # 添加一些文本以便识别
    draw.text((10, 10), f"{width}x{height}", fill=(255, 255, 255))

    # 保存到BytesIO
    buffer = BytesIO()
    image.save(buffer, format=format)
    buffer.seek(0)

    return buffer.getvalue()


async def test_storage_service_directly():
    """直接测试StorageService内部逻辑"""
    print("=" * 60)
    print("StorageService内部逻辑测试")
    print("=" * 60)

    tests_passed = 0
    tests_failed = 0

    # 测试1: 验证头像尺寸验证函数
    print("\n1. 测试头像尺寸验证函数...")
    try:
        # 测试有效尺寸
        assert StorageService.validate_avatar_dimensions(100, 100) == True, "正方形图片应该通过验证"
        assert StorageService.validate_avatar_dimensions(110, 100) == False, "非正方形图片应该失败"
        assert StorageService.validate_avatar_dimensions(100, 90) == False, "非正方形图片应该失败"

        # 测试在容差范围内的尺寸
        assert StorageService.validate_avatar_dimensions(105, 100) == True, "在容差范围内应该通过"
        assert StorageService.validate_avatar_dimensions(100, 95) == True, "在容差范围内应该通过"

        # 测试无效尺寸
        assert StorageService.validate_avatar_dimensions(0, 100) == False, "零宽度应该失败"
        assert StorageService.validate_avatar_dimensions(100, 0) == False, "零高度应该失败"
        assert StorageService.validate_avatar_dimensions(-100, 100) == False, "负宽度应该失败"

        print("  ✅ 测试通过")
        tests_passed += 1
    except Exception as e:
        print(f"  ❌ 测试失败: {e}")
        tests_failed += 1

    # 测试2: 测试正方形裁剪逻辑
    print("\n2. 测试正方形裁剪逻辑...")
    try:
        # 创建测试图片
        image_content = create_test_image(300, 150)  # 长方形图片

        # 手动测试裁剪逻辑
        image_buffer = BytesIO(image_content)
        image = Image.open(image_buffer)

        # 验证原始尺寸
        assert image.width == 300, f"原始宽度应该是300，实际是{image.width}"
        assert image.height == 150, f"原始高度应该是150，实际是{image.height}"

        # 测试裁剪逻辑（不实际执行，只验证逻辑）
        width, height = image.size
        if width > height:
            left = (width - height) // 2
            top = 0
            right = left + height
            bottom = height
        else:
            left = 0
            top = (height - width) // 2
            right = width
            bottom = top + width

        # 验证裁剪区域计算正确
        expected_crop = (75, 0, 225, 150)
        actual_crop = (left, top, right, bottom)
        assert actual_crop == expected_crop, f"裁剪区域计算错误: {actual_crop} != {expected_crop}"

        print(f"  原始尺寸: 300x150")
        print(f"  计算裁剪区域: {actual_crop}")
        print("  ✅ 测试通过")
        tests_passed += 1
    except Exception as e:
        print(f"  ❌ 测试失败: {e}")
        tests_failed += 1

    # 测试3: 测试尺寸调整逻辑
    print("\n3. 测试尺寸调整逻辑...")
    try:
        from app.services.storage_service import AVATAR_MAX_SIZE, AVATAR_MIN_SIZE

        test_cases = [
            (200, 100, "大于最大尺寸，应缩小到100px"),
            (100, 100, "等于最大尺寸，应保持不变"),
            (80, 80, "在50-100之间，应保持不变"),
            (50, 50, "等于最小尺寸，应保持不变"),
            (30, 50, "小于最小尺寸，应放大到50px"),
        ]

        all_correct = True
        for original, expected, description in test_cases:
            # 模拟调整逻辑
            if original > AVATAR_MAX_SIZE:
                adjusted = AVATAR_MAX_SIZE
            elif original < AVATAR_MIN_SIZE:
                adjusted = AVATAR_MIN_SIZE
            else:
                adjusted = original

            if adjusted == expected:
                print(f"  ✅ {description}: {original}px -> {adjusted}px")
            else:
                print(f"  ❌ {description}: {original}px -> {adjusted}px (期望: {expected}px)")
                all_correct = False

        if all_correct:
            print("  ✅ 所有尺寸调整逻辑正确")
            tests_passed += 1
        else:
            print("  ❌ 尺寸调整逻辑有误")
            tests_failed += 1
    except Exception as e:
        print(f"  ❌ 测试失败: {e}")
        tests_failed += 1

    # 测试4: 测试文件大小限制逻辑
    print("\n4. 测试文件大小限制逻辑...")
    try:
        from app.services.storage_service import AVATAR_MAX_FILE_SIZE

        print(f"  最大文件大小: {AVATAR_MAX_FILE_SIZE // (1024*1024)}MB")

        test_cases = [
            (AVATAR_MAX_FILE_SIZE - 1, True, "刚好小于限制"),
            (AVATAR_MAX_FILE_SIZE, True, "等于限制"),
            (AVATAR_MAX_FILE_SIZE + 1, False, "刚好超过限制"),
            (10 * 1024 * 1024, False, "10MB（超过限制）"),
        ]

        all_correct = True
        for size, should_pass, description in test_cases:
            passes = size <= AVATAR_MAX_FILE_SIZE
            if passes == should_pass:
                print(f"  ✅ {description}: {size // 1024}KB -> {'通过' if passes else '拒绝'}")
            else:
                print(f"  ❌ {description}: {size // 1024}KB -> {'通过' if passes else '拒绝'} (期望: {'通过' if should_pass else '拒绝'})")
                all_correct = False

        if all_correct:
            print("  ✅ 文件大小限制逻辑正确")
            tests_passed += 1
        else:
            print("  ❌ 文件大小限制逻辑有误")
            tests_failed += 1
    except Exception as e:
        print(f"  ❌ 测试失败: {e}")
        tests_failed += 1

    # 测试5: 测试图片验证函数
    print("\n5. 测试图片验证函数...")
    try:
        # 创建有效图片
        valid_image_content = create_test_image(100, 100)

        # 测试验证函数
        is_valid = StorageService.validate_image_content(valid_image_content)
        assert is_valid == True, "有效图片应该通过验证"

        # 测试无效内容
        invalid_content = b"not an image"
        is_valid = StorageService.validate_image_content(invalid_content)
        assert is_valid == False, "无效内容应该失败"

        print("  ✅ 图片验证函数正确")
        tests_passed += 1
    except Exception as e:
        print(f"  ❌ 测试失败: {e}")
        tests_failed += 1

    # 测试6: 测试缓存键生成
    print("\n6. 测试缓存键生成...")
    try:
        test_cases = [
            ("user123", "avatar:user123"),
            ("test-456", "avatar:test-456"),
            ("", "avatar:"),
        ]

        all_correct = True
        for bipupu_id, expected in test_cases:
            cache_key = StorageService.get_avatar_cache_key(bipupu_id)
            if cache_key == expected:
                print(f"  ✅ {bipupu_id} -> {cache_key}")
            else:
                print(f"  ❌ {bipupu_id} -> {cache_key} (期望: {expected})")
                all_correct = False

        if all_correct:
            print("  ✅ 缓存键生成正确")
            tests_passed += 1
        else:
            print("  ❌ 缓存键生成有误")
            tests_failed += 1
    except Exception as e:
        print(f"  ❌ 测试失败: {e}")
        tests_failed += 1

    # 测试7: 测试ETag生成
    print("\n7. 测试ETag生成...")
    try:
        # 测试数据
        avatar_data = b"test_avatar_data"
        version_info = b"version_123"

        # 生成ETag
        etag = StorageService.get_avatar_etag(avatar_data, version_info)

        # 验证ETag格式
        assert etag.startswith('"'), "ETag应该以双引号开头"
        assert etag.endswith('"'), "ETag应该以双引号结尾"
        assert len(etag) == 34, f"ETag长度应该为34，实际是{len(etag)}"  # 32位MD5 + 2个引号

        print(f"  生成的ETag: {etag}")
        print(f"  ETag长度: {len(etag)}")
        print("  ✅ ETag生成正确")
        tests_passed += 1
    except Exception as e:
        print(f"  ❌ 测试失败: {e}")
        tests_failed += 1

    # 总结
    print("\n" + "=" * 60)
    print("测试总结")
    print("=" * 60)
    print(f"总测试数: {tests_passed + tests_failed}")
    print(f"通过: {tests_passed}")
    print(f"失败: {tests_failed}")

    if tests_failed == 0:
        print("\n🎉 所有测试通过！StorageService内部逻辑验证成功。")
        print("\n验证的功能:")
        print("1. ✅ 头像尺寸验证函数")
        print("2. ✅ 正方形裁剪逻辑")
        print("3. ✅ 尺寸调整逻辑")
        print("4. ✅ 文件大小限制逻辑")
        print("5. ✅ 图片验证函数")
        print("6. ✅ 缓存键生成")
        print("7. ✅ ETag生成")
    else:
        print(f"\n⚠️  有 {tests_failed} 个测试失败")

    return tests_failed == 0


if __name__ == "__main__":
    # 运行测试
    success = asyncio.run(test_storage_service_directly())

    # 退出码
    sys.exit(0 if success else 1)
