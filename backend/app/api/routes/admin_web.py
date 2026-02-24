from fastapi import APIRouter, Request, Depends, Form, HTTPException
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from datetime import datetime, time, timezone
from fastapi.responses import RedirectResponse
import logging

logger = logging.getLogger(__name__)

from app.db.database import get_db
from app.models.user import User
from app.models.message import Message
from app.models.poster import Poster
from app.models.trusted_contact import TrustedContact
from app.models.user_block import UserBlock
from app.core.security import get_current_superuser_web, authenticate_user, create_access_token
from app.services.message_service import MessageService
from app.schemas.message import MessageCreate

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
    access_token = create_access_token(data={"sub": user.id})

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


@router.post("/users/{user_id}/toggle", tags=["管理后台"])
async def toggle_user_status(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """切换用户激活状态（启用/禁用）"""
    from app.services.user_service import UserService
    from app.core.exceptions import NotFoundException

    try:
        user = UserService.toggle_user_status(db, user_id)
        return {"message": f"用户状态已{'启用' if user.is_active else '禁用'}", "is_active": user.is_active}
    except NotFoundException as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"切换用户状态失败: {e}")
        raise HTTPException(status_code=500, detail="操作失败")

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

@router.get("/posters", tags=["管理后台"])
async def posters_page(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """海报管理页面"""
    posters = db.query(Poster).order_by(Poster.display_order.asc(), Poster.id.asc()).all()
    return templates.TemplateResponse("posters.html", {
        "request": request,
        "posters": posters
    })

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

    try:
        service.is_active = not service.is_active
        db.commit()

        return RedirectResponse(url="/admin/service_accounts", status_code=302)
    except Exception as e:
        db.rollback()
        logger.error(f"切换服务号状态失败: {e}")
        raise HTTPException(status_code=500, detail="操作失败")

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
        # 使用StorageService处理头像压缩

        # 验证文件类型
        if not file.content_type or not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="请上传图片文件")

        # 使用StorageService处理头像压缩
        avatar_data = await StorageService.save_avatar(file)

        # 更新数据库
        try:
            service.avatar_data = avatar_data
            service.increment_avatar_version()  # 增加版本号，使缓存失效
            db.commit()

            return RedirectResponse(url="/admin/service_accounts", status_code=302)
        except Exception as e:
            db.rollback()
            logger.error(f"上传服务号头像失败: {e}")
            raise HTTPException(status_code=500, detail="操作失败")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/service_accounts/{service_id}/push-time", tags=["管理后台"])
