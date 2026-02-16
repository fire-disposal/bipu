"""封装对第三方农历/八字库的调用。该模块尝试导入 `lunarpython`，若不可用则降级返回 None。

提供函数：
- compute_bazi(birthday_iso: str, birth_time: Optional[str]) -> Optional[str]
- compute_lunar_date(birthday_iso: str) -> Optional[dict]

注意：birthplace/经纬度暂由前端提供并存储，但本实现仅使用本地时间计算八字。
"""
from typing import Optional
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


def _import_lunar_python():
    try:
        from lunarpython import Solar
        return Solar
    except Exception as e:
        logger.debug(f"lunarpython not available: {e}")
        return None


def compute_bazi(birthday_iso: str, birth_time: Optional[str] = None) -> Optional[str]:
    """基于 ISO 日期字符串和可选出生时间（HH:MM）尝试生成八字字符串。

    返回可读的八字文本或 None（当库不可用或解析失败时）。
    """
    Solar = _import_lunar_python()
    if Solar is None:
        return None

    try:
        # 解析生日和时间
        if birth_time:
            try:
                dt = datetime.fromisoformat(f"{birthday_iso}T{birth_time}")
            except ValueError:
                # 宽松解析 HH:MM 或 HH:MM:SS
                parts = birth_time.split(":")
                h = int(parts[0]) if len(parts) > 0 and parts[0].isdigit() else 0
                m = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 0
                s = int(parts[2]) if len(parts) > 2 and parts[2].isdigit() else 0
                base_dt = datetime.fromisoformat(birthday_iso)
                dt = base_dt.replace(hour=h, minute=m, second=s, microsecond=0)
        else:
            dt = datetime.fromisoformat(birthday_iso)

        # 创建 Solar 对象
        solar = Solar.fromYmdHms(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
        lunar = solar.getLunar()
        eight_char = lunar.getEightChar()

        # 获取八字字符串（lunarpython 的 EightChar 对象有 toString()）
        if hasattr(eight_char, 'toString'):
            return eight_char.toString()
        return str(eight_char)

    except Exception as e:
        logger.exception(f"Failed to compute bazi: {e}")
        return None


def compute_lunar_date(birthday_iso: str) -> Optional[dict]:
    """返回 lunar 日期信息字典：年/月/日/是否闰月等，或 None。"""
    Solar = _import_lunar_python()
    if Solar is None:
        return None

    try:
        dt = datetime.fromisoformat(birthday_iso)
        solar = Solar.fromYmd(dt.year, dt.month, dt.day)
        lunar = solar.getLunar()
        return {
            'lunar_year': lunar.getYear(),
            'lunar_month': lunar.getMonth(),
            'lunar_day': lunar.getDay(),
            'is_leap': lunar.isLeap(),
            'lunar_year_name': lunar.getYearInGanZhi(),
        }
    except Exception as e:
        logger.exception(f"Failed to compute lunar date: {e}")
        return None