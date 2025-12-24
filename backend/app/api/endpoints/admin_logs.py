"""管理员操作日志管理端点"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date

from app.db.database import get_db
from app.models.adminlog import AdminLog
from app.models.user import User
from app.schemas.adminlog import (
    AdminLogCreate, AdminLogResponse
)
from app.core.security import get_current_superuser
from app.core.exceptions import NotFoundException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


def create_admin_log(
    db: Session,
    admin_id: int,
    action: str,
    detail: Optional[dict] = None
) -> AdminLog:
    """创建管理员操作日志（内部函数）"""
    log = AdminLog(
        admin_id=admin_id,
        action=action,
        detail=detail or {}
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log


@router.get("/", response_model=List[AdminLogResponse])
async def get_admin_logs(
    skip: int = 0,
    limit: int = 100,
    admin_id: Optional[int] = None,
    action: Optional[str] = None,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """获取管理员操作日志（需要超级用户权限）"""
    query = db.query(AdminLog)
    
    if admin_id:
        query = query.filter(AdminLog.admin_id == admin_id)
    if action:
        query = query.filter(AdminLog.action.contains(action))
    if start_date:
        query = query.filter(AdminLog.timestamp >= start_date)
    if end_date:
        query = query.filter(AdminLog.timestamp <= end_date)
    
    logs = query.order_by(AdminLog.timestamp.desc()).offset(skip).limit(limit).all()
    return logs


@router.get("/stats")
async def get_admin_log_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """获取管理员操作日志统计（需要超级用户权限）"""
    total_logs = db.query(AdminLog).count()
    
    # 按操作类型统计
    action_stats = {}
    actions = db.query(AdminLog.action).distinct().all()
    for action in actions:
        action_name = action[0]
        count = db.query(AdminLog).filter(AdminLog.action == action_name).count()
        action_stats[action_name] = count
    
    # 按管理员统计
    admin_stats = {}
    admin_logs = db.query(AdminLog.admin_id, User.username).join(
        User, AdminLog.admin_id == User.id
    ).distinct().all()
    
    for admin_id, username in admin_logs:
        count = db.query(AdminLog).filter(AdminLog.admin_id == admin_id).count()
        admin_stats[username] = count
    
    # 最近7天的日志数量
    from datetime import timedelta
    recent_date = datetime.utcnow() - timedelta(days=7)
    recent_logs = db.query(AdminLog).filter(AdminLog.timestamp >= recent_date).count()
    
    return {
        "total_logs": total_logs,
        "recent_logs_7d": recent_logs,
        "action_stats": action_stats,
        "admin_stats": admin_stats
    }


@router.get("/{log_id}", response_model=AdminLogResponse)
async def get_admin_log(
    log_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """获取指定管理员日志（需要超级用户权限）"""
    log = db.query(AdminLog).filter(AdminLog.id == log_id).first()
    if not log:
        raise NotFoundException("Admin log not found")
    return log


@router.delete("/{log_id}")
async def delete_admin_log(
    log_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    """删除管理员日志（需要超级用户权限）"""
    log = db.query(AdminLog).filter(AdminLog.id == log_id).first()
    if not log:
        raise NotFoundException("Admin log not found")
    
    db.delete(log)
    db.commit()
    
    logger.info(f"Admin log deleted: {log_id} by {current_user.username}")
    return {"message": "Admin log deleted successfully"}


# 管理端操作记录函数
def log_admin_action(
    db: Session,
    admin_id: int,
    action: str,
    detail: Optional[dict] = None
):
    """记录管理员操作（供其他端点调用）"""
    try:
        create_admin_log(db, admin_id, action, detail)
    except Exception as e:
        logger.error(f"Failed to log admin action: {e}")