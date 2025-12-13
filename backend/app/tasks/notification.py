"""通知相关任务"""
import asyncio
import smtplib
from datetime import datetime
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from celery import shared_task
from app.db.database import SessionLocal
from app.models.notification import Notification, NotificationStatus
from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)


@shared_task(bind=True, max_retries=3)
def send_email_notification(self, notification_id: int):
    """发送邮件通知"""
    try:
        db = SessionLocal()
        notification = db.query(Notification).filter(Notification.id == notification_id).first()
        
        if not notification:
            logger.error(f"通知 {notification_id} 不存在")
            return
        
        if notification.status != NotificationStatus.PENDING:
            logger.warning(f"通知 {notification_id} 状态不是待发送")
            return
        
        # 更新状态为发送中
        notification.status = NotificationStatus.SENT
        notification.sent_at = datetime.utcnow()
        db.commit()
        
        # 这里应该配置真实的SMTP服务器
        # 现在只是模拟发送
        try:
            # 模拟邮件发送
            msg = MIMEMultipart()
            msg['From'] = "noreply@bipupu.com"
            msg['To'] = notification.target
            msg['Subject'] = notification.title
            
            body = notification.content
            msg.attach(MIMEText(body, 'plain'))
            
            # 这里应该连接到真实的SMTP服务器
            # smtp_server = smtplib.SMTP('smtp.gmail.com', 587)
            # smtp_server.starttls()
            # smtp_server.login("your_email@gmail.com", "your_password")
            # smtp_server.send_message(msg)
            # smtp_server.quit()
            
            logger.info(f"邮件通知发送成功: {notification.title} -> {notification.target}")
            notification.result = "Email sent successfully"
            
        except Exception as e:
            logger.error(f"邮件发送失败: {e}")
            notification.status = NotificationStatus.FAILED
            notification.error_message = str(e)
            notification.retry_count += 1
            
            # 如果重试次数未达到最大值，则重试
            if notification.retry_count < notification.max_retries:
                raise self.retry(countdown=60 * (notification.retry_count + 1))  # 指数退避
            
        db.commit()
        
    except Exception as e:
        logger.error(f"发送邮件通知失败: {e}")
        if notification:
            notification.status = NotificationStatus.FAILED
            notification.error_message = str(e)
            db.commit()
        raise
    finally:
        db.close()


@shared_task(bind=True, max_retries=3)
def send_push_notification(self, notification_id: int):
    """发送推送通知"""
    try:
        db = SessionLocal()
        notification = db.query(Notification).filter(Notification.id == notification_id).first()
        
        if not notification:
            logger.error(f"通知 {notification_id} 不存在")
            return
        
        if notification.status != NotificationStatus.PENDING:
            logger.warning(f"通知 {notification_id} 状态不是待发送")
            return
        
        # 更新状态为发送中
        notification.status = NotificationStatus.SENT
        notification.sent_at = datetime.utcnow()
        db.commit()
        
        try:
            # 这里应该集成真实的推送服务（如FCM、APNs等）
            # 现在只是模拟发送
            
            device_token = notification.target
            
            # 模拟推送发送
            logger.info(f"推送通知发送成功: {notification.title} -> {device_token}")
            notification.result = "Push notification sent successfully"
            
        except Exception as e:
            logger.error(f"推送发送失败: {e}")
            notification.status = NotificationStatus.FAILED
            notification.error_message = str(e)
            notification.retry_count += 1
            
            if notification.retry_count < notification.max_retries:
                raise self.retry(countdown=60 * (notification.retry_count + 1))
            
        db.commit()
        
    except Exception as e:
        logger.error(f"发送推送通知失败: {e}")
        if notification:
            notification.status = NotificationStatus.FAILED
            notification.error_message = str(e)
            db.commit()
        raise
    finally:
        db.close()


@shared_task(bind=True, max_retries=3)
def send_sms_notification(self, notification_id: int):
    """发送短信通知"""
    try:
        db = SessionLocal()
        notification = db.query(Notification).filter(Notification.id == notification_id).first()
        
        if not notification:
            logger.error(f"通知 {notification_id} 不存在")
            return
        
        if notification.status != NotificationStatus.PENDING:
            logger.warning(f"通知 {notification_id} 状态不是待发送")
            return
        
        # 更新状态为发送中
        notification.status = NotificationStatus.SENT
        notification.sent_at = datetime.utcnow()
        db.commit()
        
        try:
            # 这里应该集成真实的短信服务（如Twilio、阿里云短信等）
            # 现在只是模拟发送
            
            phone_number = notification.target
            
            # 模拟短信发送
            logger.info(f"短信通知发送成功: {notification.title} -> {phone_number}")
            notification.result = "SMS sent successfully"
            
        except Exception as e:
            logger.error(f"短信发送失败: {e}")
            notification.status = NotificationStatus.FAILED
            notification.error_message = str(e)
            notification.retry_count += 1
            
            if notification.retry_count < notification.max_retries:
                raise self.retry(countdown=60 * (notification.retry_count + 1))
            
        db.commit()
        
    except Exception as e:
        logger.error(f"发送短信通知失败: {e}")
        if notification:
            notification.status = NotificationStatus.FAILED
            notification.error_message = str(e)
            db.commit()
        raise
    finally:
        db.close()


@shared_task
def process_pending_notifications():
    """处理待发送的通知"""
    try:
        db = SessionLocal()
        
        # 获取所有待发送的通知
        pending_notifications = db.query(Notification).filter(
            Notification.status == NotificationStatus.PENDING
        ).all()
        
        processed_count = 0
        failed_count = 0
        
        for notification in pending_notifications:
            try:
                # 根据通知类型调用相应的任务
                if notification.notification_type.value == "email":
                    send_email_notification.delay(notification.id)
                elif notification.notification_type.value == "push":
                    send_push_notification.delay(notification.id)
                elif notification.notification_type.value == "sms":
                    send_sms_notification.delay(notification.id)
                elif notification.notification_type.value == "webhook":
                    # Webhook通知可以同步处理
                    send_webhook_notification(notification.id)
                
                processed_count += 1
                
            except Exception as e:
                logger.error(f"处理通知 {notification.id} 失败: {e}")
                notification.status = NotificationStatus.FAILED
                notification.error_message = str(e)
                failed_count += 1
        
        db.commit()
        logger.info(f"处理了 {processed_count} 个通知，失败 {failed_count} 个")
        
        return {
            "processed": processed_count,
            "failed": failed_count,
            "total": len(pending_notifications)
        }
        
    except Exception as e:
        logger.error(f"处理待发送通知失败: {e}")
        raise
    finally:
        db.close()


def send_webhook_notification(notification_id: int):
    """发送Webhook通知（同步执行）"""
    # 这里应该实现Webhook发送逻辑
    # 由于Webhook通常是HTTP请求，可以同步执行
    logger.info(f"Webhook通知 {notification_id} 发送逻辑待实现")