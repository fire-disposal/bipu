from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/", response_model=List[UserResponse])
async def get_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """获取用户列表"""
    users = db.query(User).offset(skip).limit(limit).all()
    return users


@router.post("/", response_model=UserResponse)
async def create_user(
    user: UserCreate,
    db: Session = Depends(get_db)
):
    """创建新用户"""
    # 检查用户是否已存在
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # 创建新用户
    db_user = User(**user.dict())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    logger.info(f"Created new user: {user.email}")
    return db_user


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    db: Session = Depends(get_db)
):
    """获取指定用户"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_update: UserCreate,
    db: Session = Depends(get_db)
):
    """更新用户信息"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    for key, value in user_update.dict().items():
        setattr(user, key, value)
    
    db.commit()
    db.refresh(user)
    
    logger.info(f"Updated user: {user.email}")
    return user


@router.delete("/{user_id}")
async def delete_user(
    user_id: int,
    db: Session = Depends(get_db)
):
    """删除用户"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(user)
    db.commit()
    
    logger.info(f"Deleted user: {user.email}")
    return {"message": "User deleted successfully"}