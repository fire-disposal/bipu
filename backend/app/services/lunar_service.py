from typing import Optional
from datetime import datetime
import logging
from lunar_python import Solar

logger = logging.getLogger(__name__)


def compute_bazi(birthday_iso: str, birth_time: Optional[str] = None) -> Optional[str]:
    try:
        if birth_time:
            try:
                dt = datetime.fromisoformat(f"{birthday_iso}T{birth_time}")
            except ValueError:
                parts = birth_time.split(":")
                h = int(parts[0]) if len(parts) > 0 and parts[0].isdigit() else 0
                m = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 0
                s = int(parts[2]) if len(parts) > 2 and parts[2].isdigit() else 0
                base_dt = datetime.fromisoformat(birthday_iso)
                dt = base_dt.replace(hour=h, minute=m, second=s, microsecond=0)
        else:
            dt = datetime.fromisoformat(birthday_iso)

        solar = Solar.fromYmdHms(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
        eight_char = solar.getLunar().getEightChar()
        return eight_char.toString() if hasattr(eight_char, 'toString') else str(eight_char)

    except Exception as e:
        logger.exception(f"Failed to compute bazi: {e}")
        return None


def compute_lunar_date(birthday_iso: str) -> Optional[dict]:
    try:
        dt = datetime.fromisoformat(birthday_iso)
        lunar = Solar.fromYmd(dt.year, dt.month, dt.day).getLunar()
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