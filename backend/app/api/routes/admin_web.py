from fastapi import APIRouter, Request, Depends, Form, HTTPException
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from datetime import datetime, time
from fastapi.responses import RedirectResponse
import logging
from app.models.service_account import ServiceAccount
from app.models.push_log import PushLog
from fastapi import UploadFile, File
from app.db.database import get_db
from app.models.user import User
from app.models.message import Message
from app.models.poster import Poster

from app.core.security import (
    get_current_superuser_web,
    authenticate_user,
    create_access_token,
)

logger = logging.getLogger(__name__)


router = APIRouter()
templates = Jinja2Templates(directory="templates")


@router.get("/login")
async def admin_login_page(request: Request):
    """管理后台登录页面"""
    return templates.TemplateResponse("login.html", {"request": request})


@router.post("/login")
async def admin_login(
    request: Request,
    username: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_db),
):
    """处理管理后台登录"""
    user = authenticate_user(db, username, password)
    if not user:
        return templates.TemplateResponse(
            "login.html", {"request": request, "error": "用户名或密码错误"}
        )

    if not user.is_superuser:
        return templates.TemplateResponse(
            "login.html", {"request": request, "error": "没有管理员权限"}
        )

    # 创建访问令牌
    access_token = create_access_token(data={"sub": str(user.id)})

    # 创建响应并设置cookie
    response = RedirectResponse(url="/admin", status_code=302)
    response.set_cookie(
        key="access_token",
        value=f"Bearer {access_token}",
        httponly=True,
        max_age=1800,  # 30分钟
        expires=1800,
    )

    return response


@router.post("/logout")
async def admin_logout():
    """处理管理后台登出"""
    response = RedirectResponse(url="/admin/login", status_code=302)
    response.delete_cookie(key="access_token")
    return response


@router.get("/")
async def admin_dashboard(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """管理后台仪表板"""
    from app.services.stats_service import StatsService

    # 获取统计数据 (使用重构后的服务)
    stats = StatsService.get_dashboard_stats(db)

    # 最近用户
    recent_users = db.query(User).order_by(User.created_at.desc()).limit(5).all()

    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "stats": stats,  # 注意: 模板中可能需要调整 data structure usage，改为 stats.users.total 形式
            "recent_users": recent_users,
            "current_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        },
    )


