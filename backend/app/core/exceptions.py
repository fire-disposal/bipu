"""统一异常处理模块"""

from typing import Optional, Dict, Any, Union, Awaitable
from fastapi import HTTPException, status, Request
from fastapi.responses import JSONResponse, Response
from starlette.responses import RedirectResponse
from app.core.logging import get_logger

logger = get_logger(__name__)


class BaseCustomException(Exception):
    """自定义异常基类"""

    def __init__(self, message: str, code: Optional[str] = None, details: Optional[Dict[str, Any]] = None):
        self.message = message
        self.code = code
        self.details = details or {}
        super().__init__(self.message)


class ValidationException(BaseCustomException):
    """验证异常"""
    pass


class NotFoundException(BaseCustomException):
    """资源未找到异常"""
    pass


class UnauthorizedException(BaseCustomException):
    """未授权异常"""
    pass


class ForbiddenException(BaseCustomException):
    """禁止访问异常"""
    pass


class ConflictException(BaseCustomException):
    """冲突异常"""
    pass


class InternalServerException(BaseCustomException):
    """服务器内部错误异常"""
    pass


def exception_handler(exc: BaseCustomException) -> Dict[str, Any]:
    """异常转换为HTTP响应格式"""
    return {
        "success": False,
        "error": {
            "type": exc.__class__.__name__,
            "message": exc.message,
            "code": exc.code,
            "details": exc.details
        }
    }



class AdminAuthException(Exception):
    """管理后台认证失败异常，用于触发重定向"""
    pass

async def admin_auth_exception_handler(request: Request, exc: AdminAuthException) -> RedirectResponse:
    """捕获管理后台认证异常，重定向到登录页"""
    return RedirectResponse(url="/admin/login", status_code=302)


async def custom_exception_handler(request: Request, exc: BaseCustomException) -> JSONResponse:
    """FastAPI异常处理器"""
    logger.error(f"Exception occurred: {exc.__class__.__name__}: {exc.message}")

    # 根据异常类型返回相应的HTTP状态码
    if isinstance(exc, ValidationException):
        status_code = status.HTTP_422_UNPROCESSABLE_ENTITY
    elif isinstance(exc, NotFoundException):
        status_code = status.HTTP_404_NOT_FOUND
    elif isinstance(exc, UnauthorizedException):
        status_code = status.HTTP_401_UNAUTHORIZED
    elif isinstance(exc, ForbiddenException):
        status_code = status.HTTP_403_FORBIDDEN
    elif isinstance(exc, ConflictException):
        status_code = status.HTTP_409_CONFLICT
    else:
        status_code = status.HTTP_500_INTERNAL_SERVER_ERROR

    return JSONResponse(
        status_code=status_code,
        content=exception_handler(exc)
    )


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """处理HTTPException"""
    logger.warning(f"HTTP Exception: {exc.status_code} - {exc.detail}")

    error_response = {
        "success": False,
        "error": {
            "type": "HTTPException",
            "message": str(exc.detail),
            "code": str(exc.status_code),
            "details": {}
        }
    }

    return JSONResponse(
        status_code=exc.status_code,
        content=error_response
    )


async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """处理一般异常"""
    logger.error(f"General exception: {exc}", exc_info=True)

    error_response = {
        "success": False,
        "error": {
            "type": "InternalServerError",
            "message": "Internal server error",
            "code": "INTERNAL_ERROR",
            "details": {}
        }
    }

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=error_response
    )
