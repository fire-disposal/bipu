"""设备相关任务"""
from datetime import datetime, timedelta
from sqlalchemy import and_
from celery import shared_task
from app.db.database import SessionLocal
from app.models.device import Device
from app.models.message import Message, MessageType
from app.core.logging import get_logger

logger = get_logger(__name__)


@shared_task
def update_device_status():
    """更新设备状态（将长时间未心跳的设备标记为离线）"""
    try:
        db = SessionLocal()
        
        # 计算5分钟前的日期（设备心跳超时时间）
        timeout_date = datetime.utcnow() - timedelta(minutes=5)
        
        # 查找在线但长时间未心跳的设备
        offline_devices = db.query(Device).filter(
            and_(
                Device.status == "online",
                Device.last_seen_at < timeout_date
            )
        ).all()
        
        updated_count = 0
        for device in offline_devices:
            device.status = "offline"
            updated_count += 1
            
            # 创建设备离线消息
            message = Message(
                title=f"设备离线提醒",
                content=f"设备 {device.name} (ID: {device.device_id}) 已离线",
                message_type=MessageType.ALERT,
                priority=5,
                user_id=device.user_id,
                device_id=device.id
            )
            db.add(message)
            
            logger.info(f"设备 {device.name} 状态更新为离线")
        
        db.commit()
        logger.info(f"更新了 {updated_count} 个设备状态为离线")
        
        return {"updated_devices": updated_count}
        
    except Exception as e:
        logger.error(f"更新设备状态失败: {e}")
        raise
    finally:
        db.close()


@shared_task
def check_device_health():
    """检查设备健康状态"""
    try:
        db = SessionLocal()
        
        # 获取所有在线设备
        online_devices = db.query(Device).filter(Device.status == "online").all()
        
        healthy_count = 0
        warning_count = 0
        
        for device in online_devices:
            # 这里可以添加实际的健康检查逻辑
            # 现在只是模拟检查
            if device.last_seen_at:
                time_diff = datetime.utcnow() - device.last_seen_at
                if time_diff > timedelta(minutes=2):
                    # 创建警告消息
                    message = Message(
                        title=f"设备健康警告",
                        content=f"设备 {device.name} (ID: {device.device_id}) 响应缓慢",
                        message_type=MessageType.ALERT,
                        priority=3,
                        user_id=device.user_id,
                        device_id=device.id
                    )
                    db.add(message)
                    warning_count += 1
                else:
                    healthy_count += 1
        
        db.commit()
        logger.info(f"设备健康检查完成: {healthy_count} 个健康, {warning_count} 个警告")
        
        return {
            "healthy_devices": healthy_count,
            "warning_devices": warning_count,
            "total_checked": len(online_devices)
        }
        
    except Exception as e:
        logger.error(f"设备健康检查失败: {e}")
        raise
    finally:
        db.close()


@shared_task
def cleanup_offline_devices():
    """清理长时间离线的设备（可选任务）"""
    try:
        db = SessionLocal()
        
        # 计算7天前的日期
        cutoff_date = datetime.utcnow() - timedelta(days=7)
        
        # 查找长时间离线的设备
        offline_devices = db.query(Device).filter(
            and_(
                Device.status == "offline",
                Device.last_seen_at < cutoff_date
            )
        ).all()
        
        # 这里可以选择删除或归档这些设备
        # 现在只是记录日志
        logger.info(f"发现 {len(offline_devices)} 个长时间离线的设备")
        
        for device in offline_devices:
            logger.info(f"设备 {device.name} (ID: {device.device_id}) 已离线超过7天")
        
        return {"offline_devices": len(offline_devices)}
        
    except Exception as e:
        logger.error(f"清理离线设备失败: {e}")
        raise
    finally:
        db.close()