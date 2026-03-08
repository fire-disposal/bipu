"""
推送内容生成器

设计：
- CONTENT_REGISTRY 注册表将服务名/前缀映射到生成函数，避免 if/elif 堆叠
- 新增内置服务只需在 _register_builtin 中添加一行，无需新建文件
- 真正动态/外部服务的内容由调用方（API 层）传入，ContentGenerator 只处理内置服务
"""
import random
from datetime import datetime, timezone
from typing import Dict, Any, Optional


class ContentGenerator:
    """简化内容生成器"""

    # 运势等级
    FORTUNE_LEVELS = [
        ("大吉", "今天是你闪耀的日子！"),
        ("吉",   "顺利的一天，好事会发生。"),
        ("平",   "平稳的一天，保持平常心。"),
        ("小凶", "需要小心谨慎的一天。"),
        ("凶",   "挑战较多，保持冷静。")
    ]

    # 运势领域
    FORTUNE_AREAS = [
        ("事业", [
            "今天适合制定长期计划",
            "与同事合作会有好结果",
            "勇敢表达你的想法",
            "注意工作细节"
        ]),
        ("财运", [
            "可能有意外之财",
            "谨慎投资决策",
            "适合储蓄的日子",
            "避免冲动消费"
        ]),
        ("感情", [
            "适合表达情感",
            "多关心身边的人",
            "单身者可能有惊喜",
            "沟通是解决问题的关键"
        ]),
        ("健康", [
            "注意饮食平衡",
            "适当运动有益身心",
            "保证充足睡眠",
            "保持心情愉快"
        ])
    ]

    # 天气类型
    WEATHER_TYPES = [
        ("晴",   "阳光明媚，适合外出"),
        ("多云", "云层较多，光线柔和"),
        ("少云", "偶尔有云，天气舒适"),
        ("雨",   "有雨，记得带伞"),
        ("雷阵雨", "雷雨交加，注意安全"),
        ("雪",   "雪花飘飘，注意保暖"),
        ("雾",   "能见度较低，小心出行"),
        ("风",   "风力较大，注意防风")
    ]

    # 城市天气特征
    CITY_WEATHER = {
        "北京": {"climate": "温带季风气候", "temp_adjust": 0, "humidity_adjust": -10},
        "上海": {"climate": "亚热带季风气候", "temp_adjust": 5, "humidity_adjust": 15},
        "广州": {"climate": "亚热带季风气候", "temp_adjust": 8, "humidity_adjust": 20},
        "深圳": {"climate": "亚热带季风气候", "temp_adjust": 7, "humidity_adjust": 18},
        "成都": {"climate": "亚热带季风气候", "temp_adjust": 3, "humidity_adjust": 25},
        "杭州": {"climate": "亚热带季风气候", "temp_adjust": 4, "humidity_adjust": 18},
        "南京": {"climate": "亚热带季风气候", "temp_adjust": 2, "humidity_adjust": 15},
        "武汉": {"climate": "亚热带季风气候", "temp_adjust": 3, "humidity_adjust": 20},
        "西安": {"climate": "温带季风气候", "temp_adjust": -1, "humidity_adjust": -5},
        "重庆": {"climate": "亚热带季风气候", "temp_adjust": 6, "humidity_adjust": 30}
    }

    def __init__(self):
        # 注册表：服务名（精确匹配）或前缀（以 "." 分割判断）→ 生成函数
        # 函数签名：(self, service_name, user_id, current_time, extra_data) → str
        self._registry: Dict[str, Any] = {}
        self._register_builtin()

    def _register_builtin(self):
        """注册所有内置服务的内容生成器。"""
        self._registry["cosmic.fortune"] = self._gen_fortune
        self._registry["weather.service"] = self._gen_weather
        self._registry["notification."] = self._gen_notification  # 前缀匹配

    def _gen_fortune(self, service_name: str, user_id: str,
                     current_time: datetime, extra_data: Optional[Dict[str, Any]]) -> str:
        return self.generate_fortune(user_id, current_time)

    def _gen_weather(self, service_name: str, user_id: str,
                     current_time: datetime, extra_data: Optional[Dict[str, Any]]) -> str:
        location = (extra_data or {}).get("location", "北京")
        return self.generate_weather(location, current_time)

    def _gen_notification(self, service_name: str, user_id: str,
                          current_time: datetime, extra_data: Optional[Dict[str, Any]]) -> str:
        d = extra_data or {}
        return self.generate_notification(
            d.get("title", "系统通知"),
            d.get("message", ""),
            d.get("urgency", "normal"),
        )

    def generate_fortune(self, user_id: str, current_time: datetime) -> str:
        """生成运势内容（无 emoji，适配嵌入式小屏）。"""
        seed = sum(ord(c) for c in user_id) + current_time.year * 10000 + current_time.month * 100 + current_time.day
        random.seed(seed)

        level_name, level_desc = random.choice(self.FORTUNE_LEVELS)
        selected_areas = random.sample(self.FORTUNE_AREAS, 3)
        lucky_number = random.randint(1, 99)
        lucky_colors = ["红色", "金色", "蓝色", "绿色", "紫色", "白色", "黑色"]
        lucky_color = random.choice(lucky_colors)
        advice = random.choice([
            "保持积极心态，好事自然来",
            "今天适合学习新知识或技能",
            "关心身边的人，传递温暖",
            "注意休息，保持身心健康",
            "勇敢尝试，不怕失败"
        ])

        lines = [
            f"[ {level_name} ]  {level_desc}",
            current_time.strftime("%Y年%m月%d日"),
            "",
            "-- 今日运势 --",
        ]
        for area_name, tips in selected_areas:
            lines.append(f"  {area_name}: {random.choice(tips)}")
        lines += [
            "",
            "-- 幸运指南 --",
            f"  幸运数字: {lucky_number}",
            f"  幸运颜色: {lucky_color}",
            "",
            f">> {advice}",
            "",
            "运势仅供参考，真正的幸运来自你的努力。",
        ]
        return "\n".join(lines)

    def generate_weather(self, location: str, current_time: datetime) -> str:
        """生成天气内容（无 emoji，适配嵌入式小屏）。"""
        city_info = self.CITY_WEATHER.get(location, self.CITY_WEATHER["北京"])

        seed = sum(ord(c) for c in location) + current_time.year * 10000 + current_time.month * 100 + current_time.day
        random.seed(seed)

        weather_name, weather_desc = random.choice(self.WEATHER_TYPES)

        base_temp = random.randint(15, 30)
        temperature = base_temp + city_info["temp_adjust"]
        base_humidity = random.randint(40, 80)
        humidity = max(30, min(95, base_humidity + city_info["humidity_adjust"]))
        wind_speed = random.randint(1, 5)

        aqi = random.randint(20, 150)
        aqi_level = "优" if aqi <= 50 else ("良" if aqi <= 100 else ("轻度污染" if aqi <= 150 else "中度污染"))

        weather_advice = {
            "晴":   "适合户外活动，记得防晒",
            "多云": "天气舒适，适合各种活动",
            "少云": "天气宜人，适合外出",
            "雨":   "记得带伞，注意防滑",
            "雷阵雨": "尽量避免外出，注意安全",
            "雪":   "注意保暖，小心路滑",
            "雾":   "能见度低，小心驾驶",
            "风":   "注意防风，固定好物品"
        }
        advice = weather_advice.get(weather_name, "注意天气变化，合理安排活动")

        lines = [
            f"[ {location}天气 ]  {weather_name} · {weather_desc}",
            current_time.strftime("%Y年%m月%d日"),
            f"气候: {city_info['climate']}",
            "",
            "-- 实时天气 --",
            f"  温度: {temperature} °C",
            f"  湿度: {humidity} %",
            f"  风力: {wind_speed} 级",
            f"  空气: {aqi_level}  AQI {aqi}",
            "",
            f">> {advice}",
            "",
            "-- 未来3小时 --",
        ]
        for i in range(1, 4):
            hour_temp = temperature + random.randint(-2, 2)
            hour_trend = random.choice(["持平", "略有变化", "逐渐转好"])
            lines.append(f"  {(current_time.hour + i) % 24:02d}:00  {hour_temp} °C  {hour_trend}")
        lines += [
            "",
            "天气变化快，请及时关注最新预报。",
        ]
        return "\n".join(lines)

    def generate_notification(self, title: str, message: str, urgency: str = "normal") -> str:
        """生成通知内容（无 emoji，适配嵌入式小屏）。"""
        urgency_prefix = {"high": "[!] ", "normal": "[*] ", "low": "[-] "}
        urgency_hint   = {
            "high":   "重要通知，请及时处理。",
            "normal": "普通通知，请合理安排时间查看。",
            "low":    "一般通知，可在方便时查看。"
        }
        prefix = urgency_prefix.get(urgency, "[*] ")
        hint   = urgency_hint.get(urgency, "")
        current_time = datetime.now(timezone.utc)

        lines = [
            f"{prefix}{title}",
            "-" * min(len(title) + len(prefix), 32),
        ]
        if message:
            lines += ["", message, ""]
        lines += [
            f"发送: {current_time.strftime('%Y-%m-%d %H:%M')}",
        ]
        if hint:
            lines += ["", hint]
        return "\n".join(lines)

    def generate_custom_content(self, template: str, data: Dict[str, Any]) -> str:
        """
        生成自定义内容

        Args:
            template: 模板字符串，使用 {key} 格式
            data: 模板数据

        Returns:
            str: 生成的内容
        """
        try:
            content = template
            for key, value in data.items():
                content = content.replace(f"{{{key}}}", str(value))
            current_time = datetime.now(timezone.utc)
            content += f"\n\n生成: {current_time.strftime('%Y-%m-%d %H:%M')}"
            return content
        except Exception as e:
            return f"内容生成失败: {str(e)}"

    def get_service_content(self, service_name: str, user_id: str,
                           current_time: datetime,
                           extra_data: Optional[Dict[str, Any]] = None) -> str:
        """根据服务名从注册表分发内容生成；未注册服务返回默认内容。"""
        # 精确匹配
        if service_name in self._registry:
            return self._registry[service_name](service_name, user_id, current_time, extra_data)
        # 前缀匹配（如 notification.xxx）
        for key, fn in self._registry.items():
            if key.endswith(".") and service_name.startswith(key):
                return fn(service_name, user_id, current_time, extra_data)
        # 默认兜底
        return f"来自 {service_name} 的推送\n时间: {current_time.strftime('%Y-%m-%d %H:%M')}\n感谢您的订阅。"
