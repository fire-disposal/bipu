"""客户端黑名单API路由 - 用户业务功能，无需管理员权限"""

from typing import cast, Any

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
    """拉黑用户

    参数：
    - user_id: 要拉黑的用户ID

    返回：
    - 成功：返回操作成功消息
    - 失败：404（用户不存在）或400（已拉黑）或500（数据库操作失败）

    注意：
    - 需要用户认证
    - 不能拉黑自己
    - 拉黑后，双方将无法互相发送消息
    - 拉黑关系是单向的
    """
    ub = UserService.block_user(db, current_user, block_request.user_id)
    logger.info(f"用户拉黑: {current_user.username} 拉黑 {block_request.user_id}")
    return {"message": "用户已拉黑"}


@router.delete("/blocks/{user_id}", response_model=StatusResponse, tags=["黑名单"])
async def unblock_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """解除拉黑用户

    参数：
    - user_id: 要解除拉黑的用户ID

    返回：
    - 成功：返回操作成功消息
    - 失败：404（用户不存在或未拉黑）或500（数据库操作失败）

    注意：
    - 需要用户认证
    - 解除拉黑后，双方可以重新互相发送消息
    - 解除拉黑不会自动添加为联系人
    """
    UserService.unblock_user(db, current_user, user_id)
    logger.info(f"用户解除拉黑: {current_user.username} 解除拉黑用户ID {user_id}")
    return {"message": "用户已解除拉黑"}


@router.get("/blocks", response_model=PaginatedResponse[BlockedUserResponse], tags=["黑名单"])
async def get_blocked_users(
    params: PaginationParams = Depends(),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取当前用户的黑名单列表

    参数：
    - page: 页码，默认为1
    - size: 每页数量，默认为20，最大100

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
    rows, total = UserService.get_blocked_users(db, current_user, params)

    # 转换为响应模型
    blocked_users = []
    for user, blocked_at in rows:
        # 从 SQLAlchemy 模型实例中提取属性值，使用 cast 解决类型推断问题
        blocked_users.append(BlockedUserResponse(
            id=cast(int, user.id),
            bipupu_id=cast(str, user.bipupu_id),
            username=cast(str, user.username),
            nickname=cast(str, user.nickname) if user.nickname else None,
            avatar_url=cast(str, user.avatar_url) if user.avatar_url else None,
            blocked_at=blocked_at
        ))

    return PaginatedResponse.create(blocked_users, total, params)
