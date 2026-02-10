"""用户公开信息路由"""
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/users/{bipupu_id}", response_model=UserResponse, tags=["用户"])
async def get_user_by_bipupu_id(
    bipupu_id: str,
    db: Session = Depends(get_db)
):
    """通过 bipupu_id 获取用户公开信息"""
    user = db.query(User).filter(User.bipupu_id == bipupu_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user


@router.get("/users/{bipupu_id}/avatar", tags=["用户"])
async def get_user_avatar_by_bipupu_id(
    bipupu_id: str,
    db: Session = Depends(get_db)
):
    """通过 bipupu_id 获取用户头像"""
    user = db.query(User).filter(User.bipupu_id == bipupu_id).first()
    if not user or not user.avatar_data:
        raise HTTPException(status_code=404, detail="Avatar not found")
    
    return Response(
        content=user.avatar_data,
        media_type=user.avatar_mimetype or "image/jpeg",
        headers={"Cache-Control": "public, max-age=3600"}  # 缓存1小时
    )
