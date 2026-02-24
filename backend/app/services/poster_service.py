"""海报服务 - 极简版本，仿照头像存储方式"""
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional, List
from datetime import datetime
from fastapi import UploadFile, HTTPException
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
        3. 检查并调整显示顺序
        4. 创建海报记录
        """
        try:
            # 验证文件类型
            if not image_file.content_type or not image_file.content_type.startswith('image/'):
                raise ValueError("请上传图片文件")

            # 检查显示顺序是否已被占用
            existing_poster = db.query(Poster).filter(
                Poster.display_order == poster_data.display_order
            ).first()

            if existing_poster:
                # 如果有重复的显示顺序，自动调整为下一个可用值
                # 查找当前顺序之后的最大顺序值
                max_order = db.query(func.max(Poster.display_order)).scalar() or 0
                adjusted_order = max_order + 1
                logger.info(f"显示顺序 {poster_data.display_order} 已被占用，自动调整为 {adjusted_order}")
                display_order = adjusted_order
            else:
                display_order = poster_data.display_order

            # 使用StorageService处理海报图片优化
            image_data = await StorageService.save_poster(image_file)

            # 创建海报记录
            poster = Poster(
                title=poster_data.title,
                image_data=image_data,
                link_url=poster_data.link_url,
                display_order=display_order,
                is_active=poster_data.is_active
            )

            db.add(poster)
            try:
                db.commit()
                db.refresh(poster)
            except Exception as e:
                db.rollback()
                logger.error(f"数据库提交失败: {str(e)}")
                raise HTTPException(status_code=500, detail="创建海报失败，数据库错误")

            logger.info(f"海报创建成功: {poster.title} (ID: {poster.id})")
            return poster

        except ValueError as e:
            logger.warning(f"创建海报参数错误: {str(e)}")
            raise HTTPException(status_code=400, detail=str(e))
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"创建海报未知错误: {str(e)}")
            raise HTTPException(status_code=500, detail="创建海报失败")

    @staticmethod
    def update_poster(
        db: Session,
        poster_id: int,
        poster_data: PosterUpdate
    ) -> Optional[Poster]:
        """更新海报"""
        try:
            poster = db.query(Poster).filter(Poster.id == poster_id).first()
            if not poster:
                logger.warning(f"尝试更新不存在的海报: ID={poster_id}")
                return None

            # 更新字段
            update_data = poster_data.model_dump(exclude_unset=True)

            # 特殊处理显示顺序：检查是否与其他海报冲突
            if 'display_order' in update_data:
                new_order = update_data['display_order']
                if new_order != poster.display_order:
                    # 检查新顺序是否已被其他海报占用
                    existing_poster = db.query(Poster).filter(
                        Poster.display_order == new_order,
                        Poster.id != poster_id
                    ).first()

                    if existing_poster:
                        # 如果有冲突，交换两个海报的顺序
                        logger.info(f"显示顺序冲突：海报 {poster_id} 尝试使用顺序 {new_order}，但已被海报 {existing_poster.id} 占用，执行顺序交换")
                        existing_poster.display_order = poster.display_order

            for field, value in update_data.items():
                setattr(poster, field, value)

            poster.updated_at = datetime.now()

            try:
                db.commit()
                db.refresh(poster)
            except Exception as e:
                db.rollback()
                logger.error(f"更新海报数据库提交失败: {str(e)}")
                raise HTTPException(status_code=500, detail="更新海报失败，数据库错误")

            logger.info(f"海报更新成功: {poster.title} (ID: {poster.id})")
            return poster

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"更新海报未知错误: {str(e)}")
            raise HTTPException(status_code=500, detail="更新海报失败")

    @staticmethod
    async def update_poster_image(
        db: Session,
        poster_id: int,
        image_file: UploadFile
    ) -> Optional[Poster]:
        """更新海报图片"""
        try:
            poster = db.query(Poster).filter(Poster.id == poster_id).first()
            if not poster:
                logger.warning(f"尝试更新不存在的海报图片: ID={poster_id}")
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
            except Exception as e:
                db.rollback()
                logger.error(f"更新海报图片数据库提交失败: {str(e)}")
                raise HTTPException(status_code=500, detail="更新海报图片失败，数据库错误")

            logger.info(f"海报图片更新成功: {poster.title} (ID: {poster.id})")
            return poster

        except ValueError as e:
            logger.warning(f"更新海报图片参数错误: {str(e)}")
            raise HTTPException(status_code=400, detail=str(e))
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"更新海报图片未知错误: {str(e)}")
            raise HTTPException(status_code=500, detail="更新海报图片失败")

    @staticmethod
    def delete_poster(db: Session, poster_id: int) -> bool:
        """删除海报"""
        try:
            poster = db.query(Poster).filter(Poster.id == poster_id).first()
            if not poster:
                logger.warning(f"尝试删除不存在的海报: ID={poster_id}")
                return False

            db.delete(poster)
            try:
                db.commit()
            except Exception as e:
                db.rollback()
                logger.error(f"删除海报数据库提交失败: {str(e)}")
                raise HTTPException(status_code=500, detail="删除海报失败，数据库错误")

            logger.info(f"海报删除成功: {poster.title} (ID: {poster.id})")
            return True

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"删除海报未知错误: {str(e)}")
            raise HTTPException(status_code=500, detail="删除海报失败")

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
            Poster.id.asc()  # 使用ID作为二级排序，确保顺序稳定
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
            Poster.id.asc()  # 使用ID作为二级排序，确保顺序稳定
        )

        total = query.count()
        posters = query.offset(skip).limit(limit).all()

        return posters, total
