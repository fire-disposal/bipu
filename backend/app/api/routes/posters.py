"""海报API路由 - 极简版本"""
from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File, Form, Request
from sqlalchemy.orm import Session
from typing import Optional, List
import base64

from app.db.database import get_db
from app.models.user import User
from app.schemas.poster import PosterCreate, PosterUpdate, PosterResponse, PosterListResponse
from app.services.poster_service import PosterService
from app.core.security import get_current_user, get_current_superuser_web
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/", response_model=PosterListResponse, tags=["海报"])
async def get_posters(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """获取海报列表（管理用）"""
    skip = (page - 1) * page_size
    posters, total = PosterService.get_all_posters(db, skip, page_size)

    return {
        "posters": posters,
        "total": total,
        "page": page,
        "page_size": page_size
    }


@router.get("/active", response_model=List[PosterResponse], tags=["海报"])
async def get_active_posters(
    limit: int = Query(10, ge=1, le=20, description="返回数量"),
    db: Session = Depends(get_db)
):
    """获取激活的海报列表（前端轮播用）"""
    posters = PosterService.get_active_posters(db, limit)
    return posters


@router.get("/{poster_id}", response_model=PosterResponse, tags=["海报"])
async def get_poster(
    poster_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """获取单个海报详情"""
    poster = PosterService.get_poster(db, poster_id)
    if not poster:
        raise HTTPException(status_code=404, detail="海报不存在")
    return poster


@router.get("/{poster_id}/image", tags=["海报"])
async def get_poster_image(
    poster_id: int,
    db: Session = Depends(get_db)
):
    """获取海报图片（JSON格式，包含base64编码）"""
    poster = PosterService.get_poster(db, poster_id)
    if not poster or not poster.image_data:
        raise HTTPException(status_code=404, detail="海报或图片不存在")

    # 获取base64编码的图片数据
    image_base64 = PosterService.get_poster_image_base64(poster)

    return {
        "poster_id": poster_id,
        "title": poster.title,
        "image_data": image_base64,
        "mime_type": "image/jpeg"  # StorageService统一保存为JPEG格式
    }


@router.get("/{poster_id}/image/binary", tags=["海报"])
async def get_poster_image_binary(
    request: Request,
    poster_id: int,
    db: Session = Depends(get_db)
):
    """获取海报图片（二进制格式，直接用于img标签）"""
    from app.services.storage_service import StorageService
    from fastapi.responses import Response

    poster = PosterService.get_poster(db, poster_id)
    if not poster or not poster.image_data:
        raise HTTPException(status_code=404, detail="海报或图片不存在")

    # 生成ETag - 使用更新时间戳
    updated_at_timestamp = poster.updated_at.timestamp() if poster.updated_at else 0
    etag_input = f"{poster.id}:{updated_at_timestamp}".encode()
    etag = StorageService.get_avatar_etag(poster.image_data, etag_input)

    # 检查If-None-Match头
    if_none_match = request.headers.get("if-none-match")
    if if_none_match and if_none_match == etag:
        return Response(status_code=304)  # Not Modified

    # 返回二进制图片数据
    return Response(
        content=poster.image_data,
        media_type="image/jpeg",  # StorageService统一保存为JPEG格式
        headers={
            "ETag": etag,
            "Cache-Control": "public, max-age=86400",  # 缓存24小时
            "Content-Disposition": f'inline; filename="poster-{poster.id}.jpg"'
        }
    )


@router.post("/", response_model=PosterResponse, status_code=status.HTTP_201_CREATED, tags=["海报"])
async def create_poster(
    title: str = Form(..., description="海报标题"),
    link_url: Optional[str] = Form(None, description="点击跳转链接"),
    display_order: int = Form(0, ge=0, description="显示顺序"),
    is_active: bool = Form(True, description="是否激活"),
    image_file: UploadFile = File(..., description="海报图片"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """创建海报"""
    try:
        # 构建海报数据
        poster_data = PosterCreate(
            title=title,
            link_url=link_url,
            display_order=display_order,
            is_active=is_active
        )

        # 创建海报
        poster = await PosterService.create_poster(db, poster_data, image_file)
        return poster

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"创建海报失败: {e}")
        raise HTTPException(status_code=500, detail="创建海报失败")


@router.put("/{poster_id}", response_model=PosterResponse, tags=["海报"])
async def update_poster(
    poster_id: int,
    poster_data: PosterUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """更新海报信息"""
    poster = PosterService.update_poster(db, poster_id, poster_data)
    if not poster:
        raise HTTPException(status_code=404, detail="海报不存在")
    return poster


@router.put("/{poster_id}/image", response_model=PosterResponse, tags=["海报"])
async def update_poster_image(
    poster_id: int,
    image_file: UploadFile = File(..., description="新海报图片"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """更新海报图片"""
    try:
        poster = await PosterService.update_poster_image(db, poster_id, image_file)
        if not poster:
            raise HTTPException(status_code=404, detail="海报不存在")
        return poster

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"更新海报图片失败: {e}")
        raise HTTPException(status_code=500, detail="更新海报图片失败")


@router.delete("/{poster_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["海报"])
async def delete_poster(
    poster_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """删除海报"""
    success = PosterService.delete_poster(db, poster_id)
    if not success:
        raise HTTPException(status_code=404, detail="海报不存在")
    return None
