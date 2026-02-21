#!/usr/bin/env python3
"""
服务号推送时间设置测试脚本

测试功能：
1. 服务号初始化
2. 用户订阅服务号
3. 设置个人化推送时间
4. 模拟推送时间检查
"""

import asyncio
import sys
from datetime import datetime, time, timedelta
from sqlalchemy.orm import Session
import pytz

# 添加项目路径
sys.path.insert(0, '.')

from app.db.database import SessionLocal
from app.models.user import User
from app.models.service_account import ServiceAccount, subscription_table
from app.core.security import get_password_hash
from app.core.user_utils import generate_bipupu_id
from app.tasks.subscriptions import (
    get_users_for_push_time,
    generate_daily_fortune,
    generate_weather_forecast
)
from sqlalchemy import select, update, func


def create_test_user(db: Session, username: str = "testuser", timezone: str = "Asia/Shanghai") -> User:
    """创建测试用户"""
    # 检查用户是否已存在
    existing_user = db.query(User).filter(User.username == username).first()
    if existing_user:
        print(f"用户已存在: {username}")
        return existing_user

    # 生成唯一的bipupu_id
    bipupu_id = generate_bipupu_id(db)

    user = User(
        username=username,
        bipupu_id=bipupu_id,
        hashed_password=get_password_hash("testpassword123"),
        nickname=f"测试用户-{username}",
        timezone=timezone,
        fortune_time="09:00",  # 默认运势推送时间
        is_active=True,
        is_superuser=False
    )

    db.add(user)
    db.commit()
    db.refresh(user)
    print(f"创建测试用户: {username} (bipupu_id: {bipupu_id}, 时区: {timezone})")
    return user


def subscribe_service(db: Session, user: User, service_name: str, push_time: str = None) -> bool:
    """用户订阅服务号"""
    # 获取服务号
    service = db.query(ServiceAccount).filter(
        ServiceAccount.name == service_name,
        ServiceAccount.is_active == True
    ).first()

    if not service:
        print(f"服务号不存在: {service_name}")
        return False

    # 检查是否已订阅
    stmt = select(subscription_table.c.user_id).where(
        subscription_table.c.user_id == user.id,
        subscription_table.c.service_account_id == service.id
    )
    existing = db.execute(stmt).first()

    if existing:
        print(f"用户已订阅服务号: {service_name}")
        return True

    # 准备订阅数据
    subscription_data = {
        "user_id": user.id,
        "service_account_id": service.id,
        "is_enabled": True,
        "created_at": func.now()
    }

    # 设置推送时间
    if push_time:
        try:
            hour, minute = map(int, push_time.split(':'))
            subscription_data['push_time'] = time(hour, minute)
            print(f"设置推送时间: {push_time}")
        except (ValueError, AttributeError):
            print(f"推送时间格式无效: {push_time}")

    # 插入订阅记录
    try:
        stmt = subscription_table.insert().values(**subscription_data)
        db.execute(stmt)
        db.commit()
        print(f"用户 {user.username} 成功订阅服务号: {service_name}")
        return True
    except Exception as e:
        db.rollback()
        print(f"订阅失败: {e}")
        return False


def update_push_time(db: Session, user: User, service_name: str, push_time: str) -> bool:
    """更新用户的推送时间设置"""
    # 获取服务号
    service = db.query(ServiceAccount).filter(
        ServiceAccount.name == service_name,
        ServiceAccount.is_active == True
    ).first()

    if not service:
        print(f"服务号不存在: {service_name}")
        return False

    # 解析时间
    try:
        hour, minute = map(int, push_time.split(':'))
        push_time_obj = time(hour, minute)
    except (ValueError, AttributeError):
        print(f"推送时间格式无效: {push_time}")
        return False

    # 更新推送时间
    try:
        stmt = (
            update(subscription_table)
            .where(
                subscription_table.c.user_id == user.id,
                subscription_table.c.service_account_id == service.id
            )
            .values(push_time=push_time_obj, updated_at=func.now())
        )

        result = db.execute(stmt)
        db.commit()

        if result.rowcount > 0:
            print(f"更新推送时间成功: {service_name} -> {push_time}")
            return True
        else:
            print(f"用户未订阅该服务号: {service_name}")
            return False
    except Exception as e:
        db.rollback()
        print(f"更新推送时间失败: {e}")
        return False


