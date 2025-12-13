"""设备管理端点"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.db.database import get_db
from app.models.device import Device
from app.models.user import User
from app.schemas.device import (
    DeviceCreate, DeviceUpdate, DeviceResponse, DeviceList, DeviceStats
)
from app.core.security import get_current_active_user
from app.core.exceptions import NotFoundException, ValidationException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.post("/", response_model=DeviceResponse)
async def create_device(
    device: DeviceCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """创建设备"""
    # 检查设备ID是否已存在
    existing_device = db.query(Device).filter(
        Device.device_id == device.device_id
    ).first()
    
    if existing_device:
        raise ValidationException("Device ID already exists")
    
    # 创建设备
    device_data = device.dict()
    device_data["user_id"] = current_user.id
    
    db_device = Device(**device_data)
    db.add(db_device)
    db.commit()
    db.refresh(db_device)
    
    logger.info(f"Device created: {device.name} by user {current_user.email}")
    return db_device


@router.get("/", response_model=DeviceList)
async def get_devices(
    skip: int = 0,
    limit: int = 100,
    status_filter: Optional[str] = None,
    device_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取设备列表"""
    query = db.query(Device).filter(Device.user_id == current_user.id)
    
    # 应用过滤条件
    if status_filter:
        query = query.filter(Device.status == status_filter)
    if device_type:
        query = query.filter(Device.device_type == device_type)
    
    total = query.count()
    devices = query.offset(skip).limit(limit).all()
    
    return DeviceList(
        items=devices,
        total=total,
        page=skip // limit + 1,
        size=limit
    )


@router.get("/stats", response_model=DeviceStats)
async def get_device_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取设备统计信息"""
    query = db.query(Device).filter(Device.user_id == current_user.id)
    
    total = query.count()
    online = query.filter(Device.status == "online").count()
    offline = query.filter(Device.status == "offline").count()
    error = query.filter(Device.status == "error").count()
    maintenance = query.filter(Device.status == "maintenance").count()
    
    return DeviceStats(
        total=total,
        online=online,
        offline=offline,
        error=error,
        maintenance=maintenance
    )


@router.get("/{device_id}", response_model=DeviceResponse)
async def get_device(
    device_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取指定设备"""
    device = db.query(Device).filter(
        Device.id == device_id,
        Device.user_id == current_user.id
    ).first()
    
    if not device:
        raise NotFoundException("Device not found")
    
    return device


@router.put("/{device_id}", response_model=DeviceResponse)
async def update_device(
    device_id: int,
    device_update: DeviceUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新设备信息"""
    device = db.query(Device).filter(
        Device.id == device_id,
        Device.user_id == current_user.id
    ).first()
    
    if not device:
        raise NotFoundException("Device not found")
    
    # 检查设备ID是否被其他设备使用
    if device_update.device_id:
        existing_device = db.query(Device).filter(
            Device.device_id == device_update.device_id,
            Device.id != device_id
        ).first()
        
        if existing_device:
            raise ValidationException("Device ID already exists")
    
    # 更新设备信息
    update_data = device_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(device, key, value)
    
    db.commit()
    db.refresh(device)
    
    logger.info(f"Device updated: {device.name} by user {current_user.email}")
    return device


@router.delete("/{device_id}")
async def delete_device(
    device_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除设备"""
    device = db.query(Device).filter(
        Device.id == device_id,
        Device.user_id == current_user.id
    ).first()
    
    if not device:
        raise NotFoundException("Device not found")
    
    db.delete(device)
    db.commit()
    
    logger.info(f"Device deleted: {device.name} by user {current_user.email}")
    return {"message": "Device deleted successfully"}


@router.post("/{device_id}/heartbeat")
async def device_heartbeat(
    device_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """设备心跳（更新最后在线时间）"""
    device = db.query(Device).filter(
        Device.id == device_id,
        Device.user_id == current_user.id
    ).first()
    
    if not device:
        raise NotFoundException("Device not found")
    
    device.last_seen_at = datetime.utcnow()
    device.status = "online"
    
    db.commit()
    
    logger.info(f"Device heartbeat: {device.name}")
    return {"message": "Heartbeat received"}


@router.post("/{device_id}/status")
async def update_device_status(
    device_id: int,
    status: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新设备状态"""
    device = db.query(Device).filter(
        Device.id == device_id,
        Device.user_id == current_user.id
    ).first()
    
    if not device:
        raise NotFoundException("Device not found")
    
    if status not in ["online", "offline", "error", "maintenance"]:
        raise ValidationException("Invalid status")
    
    device.status = status
    if status == "online":
        device.last_seen_at = datetime.utcnow()
    
    db.commit()
    
    logger.info(f"Device status updated: {device.name} -> {status}")
    return {"message": f"Device status updated to {status}"}