@router.get("/users")
async def admin_users(
    request: Request,
    page: int = 1,
    per_page: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """用户管理页面"""
    offset = (page - 1) * per_page
    users = db.query(User).offset(offset).limit(per_page).all()
    total = db.query(User).count()

    return templates.TemplateResponse(
        "users.html",
        {
            "request": request,
            "users": users,
            "page": page,
            "per_page": per_page,
            "total": total,
            "total_pages": (total + per_page - 1) // per_page,
        },
    )


@router.get("/users/{user_id}")
async def admin_user_detail(
    request: Request,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """用户详情页面"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return templates.TemplateResponse(
        "user_detail.html", {"request": request, "user": user}
    )


@router.post("/users/{user_id}/toggle")
async def toggle_user_status(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """切换用户激活状态（启用/禁用）"""
    from app.services.user_service import UserService
    from app.core.exceptions import NotFoundException

    try:
        user = UserService.toggle_user_status(db, user_id)
        return {
            "message": f"用户状态已{'启用' if user.is_active else '禁用'}",
            "is_active": user.is_active,
        }
    except NotFoundException as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"切换用户状态失败: {e}")
        raise HTTPException(status_code=500, detail="操作失败")


@router.get("/messages")
async def admin_messages(
    request: Request,
    page: int = 1,
    per_page: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """消息管理页面"""
    offset = (page - 1) * per_page
    messages = (
        db.query(Message)
        .order_by(Message.created_at.desc())
        .offset(offset)
        .limit(per_page)
        .all()
    )
    total = db.query(Message).count()

    return templates.TemplateResponse(
        "messages.html",
        {
            "request": request,
            "messages": messages,
            "page": page,
            "per_page": per_page,
            "total": total,
            "total_pages": (total + per_page - 1) // per_page,
        },
    )


@router.get("/posters")
async def posters_page(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """海报管理页面"""
    posters = (
        db.query(Poster).order_by(Poster.display_order.asc(), Poster.id.asc()).all()
    )
    return templates.TemplateResponse(
        "posters.html", {"request": request, "posters": posters}
    )


@router.get("/service_accounts")
async def admin_services(
    request: Request,
    page: int = 1,
    per_page: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """服务号管理页面"""
    offset = (page - 1) * per_page
    services = db.query(ServiceAccount).offset(offset).limit(per_page).all()
    total = db.query(ServiceAccount).count()

    return templates.TemplateResponse(
        "service_accounts.html",
        {
            "request": request,
            "services": services,
            "page": page,
            "per_page": per_page,
            "total": total,
            "total_pages": (total + per_page - 1) // per_page,
        },
    )


@router.post("/service_accounts/{service_id}/toggle")
async def toggle_service_status(
    service_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """切换服务号激活状态"""
    service = db.query(ServiceAccount).filter(ServiceAccount.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    try:
        service.is_active = not service.is_active
        db.commit()

        return RedirectResponse(url="/admin/service_accounts", status_code=302)
    except Exception as e:
        db.rollback()
        logger.error(f"切换服务号状态失败: {e}")
        raise HTTPException(status_code=500, detail="操作失败")


@router.post("/service_accounts/{service_id}/avatar")
async def upload_service_avatar(
    service_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """上传服务号头像"""
    service = db.query(ServiceAccount).filter(ServiceAccount.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    try:
        from app.services.storage_service import StorageService
        # 使用StorageService处理头像压缩

        # 验证文件类型
        if not file.content_type or not file.content_type.startswith("image/"):
            raise HTTPException(
                status_code=400, detail="请上传图片文件（支持JPG、PNG等格式）"
            )

        # 使用StorageService处理头像压缩
        try:
            avatar_data = await StorageService.save_avatar(file)
        except ValueError as e:
            # 处理StorageService抛出的具体错误
            raise HTTPException(status_code=400, detail=str(e))
        except Exception as e:
            logger.error(f"服务号头像处理失败: {e}")
            raise HTTPException(
                status_code=500, detail="头像处理失败，请确保图片格式正确且尺寸合理"
            )

        # 更新数据库
        try:
            service.avatar_data = avatar_data
            db.commit()

            return RedirectResponse(url="/admin/service_accounts", status_code=302)
        except Exception as e:
            db.rollback()
            logger.error(f"上传服务号头像失败: {e}")
            raise HTTPException(status_code=500, detail="操作失败")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"服务号头像上传失败: {e}")
        raise HTTPException(status_code=500, detail=f"头像上传失败: {str(e)}")


@router.post("/service_accounts/{service_id}/push-time")
async def update_service_push_time(
    service_id: int,
    push_time: str = Form(...),
    description: str = Form(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """更新服务号推送时间和描述"""
    service = db.query(ServiceAccount).filter(ServiceAccount.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    try:
        # 解析推送时间
        try:
            hour, minute = map(int, push_time.split(":"))
            if not (0 <= hour <= 23 and 0 <= minute <= 59):
                raise ValueError("时间格式无效")
            service.default_push_time = time(hour, minute)
        except (ValueError, AttributeError):
            raise HTTPException(
                status_code=400, detail="时间格式无效，请使用 HH:MM 格式"
            )

        # 更新描述（如果提供）
        if description is not None:
            service.description = description

        db.commit()

        return RedirectResponse(url="/admin/service_accounts", status_code=302)
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"更新服务号推送时间失败: {e}")
        raise HTTPException(status_code=500, detail="操作失败")


@router.post("/service_accounts/{service_name}/trigger-push")
async def trigger_service_push(
    service_name: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """立即触发服务号推送任务（无视时间和用户限制）"""
    from app.models.service_account import ServiceAccount
    from app.services.service_accounts import broadcast_push

    # 检查服务号是否存在
    service = (
        db.query(ServiceAccount).filter(ServiceAccount.name == service_name).first()
    )
    if not service:
        return RedirectResponse(
            url=f"/admin/service_accounts?error=Service {service_name} not found",
            status_code=302,
        )

    # 获取所有订阅者
    subscribers = service.subscribers
    if not subscribers:
        return RedirectResponse(
            url=f"/admin/service_accounts?msg=No subscribers for {service_name}",
            status_code=302,
        )

    # 触发推送任务（内容由send_push自动生成）
    try:
        success_count = await broadcast_push(db, service_name, None, None)

        # 构建详细反馈信息
        if success_count > 0:
            msg = f"✅ 推送成功发送给 {success_count} 位订阅者"
        else:
            msg = "⚠️ 推送失败：没有订阅者或发送失败"

    except Exception as e:
        logger.error(f"触发推送任务失败: {e}")
        return RedirectResponse(
            url=f"/admin/service_accounts?error=Failed to trigger push: {str(e)}",
            status_code=302,
        )

    return RedirectResponse(url=f"/admin/service_accounts?msg={msg}", status_code=302)


@router.get("/push_logs")
async def admin_push_logs(
    request: Request,
    page: int = 1,
    per_page: int = 50,
    status: str = None,  # type: ignore
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """消息推送日志查看页面"""
    from sqlalchemy import desc
    
    offset = (page - 1) * per_page
    
    # 构建查询
    query = db.query(PushLog).order_by(desc(PushLog.created_at))
    
    # 按状态过滤
    if status and status != 'all':
        query = query.filter(PushLog.status == status)
    
    # 获取总数
    total = query.count()
    
    # 获取分页数据
    logs = query.offset(offset).limit(per_page).all()
    
    # 计算统计信息
    all_logs = db.query(PushLog).all()
    stats = {
        'total': len(all_logs),
        'success': len([l for l in all_logs if l.status == 'success']),
        'failed': len([l for l in all_logs if l.status == 'failed']),
        'processing': len([l for l in all_logs if l.status == 'processing']),
        'pending': len([l for l in all_logs if l.status == 'pending']),
    }
    
    return templates.TemplateResponse(
        "push_logs.html",
        {
            "request": request,
            "logs": logs,
            "page": page,
            "per_page": per_page,
            "total": total,
            "total_pages": (total + per_page - 1) // per_page,
            "stats": stats,
            "current_status": status or 'all',
        },
    )


@router.get("/push_logs/{log_id}/detail")
async def get_push_log_detail(
    log_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web),
):
    """获取推送日志详情（JSON格式）"""
    log = db.query(PushLog).filter(PushLog.id == log_id).first()
    if not log:
        raise HTTPException(status_code=404, detail="Push log not found")
    
    return {
        "id": log.id,
        "service_name": log.service_name,
        "receiver_bipupu_id": log.receiver_bipupu_id,
        "status": log.status.value if log.status else None,
        "content_preview": log.content_preview,
        "error_message": log.error_message,
        "retry_count": log.retry_count,
        "max_retries": log.max_retries,
        "task_id": log.task_id,
        "task_name": log.task_name,
        "extra_data": log.extra_data,
        "created_at": log.created_at.isoformat() if log.created_at else None,
        "started_at": log.started_at.isoformat() if log.started_at else None,
        "completed_at": log.completed_at.isoformat() if log.completed_at else None,
    }
