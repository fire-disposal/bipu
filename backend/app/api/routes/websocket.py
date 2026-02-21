"""WebSocket 路由"""
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query, status
from app.core.websocket import manager
from app.core.logging import get_logger
from app.core.security import decode_token
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import User
import json

logger = get_logger(__name__)

router = APIRouter()


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(..., description="访问令牌"),
    db: Session = Depends(get_db)
):
    """WebSocket 连接端点

    连接流程：
    1. 客户端使用 token 连接: ws://host/api/ws?token=xxx
    2. 服务端验证 token → 绑定 bipupu_id 到 WebSocket 连接
    3. 此后，所有发给该用户的 Message 都通过此连接推送

    心跳机制：
    - 客户端每 30s 发 { "type": "ping" }
    - 服务端回 { "type": "pong" }
    """

    # 验证 token
    try:
        payload = decode_token(token)
        if not payload or payload.get("type") != "access":
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        user_id = payload.get("sub")
        if not user_id:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        # 获取用户信息
        user = db.query(User).filter(User.id == int(user_id)).first()
        if not user or not user.is_active:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        bipupu_id = user.bipupu_id

    except Exception as e:
        logger.error(f"WebSocket 认证失败: {e}")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    # 建立连接
    await manager.connect(websocket, bipupu_id)

    try:
        while True:
            # 接收客户端消息
            data = await websocket.receive_text()

            try:
                message = json.loads(data)
                msg_type = message.get("type")

                # 处理心跳
                if msg_type == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
                    logger.debug(f"💓 心跳: {bipupu_id}")
                else:
                    logger.debug(f"收到消息: {message}")

            except json.JSONDecodeError:
                logger.warning(f"无法解析的消息: {data}")

    except WebSocketDisconnect:
        manager.disconnect(websocket)
        logger.info(f"🔌 用户断开连接: {bipupu_id}")
    except Exception as e:
        logger.error(f"WebSocket 错误: {e}")
        manager.disconnect(websocket)
