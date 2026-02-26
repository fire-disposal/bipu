from fastapi import APIRouter, Depends, HTTPException, Response, Request
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import List, Optional
import logging
from datetime import datetime, time

from app.db.database import get_db
from app.models.service_account import ServiceAccount, subscription_table
from app.schemas.service_account import (
    ServiceAccountResponse,
    ServiceAccountList,
    SubscriptionSettingsUpdate,
    SubscriptionSettingsResponse,
    UserSubscriptionResponse,
    UserSubscriptionList,
    PushTimeSource
)
from app.core.security import get_current_user
from app.models.user import User
from sqlalchemy import select, update, func

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/", response_model=ServiceAccountList, tags=["服务号"])
async def list_service_accounts(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取所有活跃的服务号列表

    参数：
    - skip: 跳过的记录数，用于分页
    - limit: 每页返回的记录数，最大100

    返回：
    - items: 服务号列表
    - total: 活跃服务号总数

    注意：只返回 is_active=True 的服务号
    """
    services = (
        db.query(ServiceAccount)
        .filter(ServiceAccount.is_active == True)
        .offset(skip)
        .limit(limit)
        .all()
    )
    total = db.query(ServiceAccount).filter(ServiceAccount.is_active == True).count()

    return {"items": services, "total": total}


@router.get("/{name}", response_model=ServiceAccountResponse, tags=["服务号"])
async def get_service_account(
    name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取指定服务号详情

    参数：
    - name: 服务号名称

    返回：
    - 成功：返回服务号详细信息
    - 失败：404（服务号不存在）

    注意：需要用户认证
    """
    service = db.query(ServiceAccount).filter(ServiceAccount.name == name).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service account not found")
    return service


@router.get("/{name}/avatar", tags=["服务号"])
async def get_service_avatar(request: Request, name: str, db: Session = Depends(get_db)):
    """获取服务号头像

    参数：
    - name: 服务号名称

    特性：
    - 支持ETag缓存，减少带宽消耗
    - 支持HTTP 304 Not Modified响应
    - 头像数据缓存24小时

    返回：
    - 成功：返回JPEG格式的头像图片
    - 失败：404（服务号或头像不存在）
    """
    from app.services.storage_service import StorageService
    from app.services.redis_service import RedisService

    service = db.query(ServiceAccount).filter(ServiceAccount.name == name).first()
    if not service or not service.avatar_data:
        # 根据用户反馈：前端有自动处理无头像并使用首字母显示的方案
        # 没有头像没有关系，无需处理默认头像配置
        raise HTTPException(status_code=404, detail="Avatar not found")

    # 生成ETag - 使用时间戳
    updated_at_timestamp = service.updated_at.timestamp() if service.updated_at else 0
    etag_input = f"{updated_at_timestamp}".encode()
    etag = StorageService.get_avatar_etag(service.avatar_data, etag_input)

    # 检查ETag匹配
    if request and request.headers.get("if-none-match") == etag:
        return Response(status_code=304)

    # 尝试从缓存获取头像
    cache_key = StorageService.get_avatar_cache_key(name)
    cached_avatar = await RedisService.get_cache(cache_key)

    # 如果缓存存在且ETag匹配，使用缓存
    if cached_avatar:
        # 验证缓存是否仍然有效（基于版本号）
        cached_etag = StorageService.get_avatar_etag(cached_avatar, etag_input.encode() if isinstance(etag_input, str) else etag_input)
        if cached_etag == etag:
            logger.debug(f"服务号头像缓存命中: {name}")
            return Response(
                content=cached_avatar,
                media_type="image/jpeg",
                headers={
                    "Cache-Control": "public, max-age=86400",  # 缓存1天
                    "ETag": etag
                }
            )

    # 缓存头像数据（或更新缓存）
    await RedisService.set_cache(cache_key, service.avatar_data, expire=86400)  # 缓存1天

    return Response(
        content=service.avatar_data,
        media_type="image/jpeg",  # 统一使用JPEG格式，与用户头像保持一致
        headers={
            "Cache-Control": "public, max-age=86400",  # 缓存1天
            "ETag": etag
        }
    )


@router.get("/subscriptions/", response_model=UserSubscriptionList)
async def get_user_subscriptions(
    current_user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    """获取当前用户订阅的所有服务号列表

    返回：
    - subscriptions: 订阅的服务号列表，包含服务信息和订阅设置
    - total: 订阅的服务号总数

    包含信息：
    - 服务号基本信息（名称、描述、头像等）
    - 订阅设置（推送时间、启用状态、订阅时间等）

    注意：需要用户认证
    """
    subscriptions = []

    # 查询用户的订阅设置
    stmt = select(
        subscription_table.c.service_account_id,
        subscription_table.c.push_time,
        subscription_table.c.is_enabled,
        subscription_table.c.created_at,
        subscription_table.c.updated_at
    ).where(subscription_table.c.user_id == current_user.id)

    subscription_settings = db.execute(stmt).all()

    for setting in subscription_settings:
        service = db.query(ServiceAccount).filter(
            ServiceAccount.id == setting.service_account_id
        ).first()

        if service:
            # 确定推送时间及来源
            push_time_str = None
            push_time_source = "none"

            if setting.push_time:
                push_time_str = setting.push_time.strftime("%H:%M")
                push_time_source = PushTimeSource.SUBSCRIPTION
            elif service.default_push_time:
                push_time_str = service.default_push_time.strftime("%H:%M")
                push_time_source = PushTimeSource.SERVICE_DEFAULT
            else:
                push_time_source = PushTimeSource.NONE

            subscription_response = UserSubscriptionResponse(
                service=service,
                settings=SubscriptionSettingsResponse(
                    service_name=str(service.name),
                    service_description=str(service.description) if service.description else None,
                    push_time=push_time_str,
                    is_enabled=setting.is_enabled,
                    subscribed_at=setting.created_at,
                    updated_at=setting.updated_at,
                    push_time_source=push_time_source
                )
            )
            subscriptions.append(subscription_response)

    return {"subscriptions": subscriptions, "total": len(subscriptions)}


@router.get("/{name}/settings", response_model=SubscriptionSettingsResponse)
async def get_subscription_settings(
    name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取指定服务号的订阅设置

    参数：
    - name: 服务号名称

    返回：
    - 成功：返回该服务号的订阅设置详情
    - 失败：404（服务号不存在或未订阅）

    包含信息：
    - 服务号基本信息
    - 推送时间设置及来源
    - 订阅启用状态
    - 订阅时间戳

    注意：需要用户认证且已订阅该服务号
    """
    service = db.query(ServiceAccount).filter(ServiceAccount.name == name).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service account not found")

    # 查询订阅设置
    stmt = select(
        subscription_table.c.push_time,
        subscription_table.c.is_enabled,
        subscription_table.c.created_at,
        subscription_table.c.updated_at
    ).where(
        subscription_table.c.user_id == current_user.id,
        subscription_table.c.service_account_id == service.id
    )

    result = db.execute(stmt).first()

    if not result:
        raise HTTPException(status_code=404, detail="Not subscribed to this service")

    # 确定推送时间及来源
    push_time_str = None
    push_time_source = PushTimeSource.NONE

    if result.push_time:
        push_time_str = result.push_time.strftime("%H:%M")
        push_time_source = PushTimeSource.SUBSCRIPTION
    elif service.default_push_time:
        push_time_str = service.default_push_time.strftime("%H:%M")
        push_time_source = PushTimeSource.SERVICE_DEFAULT

    return SubscriptionSettingsResponse(
        service_name=str(service.name),
        service_description=str(service.description) if service.description else None,
        push_time=push_time_str,
        is_enabled=result.is_enabled,
        subscribed_at=result.created_at,
        updated_at=result.updated_at,
        push_time_source=push_time_source
    )


@router.put("/{name}/settings", response_model=SubscriptionSettingsResponse)
async def update_subscription_settings(
    name: str,
    settings_update: SubscriptionSettingsUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新服务号订阅设置

    参数：
    - name: 服务号名称
    - push_time: 推送时间（HH:MM格式），可选
    - is_enabled: 是否启用推送，可选

    返回：
    - 成功：返回更新后的订阅设置
    - 失败：404（服务号不存在或未订阅）或400（时间格式无效）

    注意：
    - 需要用户认证且已订阅该服务号
    - 推送时间格式必须为 HH:MM（24小时制）
    - 如果只更新部分字段，其他字段保持不变
    - 设置 push_time=null 可清除个人化设置，恢复使用默认时间
    """
    service = db.query(ServiceAccount).filter(ServiceAccount.name == name).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service account not found")

    # 检查是否已订阅
    stmt = select(subscription_table.c.service_account_id).where(
        subscription_table.c.user_id == current_user.id,
        subscription_table.c.service_account_id == service.id
    )

    subscription_exists = db.execute(stmt).first()
    if not subscription_exists:
        raise HTTPException(status_code=404, detail="Not subscribed to this service")

    # 准备更新数据
    update_data = {"updated_at": func.now()}

    if settings_update.push_time is not None:
        if settings_update.push_time == "":
            # 清除个人化推送时间，恢复使用默认
            update_data['push_time'] = None
        else:
            # 解析时间字符串
            try:
                hour, minute = map(int, settings_update.push_time.split(':'))
                update_data['push_time'] = time(hour, minute)
            except (ValueError, AttributeError):
                raise HTTPException(status_code=400, detail="Invalid time format. Use HH:MM")

    if settings_update.is_enabled is not None:
        update_data['is_enabled'] = settings_update.is_enabled

    # 执行更新
    try:
        stmt = (
            update(subscription_table)
            .where(
                subscription_table.c.user_id == current_user.id,
                subscription_table.c.service_account_id == service.id
            )
            .values(**update_data)
        )

        result = db.execute(stmt)
        db.commit()

        if result is None or (hasattr(result, 'rowcount') and result.rowcount == 0):
            raise HTTPException(status_code=404, detail="Subscription not found")

        # 获取更新后的设置
        updated_stmt = select(
            subscription_table.c.push_time,
            subscription_table.c.is_enabled,
            subscription_table.c.created_at,
            subscription_table.c.updated_at
        ).where(
            subscription_table.c.user_id == current_user.id,
            subscription_table.c.service_account_id == service.id
        )

        updated_result = db.execute(updated_stmt).first()

        # 确定推送时间及来源
        push_time_str = None
        push_time_source = PushTimeSource.NONE

        if updated_result and updated_result.push_time:
            push_time_str = updated_result.push_time.strftime("%H:%M")
            push_time_source = PushTimeSource.SUBSCRIPTION
        elif service.default_push_time:
            push_time_str = service.default_push_time.strftime("%H:%M")
            push_time_source = PushTimeSource.SERVICE_DEFAULT

        logger.info(f"用户 {current_user.bipupu_id} 更新了服务号 {name} 的订阅设置")

        return SubscriptionSettingsResponse(
            service_name=str(service.name),
            service_description=str(service.description) if service.description else None,
            push_time=push_time_str,
            is_enabled=updated_result.is_enabled if updated_result else True,
            subscribed_at=updated_result.created_at if updated_result else datetime.now(),
            updated_at=updated_result.updated_at if updated_result else None,
            push_time_source=push_time_source
        )

    except Exception as e:
        db.rollback()
        logger.error(f"更新订阅设置失败: {e}")
        raise HTTPException(status_code=500, detail="Failed to update subscription settings")


@router.post("/{name}/subscribe")
async def subscribe_service_account(
    name: str,
    settings_update: Optional[SubscriptionSettingsUpdate] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """订阅服务号

    参数：
    - name: 要订阅的服务号名称
    - push_time: 初始推送时间（HH:MM格式），可选
    - is_enabled: 初始启用状态，可选，默认为True

    返回：
    - 成功：返回订阅成功信息
    - 失败：404（服务号不存在）或400（已订阅）或500（数据库操作失败）

    注意：
    - 需要用户认证
    - 只能订阅 is_active=True 的服务号
    - 推送时间格式必须为 HH:MM（24小时制）
    - 如果未提供推送时间，使用服务号默认推送时间
    """
    service = (
        db.query(ServiceAccount)
        .filter(ServiceAccount.name == name, ServiceAccount.is_active == True)
        .first()
    )
    if not service:
        raise HTTPException(status_code=404, detail="Service account not found")

    # 使用数据库查询进行预检查，避免竞态条件
    existing_subscription = (
        db.query(current_user.__class__)
        .filter(
            current_user.__class__.id == current_user.id,
            current_user.__class__.subscriptions.any(ServiceAccount.id == service.id),
        )
        .first()
    )

    if existing_subscription:
        raise HTTPException(status_code=400, detail="Already subscribed")

    try:
        # 准备订阅数据
        subscription_data = {
            "user_id": current_user.id,
            "service_account_id": service.id,
            "is_enabled": True,
            "created_at": func.now()
        }

        # 设置推送时间（优先级：用户提供 > 服务号默认时间）
        push_time_to_use = None

        if settings_update and settings_update.push_time:
            # 使用用户提供的推送时间
            push_time_to_use = settings_update.push_time
        else:
            # 使用服务号的默认推送时间
            push_time_to_use = service.default_push_time.strftime("%H:%M")

        # 设置推送时间
        if push_time_to_use:
            try:
                hour, minute = map(int, push_time_to_use.split(':'))
                subscription_data['push_time'] = time(hour, minute)
            except (ValueError, AttributeError):
                raise HTTPException(status_code=400, detail="Invalid time format. Use HH:MM")

        # 设置启用状态（如果提供）
        if settings_update and settings_update.is_enabled is not None:
            subscription_data['is_enabled'] = settings_update.is_enabled

        # 插入订阅记录
        stmt = subscription_table.insert().values(**subscription_data)
        db.execute(stmt)
        db.commit()

        logger.info(f"用户 {current_user.bipupu_id} 订阅了服务号 {name}")

        return {
            "message": "Subscribed successfully",
            "service_name": service.name,
            "push_time": push_time_to_use,
            "is_enabled": settings_update.is_enabled if settings_update else True,
            "push_time_source": "user_provided" if settings_update and settings_update.push_time else
                              "service_default" if service.default_push_time else "none"
        }
    except IntegrityError as e:
        db.rollback()
        # 处理数据库唯一约束冲突
        if "subscriptions_pkey" in str(e):
            raise HTTPException(status_code=400, detail="Already subscribed")
        # 其他完整性错误
        logger.error(f"Integrity error in subscribe_service_account: {e}")
        raise HTTPException(status_code=500, detail="Database operation failed")
    except Exception as e:
        db.rollback()
        # 其他数据库错误
        logger.error(f"Unexpected error in subscribe_service_account: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.delete("/{name}/subscribe")
async def unsubscribe_service_account(
    name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """取消订阅服务号

    参数：
    - name: 要取消订阅的服务号名称

    返回：
    - 成功：返回取消订阅成功信息
    - 失败：404（服务号不存在）或400（未订阅）或500（数据库操作失败）

    注意：
    - 需要用户认证
    - 取消订阅后，该服务号的推送将停止
    - 订阅记录将被删除，相关设置不会保留
    """
    service = db.query(ServiceAccount).filter(ServiceAccount.name == name).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service account not found")

    if service not in current_user.subscriptions:
        raise HTTPException(status_code=400, detail="Not subscribed")

    try:
        current_user.subscriptions.remove(service)
        db.commit()
        return {"message": "Unsubscribed successfully"}
    except Exception as e:
        db.rollback()
        logger.error(f"Error in unsubscribe_service_account: {e}")
        raise HTTPException(status_code=500, detail="Database operation failed")
