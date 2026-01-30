server {
    listen 80;
    listen [::]:80;
    server_name bipupu.205716.xyz;
    # 强制所有 HTTP 请求跳转到 HTTPS
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name bipupu.205716.xyz;
    # 证书路径保持不变
    ssl_certificate /etc/nginx/ssl/*.205716.xyz_205716.xyz_P256/fullchain.cer;
    ssl_certificate_key /etc/nginx/ssl/*.205716.xyz_205716.xyz_P256/private.key;
    # 性能优化参数
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    location / {
        proxy_pass http://127.0.0.1:8080;
        # 基础 Header 传递
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        # --- 核心优化：WebSocket 支持 ---
        # 解决 Nginx UI 日志、终端无法显示的问题
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        # 延长超时时间，防止 SSH 终端因空闲自动断开
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
}