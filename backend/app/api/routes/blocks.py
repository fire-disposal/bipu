"""黑名单路由 - 优化版本

设计原则：
1. 精简：使用优化后的数据模型
2. 安全：严格的权限验证
3. 实用：提供核心黑名单功能
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.models.user import User
from app.models.user_block import UserBlock
from app.schemas.user import BlockUserRequest, BlockedUserResponse
from app.schemas.common import (
    PaginationParams, PaginatedResponse, SuccessResponse, CountResponse
)
from app.core.security import get_current_active_user
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.post("/", response_model=SuccessResponse, tags=["黑名单"])
async def block_user(
    block_data: BlockUserRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """拉黑用户

    参数：
    - bipupu_id: 要拉黑的用户ID

    返回：
    - 成功：返回成功消息
    - 失败：400（参数错误）或404（用户不存在）或409（已拉黑）
    """
    try:
        # 检查要拉黑的用户是否存在
        blocked_user = db.query(User).filter(
            User.bipupu_id == block_data.bipupu_id,
            User.is_active == True
        ).first()

        if not blocked_user:
            raise HTTPException(status_code=404, detail="用户不存在")

        # 检查是否是自己
        if block_data.bipupu_id == current_user.bipupu_id:
            raise HTTPException(status_code=400, detail="不能拉黑自己")

        # 检查是否已拉黑
        existing_block = db.query(UserBlock).filter(
            UserBlock.user_id == current_user.id,
            UserBlock.blocked_user_id == blocked_user.id
        ).first()

        if existing_block:
            raise HTTPException(status_code=409, detail="用户已拉黑")

        # 创建拉黑记录
        block = UserBlock(
            user_id=current_user.id,
            blocked_user_id=blocked_user.id
        )

        db.add(block)
        db.commit()

        logger.info(f"用户拉黑成功: user_id={current_user.id}, blocked_user_id={blocked_user.id}")
        return SuccessResponse(message="用户已拉黑")

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"拉黑用户失败: {e}")
        raise HTTPException(status_code=500, detail="拉黑用户失败")


@router.get("/", response_model=PaginatedResponse[BlockedUserResponse], tags=["黑名单"])
async def get_blocked_users(
    params: PaginationParams = Depends(),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """获取黑名单列表

    参数：
    - page: 页码（从1开始）
    - size: 每页数量（1-100）

    返回：
    - 成功：返回黑名单用户列表
    - 失败：400（参数错误）
    """
    try:
        # 查询黑名单
        query = db.query(UserBlock).filter(
            UserBlock.user_id == current_user.id
        )

        # 计算总数
        total = query.count()

        # 分页查询
        blocks = query.order_by(UserBlock.blocked_at.desc()) \
            .offset(params.skip) \
            .limit(params.size) \
            .all()

        # 构建响应
        blocked_users = []
        for block in blocks:
            # 获取被拉黑的用户信息
            blocked_user = db.query(User).filter(User.id == block.blocked_user_id).first()
            if blocked_user:
                # 使用model_validate自动处理类型转换
                blocked_users.append(BlockedUserResponse.model_validate({
                    "bipupu_id": blocked_user.bipupu_id,
                    "username": blocked_user.username,
                    "nickname": blocked_user.nickname,
                    "avatar_url": blocked_user.avatar_url,
                    "blocked_at": block.blocked_at
                }))

        return PaginatedResponse.create(blocked_users, total, params)

    except Exception as e:
        logger.error(f"获取黑名单列表失败: {e}")
        raise HTTPException(status_code=500, detail="获取黑名单列表失败")


@router.delete("/{bipupu_id}", response_model=SuccessResponse, tags=["黑名单"])
async def unblock_user(
    bipupu_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """取消拉黑用户

    参数：
    - bipupu_id: 要取消拉黑的用户ID

    返回：
    - 成功：返回成功消息
    - 失败：404（未拉黑该用户）
    """
    try:
        # 查找要取消拉黑的用户
        blocked_user = db.query(User).filter(
            User.bipupu_id == bipupu_id,
            User.is_active == True
        ).first()

        if not blocked_user:
            raise HTTPException(status_code=404, detail="用户不存在")

        # 查找拉黑记录
        block = db.query(UserBlock).filter(
            UserBlock.user_id == current_user.id,
            UserBlock.blocked_user_id == blocked_user.id
        ).first()

        if not block:
            raise HTTPException(status_code=404, detail="未拉黑该用户")

        # 删除拉黑记录
        db.delete(block)
        db.commit()

        logger.info(f"取消拉黑成功: user_id={current_user.id}, blocked_user_id={blocked_user.id}")
        return SuccessResponse(message="已取消拉黑")

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"取消拉黑失败: {e}")
        raise HTTPException(status_code=500, detail="取消拉黑失败")


@router.get("/check/{bipupu_id}", response_model=dict, tags=["黑名单"])
async def check_block_status(
    bipupu_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """检查用户是否被拉黑

    参数：
    - bipupu_id: 要检查的用户ID

    返回：
    - 成功：返回检查结果
    - 失败：404（用户不存在）
    """
    try:
        # 检查用户是否存在
        target_user = db.query(User).filter(
            User.bipupu_id == bipupu_id,
            User.is_active == True
        ).first()

        if not target_user:
            raise HTTPException(status_code=404, detail="用户不存在")

        # 检查是否被当前用户拉黑
        is_blocked = db.query(UserBlock).filter(
            UserBlock.user_id == current_user.id,
            UserBlock.blocked_user_id == target_user.id
        ).first() is not None

        # 检查是否被对方拉黑
        is_blocked_by = db.query(UserBlock).filter(
            UserBlock.user_id == target_user.id,
            UserBlock.blocked_user_id == current_user.id
        ).first() is not None

        return {
            "is_blocked": is_blocked,
            "is_blocked_by": is_blocked_by,
            "mutual_block": is_blocked and is_blocked_by
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"检查拉黑状态失败: {e}")
        raise HTTPException(status_code=500, detail="检查拉黑状态失败")


@router.get("/search", response_model=List[BlockedUserResponse], tags=["黑名单"])
async def search_blocked_users(
    query: str = Query(..., description="搜索关键词（用户名或昵称）"),
    limit: int = Query(10, ge=1, le=50, description="返回结果数量"),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """搜索黑名单用户

    参数：
    - query: 搜索关键词
    - limit: 返回结果数量（1-50）

    返回：
    - 成功：返回匹配的黑名单用户列表
    - 失败：400（参数错误）
    """
    try:
        # 查询当前用户的黑名单
        blocks = db.query(UserBlock).filter(
            UserBlock.user_id == current_user.id
        ).all()

        if not blocks:
            return []

        # 获取被拉黑的用户ID列表
        blocked_user_ids = [block.blocked_user_id for block in blocks]

        # 搜索匹配的用户
        search_pattern = f"%{query}%"
        blocked_users = db.query(User).filter(
            User.id.in_(blocked_user_ids),
            User.is_active == True,
            (User.username.ilike(search_pattern) | User.nickname.ilike(search_pattern))
        ).limit(limit).all()

        # 构建响应
        results = []
        for user in blocked_users:
            # 获取拉黑时间
            block = next((b for b in blocks if b.blocked_user_id == user.id), None)
            if block:
                # 使用model_validate自动处理类型转换
                results.append(BlockedUserResponse.model_validate({
                    "bipupu_id": user.bipupu_id,
                    "username": user.username,
                    "nickname": user.nickname,
                    "avatar_url": user.avatar_url,
                    "blocked_at": block.blocked_at
                }))

        return results

    except Exception as e:
        logger.error(f"搜索黑名单用户失败: {e}")
        raise HTTPException(status_code=500, detail="搜索黑名单用户失败")


@router.get("/count", response_model=CountResponse, tags=["黑名单"])
async def get_blocked_users_count(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """获取黑名单用户数量

    返回：
    - 成功：返回黑名单用户数量
    """
    try:
        count = db.query(UserBlock).filter(
            UserBlock.user_id == current_user.id
        ).count()

        return CountResponse(count=count)

    except Exception as e:
        logger.error(f"获取黑名单数量失败: {e}")
        raise HTTPException(status_code=500, detail="获取黑名单数量失败")
