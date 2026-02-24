"""客户端黑名单 API 路由 - 用户业务功能，无需管理员权限"""

from typing import List, Optional, cast
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.db.database import get_db
from app.models.user import User
from app.models.user_block import UserBlock
from app.schemas.user import BlockUserRequest, BlockedUserResponse
from app.schemas.common import PaginationParams, PaginatedResponse, StatusResponse
from app.core.security import get_current_active_user
from app.services.user_service import UserService
from app.core.exceptions import ValidationException, NotFoundException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


def _get_user_by_bipupu_id(db: Session, bipupu_id: str) -> User:
    """通过 bipupu_id 获取用户，如果不存在则抛出 404 异常"""
    user = db.query(User).filter(User.bipupu_id == bipupu_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    return cast(User, user)


def _validate_not_self(current_user: User, target_user: User) -> None:
    """验证目标用户不是当前用户自己"""
    if target_user.id == current_user.id:
        raise HTTPException(status_code=400, detail="不能对自己执行此操作")


@router.post("/blocks", response_model=StatusResponse, tags=["黑名单"])
async def block_user(
    block_request: BlockUserRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """拉黑用户

    参数：
    - bipupu_id: 要拉黑的用户 Bipupu ID（业务 ID）

    返回：
    - 成功：返回操作成功消息
    - 失败：404（用户不存在）或 400（已拉黑或不能拉黑自己）或 500（数据库操作失败）

    注意：
    - 需要用户认证
    - 不能拉黑自己
    - 拉黑后，双方将无法互相发送消息
    - 拉黑关系是单向的
    """
    # 查找要拉黑的用户
    blocked_user = _get_user_by_bipupu_id(db, block_request.bipupu_id)

    # 不能拉黑自己
    _validate_not_self(current_user, blocked_user)

    try:
        # 使用 cast 确保类型正确，blocked_user.id 是 Integer 类型
        UserService.block_user(db, current_user, cast(int, blocked_user.id))
        logger.info(f"用户拉黑成功：{current_user.username} 拉黑 {block_request.bipupu_id}")
        return {"message": "用户已拉黑"}
    except ValidationException as e:
        if "already blocked" in str(e).lower():
            raise HTTPException(status_code=400, detail="用户已在黑名单中")
        elif "cannot block yourself" in str(e).lower():
            raise HTTPException(status_code=400, detail="不能拉黑自己")
        else:
            raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"拉黑用户失败：{str(e)}")
        raise HTTPException(status_code=500, detail="拉黑操作失败")


@router.delete("/blocks/{bipupu_id}", response_model=StatusResponse, tags=["黑名单"])
async def unblock_user(
    bipupu_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """解除拉黑用户

    参数：
    - bipupu_id: 要解除拉黑的用户 Bipupu ID（业务 ID）

    返回：
    - 成功：返回操作成功消息
    - 失败：404（用户不存在或未拉黑）或 500（数据库操作失败）

    注意：
    - 需要用户认证
    - 解除拉黑后，双方可以重新互相发送消息
    - 解除拉黑不会自动添加为联系人
    """
    # 查找要解除拉黑的用户
    blocked_user = _get_user_by_bipupu_id(db, bipupu_id)

    try:
        # 使用 cast 确保类型正确，blocked_user.id 是 Integer 类型
        UserService.unblock_user(db, current_user, cast(int, blocked_user.id))
        logger.info(f"用户解除拉黑成功：{current_user.username} 解除拉黑 {bipupu_id}")
        return {"message": "用户已解除拉黑"}
    except ValidationException as e:
        if "block entry not found" in str(e).lower():
            raise HTTPException(status_code=404, detail="用户不在黑名单中")
        else:
            raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"解除拉黑用户失败：{str(e)}")
        raise HTTPException(status_code=500, detail="解除拉黑操作失败")


@router.get("/blocks", response_model=PaginatedResponse[BlockedUserResponse], tags=["黑名单"])
async def get_blocked_users(
    page: int = Query(1, ge=1, description="页码"),
    size: int = Query(20, ge=1, le=100, description="每页数量"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取当前用户的黑名单列表

    参数：
    - page: 页码，默认为 1
    - size: 每页数量，默认为 20，最大 100

    返回：
    - items: 黑名单用户列表
    - total: 黑名单用户总数
    - page: 当前页码
    - size: 每页数量
    - pages: 总页数

    包含信息：
    - 用户基本信息（ID、bipupu_id、用户名、昵称、头像）
    - 拉黑时间

    注意：
    - 需要用户认证
    - 返回分页结果，支持分页查询
    """
    params = PaginationParams(page=page, size=size)
    rows, total = UserService.get_blocked_users(db, current_user, params)

    # 转换为响应模型
    blocked_users = []
    for user, blocked_at in rows:
        blocked_users.append(BlockedUserResponse(
            id=user.id,  # type: ignore
            bipupu_id=user.bipupu_id,  # type: ignore
            username=user.username,  # type: ignore
            nickname=user.nickname,  # type: ignore
            avatar_url=user.avatar_url,  # type: ignore
            blocked_at=blocked_at
        ))

    return PaginatedResponse.create(blocked_users, total, params)


@router.get("/blocks/check/{bipupu_id}", response_model=dict, tags=["黑名单"])
async def check_block_status(
    bipupu_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """检查与指定用户的拉黑关系状态

    参数：
    - bipupu_id: 要检查的用户 Bipupu ID

    返回：
    - is_blocked_by_me: 我是否拉黑了对方
    - is_blocked_by_them: 对方是否拉黑了我
    - mutual_block: 是否互相拉黑
    - user_info: 用户基本信息（如果用户存在）

    注意：
    - 需要用户认证
    - 如果用户不存在，返回 404
    """
    # 查找目标用户
    target_user = _get_user_by_bipupu_id(db, bipupu_id)

    # 检查我是否拉黑了对方
    blocked_by_me = db.query(UserBlock).filter(
        UserBlock.blocker_id == current_user.id,
        UserBlock.blocked_id == target_user.id
    ).first() is not None

    # 检查对方是否拉黑了我
    blocked_by_them = db.query(UserBlock).filter(
        UserBlock.blocker_id == target_user.id,
        UserBlock.blocked_id == current_user.id
    ).first() is not None

    return {
        "is_blocked_by_me": blocked_by_me,
        "is_blocked_by_them": blocked_by_them,
        "mutual_block": blocked_by_me and blocked_by_them,
        "user_info": {
            "id": target_user.id,  # type: ignore
            "bipupu_id": target_user.bipupu_id,  # type: ignore
            "username": target_user.username,  # type: ignore
            "nickname": target_user.nickname,  # type: ignore
            "avatar_url": target_user.avatar_url  # type: ignore
        }
    }


@router.get("/blocks/search", response_model=List[BlockedUserResponse], tags=["黑名单"])
async def search_blocked_users(
    keyword: str = Query(..., description="搜索关键词（用户名、昵称或 bipupu_id）"),
    limit: int = Query(10, ge=1, le=50, description="返回结果数量限制"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """在黑名单中搜索用户

    参数：
    - keyword: 搜索关键词，支持用户名、昵称或 bipupu_id 的部分匹配
    - limit: 返回结果数量限制，默认为 10，最大 50

    返回：
    - 匹配的黑名单用户列表

    注意：
    - 需要用户认证
    - 搜索不区分大小写
    - 返回结果按拉黑时间倒序排列
    """
    # 构建搜索条件
    search_pattern = f"%{keyword}%"

    # 查询当前用户的黑名单中匹配的用户
    query = db.query(User, UserBlock.created_at).join(
        UserBlock, User.id == UserBlock.blocked_id
    ).filter(
        UserBlock.blocker_id == current_user.id,
        or_(
            User.username.ilike(search_pattern),
            User.nickname.ilike(search_pattern),
            User.bipupu_id.ilike(search_pattern)
        )
    ).order_by(UserBlock.created_at.desc()).limit(limit)

    rows = query.all()

    # 转换为响应模型
    blocked_users = []
    for user, blocked_at in rows:
        blocked_users.append(BlockedUserResponse(
            id=user.id,  # type: ignore
            bipupu_id=user.bipupu_id,  # type: ignore
            username=user.username,  # type: ignore
            nickname=user.nickname,  # type: ignore
            avatar_url=user.avatar_url,  # type: ignore
            blocked_at=blocked_at
        ))

    return blocked_users


@router.get("/blocks/count", response_model=dict, tags=["黑名单"])
async def get_block_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取黑名单统计信息

    参数：
    - 无

    返回：
    - total_blocks: 我拉黑的用户总数
    - total_blocked_by: 拉黑我的用户总数
    - mutual_blocks: 互相拉黑的用户数

    注意：
    - 需要用户认证
    """
    # 我拉黑的用户总数
    total_blocks = db.query(UserBlock).filter(
        UserBlock.blocker_id == current_user.id
    ).count()

    # 拉黑我的用户总数
    total_blocked_by = db.query(UserBlock).filter(
        UserBlock.blocked_id == current_user.id
    ).count()

    # 互相拉黑的用户数（需要子查询优化）
    mutual_blocks_query = db.query(UserBlock).filter(
        UserBlock.blocker_id == current_user.id,
        UserBlock.blocked_id.in_(
            db.query(UserBlock.blocker_id).filter(
                UserBlock.blocked_id == current_user.id
            )
        )
    )
    mutual_blocks = mutual_blocks_query.count()

    return {
        "total_blocks": total_blocks,
        "total_blocked_by": total_blocked_by,
        "mutual_blocks": mutual_blocks
    }
