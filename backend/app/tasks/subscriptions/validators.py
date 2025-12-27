"""消息验证器"""
from typing import Dict, Any, Optional
from app.core.logging import get_logger


logger = get_logger(__name__)


class MessageValidator:
    """消息内容和格式验证器"""
    
    # 消息标题限制
    MIN_TITLE_LENGTH = 1
    MAX_TITLE_LENGTH = 200
    
    # 消息内容限制
    MIN_CONTENT_LENGTH = 1
    MAX_CONTENT_LENGTH = 5000
    
    # 优先级限制
    MIN_PRIORITY = 0
    MAX_PRIORITY = 10
    
    # 禁止的字符
    FORBIDDEN_CHARS = ['<script>', '</script>', 'javascript:', 'onerror=', 'onload=']
    
    @classmethod
    def validate_title(cls, title: str) -> bool:
        """验证消息标题
        
        Args:
            title: 消息标题
            
        Returns:
            bool: 是否有效
            
        Raises:
            ValueError: 如果验证失败
        """
        if not isinstance(title, str):
            raise ValueError("标题必须是字符串类型")
        
        if not title or len(title.strip()) < cls.MIN_TITLE_LENGTH:
            raise ValueError(f"标题长度必须至少 {cls.MIN_TITLE_LENGTH} 个字符")
        
        if len(title) > cls.MAX_TITLE_LENGTH:
            raise ValueError(f"标题长度不能超过 {cls.MAX_TITLE_LENGTH} 个字符")
        
        if cls._contains_forbidden_chars(title):
            raise ValueError("标题包含不安全的字符")
        
        return True
    
    @classmethod
    def validate_content(cls, content: str) -> bool:
        """验证消息内容
        
        Args:
            content: 消息内容
            
        Returns:
            bool: 是否有效
            
        Raises:
            ValueError: 如果验证失败
        """
        if not isinstance(content, str):
            raise ValueError("内容必须是字符串类型")
        
        if not content or len(content.strip()) < cls.MIN_CONTENT_LENGTH:
            raise ValueError(f"内容长度必须至少 {cls.MIN_CONTENT_LENGTH} 个字符")
        
        if len(content) > cls.MAX_CONTENT_LENGTH:
            raise ValueError(f"内容长度不能超过 {cls.MAX_CONTENT_LENGTH} 个字符")
        
        if cls._contains_forbidden_chars(content):
            raise ValueError("内容包含不安全的字符")
        
        return True
    
    @classmethod
    def validate_priority(cls, priority: int) -> bool:
        """验证优先级
        
        Args:
            priority: 优先级值
            
        Returns:
            bool: 是否有效
            
        Raises:
            ValueError: 如果验证失败
        """
        if not isinstance(priority, int):
            raise ValueError("优先级必须是整数类型")
        
        if not (cls.MIN_PRIORITY <= priority <= cls.MAX_PRIORITY):
            raise ValueError(
                f"优先级必须在 {cls.MIN_PRIORITY}-{cls.MAX_PRIORITY} 之间"
            )
        
        return True
    
    @classmethod
    def validate_pattern(cls, pattern: Optional[Dict[str, Any]]) -> bool:
        """验证消息 pattern
        
        Args:
            pattern: 消息 pattern 字典
            
        Returns:
            bool: 是否有效
            
        Raises:
            ValueError: 如果验证失败
        """
        if pattern is None:
            return True
        
        if not isinstance(pattern, dict):
            raise ValueError("Pattern 必须是字典类型")
        
        # 验证必要字段
        required_fields = {"source_type", "subscription_type"}
        if not required_fields.issubset(pattern.keys()):
            logger.warning(f"Pattern 缺少必要字段: {required_fields - pattern.keys()}")
        
        # 验证 RGB
        if "rgb" in pattern:
            rgb = pattern["rgb"]
            if not isinstance(rgb, dict):
                raise ValueError("RGB 必须是字典类型")
            for key in ["r", "g", "b"]:
                if key not in rgb or not isinstance(rgb[key], int):
                    raise ValueError(f"RGB 必须包含 r、g、b 三个整数字段")
                if not (0 <= rgb[key] <= 255):
                    raise ValueError(f"RGB 值必须在 0-255 之间")
        
        # 验证 vibe
        if "vibe" in pattern:
            vibe = pattern["vibe"]
            if not isinstance(vibe, dict):
                raise ValueError("Vibe 必须是字典类型")
            if "intensity" in vibe:
                if not isinstance(vibe["intensity"], int) or not (0 <= vibe["intensity"] <= 100):
                    raise ValueError("Vibe intensity 必须是 0-100 之间的整数")
            if "duration" in vibe:
                if not isinstance(vibe["duration"], int) or vibe["duration"] <= 0:
                    raise ValueError("Vibe duration 必须是正整数（毫秒）")
        
        return True
    
    @classmethod
    def validate_message(
        cls,
        title: str,
        content: str,
        priority: int,
        pattern: Optional[Dict[str, Any]] = None
    ) -> bool:
        """一次性验证完整的消息
        
        Args:
            title: 消息标题
            content: 消息内容
            priority: 优先级
            pattern: 消息 pattern（可选）
            
        Returns:
            bool: 是否有效
            
        Raises:
            ValueError: 如果验证失败
        """
        cls.validate_title(title)
        cls.validate_content(content)
        cls.validate_priority(priority)
        cls.validate_pattern(pattern)
        return True
    
    @staticmethod
    def _contains_forbidden_chars(text: str) -> bool:
        """检查文本是否包含禁止的字符
        
        Args:
            text: 要检查的文本
            
        Returns:
            bool: 是否包含禁止字符
        """
        text_lower = text.lower()
        return any(forbidden in text_lower for forbidden in MessageValidator.FORBIDDEN_CHARS)
