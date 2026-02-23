## 📱 前端适配指南

### 1. 新增字段说明

#### `waveform` 字段
- **类型**: `number[]` 或 `null`
- **描述**: 音频振幅包络数据，用于语音消息可视化
- **格式**: 0-255的整数数组，建议长度不超过128
- **示例**: `[12, 45, 100, 20, 78, 90, 34, 67]`

### 2. API接口变更

#### 2.1 发送消息接口 (`POST /api/messages/`)

**请求体新增字段**:
```typescript
interface MessageCreateRequest {
  receiver_id: string;
  content: string;
  message_type?: "NORMAL" | "VOICE" | "SYSTEM"; // 默认为"NORMAL"
  pattern?: Record<string, any>; // 可选，JSON扩展字段
  waveform?: number[]; // 新增：音频振幅包络
}
```

**示例请求**:
```javascript
// 发送普通消息
await fetch('/api/messages/', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    receiver_id: 'user456',
    content: '你好，这是一条测试消息',
    message_type: 'NORMAL'
  })
});

// 发送语音消息（带波形数据）
await fetch('/api/messages/', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    receiver_id: 'user456',
    content: '语音消息内容',
    message_type: 'VOICE',
    waveform: [12, 45, 100, 20, 78, 90, 34, 67] // 波形数据
  })
});
```

#### 2.2 新增长轮询接口 (`GET /api/messages/poll`)

**接口说明**:
- 用于实时获取新消息
- 支持长轮询机制，减少频繁请求

**请求参数**:
```typescript
interface PollMessagesParams {
  last_msg_id: number; // 最后收到的消息ID，初始为0
  timeout?: number;    // 超时时间（秒），默认30，最大120
}
```

**响应格式**:
```typescript
interface MessageResponse {
  id: number;
  sender_bipupu_id: string;
  receiver_bipupu_id: string;
  content: string;
  message_type: string;
  pattern?: Record<string, any>;
  waveform?: number[]; // 新增字段
  created_at: string; // ISO格式时间戳
}
```

**前端实现示例**:
```javascript
class MessagePoller {
  constructor(token, onNewMessages) {
    this.token = token;
    this.onNewMessages = onNewMessages;
    this.lastMsgId = 0;
    this.isPolling = false;
  }

  async start() {
    this.isPolling = true;
    await this.poll();
  }

  stop() {
    this.isPolling = false;
  }

  async poll() {
    while (this.isPolling) {
      try {
        const response = await fetch(
          `/api/messages/poll?last_msg_id=${this.lastMsgId}&timeout=30`,
          {
            headers: {
              'Authorization': `Bearer ${this.token}`
            }
          }
        );

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }

        const messages = await response.json();
        
        if (messages.length > 0) {
          // 更新最后消息ID
          this.lastMsgId = messages[messages.length - 1].id;
          
          // 处理新消息
          this.onNewMessages(messages);
        }
      } catch (error) {
        console.error('轮询错误:', error);
        // 等待5秒后重试
        await new Promise(resolve => setTimeout(resolve, 5000));
      }
    }
  }
}

// 使用示例
const poller = new MessagePoller(userToken, (messages) => {
  messages.forEach(message => {
    console.log('收到新消息:', message);
    
    // 如果有波形数据，进行可视化
    if (message.waveform) {
      visualizeWaveform(message.waveform);
    }
  });
});

// 开始轮询
poller.start();

// 停止轮询（如页面离开时）
// poller.stop();
```

#### 2.3 WebSocket消息格式更新

**WebSocket连接**:
```javascript
// 建立WebSocket连接
const ws = new WebSocket(`ws://${host}/api/ws?token=${token}`);

ws.onopen = () => {
  console.log('WebSocket连接已建立');
  
  // 开始心跳（每25秒发送一次ping）
  setInterval(() => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type: 'ping' }));
    }
  }, 25000);
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  
  switch (message.type) {
    case 'pong':
      // 心跳响应
      console.log('收到心跳响应');
      break;
      
    case 'new_message':
      // 新消息通知
      const payload = message.payload;
      console.log('收到新消息:', payload);
      
      // 处理波形数据
      if (payload.waveform) {
        visualizeWaveform(payload.waveform);
      }
      break;
      
    default:
      console.log('收到未知类型消息:', message);
  }
};

ws.onclose = () => {
  console.log('WebSocket连接已关闭');
};
```

**WebSocket消息格式**:
```typescript
interface WebSocketMessage {
  type: 'ping' | 'pong' | 'new_message';
  payload?: NewMessagePayload;
}

