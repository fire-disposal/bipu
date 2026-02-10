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
