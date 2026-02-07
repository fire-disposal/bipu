import os
import uuid
from PIL import Image
from fastapi import UploadFile
from app.core.config import settings
from sqlalchemy.orm import Session
from app.models.user import User
from typing import Tuple, Optional

class StorageService:
    @staticmethod
    async def save_avatar_to_db(file: UploadFile, user_id: int, db: Session) -> Tuple[bytes, str, str]:
        """保存用户头像到数据库并进行压缩，返回二进制数据"""
        # 读取文件内容
        content = await file.read()
        
        # 保存并压缩图片
        image = Image.open(file.file)
        
        # 转换为RGB以保存为JPEG
        if image.mode in ("RGBA", "P"):
            image = image.convert("RGB")
            
        # 设置最大尺寸
        max_size = (400, 400)
        image.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        # 保存到内存中的BytesIO
        from io import BytesIO
        output = BytesIO()
        image.save(output, "JPEG", quality=85, optimize=True)
        compressed_data = output.getvalue()
        
        # 获取文件信息
        filename = file.filename or "avatar.jpg"
        mimetype = file.content_type or "image/jpeg"
        
        return compressed_data, filename, mimetype

    @staticmethod
    async def save_avatar(file: UploadFile, user_id: int) -> str:
        """保存用户头像到文件系统并进行压缩（原有方法保持兼容）"""
        # 确保上传目录存在（并发安全）
        upload_dir = os.path.join("uploads", "avatars")
        try:
            os.makedirs(upload_dir, exist_ok=True)
        except FileExistsError:
            # 目录已存在，继续
            pass
        
        # 生成唯一文件名
        extension = os.path.splitext(file.filename)[1].lower()
        if extension not in [".jpg", ".jpeg", ".png"]:
            extension = ".jpg"
        
        filename = f"user_{user_id}_{uuid.uuid4().hex}{extension}"
        file_path = os.path.join(upload_dir, filename)

        # 保存并压缩图片
        image = Image.open(file.file)
        
        # 转换为RGB以保存为JPEG
        if image.mode in ("RGBA", "P"):
            image = image.convert("RGB")
            
        # 设置最大尺寸
        max_size = (400, 400)
        image.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        # 保存图片，质量设为85
        image.save(file_path, "JPEG", quality=85, optimize=True)
        
        # 返回相对URL
        return f"/uploads/avatars/{filename}"

    @staticmethod
    def delete_old_avatar(avatar_url: str):
        """删除旧的头像文件"""
        if not avatar_url or not avatar_url.startswith("/uploads/"):
            return
            
        # 移除开头的 /
        relative_path = avatar_url.lstrip("/")
        # 注意：这里假设 uploads 目录在 backend 根目录下
        file_path = os.path.join(os.getcwd(), relative_path)
        
        if os.path.exists(file_path):
            try:
                os.remove(file_path)
            except Exception:
                pass
