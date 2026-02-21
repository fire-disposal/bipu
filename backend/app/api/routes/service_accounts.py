from fastapi import APIRouter, Depends, HTTPException, Response, Request
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import List
import logging

from app.db.database import get_db
from app.models.service_account import ServiceAccount, subscription_table
from app.schemas.service_account import (
    ServiceAccountResponse,
    ServiceAccountList,
    SubscriptionSettingsUpdate,
    SubscriptionSettingsResponse,
    UserSubscriptionResponse,
    UserSubscriptionList
)
from app.core.security import get_current_user
from app.models.user import User
from sqlalchemy import select, update, func
from datetime import time

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/", response_model=ServiceAccountList)
async def list_service_accounts(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取所有活跃的服务号列表"""
    services = (
        db.query(ServiceAccount)
        .filter(ServiceAccount.is_active == True)
        .offset(skip)
        .limit(limit)
        .all()
    )
    total = db.query(ServiceAccount).filter(ServiceAccount.is_active == True).count()

    return {"items": services, "total": total}


@router.get("/{name}", response_model=ServiceAccountResponse)
async def get_service_account(
    name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """获取指定服务号详情"""
    service = db.query(ServiceAccount).filter(ServiceAccount.name == name).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service account not found")
    return service


@router.get("/{name}/avatar")
async def get_service_avatar(request: Request, name: str, db: Session = Depends(get_db)):
    """获取服务号头像 - 优化版本，支持缓存"""
    from app.services.storage_service import StorageService
    from app.services.redis_service import RedisService

    service = db.query(ServiceAccount).filter(ServiceAccount.name == name).first()
    if not service or not service.avatar_data:
        # 根据用户反馈：前端有自动处理无头像并使用首字母显示的方案
        # 没有头像没有关系，无需处理默认头像配置
        raise HTTPException(status_code=404, detail="Avatar not found")

    # 生成ETag - 使用版本号和时间戳
    version = service.avatar_version or 0
    updated_at_timestamp = service.updated_at.timestamp() if service.updated_at else 0
    etag_input = f"{version}:{updated_at_timestamp}".encode()
    etag = StorageService.get_avatar_etag(service.avatar_data, etag_input.encode() if isinstance(etag_input, str) else etag_input)

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
    """获取用户订阅的服务号列表（包含订阅设置）"""
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
            # 格式化推送时间
            push_time_str = None
            if setting.push_time:
                push_time_str = setting.push_time.strftime("%H:%M")

            subscription_response = UserSubscriptionResponse(
                service=service,
                settings=SubscriptionSettingsResponse(
                    service_name=service.name,
                    service_description=service.description,
                    push_time=push_time_str,
                    is_enabled=setting.is_enabled,
                    subscribed_at=setting.created_at,
                    updated_at=setting.updated_at
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
    """获取指定服务号的订阅设置"""
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

    # 格式化推送时间
    push_time_str = None
    if result.push_time:
        push_time_str = result.push_time.strftime("%H:%M")

    return SubscriptionSettingsResponse(
        service_name=service.name,
        service_description=service.description,
        push_time=push_time_str,
        is_enabled=result.is_enabled,
        subscribed_at=result.created_at,
        updated_at=result.updated_at
    )


@router.put("/{name}/settings", response_model=SubscriptionSettingsResponse)
async def update_subscription_settings(
    name: str,
    settings_update: SubscriptionSettingsUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新订阅设置（推送时间、启用状态）"""
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

        if result.rowcount == 0:
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

        # 格式化推送时间
        push_time_str = None
        if updated_result.push_time:
            push_time_str = updated_result.push_time.strftime("%H:%M")

        logger.info(f"用户 {current_user.bipupu_id} 更新了服务号 {name} 的订阅设置")

        return SubscriptionSettingsResponse(
            service_name=service.name,
            service_description=service.description,
            push_time=push_time_str,
            is_enabled=updated_result.is_enabled,
            subscribed_at=updated_result.created_at,
            updated_at=updated_result.updated_at
        )

    except Exception as e:
        db.rollback()
        logger.error(f"更新订阅设置失败: {e}")
        raise HTTPException(status_code=500, detail="Failed to update subscription settings")


@router.post("/{name}/subscribe")
async def subscribe_service_account(
    name: str,
    settings_update: SubscriptionSettingsUpdate = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """订阅服务号（可设置初始推送时间）"""
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

        # 设置推送时间（如果提供）
        if settings_update and settings_update.push_time:
            try:
                hour, minute = map(int, settings_update.push_time.split(':'))
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
            "push_time": settings_update.push_time if settings_update else None,
            "is_enabled": settings_update.is_enabled if settings_update else True
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
    """取消订阅服务号"""
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
