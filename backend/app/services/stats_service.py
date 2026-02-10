from sqlalchemy import func, text
from sqlalchemy.orm import Session
from datetime import date, datetime, timedelta, timezone
from app.models.user import User
from app.models.message import Message
from app.models.service_account import ServiceAccount
from app.db.database import get_redis
from app.core.logging import get_logger

logger = get_logger(__name__)

class StatsService:
    @staticmethod
    async def check_system_health(db: Session, project_name: str = "bipupu-backend") -> dict:
        """检查系统健康状态"""
        try:
            # 检查数据库连接
            db.execute(text("SELECT 1"))
            
            # 检查Redis连接
            redis_client = await get_redis()
            await redis_client.ping()
            
            return {
                "status": "healthy",
                "database": "connected",
                "redis": "connected",
                "service": project_name
            }
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return {
                "status": "unhealthy",
                "error": str(e),
                "service": project_name
            }

    @staticmethod
    def get_dashboard_stats(db: Session) -> dict:
        """
        获取管理面板相关统计数据 (整合查询)
        """
        # 1. 用户统计
        total_users = db.query(func.count(User.id)).scalar() or 0
        active_users = db.query(func.count(User.id)).filter(User.is_active == True).scalar() or 0
        today = date.today()
        today_new_users = db.query(func.count(User.id)).filter(func.date(User.created_at) == today).scalar() or 0
        
        # 2. 消息统计
        total_messages = db.query(func.count(Message.id)).scalar() or 0
        today_messages = db.query(func.count(Message.id)).filter(func.date(Message.created_at) == today).scalar() or 0
        
        # 3. 服务号统计
        total_services = db.query(func.count(ServiceAccount.id)).scalar() or 0
        active_services = db.query(func.count(ServiceAccount.id)).filter(ServiceAccount.is_active == True).scalar() or 0
        
        return {
            "users": {
                "total": total_users,
                "active": active_users,
                "today_new": today_new_users
            },
            "messages": {
                "total": total_messages,
                "today": today_messages
            },
            "services": {
                "total": total_services,
                "active": active_services
            }
        }

