"""用户工具函数"""
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from app.models.user import User
import random


def generate_bipupu_id(db: Session) -> str:
    """生成唯一的 4 位数字 ID
    
    策略：
    1. 从 0001 开始递增分配
    2. 如果有空洞（删除的用户），可以复用
    3. 确保唯一性（使用数据库唯一约束兜底）
    
    线程安全：
    - 使用数据库唯一约束防止并发冲突
    - 调用方需要捕获 IntegrityError 并重试
    """
    # 先尝试获取最小的可用 ID（填补空洞）
    # 查询所有已使用的 ID，找到第一个未使用的
    used_ids = db.query(User.bipupu_id).filter(
        User.bipupu_id.like('____')  # 只匹配 4 位数字
    ).all()
    
    used_id_set = {str(row[0]) for row in used_ids if row[0] and str(row[0]).isdigit()}
    
    # 从 0001 开始找第一个未使用的 ID
    for i in range(1, 10000):
        bipupu_id = f"{i:04d}"
        if bipupu_id not in used_id_set:
            return bipupu_id
    
    # 如果所有 4 位数字都用完了，抛出异常
    raise ValueError("ID pool exhausted: 所有 4 位数字 ID 已用尽")


def is_service_account(bipupu_id: str) -> bool:
    """判断是否为服务号
    
    服务号示例：
    - cosmic.fortune
    - weather.service
    - system.notification
    """
    return "." in bipupu_id and not bipupu_id.isdigit()


def get_western_zodiac(birth_date):
    """根据公历生日返回中文星座名称。支持 date 或 datetime 或 ISO 字符串。"""
    from datetime import datetime, date

    if birth_date is None:
        return None

    if isinstance(birth_date, str):
        try:
            birth_date = datetime.fromisoformat(birth_date).date()
        except Exception:
            try:
                birth_date = datetime.strptime(birth_date, "%Y-%m-%d").date()
            except Exception:
                return None

    if isinstance(birth_date, datetime):
        birth_date = birth_date.date()

    if not isinstance(birth_date, date):
        return None

    month = birth_date.month
    day = birth_date.day
    if (month == 1 and day >= 20) or (month == 2 and day <= 18):
        return "水瓶座"
    if (month == 2 and day >= 19) or (month == 3 and day <= 20):
        return "双鱼座"
    if (month == 3 and day >= 21) or (month == 4 and day <= 19):
        return "白羊座"
    if (month == 4 and day >= 20) or (month == 5 and day <= 20):
        return "金牛座"
    if (month == 5 and day >= 21) or (month == 6 and day <= 20):
        return "双子座"
    if (month == 6 and day >= 21) or (month == 7 and day <= 22):
        return "巨蟹座"
    if (month == 7 and day >= 23) or (month == 8 and day <= 22):
        return "狮子座"
    if (month == 8 and day >= 23) or (month == 9 and day <= 22):
        return "处女座"
    if (month == 9 and day >= 23) or (month == 10 and day <= 22):
        return "天秤座"
    if (month == 10 and day >= 23) or (month == 11 and day <= 21):
        return "天蝎座"
    if (month == 11 and day >= 22) or (month == 12 and day <= 21):
        return "射手座"
    if (month == 12 and day >= 22) or (month == 1 and day <= 19):
        return "摩羯座"
    return None
