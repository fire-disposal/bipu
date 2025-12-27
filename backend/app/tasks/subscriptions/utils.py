"""订阅处理器工具函数"""
from typing import Dict, Any
from datetime import datetime, time


def parse_time_string(time_str: str) -> time:
    """解析时间字符串（HH:MM 格式）
    
    Args:
        time_str: 时间字符串，格式为 "HH:MM"
        
    Returns:
        time: 时间对象
        
    Raises:
        ValueError: 如果时间字符串格式无效
    """
    try:
        return datetime.strptime(time_str, "%H:%M").time()
    except ValueError as e:
        raise ValueError(f"时间字符串格式无效: {time_str}，应为 HH:MM 格式") from e


def is_time_in_range(current_time: time, start_time: time, end_time: time) -> bool:
    """检查时间是否在范围内
    
    支持跨午夜的时间范围（例如 22:00 - 06:00）。
    
    Args:
        current_time: 当前时间
        start_time: 范围开始时间
        end_time: 范围结束时间
        
    Returns:
        bool: 是否在范围内
    """
    if start_time <= end_time:
        # 正常范围（不跨午夜）
        return start_time <= current_time <= end_time
    else:
        # 跨午夜范围
        return current_time >= start_time or current_time <= end_time


def merge_pattern_data(
    base_pattern: Dict[str, Any],
    additional_data: Dict[str, Any]
) -> Dict[str, Any]:
    """合并消息 pattern 数据
    
    Args:
        base_pattern: 基础 pattern 字典
        additional_data: 要添加的额外数据
        
    Returns:
        dict: 合并后的 pattern 字典
    """
    result = base_pattern.copy()
    result.update(additional_data)
    return result


def calculate_priority_from_importance(importance_level: str) -> int:
    """根据重要性级别计算优先级
    
    Args:
        importance_level: 重要性级别 ("low", "medium", "high", "critical")
        
    Returns:
        int: 优先级（0-10）
    """
    mapping = {
        "low": 1,
        "medium": 5,
        "high": 7,
        "critical": 10
    }
    return mapping.get(importance_level.lower(), 5)