interface NewMessagePayload {
  id: number;
  sender_id: string;
  content: string;
  message_type: string;
  pattern?: Record<string, any>;
  waveform?: number[]; // 新增字段
  created_at: string;
}
```

### 3. 波形数据可视化建议

#### 3.1 基础可视化函数
```javascript
/**
 * 绘制波形图
 * @param {number[]} waveform - 波形数据数组
 * @param {HTMLCanvasElement} canvas - 画布元素
 * @param {string} color - 波形颜色，默认'#4a90e2'
 */
function drawWaveform(waveform, canvas, color = '#4a90e2') {
  if (!waveform || waveform.length === 0) {
    return;
  }

  const ctx = canvas.getContext('2d');
  const width = canvas.width;
  const height = canvas.height;
  
  // 清空画布
  ctx.clearRect(0, 0, width, height);
  
  // 计算每个点的位置
  const pointWidth = width / waveform.length;
  const maxValue = Math.max(...waveform);
  
  // 绘制波形
  ctx.beginPath();
  ctx.strokeStyle = color;
  ctx.lineWidth = 2;
  
  for (let i = 0; i < waveform.length; i++) {
    const x = i * pointWidth;
    const value = waveform[i];
    const y = height - (value / maxValue) * height;
    
    if (i === 0) {
      ctx.moveTo(x, y);
    } else {
      ctx.lineTo(x, y);
    }
  }
  
  ctx.stroke();
}

/**
 * 创建简单的波形预览
 * @param {number[]} waveform - 波形数据
 * @returns {string} - 简化的波形字符串表示
 */
function createWaveformPreview(waveform) {
  if (!waveform || waveform.length === 0) {
    return '▁▁▁▁';
  }
  
  // 将0-255映射到8个字符
  const chars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
  const previewLength = Math.min(waveform.length, 16); // 最多显示16个字符
  
  let result = '';
  for (let i = 0; i < previewLength; i++) {
    const value = waveform[Math.floor(i * waveform.length / previewLength)];
    const charIndex = Math.floor((value / 255) * (chars.length - 1));
    result += chars[charIndex];
  }
  
  return result;
}
```

#### 3.2 React组件示例
```jsx
import React, { useEffect, useRef } from 'react';

const WaveformVisualizer = ({ waveform, width = 200, height = 60, color = '#4a90e2' }) => {
  const canvasRef = useRef(null);
  
  useEffect(() => {
    if (canvasRef.current && waveform) {
      drawWaveform(waveform, canvasRef.current, color);
    }
  }, [waveform, color]);
  
  if (!waveform || waveform.length === 0) {
    return (
      <div className="waveform-placeholder">
        <span>无波形数据</span>
      </div>
    );
  }
  
  return (
    <div className="waveform-container">
      <canvas
        ref={canvasRef}
        width={width}
        height={height}
        className="waveform-canvas"
      />
      <div className="waveform-info">
        <span>{waveform.length}个采样点</span>
        <span>峰值: {Math.max(...waveform)}</span>
      </div>
    </div>
  );
};

// CSS样式
const styles = `
.waveform-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin: 10px 0;
}

.waveform-canvas {
  border: 1px solid #e0e0e0;
  border-radius: 4px;
  background: #f8f9fa;
}

.waveform-info {
  display: flex;
  justify-content: space-between;
  width: 100%;
  margin-top: 5px;
  font-size: 12px;
  color: #666;
}

.waveform-placeholder {
  padding: 20px;
  text-align: center;
  color: #999;
  background: #f5f5f5;
  border-radius: 4px;
}
`;
```

### 4. 数据验证建议

#### 4.1 波形数据验证
```javascript
/**
 * 验证波形数据
 * @param {number[]} waveform - 波形数据
 * @returns {boolean} - 是否有效
 */
function validateWaveform(waveform) {
  // 允许null或undefined
  if (waveform == null) {
    return true;
  }
  
  // 必须是数组
  if (!Array.isArray(waveform)) {
    console.error('波形数据必须是数组');
    return false;
  }
  
  // 检查数组元素
  for (let i = 0; i < waveform.length; i++) {
    const value = waveform[i];
    
    // 必须是数字
    if (typeof value !== 'number') {
      console.error(`波形数据位置${i}不是数字:`, value);
      return false;
    }
    
    // 必须在0-255范围内
    if (value < 0 || value > 255) {
      console.error(`波形数据位置${i}超出范围(0-255):`, value);
      return false;
    }
    
    // 必须是整数
    if (!Number.isInteger(value)) {
      console.error(`波形
