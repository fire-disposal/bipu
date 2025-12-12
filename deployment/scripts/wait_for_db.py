# wait_for_db.py

import os
import time
import sys
import psycopg2
from urllib.parse import urlparse

# 从环境变量获取连接信息
# 使用 DATABASE_URL 来获取主机、用户和密码，但连接到默认的 'postgres' 数据库进行健康检查
DATABASE_URL = os.getenv("DATABASE_URL") 
MAX_ATTEMPTS = 30

def get_connection_params(db_url: str):
    """解析 DATABASE_URL 并返回连接参数，将数据库名强制设置为 'postgres' 用于初始检查。"""
    if not db_url:
        print("Error: DATABASE_URL environment variable is not set.")
        sys.exit(1)
        
    url = urlparse(db_url)
    return {
        "host": url.hostname,
        "user": url.username,
        "password": url.password,
        "database": "postgres", # 始终连接到默认的 postgres 数据库进行检查
        "port": url.port or 5432
    }

def wait_for_db():
    """循环尝试连接数据库，直到成功或达到最大尝试次数。"""
    try:
        params = get_connection_params(DATABASE_URL)
    except Exception as e:
        print(f"Error parsing DATABASE_URL: {e}")
        sys.exit(1)

    print(f"⏳ Waiting for PostgreSQL connection to be ready at {params['host']}...")
    
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            # 尝试连接
            conn = psycopg2.connect(**params)
            conn.close()
            print("✅ Database connection established.")
            return
        except psycopg2.OperationalError as e:
            # 捕获连接失败、认证失败等
            if "authentication failed" in str(e):
                 print(f"   Attempt {attempt}/{MAX_ATTEMPTS}: Authentication failed. Check password/user.")
                 sys.exit(1) # 认证失败是配置问题，应该立即退出
            
            print(f"   Attempt {attempt}/{MAX_ATTEMPTS}: Waiting for DB... ({e})")
            time.sleep(1)
        
    print(f"❌ Failed to connect to database after {MAX_ATTEMPTS} attempts.")
    sys.exit(1)

if __name__ == "__main__":
    wait_for_db()