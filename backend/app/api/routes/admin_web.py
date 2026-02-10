from fastapi import APIRouter, Request, Depends, Form, HTTPException
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from datetime import datetime
from fastapi.responses import RedirectResponse

from app.db.database import get_db
from app.models.user import User
from app.models.message import Message
from app.core.security import get_current_superuser_web, authenticate_user, create_access_token
from app.services.message_service_new import MessageService
from app.schemas.message_new import MessageCreate

router = APIRouter()
templates = Jinja2Templates(directory="templates")

@router.get("/login", tags=["管理后台"])
async def admin_login_page(request: Request):
    """管理后台登录页面"""
    return templates.TemplateResponse("login.html", {"request": request})

@router.post("/login", tags=["管理后台"])
async def admin_login(
    request: Request,
    username: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_db)
):
    """处理管理后台登录"""
    user = authenticate_user(db, username, password)
    if not user:
        return templates.TemplateResponse("login.html", {
            "request": request,
            "error": "用户名或密码错误"
        })
    
    if not user.is_superuser:
        return templates.TemplateResponse("login.html", {
            "request": request,
            "error": "没有管理员权限"
        })
    
    # 创建访问令牌
    access_token = create_access_token(data={"sub": user.username})
    
    # 创建响应并设置cookie
    response = RedirectResponse(url="/admin", status_code=302)
    response.set_cookie(
        key="access_token",
        value=f"Bearer {access_token}",
        httponly=True,
        max_age=1800,  # 30分钟
        expires=1800
    )
    
    return response

@router.post("/logout", tags=["管理后台"])
async def admin_logout():
    """处理管理后台登出"""
    response = RedirectResponse(url="/admin/login", status_code=302)
    response.delete_cookie(key="access_token")
    return response

