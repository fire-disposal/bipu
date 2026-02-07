from fastapi import APIRouter, Request, Depends, Form, HTTPException
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from datetime import datetime
from fastapi.responses import RedirectResponse

from app.db.database import get_db
from app.models.user import User
from app.models.message import Message
from app.models.subscription import SubscriptionType, UserSubscription
from app.core.security import get_current_superuser_web, authenticate_user, create_access_token

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
    # 获取统计数据
    total_users = db.query(User).count()
    active_users = db.query(User).filter(User.is_active).count()
    total_messages = db.query(Message).count()
    
    # 最近用户
    recent_users = db.query(User).order_by(User.created_at.desc()).limit(5).all()
    
    return templates.TemplateResponse("index.html", {
        "request": request,
        "stats": {
            "total_users": total_users,
            "active_users": active_users,
            "total_messages": total_messages
        },
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
    messages = db.query(Message).offset(offset).limit(per_page).all()
    total = db.query(Message).count()
    
    return templates.TemplateResponse("messages.html", {
        "request": request,
        "messages": messages,
        "page": page,
        "per_page": per_page,
        "total": total,
        "total_pages": (total + per_page - 1) // per_page
    })

@router.get("/subscriptions", tags=["管理后台"])
async def admin_subscriptions(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """订阅管理页面"""
    # 获取订阅类型
    subscription_types = db.query(SubscriptionType).all()
    
    # 获取订阅统计
    subscription_stats = []
    for sub_type in subscription_types:
        count = db.query(UserSubscription).filter(
            UserSubscription.subscription_type_id == sub_type.id,
            UserSubscription.is_enabled
        ).count()
        subscription_stats.append({
            "type_name": sub_type.name,
            "count": count
        })
    
    # 获取用户订阅列表
    user_subscriptions = db.query(UserSubscription).join(User).join(SubscriptionType).limit(50).all()
    
    return templates.TemplateResponse("subscriptions.html", {
        "request": request,
        "subscription_types": subscription_types,
        "subscription_stats": subscription_stats,
        "user_subscriptions": user_subscriptions
    })