def test_push_time_logic():
    """测试推送时间逻辑"""
    print("\n" + "="*60)
    print("测试推送时间逻辑")
    print("="*60)

    db = SessionLocal()
    try:
        # 创建测试用户
        user1 = create_test_user(db, "testuser1", "Asia/Shanghai")
        user2 = create_test_user(db, "testuser2", "America/New_York")
        user3 = create_test_user(db, "testuser3", "Europe/London")

        # 订阅服务号并设置不同的推送时间
        print("\n1. 订阅服务号并设置推送时间:")
        subscribe_service(db, user1, "cosmic.fortune", "09:00")  # 上海时间 9:00
        subscribe_service(db, user2, "cosmic.fortune", "21:00")  # 纽约时间 21:00 (UTC+5)
        subscribe_service(db, user3, "cosmic.fortune", "08:00")  # 伦敦时间 8:00

        subscribe_service(db, user1, "weather.service", "08:30")
        subscribe_service(db, user2, "weather.service", "20:30")
        subscribe_service(db, user3, "weather.service", "07:30")

        # 测试推送时间检查逻辑
        print("\n2. 测试推送时间检查逻辑:")

        # 模拟不同UTC时间
        test_times = [
            (1, 0, "01:00 UTC"),   # 上海 09:00, 纽约 20:00, 伦敦 01:00
            (13, 0, "13:00 UTC"),  # 上海 21:00, 纽约 08:00, 伦敦 13:00
            (8, 0, "08:00 UTC"),   # 上海 16:00, 纽约 03:00, 伦敦 08:00
        ]

        for hour_utc, minute_utc, label in test_times:
            print(f"\n测试时间: {label}")

            # 测试运势推送
            fortune_users = get_users_for_push_time(db, "cosmic.fortune", hour_utc, minute_utc)
            print(f"  运势推送目标用户: {len(fortune_users)} 人")
            for user_id, bipupu_id in fortune_users:
                user = db.query(User).filter(User.id == user_id).first()
                if user:
                    print(f"    - {user.username} ({user.timezone})")

            # 测试天气推送
            weather_users = get_users_for_push_time(db, "weather.service", hour_utc, minute_utc)
            print(f"  天气推送目标用户: {len(weather_users)} 人")
            for user_id, bipupu_id in weather_users:
                user = db.query(User).filter(User.id == user_id).first()
                if user:
                    print(f"    - {user.username} ({user.timezone})")

        # 测试运势生成
        print("\n3. 测试运势生成:")
        today = datetime.now()
        fortune = generate_daily_fortune(user1.bipupu_id, today)
        print("运势示例:")
        print(fortune[:200] + "...")

        # 测试天气生成
        print("\n4. 测试天气生成:")
        weather = generate_weather_forecast(today)
        print("天气示例:")
        print(weather[:200] + "...")

        # 测试时区转换
        print("\n5. 测试时区转换:")
        test_time_utc = datetime.now(pytz.UTC).replace(hour=1, minute=0, second=0, microsecond=0)

        for user in [user1, user2, user3]:
            try:
                user_tz = pytz.timezone(user.timezone)
                user_local_time = test_time_utc.astimezone(user_tz)
                print(f"  {user.username}: UTC {test_time_utc.strftime('%H:%M')} -> {user.timezone} {user_local_time.strftime('%H:%M')}")
            except Exception as e:
                print(f"  {user.username}: 时区转换失败 - {e}")

        print("\n" + "="*60)
        print("测试完成!")
        print("="*60)

    except Exception as e:
        print(f"测试失败: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()


def test_subscription_management():
    """测试订阅管理功能"""
    print("\n" + "="*60)
    print("测试订阅管理功能")
    print("="*60)

    db = SessionLocal()
    try:
        # 创建测试用户
        user = create_test_user(db, "subscription_test", "Asia/Shanghai")

        # 订阅多个服务号
        print("\n1. 订阅多个服务号:")
        services = [
            ("cosmic.fortune", "09:00"),
            ("weather.service", "08:30"),
        ]

        for service_name, push_time in services:
            subscribe_service(db, user, service_name, push_time)

        # 查询用户的订阅设置
        print("\n2. 查询用户订阅设置:")
        stmt = select(
            subscription_table.c.service_account_id,
            subscription_table.c.push_time,
            subscription_table.c.is_enabled
        ).where(subscription_table.c.user_id == user.id)

        results = db.execute(stmt).all()

        for service_id, push_time, is_enabled in results:
            service = db.query(ServiceAccount).filter(ServiceAccount.id == service_id).first()
            if service:
                push_time_str = push_time.strftime("%H:%M") if push_time else "未设置"
                print(f"  - {service.name}: 推送时间={push_time_str}, 启用={is_enabled}")

        # 更新推送时间
        print("\n3. 更新推送时间:")
        update_push_time(db, user, "cosmic.fortune", "10:00")
        update_push_time(db, user, "weather.service", "07:45")

        # 验证更新结果
        print("\n4. 验证更新结果:")
        results = db.execute(stmt).all()
        for service_id, push_time, is_enabled in results:
            service = db.query(ServiceAccount).filter(ServiceAccount.id == service_id).first()
            if service:
                push_time_str = push_time.strftime("%H:%M") if push_time else "未设置"
                print(f"  - {service.name}: 推送时间={push_time_str}, 启用={is_enabled}")

        print("\n" + "="*60)
        print("订阅管理测试完成!")
        print("="*60)

    except Exception as e:
        print(f"测试失败: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()


def main():
    """主函数"""
    print("服务号推送时间设置测试脚本")
    print("="*60)

    # 测试1: 推送时间逻辑
    test_push_time_logic()

    # 测试2: 订阅管理功能
    test_subscription_management()

    print("\n所有测试完成!")


if __name__ == "__main__":
    main()
