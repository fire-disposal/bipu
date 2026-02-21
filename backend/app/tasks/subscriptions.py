"""订阅任务 - 服务号推送系统（支持个人化推送时间）

包含：
1. 每日运势推送任务
2. 每日天气推送任务
3. 推送时间检查任务

支持功能：
- 个人化推送时间设置
- 时区处理
- 推送启用/禁用控制
"""
import random
import hashlib
import asyncio
from datetime import datetime, timezone, timedelta
from celery import shared_task
from sqlalchemy.orm import Session
from sqlalchemy import select, and_
from app.db.database import SessionLocal
from app.core.logging import get_logger
from app.models.service_account import ServiceAccount, subscription_table
from app.models.user import User
from app.services.service_accounts import send_push
import pytz

logger = get_logger(__name__)


def generate_daily_fortune(bipupu_id: str, date: datetime) -> str:
    """增强版每日运势生成器

    基于用户ID和日期生成确定性但个性化的运势
    """
    seed = f"{bipupu_id}:{date.date().isoformat()}"
    digest = hashlib.sha256(seed.encode()).hexdigest()

    # 运势元素库
    fortunes = ["大吉 🌟", "中吉 ⭐", "小吉 ✨", "平 😐", "凶 ⚠️"]
    lucky_items = ["红色外套", "笔记本电脑", "咖啡", "耳机", "Pupu机", "幸运手链", "笔记本", "钢笔"]
    lucky_colors = ["红色", "金色", "绿色", "蓝色", "紫色", "粉色", "白色", "黑色"]
    directions = ["东方", "南方", "西方", "北方", "东南方", "西南方", "东北方", "西北方"]
    advices = ["宜签约", "宜出行", "宜社交", "宜学习", "宜休息", "宜运动", "宜购物", "宜创作"]

    # 从哈希值中提取索引
    fi = int(digest[0:8], 16) % len(fortunes)
    li = int(digest[8:16], 16) % len(lucky_items)
    lc = int(digest[16:24], 16) % len(lucky_colors)
    di = int(digest[24:32], 16) % len(directions)
    ai = int(digest[32:40], 16) % len(advices)

    # 生成运势内容
    return (
        f"📅 {date.strftime('%Y年%m月%d日')} 运势\n"
        f"✨ 今日运势：{fortunes[fi]}\n"
        f"🎁 幸运物：{lucky_items[li]}\n"
        f"🎨 幸运色：{lucky_colors[lc]}\n"
        f"🧭 吉方位：{directions[di]}\n"
        f"💡 宜：{advices[ai]}\n"
        f"---\n"
        f"星座力量加持，祝您今日顺利！"
    )


