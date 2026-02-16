from celery import shared_task
from app.db.database import SessionLocal
from app.core.logging import get_logger
from app.models.service_account import ServiceAccount

from app.services import service_accounts
import pytz
from datetime import datetime, timezone
import hashlib

logger = get_logger(__name__)


def generate_daily_fortune(bipupu_id: str, date: datetime):
    """Deterministic fortune generator based on user id and date."""
    seed = f"{bipupu_id}:{date.date().isoformat()}"
    digest = hashlib.sha256(seed.encode()).hexdigest()
    # choose indices
    fortunes = ["大吉 🌟", "中吉 ⭐", "小吉 ✨", "平 😐", "凶 ⚠️"]
    lucky_items = ["红色外套", "笔记本电脑", "咖啡", "耳机", "Pupu机"]
    fi = int(digest[0:8], 16) % len(fortunes)
    li = int(digest[8:16], 16) % len(lucky_items)
    return f"今日运势：{fortunes[fi]}。\n幸运物：{lucky_items[li]}"


@shared_task(name="subscriptions.fortune")
def fortune_task():
    """检查订阅并向符合本地时间的订阅用户发送每日运势。"""
    db = SessionLocal()
    try:
        service = db.query(ServiceAccount).filter(ServiceAccount.name == "cosmic.fortune").first()
        if not service:
            logger.info("No cosmic.fortune service account found")
            return 0

        sent = 0
        now_utc = datetime.now(timezone.utc)

        for user in service.subscribers:
            # 确定用户时区和预设时间
            user_tz = user.timezone or "UTC"
            push_time = user.fortune_time or "07:30"

            try:
                tz = pytz.timezone(user_tz)
            except Exception:
                tz = pytz.UTC

            user_now = pytz.utc.localize(now_utc).astimezone(tz)
            hhmm = user_now.strftime("%H:%M")

            # 如果用户本地时间与设定时间吻合，则发送
            if hhmm == push_time:
                content = generate_daily_fortune(user.bipupu_id, user_now)
                # 以服务号身份发送，使用 SERVICE 类型
                import asyncio
                asyncio.get_event_loop().run_until_complete(
                    service_accounts.send_reply(db, "cosmic.fortune", user.bipupu_id, content, None, "SYSTEM")
                )
                sent += 1

        logger.info(f"Fortune task completed, sent={sent}")
        return sent
    except Exception as e:
        logger.error(f"Fortune task failed: {e}")
        raise
    finally:
        db.close()
