"""联系人路由 - 优化版本

设计原则：
1. 精简：使用优化后的数据模型
2. 安全：严格的权限验证
3. 实用：提供核心联系人功能
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.models.user import User
from app.models.trusted_contact import TrustedContact
from app.schemas.contact import (
    ContactCreate, ContactUpdate, ContactResponse, ContactListResponse
)
from app.schemas.common import SuccessResponse
from app.core.security import get_current_user
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/", response_model=ContactListResponse)
async def get_contacts(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取联系人列表

    参数：
    - page: 页码（从1开始）
    - page_size: 每页数量（1-100）

    返回：
    - 成功：返回联系人列表
    - 失败：400（参数错误）
    """
    try:
        # 查询联系人
        query = db.query(TrustedContact).filter(
            TrustedContact.user_id == current_user.id
        )

        # 计算总数
        total = query.count()

        # 分页查询
        contacts = query.order_by(TrustedContact.created_at.desc()) \
            .offset((page - 1) * page_size) \
            .limit(page_size) \
            .all()

        # 构建响应
        contact_responses = []
        for contact in contacts:
            # 获取联系人用户信息
            contact_user = db.query(User).filter(
                User.bipupu_id == contact.contact_bipupu_id,
                User.is_active == True
            ).first()

            if contact_user:
                contact_responses.append(ContactResponse.model_validate({
                    "id": contact.id,
                    "contact_id": contact.contact_bipupu_id,
                    "contact_username": contact_user.username,
                    "contact_nickname": contact_user.nickname,
                    "alias": contact.alias,
                    "created_at": contact.created_at
                }))

        return ContactListResponse(
            contacts=contact_responses,
            total=total,
            page=page,
            page_size=page_size
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取联系人列表失败: {e}")
        raise HTTPException(status_code=500, detail="获取联系人列表失败")


@router.post("/", response_model=ContactResponse, status_code=status.HTTP_201_CREATED)
async def create_contact(
    contact_data: ContactCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """添加联系人

    参数：
    - contact_id: 联系人用户ID
    - alias: 备注名（可选，最多50字符）

    返回：
    - 成功：返回创建的联系人
    - 失败：400（参数错误）或404（用户不存在）或409（已是联系人）
    """
    try:
        # 检查联系人用户是否存在
        contact_user = db.query(User).filter(
            User.bipupu_id == contact_data.contact_id,
            User.is_active == True
        ).first()

        if not contact_user:
            raise HTTPException(status_code=404, detail="用户不存在")

        # 检查是否已经是联系人
        existing_contact = db.query(TrustedContact).filter(
            TrustedContact.user_id == current_user.id,
            TrustedContact.contact_bipupu_id == contact_data.contact_id
        ).first()

        if existing_contact:
            raise HTTPException(status_code=409, detail="已是联系人")

        # 检查是否是自己
        if contact_data.contact_id == current_user.bipupu_id:
            raise HTTPException(status_code=400, detail="不能添加自己为联系人")

        # 创建联系人
        contact = TrustedContact(
            user_id=current_user.id,
            contact_bipupu_id=contact_data.contact_id,
            alias=contact_data.alias
        )

        db.add(contact)
        db.commit()
        db.refresh(contact)

        logger.info(f"添加联系人成功: user_id={current_user.id}, contact_id={contact_data.contact_id}")
        return ContactResponse.model_validate({
            "id": contact.id,
            "contact_id": contact.contact_bipupu_id,
            "contact_username": contact_user.username,
            "contact_nickname": contact_user.nickname,
            "alias": contact.alias,
            "created_at": contact.created_at
        })

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"添加联系人失败: {e}")
        raise HTTPException(status_code=500, detail="添加联系人失败")


@router.put("/{contact_id}", response_model=SuccessResponse)
async def update_contact(
    contact_id: str,
    contact_data: ContactUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新联系人备注

    参数：
    - contact_id: 联系人用户ID
    - alias: 新的备注名（可选，最多50字符）

    返回：
    - 成功：返回更新成功消息
    - 失败：404（联系人不存在）
    """
    try:
        # 查找联系人
        contact = db.query(TrustedContact).filter(
            TrustedContact.user_id == current_user.id,
            TrustedContact.contact_bipupu_id == contact_id
        ).first()

        if not contact:
            raise HTTPException(status_code=404, detail="联系人不存在")

        # 更新备注
        if contact_data.alias is not None:
            contact.alias = contact_data.alias

        db.add(contact)
        db.commit()

        logger.info(f"更新联系人备注成功: user_id={current_user.id}, contact_id={contact_id}")
        return SuccessResponse(message="联系人备注更新成功")

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"更新联系人备注失败: {e}")
        raise HTTPException(status_code=500, detail="更新联系人备注失败")


@router.delete("/{contact_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_contact(
    contact_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """删除联系人

    参数：
    - contact_id: 联系人用户ID

    返回：
    - 成功：204 No Content
    - 失败：404（联系人不存在）
    """
    try:
        # 查找联系人
        contact = db.query(TrustedContact).filter(
            TrustedContact.user_id == current_user.id,
            TrustedContact.contact_bipupu_id == contact_id
        ).first()

        if not contact:
            raise HTTPException(status_code=404, detail="联系人不存在")

        # 删除联系人
        db.delete(contact)
        db.commit()

        logger.info(f"删除联系人成功: user_id={current_user.id}, contact_id={contact_id}")

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"删除联系人失败: {e}")
        raise HTTPException(status_code=500, detail="删除联系人失败")
