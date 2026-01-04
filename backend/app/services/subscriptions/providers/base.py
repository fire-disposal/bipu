from abc import ABC, abstractmethod
from typing import Any, Dict, Optional

class BaseDataProvider(ABC):
    """数据提供者基类"""
    
    @abstractmethod
    def get_data(self, key: str, **kwargs) -> Dict[str, Any]:
        """获取数据
        
        Args:
            key: 查询关键字（如城市名、星座名）
            **kwargs: 其他参数
            
        Returns:
            Dict[str, Any]: 获取到的数据
        """
        pass
