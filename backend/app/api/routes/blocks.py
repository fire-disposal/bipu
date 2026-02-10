"""客户端黑名单API路由 - 用户业务功能，无需管理员权限"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.schemas.user import BlockUserRequest, BlockedUserResponse
from app.schemas.common import PaginationParams, PaginatedResponse, StatusResponse
from app.core.security import get_current_active_user
from app.services.user_service import UserService
from app.core.exceptions import ValidationException, NotFoundException
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)

@router.post("/blocks", response_model=StatusResponse, tags=["黑名单"])
async def block_user(
    block_request: BlockUserRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """拉黑用户"""
    ub = UserService.block_user(db, current_user, block_request.user_id)
    logger.info(f"用户拉黑: {current_user.username} 拉黑 {block_request.user_id}")
    return {"message": "用户已拉黑"}


@router.delete("/blocks/{user_id}", response_model=StatusResponse, tags=["黑名单"])
async def unblock_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """解除拉黑"""
    UserService.unblock_user(db, current_user, user_id)
    logger.info(f"用户解除拉黑: {current_user.username} 解除拉黑用户ID {user_id}")
    return {"message": "用户已解除拉黑"}


@router.get("/blocks", response_model=PaginatedResponse[BlockedUserResponse], tags=["黑名单"])
async def get_blocked_users(
    params: PaginationParams = Depends(),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取黑名单列表"""
    rows, total = UserService.get_blocked_users(db, current_user, params)

    # 转换为响应模型
    blocked_users = []
    for user, blocked_at in rows:
        blocked_users.append(BlockedUserResponse(
            id=user.id,
            bipupu_id=user.bipupu_id,
            username=user.username,
            nickname=user.nickname,
            avatar_url=user.avatar_url,
            blocked_at=blocked_at
        ))

    return PaginatedResponse.create(blocked_users, total, params)
