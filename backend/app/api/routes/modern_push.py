"""
推送服务 API 路由
提供推送状态查询、立即推送、广播推送、推送日志等接口
"""

from typing import Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, Body
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.services.push.service import PushService
from app.core.logging import get_logger

logger = get_logger(__name__)

router = APIRouter()


def _require_admin(current_user: User):
    if not (current_user.is_superuser if current_user.is_superuser is not None else False):
        raise HTTPException(status_code=403, detail="管理员权限不足")


@router.get("/status", tags=["推送服务"])
async def get_push_service_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """获取推送服务状态（引擎统计、服务号列表）"""
    try:
        push_service = PushService(db)
        status = push_service.get_service_status()
        return {"success": True, "data": status}
    except Exception as e:
        logger.error(f"获取推送服务状态失败: {e}")
        raise HTTPException(status_code=500, detail=f"获取服务状态失败: {str(e)}")


@router.post("/send", tags=["推送服务"])
async def send_immediate_push(
    service_name: str = Body(..., description="服务号名称"),
    user_id: Optional[str] = Body(None, description="目标用户 BIPUPU ID，为空时推给当前用户"),
    content: Optional[str] = Body(None, description="推送内容，为空时按服务号类型自动生成"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """立即向指定用户发送推送消息（高优先级）"""
    try:
        target_user_id = user_id or (str(current_user.bipupu_id) if current_user.bipupu_id else None)
        if not target_user_id:
            raise HTTPException(status_code=400, detail="用户 ID 不能为空")

        push_service = PushService(db)
        result = await push_service.send_push(
            service_name=service_name,
            user_id=target_user_id,
            content=content,
            priority=1
        )

        if not result.get("success"):
            raise HTTPException(status_code=400, detail=result.get("error", "推送发送失败"))

        return {"success": True, "data": result}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"发送立即推送失败: {e}")
        raise HTTPException(status_code=500, detail=f"发送推送失败: {str(e)}")


@router.post("/broadcast", tags=["推送服务"])
async def broadcast_push(
    service_name: str = Body(..., description="服务号名称"),
    content: Optional[str] = Body(None, description="推送内容，为空时自动生成"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """向服务号所有订阅者广播推送（管理员）"""
    _require_admin(current_user)
    try:
        push_service = PushService(db)
        result = await push_service.broadcast(service_name=service_name, content=content, priority=2)
        return {"success": True, "data": result}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"广播推送失败: {e}")
        raise HTTPException(status_code=500, detail=f"广播推送失败: {str(e)}")


@router.post("/test", tags=["推送服务"])
async def test_push(
    service_name: str = Body(..., description="服务号名称"),
    user_id: Optional[str] = Body(None, description="目标用户 BIPUPU ID，为空时推给当前用户"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """发送测试推送，验证推送链路是否正常"""
    try:
        target_user_id = user_id or (str(current_user.bipupu_id) if current_user.bipupu_id else None)
        if not target_user_id:
            raise HTTPException(status_code=400, detail="用户 ID 不能为空")

        push_service = PushService(db)
        result = await push_service.test_push(service_name=service_name, user_id=target_user_id)

        if not result.get("success"):
            raise HTTPException(status_code=400, detail=result.get("error", "测试推送失败"))

        return {"success": True, "data": result}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"发送测试推送失败: {e}")
        raise HTTPException(status_code=500, detail=f"发送测试推送失败: {str(e)}")


@router.post("/scheduled/run", tags=["推送服务"])
async def trigger_scheduled_push(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    手动触发一次定时推送检查（管理员）

    立即执行定时推送逻辑，向当前时间窗口内应收到推送的所有用户发送消息。
    可用于测试调度逻辑或在 Celery 不可用时手动补推。
    """
    _require_admin(current_user)
    try:
        push_service = PushService(db)
        result = await push_service.check_and_send_scheduled()
        return {"success": True, "data": result}
    except Exception as e:
        logger.error(f"手动触发定时推送失败: {e}")
        raise HTTPException(status_code=500, detail=f"触发失败: {str(e)}")


@router.post("/retry_failed", tags=["推送服务"])
async def retry_failed_pushes(
    max_retries: int = Body(3, description="最大重试次数上限"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """重试失败推送（管理员）"""
    _require_admin(current_user)
    try:
        push_service = PushService(db)
        result = await push_service.retry_failed(max_retries=max_retries)
        return {"success": True, "data": result}
    except Exception as e:
        logger.error(f"重试失败推送异常: {e}")
        raise HTTPException(status_code=500, detail=f"重试失败: {str(e)}")


@router.get("/logs", tags=["推送服务"])
async def get_push_logs(
    service_name: Optional[str] = Query(None, description="按服务号名称筛选"),
    receiver_id: Optional[str] = Query(None, description="按接收者 BIPUPU ID 筛选"),
    status: Optional[str] = Query(None, description="按状态筛选（pending/processing/success/failed/skipped）"),
    limit: int = Query(50, ge=1, le=200, description="返回条数"),
    skip: int = Query(0, ge=0, description="分页偏移"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """查询推送日志（管理员）- 支持多条件筛选，按时间倒序"""
    _require_admin(current_user)

    from app.models.push_log import PushLog

    query = db.query(PushLog)
    if service_name:
        query = query.filter(PushLog.service_name == service_name)
    if receiver_id:
        query = query.filter(PushLog.receiver_bipupu_id == receiver_id)
    if status:
        query = query.filter(PushLog.status == status)

    total = query.count()
    logs = query.order_by(PushLog.created_at.desc()).offset(skip).limit(limit).all()

    items = [
        {
            "id": log.id,
            "service_name": log.service_name,
            "receiver_bipupu_id": log.receiver_bipupu_id,
            "status": str(log.status.value) if hasattr(log.status, 'value') else str(log.status),
            "content_preview": log.content_preview,
            "error_message": log.error_message,
            "retry_count": log.retry_count,
            "task_id": log.task_id,
            "created_at": log.created_at.isoformat() if log.created_at else None,
            "started_at": log.started_at.isoformat() if log.started_at else None,
            "completed_at": log.completed_at.isoformat() if log.completed_at else None,
        }
        for log in logs
    ]

    return {"items": items, "total": total, "skip": skip, "limit": limit}


@router.delete("/logs/cleanup", tags=["推送服务"])
async def cleanup_push_logs(
    days: int = Query(30, ge=7, description="保留最近 N 天，更早的 success/failed 日志将被删除"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """清理旧推送日志（管理员）"""
    _require_admin(current_user)
    try:
        push_service = PushService(db)
        result = await push_service.cleanup_old_logs(days=days)
        return {"success": True, "data": result}
    except Exception as e:
        logger.error(f"清理推送日志失败: {e}")
        raise HTTPException(status_code=500, detail=f"清理失败: {str(e)}")