def generate_weather_forecast(date: datetime) -> str:
    """随机生成每日天气预报

    包含天气状况、温度、湿度、风力等信息
    """
    weather_types = [
        ("晴朗 ☀️", "sunny", 18, 32),
        ("多云 ⛅", "cloudy", 16, 28),
        ("小雨 🌧️", "rainy", 12, 22),
        ("中雨 🌧️", "rainy", 10, 20),
        ("大雨 ⛈️", "stormy", 8, 18),
        ("雷阵雨 ⚡", "stormy", 10, 24),
        ("雾 🌫️", "foggy", 14, 26),
        ("大风 💨", "windy", 15, 27),
    ]

    weather_desc, weather_type, min_temp, max_temp = random.choice(weather_types)

    # 随机生成温度范围
    temp_range = max_temp - min_temp
    today_min = min_temp + random.randint(0, temp_range // 2)
    today_max = today_min + random.randint(temp_range // 3, temp_range)

    # 随机生成湿度和风力
    humidity = random.randint(40, 95)
    wind_speed = random.randint(1, 20)

    # 空气质量
    aqi_levels = ["优", "良", "轻度污染", "中度污染", "重度污染"]
    aqi = random.choice(aqi_levels)

    # 温馨提示
    tips = {
        "sunny": "天气晴朗，适合户外活动，注意防晒",
        "cloudy": "多云天气，温度适中，适合出行",
        "rainy": "雨天路滑，记得带伞，注意安全",
        "stormy": "雷雨天气，避免外出，注意防雷",
        "foggy": "雾天能见度低，出行注意安全",
        "windy": "风大，注意防风保暖",
    }

    tip = tips.get(weather_type, "天气变化无常，请注意适时增减衣物")

    return (
        f"🌤️ {date.strftime('%Y年%m月%d日')} 天气预报\n"
        f"🌡️ 天气：{weather_desc}\n"
        f"📊 温度：{today_min}°C ~ {today_max}°C\n"
        f"💧 湿度：{humidity}%\n"
        f"💨 风力：{wind_speed}m/s\n"
        f"🌿 空气质量：{aqi}\n"
        f"💡 温馨提示：{tip}"
    )


async def _send_fortune_to_user(db: Session, user: User) -> bool:
    """异步发送运势给单个用户"""
    try:
        now_utc = datetime.now(timezone.utc)
        bipupu_id = str(user.bipupu_id)
        content = generate_daily_fortune(bipupu_id, now_utc)
        await send_push(db, "cosmic.fortune", bipupu_id, content)
        logger.debug(f"运势推送成功：{bipupu_id}")
        return True
    except Exception as e:
        logger.error(f"运势推送失败 {user.bipupu_id}: {e}")
        return False


async def _send_weather_to_user(db: Session, user: User) -> bool:
    """异步发送天气给单个用户"""
    try:
        now_utc = datetime.now(timezone.utc)
        bipupu_id = str(user.bipupu_id)
        content = generate_weather_forecast(now_utc)
        await send_push(db, "weather.service", bipupu_id, content)
        logger.debug(f"天气推送成功：{bipupu_id}")
        return True
    except Exception as e:
        logger.error(f"天气推送失败 {user.bipupu_id}: {e}")
        return False


def get_users_for_push_time(db: Session, service_name: str, target_hour_utc: int, target_minute_utc: int) -> list:
    """获取在指定UTC时间应该接收推送的用户

    只考虑设置了个人化推送时间的用户
    移除默认推送时间逻辑，简化设计
    """
    # 获取服务号
    service = db.query(ServiceAccount).filter(
        ServiceAccount.name == service_name,
        ServiceAccount.is_active == True
    ).first()

    if not service:
        return []

    # 查询所有订阅者及其设置（只查询设置了推送时间的用户）
    stmt = select(
        User.id,
        User.bipupu_id,
        User.timezone,
        subscription_table.c.push_time
    ).join(
        subscription_table,
        User.id == subscription_table.c.user_id
    ).where(
        and_(
            subscription_table.c.service_account_id == service.id,
            subscription_table.c.is_enabled == True,
            subscription_table.c.push_time.is_not(None)  # 只处理设置了推送时间的用户
        )
    )

    results = db.execute(stmt).all()

    target_users = []
    current_utc = datetime.now(timezone.utc)
    target_time_utc = current_utc.replace(hour=target_hour_utc, minute=target_minute_utc, second=0, microsecond=0)

    for user_id, bipupu_id, user_timezone, push_time in results:
        try:
            # 获取用户时区
            user_tz = pytz.timezone(user_timezone or 'Asia/Shanghai')

            # 在用户时区中创建目标时间
            user_target_time = user_tz.localize(
                datetime.combine(target_time_utc.date(), push_time)
            )

            # 转换回UTC进行比较
            user_target_utc = user_target_time.astimezone(timezone.utc)

            # 检查是否在15分钟窗口内（允许一些灵活性）
            time_diff = abs((user_target_utc - target_time_utc).total_seconds())
            if time_diff <= 900:  # 15分钟
                target_users.append((user_id, bipupu_id))

        except Exception as e:
            logger.error(f"处理用户时区失败 {bipupu_id}: {e}")
            continue

    return target_users


@shared_task(name="subscriptions.check_push_times", bind=True, max_retries=3, default_retry_delay=60)
def check_push_times_task(self) -> dict:
    """检查推送时间任务

    每15分钟运行一次，检查哪些用户应该在当前时间接收推送
    返回推送统计信息
    """
    db = SessionLocal()
    try:
        current_utc = datetime.now(timezone.utc)
        logger.info(f"开始检查推送时间: {current_utc.strftime('%Y-%m-%d %H:%M')} UTC")

        # 检查运势推送
        fortune_users = get_users_for_push_time(db, "cosmic.fortune", current_utc.hour, current_utc.minute)

        # 检查天气推送
        weather_users = get_users_for_push_time(db, "weather.service", current_utc.hour, current_utc.minute)

        stats = {
            "check_time": current_utc.isoformat(),
            "fortune": {
                "target_users": len(fortune_users),
                "user_ids": [user_id for user_id, _ in fortune_users]
            },
            "weather": {
                "target_users": len(weather_users),
                "user_ids": [user_id for user_id, _ in weather_users]
            }
        }

        logger.info(f"推送时间检查完成: 运势={len(fortune_users)}用户, 天气={len(weather_users)}用户")

        # 如果有用户需要推送，立即发送推送（不再触发独立任务）
        if fortune_users:
            # 直接发送运势推送给指定用户
            fortune_task.delay(fortune_users)
            logger.info(f"已发送运势推送给 {len(fortune_users)} 个用户")

        if weather_users:
            # 直接发送天气推送给指定用户
            weather_task.delay(weather_users)
            logger.info(f"已发送天气推送给 {len(weather_users)} 个用户")

        return stats

    except Exception as e:
        logger.error(f"检查推送时间任务失败: {e}")
        self.retry(exc=e)
        return {"error": str(e)}
    finally:
        db.close()


@shared_task(name="subscriptions.fortune", bind=True, max_retries=3, default_retry_delay=60)
def fortune_task(self, target_users: list = None) -> int:
    """每日运势推送任务（支持个人化推送时间）

    根据用户的时区和个人化推送时间发送运势
    返回发送成功的消息数量

    Args:
        target_users: 可选的目标用户列表，格式为 [(user_id, bipupu_id), ...]
                     如果为None，则自动获取当前时间应该接收推送的用户
    """
    db = SessionLocal()
    try:
        # 如果没有提供目标用户，自动获取
        if target_users is None:
            current_utc = datetime.now(timezone.utc)
            target_users = get_users_for_push_time(db, "cosmic.fortune", current_utc.hour, current_utc.minute)

        if not target_users:
            logger.info("没有需要推送运势的用户")
            return 0

        logger.info(f"开始推送运势，目标用户数量：{len(target_users)}")

        # 创建异步任务发送给目标用户
        async def send_to_target_users():
            tasks = []
            for user_id, bipupu_id in target_users:
                user = db.query(User).filter(User.id == user_id).first()
                if user:
                    tasks.append(_send_fortune_to_user(db, user))

            if not tasks:
                return 0

            results = await asyncio.gather(*tasks, return_exceptions=True)
            # 计算成功的数量
            success_count = 0
            for result in results:
                if result is True:
                    success_count += 1
                elif isinstance(result, Exception):
                    logger.error(f"异步任务异常: {result}")
            return success_count

        sent_count = asyncio.run(send_to_target_users())

        logger.info(f"运势任务完成，成功发送：{sent_count}/{len(target_users)}")
        return sent_count

    except Exception as e:
        logger.error(f"运势任务失败: {e}")
        self.retry(exc=e)
        return 0
    finally:
        db.close()


@shared_task(name="subscriptions.weather", bind=True, max_retries=3, default_retry_delay=60)
def weather_task(self, target_users: list = None) -> int:
    """每日天气推送任务（支持个人化推送时间）

    根据用户的时区和个人化推送时间发送天气预报
    返回发送成功的消息数量

    Args:
        target_users: 可选的目标用户列表，格式为 [(user_id, bipupu_id), ...]
                     如果为None，则自动获取当前时间应该接收推送的用户
    """
    db = SessionLocal()
    try:
        # 如果没有提供目标用户，自动获取
        if target_users is None:
            current_utc = datetime.now(timezone.utc)
            target_users = get_users_for_push_time(db, "weather.service", current_utc.hour, current_utc.minute)

        if not target_users:
            logger.info("没有需要推送天气的用户")
            return 0

        logger.info(f"开始推送天气，目标用户数量：{len(target_users)}")

        # 创建异步任务发送给目标用户
        async def send_to_target_users():
            tasks = []
            for user_id, bipupu_id in target_users:
                user = db.query(User).filter(User.id == user_id).first()
                if user:
                    tasks.append(_send_weather_to_user(db, user))

            if not tasks:
                return 0

            results = await asyncio.gather(*tasks, return_exceptions=True)
            # 计算成功的数量
            success_count = 0
            for result in results:
                if result is True:
                    success_count += 1
                elif isinstance(result, Exception):
                    logger.error(f"异步任务异常: {result}")
            return success_count

        sent_count = asyncio.run(send_to_target_users())

        logger.info(f"天气任务完成，成功发送：{sent_count}/{len(target_users)}")
        return sent_count

    except Exception as e:
        logger.error(f"天气任务失败: {e}")
        self.retry(exc=e)
        return 0
    finally:
        db.close()


def get_subscriber_stats(db: Session) -> dict:
    """获取订阅统计信息

    返回各个服务号的订阅者数量
    """
    services = db.query(ServiceAccount).filter(
        ServiceAccount.is_active == True
    ).all()

    stats = {}
    for service in services:
        stats[service.name] = len(service.subscribers)

    return stats


def get_push_schedule_stats(db: Session) -> dict:
    """获取推送时间统计信息

    返回各个推送时间段的用户数量分布
    """
    from sqlalchemy import func, extract

    stats = {
        "cosmic.fortune": {},
        "weather.service": {}
    }

    for service_name in ["cosmic.fortune", "weather.service"]:
        service = db.query(ServiceAccount).filter(
            ServiceAccount.name == service_name
        ).first()

        if not service:
            continue

        # 查询推送时间分布
        stmt = select(
            subscription_table.c.push_time,
            func.count(subscription_table.c.user_id).label('user_count')
        ).where(
            and_(
                subscription_table.c.service_account_id == service.id,
                subscription_table.c.is_enabled == True,
                subscription_table.c.push_time.is_not(None)
            )
        ).group_by(subscription_table.c.push_time)

        results = db.execute(stmt).all()

        time_distribution = {}
        for push_time, user_count in results:
            time_str = push_time.strftime("%H:%M")
            time_distribution[time_str] = user_count

        stats[service_name]["custom_push_times"] = time_distribution

        # 统计使用默认时间的用户
        default_time_stmt = select(
            func.count(subscription_table.c.user_id)
        ).where(
            and_(
                subscription_table.c.service_account_id == service.id,
                subscription_table.c.is_enabled == True,
                subscription_table.c.push_time.is_(None)
            )
        )

        default_count = db.execute(default_time_stmt).scalar()
        stats[service_name]["default_push_time_users"] = default_count or 0

        # 统计禁用推送的用户
        disabled_stmt = select(
            func.count(subscription_table.c.user_id)
        ).where(
            and_(
                subscription_table.c.service_account_id == service.id,
                subscription_table.c.is_enabled == False
            )
        )

        disabled_count = db.execute(disabled_stmt).scalar()
        stats[service_name]["disabled_users"] = disabled_count or 0

    return stats


def send_test_push(service_name: str, user_bipupu_id: str) -> bool:
    """发送测试推送（用于调试）

    Args:
        service_name: 服务号名称
        user_bipupu_id: 用户BIPUPU ID

    Returns:
        bool: 是否成功
    """
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.bipupu_id == user_bipupu_id).first()
        if not user:
            logger.error(f"用户 {user_bipupu_id} 不存在")
            return False

        now_utc = datetime.now(timezone.utc)

        async def send_test():
            if service_name == "cosmic.fortune":
                content = generate_daily_fortune(user_bipupu_id, now_utc)
            elif service_name == "weather.service":
                content = generate_weather_forecast(now_utc)
            else:
                logger.error(f"不支持的服务号：{service_name}")
                return False

            await send_push(db, service_name, user_bipupu_id, content)
            return True

        success = asyncio.run(send_test())
        if success:
            logger.info(f"测试推送成功：{service_name} -> {user_bipupu_id}")
        return success

    except Exception as e:
        logger.error(f"测试推送失败: {e}")
        return False
    finally:
        db.close()


def send_immediate_push(service_name: str, user_bipupu_id: str, content: str = None) -> bool:
    """立即发送推送（绕过时间检查，用于管理后台）

    Args:
        service_name: 服务号名称
        user_bipupu_id: 用户BIPUPU ID
        content: 自定义内容（可选）

    Returns:
        bool: 是否成功
    """
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.bipupu_id == user_bipupu_id).first()
        if not user:
            logger.error(f"用户 {user_bipupu_id} 不存在")
            return False

        async def send_immediate():
            if content:
                push_content = content
            elif service_name == "cosmic.fortune":
                push_content = generate_daily_fortune(user_bipupu_id, datetime.now(timezone.utc))
            elif service_name == "weather.service":
                push_content = generate_weather_forecast(datetime.now(timezone.utc))
            else:
                logger.error(f"不支持的服务号：{service_name}")
                return False

            await send_push(db, service_name, user_bipupu_id, push_content)
            return True

        success = asyncio.run(send_immediate())
        if success:
            logger.info(f"立即推送成功：{service_name} -> {user_bipupu_id}")
        return success

    except Exception as e:
        logger.error(f"立即推送失败: {e}")
        return False
    finally:
        db.close()
