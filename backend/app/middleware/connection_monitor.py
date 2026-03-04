"""数据库连接池监控中间件

监控连接池使用情况，记录长时间占用连接的请求，早期发现连接泄漏问题
"""

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from app.core.logging import get_logger
from app.db.database import engine
import time

logger = get_logger(__name__)


class ConnectionMonitorMiddleware(BaseHTTPMiddleware):
    """监控数据库连接池使用情况的中间件
    
    功能：
    1. 记录长时间占用连接的请求（> 5秒）
    2. 检测连接泄漏（连接数异常增加）
    3. 记录连接池饱和情况（> 80%）
    """
    
    async def dispatch(self, request: Request, call_next):
        """处理请求并监控连接"""
        start_time = time.time()
        
        try:
            # 获取连接池状态（查询前）
            before_size = self._get_pool_size()
            
            # 处理请求
            response = await call_next(request)
            
            # 计算请求耗时
            elapsed = time.time() - start_time
            
            # 获取连接池状态（查询后）
            after_size = self._get_pool_size()
            after_checked_in = self._get_checked_in_connections()
            
            # 🔍 监控指标 1: 长时间占用连接的请求
            if elapsed > 5:  # 超过 5 秒
                logger.warning(
                    f"⚠️ 长时间占用连接: {request.method} {request.url.path} "
                    f"耗时 {elapsed:.2f}s, 连接数 {after_size}"
                )
            
            # 🔍 监控指标 2: 连接泄漏告警
            if after_size > before_size + 3:
                logger.error(
                    f"❌ 可能的连接泄漏: {request.method} {request.url.path} "
                    f"后连接数增加 {after_size - before_size}, "
                    f"当前连接池: {after_size}"
                )
            
            # 🔍 监控指标 3: 连接池饱和度
            pool_utilization = (after_checked_in / after_size) * 100 if after_size > 0 else 0
            if pool_utilization > 80:
                logger.warning(
                    f"⚠️ 连接池接近饱和: {request.method} {request.url.path} "
                    f"饱和度 {pool_utilization:.1f}% "
                    f"({after_checked_in}/{after_size} 连接)"
                )
            
            # 🔍 监控指标 4: 长轮询接口专项监控
            if "/poll" in request.url.path:
                logger.debug(
                    f"📊 长轮询: {request.method} {request.url.path} "
                    f"耗时 {elapsed:.2f}s, 连接 {after_checked_in}/{after_size}"
                )
            
            return response
            
        except Exception as e:
            logger.error(f"❌ 请求处理失败: {request.method} {request.url.path} - {e}")
            raise

    def _get_pool_size(self) -> int:
        """获取连接池中的连接总数"""
        try:
            pool = engine.pool
            # SQLAlchemy 连接池属性
            if hasattr(pool, 'size'):
                return int(pool.size()) if callable(pool.size) else 0  # type: ignore[union-attr]
            elif hasattr(pool, '_all_conns'):
                return len(pool._all_conns)  # type: ignore[arg-type]
            elif hasattr(pool, '_pool'):
                return getattr(pool._pool, 'qsize', lambda: 0)()
            else:
                return 0
        except Exception as e:
            logger.debug(f"Failed to get pool size: {e}")
            return 0

    def _get_checked_in_connections(self) -> int:
        """获取当前被占用的连接数"""
        try:
            pool = engine.pool
            # SQLAlchemy 连接池属性
            if hasattr(pool, 'checkedout'):
                return int(pool.checkedout()) if callable(pool.checkedout) else 0  # type: ignore[union-attr]
            elif hasattr(pool, '_checked_out'):
                return len(pool._checked_out)  # type: ignore[arg-type]
            elif hasattr(pool, '_pool'):
                # 对于QueuePool，被占用的连接数 = 总数 - 队列中可用的数
                try:
                    qsize_fn = getattr(pool._pool, 'qsize', None)
                    available = qsize_fn() if qsize_fn and callable(qsize_fn) else 0
                    # 这是一个近似值
                    return max(0, 10 - available)  # 假设pool大小为10
                except Exception:
                    return 0
            return 0
        except Exception as e:
            logger.debug(f"Failed to get checked out connections: {e}")
            return 0
