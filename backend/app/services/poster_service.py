"""海报服务 - 极简版本，仿照头像存储方式"""
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import datetime
from fastapi import UploadFile
import base64

from app.models.poster import Poster
from app.schemas.poster import PosterCreate, PosterUpdate
from app.services.storage_service import StorageService
from app.core.logging import get_logger

logger = get_logger(__name__)


class PosterService:
    """海报服务类"""

    @staticmethod
    async def create_poster(
        db: Session,
        poster_data: PosterCreate,
        image_file: UploadFile
    ) -> Poster:
        """创建海报

        流程：
        1. 验证图片文件
        2. 使用StorageService处理图片压缩
        3. 创建海报记录
        """
        # 验证文件类型
        if not image_file.content_type or not image_file.content_type.startswith('image/'):
            raise ValueError("请上传图片文件")

        # 使用StorageService处理海报图片优化
        image_data = await StorageService.save_poster(image_file)

        # 创建海报记录
        poster = Poster(
            title=poster_data.title,
            image_data=image_data,
            link_url=poster_data.link_url,
            display_order=poster_data.display_order,
            is_active=poster_data.is_active
        )

        db.add(poster)
        try:
            db.commit()
            db.refresh(poster)
        except Exception:
            db.rollback()
            raise

        logger.info(f"海报创建成功: {poster.title} (ID: {poster.id})")
        return poster

    @staticmethod
    def update_poster(
        db: Session,
        poster_id: int,
        poster_data: PosterUpdate
    ) -> Optional[Poster]:
        """更新海报"""
        poster = db.query(Poster).filter(Poster.id == poster_id).first()
        if not poster:
            return None

        # 更新字段
        update_data = poster_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(poster, field, value)

        poster.updated_at = datetime.now()

        try:
            db.commit()
            db.refresh(poster)
        except Exception:
            db.rollback()
            raise

        logger.info(f"海报更新成功: {poster.title} (ID: {poster.id})")
        return poster

    @staticmethod
    async def update_poster_image(
        db: Session,
        poster_id: int,
        image_file: UploadFile
    ) -> Optional[Poster]:
        """更新海报图片"""
        poster = db.query(Poster).filter(Poster.id == poster_id).first()
        if not poster:
            return None

        # 验证文件类型
        if not image_file.content_type or not image_file.content_type.startswith('image/'):
            raise ValueError("请上传图片文件")

        # 使用StorageService处理海报图片优化
        image_data = await StorageService.save_poster(image_file)

        # 更新图片数据
        poster.image_data = image_data
        poster.updated_at = datetime.now()

        try:
            db.commit()
            db.refresh(poster)
        except Exception:
            db.rollback()
            raise

        logger.info(f"海报图片更新成功: {poster.title} (ID: {poster.id})")
        return poster

    @staticmethod
    def delete_poster(db: Session, poster_id: int) -> bool:
        """删除海报"""
        poster = db.query(Poster).filter(Poster.id == poster_id).first()
        if not poster:
            return False

        db.delete(poster)
        try:
            db.commit()
            return True
        except Exception:
            db.rollback()
            raise

        logger.info(f"海报删除成功: {poster.title} (ID: {poster.id})")
        return True

    @staticmethod
    def get_poster(db: Session, poster_id: int) -> Optional[Poster]:
        """获取单个海报"""
        return db.query(Poster).filter(Poster.id == poster_id).first()

    @staticmethod
    def get_active_posters(
        db: Session,
        limit: int = 10
    ) -> List[Poster]:
        """获取激活的海报列表（用于前端轮播）"""
        return db.query(Poster).filter(
            Poster.is_active == True
        ).order_by(
            Poster.display_order.asc(),
            Poster.created_at.desc()
        ).limit(limit).all()

    @staticmethod
    def get_all_posters(
        db: Session,
        skip: int = 0,
        limit: int = 20
    ) -> tuple[List[Poster], int]:
        """获取所有海报（用于管理）"""
        query = db.query(Poster).order_by(
            Poster.display_order.asc(),
            Poster.created_at.desc()
        )

        total = query.count()
        posters = query.offset(skip).limit(limit).all()

        return posters, total
