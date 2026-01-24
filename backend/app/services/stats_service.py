from sqlalchemy import func, text
from sqlalchemy.orm import Session
from datetime import date, datetime, timedelta, timezone
from app.models.user import User
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
    def get_user_stats(db: Session) -> dict:
        """
        获取用户相关的完备统计数据
        """
        total_users = db.query(User).count()
        active_users = db.query(User).filter(User.is_active == True).count()
        inactive_users = db.query(User).filter(User.is_active == False).count()
        superusers = db.query(User).filter(User.is_superuser == True).count()
        
        # 今日注册用户
        today = date.today()
        today_users = db.query(User).filter(
            func.date(User.created_at) == today
        ).count()
        
        # 最近7天活跃用户
        # 注意：这里假设系统已有 last_active 字段的维护逻辑
        week_ago = datetime.now(timezone.utc) - timedelta(days=7)
        recent_active_users = db.query(User).filter(
            User.last_active >= week_ago
        ).count()
        
        return {
            "total_users": total_users,
            "active_users": active_users,
            "inactive_users": inactive_users,
            "superusers": superusers,
            "today_new_users": today_users,
            "recent_active_users_7d": recent_active_users,
            "activation_rate": active_users / total_users if total_users > 0 else 0
        }

    @staticmethod
    def get_simple_user_counts(db: Session) -> dict:
        """
        获取简略的用户统计（用于后台任务/健康检查）
        优化了查询性能，只查需要的字段
        """
        total = db.query(func.count(User.id)).scalar() or 0
        active = db.query(func.count(User.id)).filter(User.is_active == True).scalar() or 0
        superusers = db.query(func.count(User.id)).filter(User.is_superuser == True).scalar() or 0
        
        return {
            "total": total,
            "active": active,
            "superusers": superusers
        }