async def update_service_push_time(
    service_id: int,
    push_time: str = Form(...),
    description: str = Form(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """更新服务号推送时间和描述"""
    service = db.query(ServiceAccount).filter(ServiceAccount.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    try:
        # 解析推送时间
        try:
            hour, minute = map(int, push_time.split(':'))
            if not (0 <= hour <= 23 and 0 <= minute <= 59):
                raise ValueError("时间格式无效")
            service.default_push_time = time(hour, minute)
        except (ValueError, AttributeError):
            raise HTTPException(status_code=400, detail="时间格式无效，请使用 HH:MM 格式")

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

@router.post("/service_accounts/{service_name}/trigger-push", tags=["管理后台"])
async def trigger_service_push(
    service_name: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """立即触发服务号推送任务（无视时间和用户限制）"""
    from app.models.service_account import ServiceAccount
    from app.services.service_accounts import broadcast_push

    # 检查服务号是否存在
    service = db.query(ServiceAccount).filter(ServiceAccount.name == service_name).first()
    if not service:
        return RedirectResponse(url=f"/admin/service_accounts?error=Service {service_name} not found", status_code=302)

    # 获取所有订阅者
    subscribers = service.subscribers
    if not subscribers:
        return RedirectResponse(url=f"/admin/service_accounts?msg=No subscribers for {service_name}", status_code=302)

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
        return RedirectResponse(url=f"/admin/service_accounts?error=Failed to trigger push: {str(e)}", status_code=302)

    return RedirectResponse(url=f"/admin/service_accounts?msg={msg}", status_code=302)


# 需要导入 send_push 函数
from app.services.service_accounts import send_push
from app.services.storage_service import StorageService
from typing import Optional

@router.get("/test_contacts", tags=["管理后台"])
async def admin_test_contacts(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """API测试页面 (联系人与黑名单)"""
    # 获取当前用户的联系人列表
    contacts_query = db.query(TrustedContact).filter(
        TrustedContact.owner_id == current_user.id
    ).all()

    contacts = []
    for contact in contacts_query:
        contact_user = db.query(User).filter(User.id == contact.contact_id).first()
        if contact_user:
            contacts.append({
                "id": contact.id,
                "contact_bipupu_id": contact_user.bipupu_id,
                "contact_username": contact_user.username,
                "contact_nickname": contact_user.nickname,
                "alias": contact.alias,
                "created_at": contact.created_at
            })

    # 获取当前用户的黑名单列表
    blacklist_query = db.query(UserBlock).filter(
        UserBlock.blocker_id == current_user.id
    ).all()

    blacklist = []
    for block in blacklist_query:
        blocked_user = db.query(User).filter(User.id == block.blocked_id).first()
        if blocked_user:
            blacklist.append({
                "id": block.id,
                "blocked_bipupu_id": blocked_user.bipupu_id,
                "blocked_username": blocked_user.username,
                "blocked_nickname": blocked_user.nickname,
                "created_at": block.created_at
            })

    return templates.TemplateResponse("test_contacts.html", {
        "request": request,
        "user": current_user,
        "contacts": contacts,
        "blacklist": blacklist
    })

@router.post("/test_contacts/add", tags=["管理后台"])
async def admin_add_contact(
    request: Request,
    contact_bipupu_id: str = Form(...),
    alias: Optional[str] = Form(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """处理添加联系人测试"""
    try:
        # 查找联系人用户
        contact_user = db.query(User).filter(User.bipupu_id == contact_bipupu_id).first()
        if not contact_user:
            raise HTTPException(status_code=404, detail="用户不存在")

        # 不能添加自己为联系人
        if contact_user.id == current_user.id:
            raise HTTPException(status_code=400, detail="不能添加自己为联系人")

        # 检查是否已经是联系人
        existing = db.query(TrustedContact).filter(
            TrustedContact.owner_id == current_user.id,
            TrustedContact.contact_id == contact_user.id
        ).first()

        if existing:
            raise HTTPException(status_code=400, detail="该用户已经是联系人")

        # 创建联系人关系
        new_contact = TrustedContact(
            owner_id=current_user.id,
            contact_id=contact_user.id,
            alias=alias
        )

        db.add(new_contact)
        db.commit()

        # 重新加载页面
        return await admin_test_contacts(request, db, current_user)

    except HTTPException as e:
        # 重新加载页面并显示错误
        contacts_query = db.query(TrustedContact).filter(
            TrustedContact.owner_id == current_user.id
        ).all()

        contacts = []
        for contact in contacts_query:
            contact_user = db.query(User).filter(User.id == contact.contact_id).first()
            if contact_user:
                contacts.append({
                    "id": contact.id,
                    "contact_bipupu_id": contact_user.bipupu_id,
                    "contact_username": contact_user.username,
                    "contact_nickname": contact_user.nickname,
                    "alias": contact.alias,
                    "created_at": contact.created_at
                })

        blacklist_query = db.query(UserBlock).filter(
            UserBlock.blocker_id == current_user.id
        ).all()

        blacklist = []
        for block in blacklist_query:
            blocked_user = db.query(User).filter(User.id == block.blocked_id).first()
            if blocked_user:
                blacklist.append({
                    "id": block.id,
                    "blocked_bipupu_id": blocked_user.bipupu_id,
                    "blocked_username": blocked_user.username,
                    "blocked_nickname": blocked_user.nickname,
                    "created_at": block.created_at
                })

        return templates.TemplateResponse("test_contacts.html", {
            "request": request,
            "user": current_user,
            "contacts": contacts,
            "blacklist": blacklist,
            "error": f"添加联系人失败: {e.detail}"
        })
    except Exception as e:
        # 重新加载页面并显示错误
        contacts_query = db.query(TrustedContact).filter(
            TrustedContact.owner_id == current_user.id
        ).all()

        contacts = []
        for contact in contacts_query:
            contact_user = db.query(User).filter(User.id == contact.contact_id).first()
            if contact_user:
                contacts.append({
                    "id": contact.id,
                    "contact_bipupu_id": contact_user.bipupu_id,
                    "contact_username": contact_user.username,
                    "contact_nickname": contact_user.nickname,
                    "alias": contact.alias,
                    "created_at": contact.created_at
                })

        blacklist_query = db.query(UserBlock).filter(
            UserBlock.blocker_id == current_user.id
        ).all()

        blacklist = []
        for block in blacklist_query:
            blocked_user = db.query(User).filter(User.id == block.blocked_id).first()
            if blocked_user:
                blacklist.append({
                    "id": block.id,
                    "blocked_bipupu_id": blocked_user.bipupu_id,
                    "blocked_username": blocked_user.username,
                    "blocked_nickname": blocked_user.nickname,
                    "created_at": block.created_at
                })

        return templates.TemplateResponse("test_contacts.html", {
            "request": request,
            "user": current_user,
            "contacts": contacts,
            "blacklist": blacklist,
            "error": f"添加联系人失败: {str(e)}"
        })

@router.post("/test_contacts/remove", tags=["管理后台"])
async def admin_remove_contact(
    request: Request,
    contact_id: int = Form(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """处理删除联系人测试"""
    try:
        # 查找联系人
        contact = db.query(TrustedContact).filter(
            TrustedContact.id == contact_id,
            TrustedContact.owner_id == current_user.id
        ).first()

        if not contact:
            raise HTTPException(status_code=404, detail="联系人不存在")

        db.delete(contact)
        db.commit()

        # 重新加载页面
        return await admin_test_contacts(request, db, current_user)

    except HTTPException as e:
        # 重新加载页面并显示错误
        return await admin_test_contacts(request, db, current_user)
    except Exception as e:
        # 重新加载页面并显示错误
        contacts_query = db.query(TrustedContact).filter(
            TrustedContact.owner_id == current_user.id
        ).all()

        contacts = []
        for contact in contacts_query:
            contact_user = db.query(User).filter(User.id == contact.contact_id).first()
            if contact_user:
                contacts.append({
                    "id": contact.id,
                    "contact_bipupu_id": contact_user.bipupu_id,
                    "contact_username": contact_user.username,
                    "contact_nickname": contact_user.nickname,
                    "alias": contact.alias,
                    "created_at": contact.created_at
                })

        blacklist_query = db.query(UserBlock).filter(
            UserBlock.blocker_id == current_user.id
        ).all()

        blacklist = []
        for block in blacklist_query:
            blocked_user = db.query(User).filter(User.id == block.blocked_id).first()
            if blocked_user:
                blacklist.append({
                    "id": block.id,
                    "blocked_bipupu_id": blocked_user.bipupu_id,
                    "blocked_username": blocked_user.username,
                    "blocked_nickname": blocked_user.nickname,
                    "created_at": block.created_at
                })

        return templates.TemplateResponse("test_contacts.html", {
            "request": request,
            "user": current_user,
            "contacts": contacts,
            "blacklist": blacklist,
            "error": f"删除联系人失败: {str(e)}"
        })

@router.post("/test_contacts/block", tags=["管理后台"])
async def admin_block_user(
    request: Request,
    blocked_bipupu_id: str = Form(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """处理添加黑名单测试"""
    try:
        # 查找要拉黑的用户
        blocked_user = db.query(User).filter(User.bipupu_id == blocked_bipupu_id).first()
        if not blocked_user:
            raise HTTPException(status_code=404, detail="用户不存在")

        # 不能拉黑自己
        if blocked_user.id == current_user.id:
            raise HTTPException(status_code=400, detail="不能拉黑自己")

        # 检查是否已经在黑名单中
        existing = db.query(UserBlock).filter(
            UserBlock.blocker_id == current_user.id,
            UserBlock.blocked_id == blocked_user.id
        ).first()

        if existing:
            raise HTTPException(status_code=400, detail="该用户已在黑名单中")

        # 创建黑名单记录
        new_block = UserBlock(
            blocker_id=current_user.id,
            blocked_id=blocked_user.id
        )

        db.add(new_block)
        db.commit()

        # 重新加载页面
        return await admin_test_contacts(request, db, current_user)

    except HTTPException as e:
        # 重新加载页面并显示错误
        return await admin_test_contacts(request, db, current_user)
    except Exception as e:
        # 重新加载页面并显示错误
        contacts_query = db.query(TrustedContact).filter(
            TrustedContact.owner_id == current_user.id
        ).all()

        contacts = []
        for contact in contacts_query:
            contact_user = db.query(User).filter(User.id == contact.contact_id).first()
            if contact_user:
                contacts.append({
                    "id": contact.id,
                    "contact_bipupu_id": contact_user.bipupu_id,
                    "contact_username": contact_user.username,
                    "contact_nickname": contact_user.nickname,
                    "alias": contact.alias,
                    "created_at": contact.created_at
                })

        blacklist_query = db.query(UserBlock).filter(
            UserBlock.blocker_id == current_user.id
        ).all()

        blacklist = []
        for block in blacklist_query:
            blocked_user = db.query(User).filter(User.id == block.blocked_id).first()
            if blocked_user:
                blacklist.append({
                    "id": block.id,
                    "blocked_bipupu_id": blocked_user.bipupu_id,
                    "blocked_username": blocked_user.username,
                    "blocked_nickname": blocked_user.nickname,
                    "created_at": block.created_at
                })

        return templates.TemplateResponse("test_contacts.html", {
            "request": request,
            "user": current_user,
            "contacts": contacts,
            "blacklist": blacklist,
            "error": f"添加黑名单失败: {str(e)}"
        })

@router.post("/test_contacts/unblock", tags=["管理后台"])
async def admin_unblock_user(
    request: Request,
    blocked_id: int = Form(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """处理移除黑名单测试"""
    try:
        # 查找黑名单记录
        block = db.query(UserBlock).filter(
            UserBlock.id == blocked_id,
            UserBlock.blocker_id == current_user.id
        ).first()

        if not block:
            raise HTTPException(status_code=404, detail="黑名单记录不存在")

        db.delete(block)
        db.commit()

        # 重新加载页面
        return await admin_test_contacts(request, db, current_user)

    except HTTPException as e:
        # 重新加载页面并显示错误
        return await admin_test_contacts(request, db, current_user)
    except Exception as e:
        # 重新加载页面并显示错误
        contacts_query = db.query(TrustedContact).filter(
            TrustedContact.owner_id == current_user.id
        ).all()

        contacts = []
        for contact in contacts_query:
            contact_user = db.query(User).filter(User.id == contact.contact_id).first()
            if contact_user:
                contacts.append({
                    "id": contact.id,
                    "contact_bipupu_id": contact_user.bipupu_id,
                    "contact_username": contact_user.username,
                    "contact_nickname": contact_user.nickname,
                    "alias": contact.alias,
                    "created_at": contact.created_at
                })

        blacklist_query = db.query(UserBlock).filter(
            UserBlock.blocker_id == current_user.id
        ).all()

        blacklist = []
        for block in blacklist_query:
            blocked_user = db.query(User).filter(User.id == block.blocked_id).first()
            if blocked_user:
                blacklist.append({
                    "id": block.id,
                    "blocked_bipupu_id": blocked_user.bipupu_id,
                    "blocked_username": blocked_user.username,
                    "blocked_nickname": blocked_user.nickname,
                    "created_at": block.created_at
                })

        return templates.TemplateResponse("test_contacts.html", {
            "request": request,
            "user": current_user,
            "contacts": contacts,
            "blacklist": blacklist,
            "error": f"移除黑名单失败: {str(e)}"
        })

@router.get("/test_profile", tags=["管理后台"])
async def admin_test_profile(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """API测试页面 (用户资料设置)"""
    return templates.TemplateResponse("test_profile.html", {
        "request": request,
        "user": current_user
    })

@router.post("/test_profile/avatar", tags=["管理后台"])
async def admin_update_avatar(
    request: Request,
    avatar_file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """处理更新头像测试"""
    try:
        # 使用StorageService处理头像
        avatar_data = await StorageService.save_avatar(avatar_file)

        # 更新用户头像
        current_user.avatar_data = avatar_data
        current_user.avatar_version = (current_user.avatar_version or 0) + 1
        db.commit()
        db.refresh(current_user)

        return templates.TemplateResponse("test_profile.html", {
            "request": request,
            "user": current_user,
            "success": "头像更新成功"
        })

    except Exception as e:
        return templates.TemplateResponse("test_profile.html", {
            "request": request,
            "user": current_user,
            "error": f"头像更新失败: {str(e)}"
        })

@router.post("/test_profile/avatar/delete", tags=["管理后台"])
async def admin_delete_avatar(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """处理删除头像测试"""
    try:
        # 删除用户头像
        current_user.avatar_data = None
        current_user.avatar_version = (current_user.avatar_version or 0) + 1
        db.commit()
        db.refresh(current_user)

        return templates.TemplateResponse("test_profile.html", {
            "request": request,
            "user": current_user,
            "success": "头像删除成功"
        })

    except Exception as e:
        return templates.TemplateResponse("test_profile.html", {
            "request": request,
            "user": current_user,
            "error": f"头像删除失败: {str(e)}"
        })

@router.post("/test_profile/update", tags=["管理后台"])
async def admin_update_profile(
    request: Request,
    nickname: Optional[str] = Form(None),
    bio: Optional[str] = Form(None),
    gender: Optional[str] = Form(None),
    birth_date: Optional[str] = Form(None),
    location: Optional[str] = Form(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """处理更新用户资料测试"""
    try:
        # 更新用户资料
        update_data = {}
        if nickname is not None:
            update_data['nickname'] = nickname
        if bio is not None:
            update_data['bio'] = bio
        if gender is not None:
            update_data['gender'] = gender
        if birth_date is not None:
            update_data['birth_date'] = birth_date
        if location is not None:
            update_data['location'] = location

        for key, value in update_data.items():
            setattr(current_user, key, value)

        db.commit()
        db.refresh(current_user)

        return templates.TemplateResponse("test_profile.html", {
            "request": request,
            "user": current_user,
            "success": "用户资料更新成功"
        })

    except Exception as e:
        return templates.TemplateResponse("test_profile.html", {
            "request": request,
            "user": current_user,
            "error": f"用户资料更新失败: {str(e)}"
        })

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
    message_type: str = Form(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser_web)
):
    """处理发送消息测试"""
    try:
        msg_data = MessageCreate(
            receiver_id=receiver_id,
            content=content,
            message_type=message_type
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
