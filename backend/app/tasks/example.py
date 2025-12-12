from celery import shared_task
from app.celery import celery_app
from app.core.logging import get_logger

logger = get_logger(__name__)


@shared_task
def add_numbers(a: int, b: int) -> int:
    """简单的加法任务"""
    result = a + b
    logger.info(f"Adding {a} + {b} = {result}")
    return result


@shared_task
def process_data(data: dict) -> dict:
    """处理数据的示例任务"""
    logger.info(f"Processing data: {data}")
    
    # 模拟一些处理工作
    processed_data = {
        "original": data,
        "processed": True,
        "timestamp": "2024-01-01T00:00:00Z"
    }
    
    logger.info(f"Data processed successfully")
    return processed_data


@shared_task(bind=True)
def long_running_task(self, duration: int = 10):
    """长时间运行的任务示例"""
    import time
    
    logger.info(f"Starting long running task for {duration} seconds")
    
    for i in range(duration):
        time.sleep(1)
        logger.info(f"Task progress: {i+1}/{duration}")
        
        # 更新任务状态
        self.update_state(
            state='PROGRESS',
            meta={'current': i+1, 'total': duration}
        )
    
    logger.info("Long running task completed")
    return {"status": "completed", "duration": duration}