@router.get("/", tags=["管理后台"])
async def admin_dashboard(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """管理后台仪表板"""
    from app.services.stats_service import StatsService
    
    # 获取统计数据 (使用重构后的服务)
    stats = StatsService.get_dashboard_stats(db)
    
    # 最近用户
    recent_users = db.query(User).order_by(User.created_at.desc()).limit(5).all()
    
    return templates.TemplateResponse("index.html", {
        "request": request,
        "stats": stats, # 注意: 模板中可能需要调整 data structure usage，改为 stats.users.total 形式
        "recent_users": recent_users,
        "current_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })

@router.get("/users", tags=["管理后台"])
async def admin_users(
    request: Request,
    page: int = 1,
    per_page: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """用户管理页面"""
    offset = (page - 1) * per_page
    users = db.query(User).offset(offset).limit(per_page).all()
    total = db.query(User).count()
    
    return templates.TemplateResponse("users.html", {
        "request": request,
        "users": users,
        "page": page,
        "per_page": per_page,
        "total": total,
        "total_pages": (total + per_page - 1) // per_page
    })

@router.get("/users/{user_id}", tags=["管理后台"])
async def admin_user_detail(
    request: Request,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """用户详情页面"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    return templates.TemplateResponse("user_detail.html", {
        "request": request,
        "user": user
    })

@router.get("/messages", tags=["管理后台"])
async def admin_messages(
    request: Request,
    page: int = 1,
    per_page: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """消息管理页面"""
    offset = (page - 1) * per_page
    messages = db.query(Message).order_by(Message.created_at.desc()).offset(offset).limit(per_page).all()
    total = db.query(Message).count()
    
    return templates.TemplateResponse("messages.html", {
        "request": request,
        "messages": messages,
        "page": page,
        "per_page": per_page,
        "total": total,
        "total_pages": (total + per_page - 1) // per_page
    })

from app.models.service_account import ServiceAccount
from fastapi import UploadFile, File

@router.get("/service_accounts", tags=["管理后台"])
async def admin_services(
    request: Request,
    page: int = 1,
    per_page: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """服务号管理页面"""
    offset = (page - 1) * per_page
    services = db.query(ServiceAccount).offset(offset).limit(per_page).all()
    total = db.query(ServiceAccount).count()
    
    return templates.TemplateResponse("service_accounts.html", {
        "request": request,
        "services": services,
        "page": page,
        "per_page": per_page,
        "total": total,
        "total_pages": (total + per_page - 1) // per_page
    })

@router.post("/service_accounts/{service_id}/toggle", tags=["管理后台"])
async def toggle_service_status(
    service_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """切换服务号激活状态"""
    service = db.query(ServiceAccount).filter(ServiceAccount.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    
    service.is_active = not service.is_active
    db.commit()
    
    return RedirectResponse(url="/admin/service_accounts", status_code=302)

@router.post("/service_accounts/{service_id}/avatar", tags=["管理后台"])
async def upload_service_avatar(
    service_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """上传服务号头像"""
    service = db.query(ServiceAccount).filter(ServiceAccount.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    
    try:
        from app.services.storage_service import StorageService
        # 注意: StorageService 默认按 user_id 存，这里需要变通。
        # 我们可以复用逻辑，但要注意 service_id 和 user_id 可能冲突。
        # 最好是重构 StorageService 支持 entity_type/entity_id，
        # 或者 暂时手动读取并存储。
        
        file_content = await file.read()
        service.avatar_data = file_content
        service.avatar_filename = file.filename
        service.avatar_mimetype = file.content_type
        
        db.commit()
        
        return RedirectResponse(url="/admin/service_accounts", status_code=302)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/service_accounts/{service_name}/broadcast", tags=["管理后台"])
async def broadcast_service_message(
    service_name: str,
    content: str = Form(...),
    led_pattern: str = Form(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """服务号广播消息"""
    from app.services.service_accounts import broadcast_message
    
    pattern = None
    if led_pattern:
        pattern = {"led": led_pattern, "animation": "flash"}
        
    count = await broadcast_message(db, service_name, content, pattern)
    
    # 可以在URL参带上结果提示，或者简单跳转
    return RedirectResponse(url=f"/admin/service_accounts?msg=Broadcast sent to {count} users", status_code=302)

@router.get("/test_chat", tags=["管理后台"])
async def admin_test_chat(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """API测试页面 (消息)"""
    # 模拟客户端获取当前用户的消息列表
    # 注意: MessageService 没有直接返回所有消息的方法，通常是分页的
    # 这里直接查库简单展示最近20条
    
    received_messages = db.query(Message).filter(
        Message.receiver_bipupu_id == current_user.bipupu_id
    ).order_by(Message.created_at.desc()).limit(20).all()
    
    sent_messages = db.query(Message).filter(
        Message.sender_bipupu_id == current_user.bipupu_id
    ).order_by(Message.created_at.desc()).limit(20).all()
    
    return templates.TemplateResponse("test_chat.html", {
        "request": request,
        "user": current_user,
        "received_messages": received_messages,
        "sent_messages": sent_messages
    })

@router.post("/test_chat/send", tags=["管理后台"])
async def admin_send_message(
    request: Request,
    receiver_id: str = Form(...),
    content: str = Form(...),
    msg_type: str = Form(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """处理发送消息测试"""
    try:
        msg_data = MessageCreate(
            receiver_id=receiver_id,
            content=content,
            msg_type=msg_type
        )
        
        await MessageService.send_message(db, current_user, msg_data)
        
        # 重新加载页面并显示成功
        # 为了简单起见，这里再走一次查询逻辑，或者直接redirect带参数
        return templates.TemplateResponse("test_chat.html", {
            "request": request,
            "user": current_user,
            "success": f"消息已发送给 {receiver_id}",
            "received_messages": db.query(Message).filter(Message.receiver_bipupu_id == current_user.bipupu_id).order_by(Message.created_at.desc()).limit(20).all(),
            "sent_messages": db.query(Message).filter(Message.sender_bipupu_id == current_user.bipupu_id).order_by(Message.created_at.desc()).limit(20).all()
        })
        
    except Exception as e:
        return templates.TemplateResponse("test_chat.html", {
            "request": request,
            "user": current_user,
            "error": f"发送失败: {str(e)}",
            "received_messages": db.query(Message).filter(Message.receiver_bipupu_id == current_user.bipupu_id).order_by(Message.created_at.desc()).limit(20).all(),
            "sent_messages": db.query(Message).filter(Message.sender_bipupu_id == current_user.bipupu_id).order_by(Message.created_at.desc()).limit(20).all()
        })

