from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.models.service_account import ServiceAccount
from app.schemas.service_account import ServiceAccountResponse, ServiceAccountList
from app.core.security import get_current_user
from app.models.user import User

router = APIRouter()

@router.get("/", response_model=ServiceAccountList)
async def list_service_accounts(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取所有活跃的服务号列表"""
    services = db.query(ServiceAccount).filter(ServiceAccount.is_active == True).offset(skip).limit(limit).all()
    total = db.query(ServiceAccount).filter(ServiceAccount.is_active == True).count()
    
    return {"items": services, "total": total}

@router.get("/{name}", response_model=ServiceAccountResponse)
async def get_service_account(
    name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取指定服务号详情"""
    service = db.query(ServiceAccount).filter(ServiceAccount.name == name).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service account not found")
    return service

@router.get("/{name}/avatar")
async def get_service_avatar(
    name: str,
    db: Session = Depends(get_db)
):
    """获取服务号头像"""
    service = db.query(ServiceAccount).filter(ServiceAccount.name == name).first()
    if not service or not service.avatar_data:
        # 返回默认头像或404
        # 这里为了体验，如果没有头像可以重定向到一个默认图，或者返回404
        raise HTTPException(status_code=404, detail="Avatar not found")
    
    return Response(
        content=service.avatar_data,
        media_type=service.avatar_mimetype or "image/png",
        headers={"Cache-Control": "public, max-age=3600"}
    )

@router.get("/subscriptions/", response_model=ServiceAccountList)
async def get_user_subscriptions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取用户订阅的服务号列表"""
    subscriptions = current_user.subscriptions
    return {"items": subscriptions, "total": len(subscriptions)}

@router.post("/{name}/subscribe")
async def subscribe_service_account(
    name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """订阅服务号"""
    service = db.query(ServiceAccount).filter(ServiceAccount.name == name, ServiceAccount.is_active == True).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service account not found")
    
    if service in current_user.subscriptions:
        raise HTTPException(status_code=400, detail="Already subscribed")
    
    current_user.subscriptions.append(service)
    db.commit()
    return {"message": "Subscribed successfully"}

@router.delete("/{name}/subscribe")
async def unsubscribe_service_account(
    name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """取消订阅服务号"""
    service = db.query(ServiceAccount).filter(ServiceAccount.name == name).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service account not found")
    
    if service not in current_user.subscriptions:
        raise HTTPException(status_code=400, detail="Not subscribed")
    
    current_user.subscriptions.remove(service)
    db.commit()
    return {"message": "Unsubscribed successfully"}
