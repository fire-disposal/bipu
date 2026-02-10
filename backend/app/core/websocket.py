"""WebSocket 连接管理器"""
from typing import Dict, Set
from fastapi import WebSocket
from datetime import datetime
import json
import asyncio
from app.core.logging import get_logger

logger = get_logger(__name__)


class ConnectionManager:
    """WebSocket 连接管理器
    
    负责：
    - 管理活跃的 WebSocket 连接
    - 按 bipupu_id 组织连接
    - 推送新消息到在线用户
    - 处理心跳和断线重连
    """
    
    def __init__(self):
        # bipupu_id -> Set[WebSocket]
        # 一个用户可能有多个设备连接
        self.active_connections: Dict[str, Set[WebSocket]] = {}
        # WebSocket -> bipupu_id 的反向映射
        self.connection_users: Dict[WebSocket, str] = {}
        # 连接时间记录
        self.connection_times: Dict[WebSocket, datetime] = {}
    
    async def connect(self, websocket: WebSocket, bipupu_id: str):
        """接受新的 WebSocket 连接"""
        await websocket.accept()
        
        if bipupu_id not in self.active_connections:
            self.active_connections[bipupu_id] = set()
        
        self.active_connections[bipupu_id].add(websocket)
        self.connection_users[websocket] = bipupu_id
        self.connection_times[websocket] = datetime.now()
        
        logger.info(f"✅ WebSocket 连接建立: {bipupu_id} (总连接数: {len(self.connection_users)})")
    
    def disconnect(self, websocket: WebSocket):
        """断开 WebSocket 连接"""
        bipupu_id = self.connection_users.get(websocket)
        
        if bipupu_id and bipupu_id in self.active_connections:
            self.active_connections[bipupu_id].discard(websocket)
            
            # 如果该用户没有其他连接了，清理记录
            if not self.active_connections[bipupu_id]:
                del self.active_connections[bipupu_id]
        
        if websocket in self.connection_users:
            del self.connection_users[websocket]
        
        if websocket in self.connection_times:
            del self.connection_times[websocket]
        
        logger.info(f"❌ WebSocket 连接断开: {bipupu_id} (总连接数: {len(self.connection_users)})")
    
    async def send_personal_message(self, message: dict, bipupu_id: str):
        """发送消息给特定用户的所有连接"""
        if bipupu_id not in self.active_connections:
            logger.debug(f"用户 {bipupu_id} 不在线，跳过 WebSocket 推送")
            return False
        
        message_json = json.dumps(message, ensure_ascii=False)
        connections = self.active_connections[bipupu_id].copy()  # 复制以避免迭代时修改
        
        success = False
        for websocket in connections:
            try:
                await websocket.send_text(message_json)
                success = True
                logger.debug(f"📤 消息已推送到 {bipupu_id}")
            except Exception as e:
                logger.error(f"发送消息失败: {e}")
                self.disconnect(websocket)
        
        return success
    
    async def broadcast(self, message: dict):
        """广播消息给所有在线用户"""
        message_json = json.dumps(message, ensure_ascii=False)
        
        for websocket in list(self.connection_users.keys()):
            try:
                await websocket.send_text(message_json)
            except Exception as e:
                logger.error(f"广播消息失败: {e}")
                self.disconnect(websocket)
    
    def is_user_online(self, bipupu_id: str) -> bool:
        """检查用户是否在线"""
        return bipupu_id in self.active_connections and len(self.active_connections[bipupu_id]) > 0
    
    def get_online_count(self) -> int:
        """获取在线用户数"""
        return len(self.active_connections)
    
    def get_connection_count(self) -> int:
        """获取总连接数"""
        return len(self.connection_users)


# 全局单例
manager = ConnectionManager()
