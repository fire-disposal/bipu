"""用户工具函数"""
from sqlalchemy.orm import Session
from app.models.user import User
import random


def generate_bipupu_id(db: Session) -> str:
    """生成唯一的8位数字ID
    
    策略：
    1. 从00000001开始递增分配
    2. 如果有空洞（删除的用户），可以复用
    3. 确保唯一性
    """
    # 获取最大的 bipupu_id
    max_user = db.query(User).order_by(User.bipupu_id.desc()).first()
    
    if not max_user:
        # 第一个用户
        return "00000001"
    
    try:
        # 尝试递增
        next_id = int(max_user.bipupu_id) + 1
        if next_id > 99999999:
            # 如果超出范围，从头开始找空洞
            raise ValueError("ID pool exhausted")
        
        bipupu_id = f"{next_id:08d}"
        
        # 确保唯一性
        while db.query(User).filter(User.bipupu_id == bipupu_id).first():
            next_id += 1
            if next_id > 99999999:
                raise ValueError("ID pool exhausted")
            bipupu_id = f"{next_id:08d}"
        
        return bipupu_id
        
    except (ValueError, AttributeError):
        # 如果出错，随机生成并检查唯一性
        max_attempts = 100
        for _ in range(max_attempts):
            bipupu_id = f"{random.randint(1, 99999999):08d}"
            if not db.query(User).filter(User.bipupu_id == bipupu_id).first():
                return bipupu_id
        
        raise ValueError("无法生成唯一的 bipupu_id")


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
