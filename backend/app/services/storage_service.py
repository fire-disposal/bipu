"""图片存储服务 - 简化版本，专注数据库存储"""
import os
from PIL import Image, ImageFile
from fastapi import UploadFile
from io import BytesIO
from typing import Optional
from app.core.logging import get_logger

# 配置PIL以处理大图片
ImageFile.LOAD_TRUNCATED_IMAGES = True  # type: ignore
Image.MAX_IMAGE_PIXELS = 100000000  # 限制最大像素数，防止内存溢出

logger = get_logger(__name__)


class StorageService:
    """图片存储服务类 - 简化版本，专注数据库存储"""

    @staticmethod
    async def save_avatar(file: UploadFile) -> bytes:
        """保存用户头像到数据库并进行压缩，返回二进制数据

        流程：
        1. 读取文件内容到内存
        2. 验证图片格式和安全性
        3. 压缩图片到100x100像素
        4. 转换为JPEG格式，质量70%
        5. 返回压缩后的二进制数据
        """
        # 读取文件内容到内存
        content = await file.read()

        # 直接从内存数据解码图片，避免文件系统操作
        image_buffer = BytesIO(content)

        try:
            # 直接从内存缓冲区打开图片
            image = Image.open(image_buffer)

            # 验证图片完整性
            image.verify()

            # 重新打开图片（verify()会关闭图片）
            image_buffer.seek(0)
            image = Image.open(image_buffer)

            # 转换为RGB以保存为JPEG
            if image.mode in ("RGBA", "P", "LA"):
                image = image.convert("RGB")

            # 设置最大尺寸 - 根据MVP需求调整为100x100
            max_size = (100, 100)
            image.thumbnail(max_size, Image.Resampling.LANCZOS)

            # 限制最大像素数量，防止超大图片
            MAX_PIXELS = 100 * 100  # 10,000像素
            if image.width * image.height > MAX_PIXELS:
                # 如果图片仍然太大，进一步缩小
                image.thumbnail((50, 50), Image.Resampling.LANCZOS)

            # 保存到内存中的BytesIO，质量设置为70%符合MVP需求
            output = BytesIO()
            image.save(output, "JPEG", quality=70, optimize=True)
            compressed_data = output.getvalue()

            logger.debug(f"头像压缩完成: 原始大小={len(content)}bytes, 压缩后={len(compressed_data)}bytes")
            return compressed_data

        except Exception as e:
            # 图片解码失败，抛出更详细的错误信息
            logger.error(f"头像图片处理失败: {str(e)}")
            raise ValueError(f"头像图片处理失败: {str(e)}")
        finally:
            # 确保缓冲区被正确清理
            image_buffer.close()

    @staticmethod
    async def save_poster(file: UploadFile) -> bytes:
        """保存海报图片到数据库并进行优化，返回二进制数据

        流程：
        1. 读取文件内容到内存
        2. 验证图片格式和安全性
        3. 优化图片尺寸，保持宽高比
        4. 转换为JPEG格式，质量85%
        5. 返回优化后的二进制数据
        """
        # 读取文件内容到内存
        content = await file.read()

        # 检查文件大小，防止内存溢出
        MAX_MEMORY_SIZE = 50 * 1024 * 1024  # 50MB
        if len(content) > MAX_MEMORY_SIZE:
            raise ValueError(f"图片文件过大，请压缩到{MAX_MEMORY_SIZE // (1024*1024)}MB以内")

        # 直接从内存数据解码图片，避免文件系统操作
        image_buffer = BytesIO(content)

        try:
            # 直接从内存缓冲区打开图片
            image = Image.open(image_buffer)

            # 检查图片尺寸，防止超大图片
            MAX_DIMENSION = 10000  # 最大边长
            if image.width > MAX_DIMENSION or image.height > MAX_DIMENSION:
                raise ValueError(f"图片尺寸过大，请将边长限制在{MAX_DIMENSION}像素以内")

            # 验证图片完整性
            image.verify()

            # 重新打开图片（verify()会关闭图片）
            image_buffer.seek(0)
            image = Image.open(image_buffer)

            # 转换为RGB以保存为JPEG
            if image.mode in ("RGBA", "P", "LA"):
                image = image.convert("RGB")

            # 海报图片优化设置
            # 保持宽高比，限制最大宽度为1200像素
            MAX_WIDTH = 1200
            MAX_HEIGHT = 800

            # 计算缩放比例
            width, height = image.size
            if width > MAX_WIDTH or height > MAX_HEIGHT:
                # 计算缩放比例，保持宽高比
                width_ratio = MAX_WIDTH / width
                height_ratio = MAX_HEIGHT / height
                ratio = min(width_ratio, height_ratio)

                new_width = int(width * ratio)
                new_height = int(height * ratio)

                # 使用高质量缩放
                image = image.resize((new_width, new_height), Image.Resampling.LANCZOS)

            # 保存到内存中的BytesIO，质量设置为85%保证海报清晰度
            output = BytesIO()
            try:
                image.save(output, "JPEG", quality=85, optimize=True, progressive=True)
                compressed_data = output.getvalue()

                # 检查压缩后的大小
                if len(compressed_data) > 5 * 1024 * 1024:  # 5MB
                    logger.warning(f"海报图片压缩后仍然较大: {len(compressed_data) // 1024}KB")
                    # 尝试进一步压缩
                    output = BytesIO()
                    image.save(output, "JPEG", quality=75, optimize=True, progressive=True)
                    compressed_data = output.getvalue()

                logger.debug(f"海报图片优化完成: 原始大小={len(content)//1024}KB, 优化后={len(compressed_data)//1024}KB, 尺寸={image.size}")
                return compressed_data
            finally:
                output.close()

        except MemoryError:
            logger.error("处理图片时内存不足")
            raise ValueError("图片处理失败：内存不足，请尝试使用较小的图片")
        except OSError as e:
            logger.error(f"图片文件损坏或格式不支持: {str(e)}")
            raise ValueError("图片文件损坏或格式不支持")
        except Exception as e:
            # 图片解码失败，抛出更详细的错误信息
            logger.error(f"海报图片处理失败: {str(e)}")
            raise ValueError(f"海报图片处理失败: {str(e)}")
        finally:
            # 确保缓冲区被正确清理
            image_buffer.close()

    @staticmethod
    def validate_image_content(content: bytes) -> bool:
        """验证图片内容安全性

        检查图片是否可以被PIL正常打开和验证
        防止恶意图片攻击
        """
        try:
            image_buffer = BytesIO(content)
            image = Image.open(image_buffer)
            image.verify()
            return True
        except Exception:
            return False
        finally:
            image_buffer.close()

    @staticmethod
    def get_avatar_cache_key(bipupu_id: str) -> str:
        """获取头像缓存键

        格式: avatar:{bipupu_id}
        用于Redis缓存
        """
        return f"avatar:{bipupu_id}"

    @staticmethod
    def get_avatar_etag(avatar_data, version_info) -> str:
        """生成头像ETag

        基于头像数据和版本信息生成ETag
        用于HTTP缓存控制

        Args:
            avatar_data: 头像二进制数据
            version_info: 版本信息（可以是时间戳、版本号等）
        """
        import hashlib
        # 确保参数是bytes类型
        if not isinstance(avatar_data, bytes):
            avatar_data = bytes(avatar_data) if avatar_data else b''
        if not isinstance(version_info, bytes):
            version_info = str(version_info).encode() if version_info else b''

        # 结合头像数据和版本信息生成哈希
        hash_input = avatar_data + version_info
        etag = hashlib.md5(hash_input).hexdigest()
        return f'"{etag}"'
