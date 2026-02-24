"""WebSocket 路由"""
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, status
from app.core.websocket import manager
from app.core.logging import get_logger
from app.core.security import decode_token
from app.db.database import SessionLocal
from app.models.user import User
import json
import asyncio

logger = get_logger(__name__)

router = APIRouter()


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(..., description="访问令牌"),
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

        # 获取用户信息 - 创建独立的数据库会话
        db = SessionLocal()
        try:
            user = db.query(User).filter(User.id == int(user_id)).first()
            if not user or not user.is_active:
                await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
                return

            bipupu_id = str(user.bipupu_id)
        finally:
            db.close()

    except Exception as e:
        logger.error(f"WebSocket 认证失败: {e}")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    # 建立连接
    await websocket.accept()
    await manager.connect(websocket, str(bipupu_id))

    # 心跳超时检测（30秒）
    HEARTBEAT_TIMEOUT = 30
    last_heartbeat = asyncio.get_event_loop().time()

    try:
        while True:
            try:
                # 设置接收超时，用于心跳检测
                data = await asyncio.wait_for(
                    websocket.receive_text(),
                    timeout=HEARTBEAT_TIMEOUT
                )

                # 更新最后心跳时间
                last_heartbeat = asyncio.get_event_loop().time()

                try:
                    message = json.loads(data)
                    msg_type = message.get("type")

                    # 处理心跳
                    if msg_type == "ping":
                        await websocket.send_text(json.dumps({"type": "pong"}))
                        logger.debug(f"💓 心跳: {bipupu_id}")
                    else:
                        logger.debug(f"收到消息: {message}")
                        # 可以在这里添加其他消息类型的处理逻辑

                except json.JSONDecodeError:
                    logger.warning(f"无法解析的消息: {data}")

            except asyncio.TimeoutError:
                # 心跳超时，发送ping检测连接是否存活
                current_time = asyncio.get_event_loop().time()
                if current_time - last_heartbeat > HEARTBEAT_TIMEOUT:
                    try:
                        await websocket.send_text(json.dumps({"type": "ping"}))
                        # 等待pong响应
                        try:
                            pong_data = await asyncio.wait_for(
                                websocket.receive_text(),
                                timeout=5
                            )
                            pong_msg = json.loads(pong_data)
                            if pong_msg.get("type") == "pong":
                                last_heartbeat = asyncio.get_event_loop().time()
                                continue
                        except (asyncio.TimeoutError, json.JSONDecodeError):
                            pass

                        # 心跳失败，断开连接
                        logger.warning(f"💔 心跳失败，断开连接: {bipupu_id}")
                        break
                    except Exception:
                        # 发送ping失败，连接已断开
                        break

    except WebSocketDisconnect:
        logger.info(f"🔌 用户主动断开连接: {bipupu_id}")
    except Exception as e:
        logger.error(f"WebSocket 错误: {e}")
    finally:
        # 确保连接被正确清理
        manager.disconnect(websocket)
