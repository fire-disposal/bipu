"""联系人路由 - 替代好友系统"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.models.user import User
from app.models.trusted_contact import TrustedContact
from app.schemas.contact import ContactCreate, ContactUpdate, ContactResponse, ContactListResponse
from app.core.security import get_current_user
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.post("/", response_model=ContactResponse, status_code=status.HTTP_201_CREATED, tags=["联系人"])
async def add_contact(
    contact_data: ContactCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """添加联系人

    参数：
    - contact_bipupu_id: 要添加的联系人的 bipupu_id
    - alias: 可选的联系人备注/别名

    返回：
    - 成功：返回新创建的联系人信息
    - 失败：404（用户不存在）或 400（已是联系人或添加自己）
    """
    # 查找联系人用户
    contact_user = db.query(User).filter(User.bipupu_id == contact_data.contact_bipupu_id).first()
    if not contact_user:
        raise HTTPException(status_code=404, detail="User not found")

    # 不能添加自己为联系人
    if contact_user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot add yourself as contact")

    # 检查是否已经是联系人
    existing = db.query(TrustedContact).filter(
        TrustedContact.owner_id == current_user.id,
        TrustedContact.contact_id == contact_user.id
    ).first()

    if existing:
        raise HTTPException(status_code=400, detail="Contact already exists")

    try:
        # 创建联系人关系
        new_contact = TrustedContact(
            owner_id=current_user.id,
            contact_id=contact_user.id,
            alias=contact_data.alias
        )

        db.add(new_contact)
        db.commit()
        db.refresh(new_contact)

        logger.info(f"User {current_user.bipupu_id} added contact {contact_user.bipupu_id}")

        # 构造响应（返回业务 ID 而非内部主键）
        return {
            "id": new_contact.id,
            "contact_bipupu_id": contact_user.bipupu_id,
            "contact_username": contact_user.username,
            "contact_nickname": contact_user.nickname,
            "alias": new_contact.alias,
            "created_at": new_contact.created_at
        }
    except Exception as e:
        db.rollback()
        logger.error(f"添加联系人失败: {e}")
        raise HTTPException(status_code=500, detail="操作失败")


@router.get("/", response_model=ContactListResponse, tags=["联系人"])
async def get_contacts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取当前用户的联系人列表

    返回：
    - contacts: 联系人列表，包含联系人基本信息及备注
    - total: 联系人总数

    注意：只返回当前用户主动添加的联系人
    """
    contacts = db.query(TrustedContact).filter(
        TrustedContact.owner_id == current_user.id
    ).all()

    contact_responses = []
    for contact in contacts:
        contact_user = db.query(User).filter(User.id == contact.contact_id).first()
        if contact_user:
            contact_responses.append({
                "id": contact.id,
                "contact_bipupu_id": contact_user.bipupu_id,
                "contact_username": contact_user.username,
                "contact_nickname": contact_user.nickname,
                "alias": contact.alias,
                "created_at": contact.created_at
            })

    return {
        "contacts": contact_responses,
        "total": len(contact_responses)
    }


@router.put("/{contact_bipupu_id}", tags=["联系人"])
async def update_contact(
    contact_bipupu_id: str,
    contact_update: ContactUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新联系人备注

    参数：
    - contact_bipupu_id: 要更新的联系人的 bipupu_id
    - alias: 新的联系人备注/别名

    返回：
    - 成功：返回更新成功消息
    - 失败：404（联系人不存在）或 500（数据库操作失败）
    """
    contact_user = db.query(User).filter(User.bipupu_id == contact_bipupu_id).first()
    if not contact_user:
        raise HTTPException(status_code=404, detail="Contact user not found")

    contact = db.query(TrustedContact).filter(
        TrustedContact.owner_id == current_user.id,
        TrustedContact.contact_id == contact_user.id
    ).first()

    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    try:
        if contact_update.alias is not None:
            contact.alias = contact_update.alias

        db.commit()
        db.refresh(contact)

        logger.info(f"User {current_user.bipupu_id} updated contact {contact_user.bipupu_id}")

        return {"message": "Contact updated successfully"}
    except Exception as e:
        db.rollback()
        logger.error(f"更新联系人失败: {e}")
        raise HTTPException(status_code=500, detail="操作失败")


@router.delete("/{contact_bipupu_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["联系人"])
async def delete_contact(
    contact_bipupu_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """删除联系人

    参数：
    - contact_bipupu_id: 要删除的联系人的 bipupu_id

    返回：
    - 成功：204 No Content
    - 失败：404（联系人不存在）或 500（数据库操作失败）
    """
    contact_user = db.query(User).filter(User.bipupu_id == contact_bipupu_id).first()
    if not contact_user:
        raise HTTPException(status_code=404, detail="Contact user not found")

    contact = db.query(TrustedContact).filter(
        TrustedContact.owner_id == current_user.id,
        TrustedContact.contact_id == contact_user.id
    ).first()

    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    try:
        db.delete(contact)
        db.commit()

        logger.info(f"User {current_user.bipupu_id} deleted contact {contact_user.bipupu_id}")

        return None
    except Exception as e:
        db.rollback()
        logger.error(f"删除联系人失败: {e}")
        raise HTTPException(status_code=500, detail="操作失败")
