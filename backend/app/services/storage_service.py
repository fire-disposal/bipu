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

# 头像配置常量
AVATAR_MAX_SIZE = 100  # 头像最大尺寸（像素）
AVATAR_MIN_SIZE = 50   # 头像最小尺寸（像素）
AVATAR_MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB，头像最大文件大小
AVATAR_QUALITY = 70    # JPEG压缩质量
AVATAR_ASPECT_RATIO_TOLERANCE = 0.1  # 宽高比容差（10%）


class StorageService:
    """图片存储服务类 - 简化版本，专注数据库存储"""

    @staticmethod
    async def save_avatar(file: UploadFile) -> bytes:
        """保存用户头像到数据库并进行压缩，返回二进制数据

        流程：
        1. 读取文件内容到内存，验证文件大小
        2. 验证图片格式、安全性和宽高比（强制1:1）
        3. 裁剪并压缩图片到正方形（最大100x100像素）
        4. 转换为JPEG格式，质量70%
        5. 返回压缩后的二进制数据
        """
        # 读取文件内容到内存
        content = await file.read()

        # 验证文件大小
        if len(content) > AVATAR_MAX_FILE_SIZE:
            raise ValueError(f"头像文件过大，最大支持 {AVATAR_MAX_FILE_SIZE // (1024*1024)}MB")

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

            # 检查图片尺寸，防止超大图片
            MAX_DIMENSION = 5000  # 最大边长
            if image.width > MAX_DIMENSION or image.height > MAX_DIMENSION:
                raise ValueError(f"图片尺寸过大，请将边长限制在{MAX_DIMENSION}像素以内")

            # 检查宽高比，强制1:1比例
            aspect_ratio = image.width / image.height
            if abs(aspect_ratio - 1.0) > AVATAR_ASPECT_RATIO_TOLERANCE:
                logger.warning(f"头像宽高比不符合1:1要求: {image.width}x{image.height} (比例: {aspect_ratio:.2f})")
                # 自动裁剪为正方形
                image = StorageService._crop_to_square(image)

            # 转换为RGB以保存为JPEG
            if image.mode in ("RGBA", "P", "LA"):
                image = image.convert("RGB")

            # 压缩到目标尺寸
            image = StorageService._resize_avatar(image)

            # 保存到内存中的BytesIO，质量设置为70%符合MVP需求
            output = BytesIO()
            image.save(output, "JPEG", quality=AVATAR_QUALITY, optimize=True)
            compressed_data = output.getvalue()

            logger.info(f"头像处理完成: 原始={len(content)//1024}KB, 压缩后={len(compressed_data)//1024}KB, 尺寸={image.width}x{image.height}")
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
    def _crop_to_square(image: Image.Image) -> Image.Image:
        """将图片裁剪为正方形

        从图片中心裁剪出最大的正方形区域
        """
        width, height = image.size

        # 计算裁剪区域
        if width > height:
            # 宽度大于高度，裁剪宽度
            left = (width - height) // 2
            top = 0
            right = left + height
            bottom = height
        else:
            # 高度大于宽度，裁剪高度
            left = 0
            top = (height - width) // 2
            right = width
            bottom = top + width

        # 执行裁剪
        cropped_image = image.crop((left, top, right, bottom))
        logger.debug(f"图片裁剪为正方形: 原始尺寸={width}x{height}, 裁剪后={cropped_image.width}x{cropped_image.height}")
        return cropped_image

    @staticmethod
    def _resize_avatar(image: Image.Image) -> Image.Image:
        """调整头像尺寸到目标大小

        确保头像尺寸在最小和最大尺寸之间，并保持正方形
        """
        width, height = image.size

        # 确保是正方形
        if width != height:
            # 如果不是正方形，使用较小的一边作为基准
            size = min(width, height)
            image = image.resize((size, size), Image.Resampling.LANCZOS)

        # 调整到目标尺寸
        if image.width > AVATAR_MAX_SIZE:
            image = image.resize((AVATAR_MAX_SIZE, AVATAR_MAX_SIZE), Image.Resampling.LANCZOS)
        elif image.width < AVATAR_MIN_SIZE:
            image = image.resize((AVATAR_MIN_SIZE, AVATAR_MIN_SIZE), Image.Resampling.LANCZOS)

        return image

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
    def validate_avatar_dimensions(width: int, height: int) -> bool:
        """验证头像尺寸是否符合要求

        检查宽高比是否为1:1（允许一定容差）
        """
        if width <= 0 or height <= 0:
            return False

        aspect_ratio = width / height
        return abs(aspect_ratio - 1.0) <= AVATAR_ASPECT_RATIO_TOLERANCE

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
