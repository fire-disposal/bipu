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


@router.post("/", response_model=ContactResponse, status_code=status.HTTP_201_CREATED)
async def add_contact(
    contact_data: ContactCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """添加联系人"""
    # 查找联系人用户
    contact_user = db.query(User).filter(User.bipupu_id == contact_data.contact_id).first()
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
    
    # 构造响应
    return {
        "id": new_contact.id,
        "contact_id": contact_user.id,
        "contact_bipupu_id": contact_user.bipupu_id,
        "contact_username": contact_user.username,
        "contact_nickname": contact_user.nickname,
        "alias": new_contact.alias,
        "created_at": new_contact.created_at
    }


@router.get("/", response_model=ContactListResponse)
async def get_contacts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取联系人列表"""
    contacts = db.query(TrustedContact).filter(
        TrustedContact.owner_id == current_user.id
    ).all()
    
    contact_responses = []
    for contact in contacts:
        contact_user = db.query(User).filter(User.id == contact.contact_id).first()
        if contact_user:
            contact_responses.append({
                "id": contact.id,
                "contact_id": contact_user.id,
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


@router.put("/{contact_id}")
async def update_contact(
    contact_id: int,
    contact_update: ContactUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新联系人（主要是更新备注）"""
    contact = db.query(TrustedContact).filter(
        TrustedContact.id == contact_id,
        TrustedContact.owner_id == current_user.id
    ).first()
    
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    
    if contact_update.alias is not None:
        contact.alias = contact_update.alias
    
    db.commit()
    db.refresh(contact)
    
    logger.info(f"User {current_user.bipupu_id} updated contact {contact_id}")
    
    return {"message": "Contact updated successfully"}


@router.delete("/{contact_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_contact(
    contact_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """删除联系人"""
    contact = db.query(TrustedContact).filter(
        TrustedContact.id == contact_id,
        TrustedContact.owner_id == current_user.id
    ).first()
    
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    
    db.delete(contact)
    db.commit()
    
    logger.info(f"User {current_user.bipupu_id} deleted contact {contact_id}")
    
    return None
