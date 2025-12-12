# initialize_db.py

import os
import sys
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from urllib.parse import urlparse

# 从环境变量获取连接信息
DATABASE_URL = os.getenv("DATABASE_URL")
BUSINESS_DB_NAME = "bipupu" # 您的目标业务数据库名称

def get_admin_connection_params(db_url: str):
    """解析 DATABASE_URL 并返回连接参数，强制连接到 'postgres' 数据库。"""
    if not db_url:
        print("Error: DATABASE_URL environment variable is not set.")
        sys.exit(1)
        
    url = urlparse(db_url)
    return {
        "host": url.hostname,
        "user": url.username,
        "password": url.password,
        "database": "postgres", # 用于执行 CREATE DATABASE 的管理数据库
        "port": url.port or 5432
    }

def ensure_database_exists():
    """检查并创建业务数据库 'bipupu'。"""
    try:
        params = get_admin_connection_params(DATABASE_URL)
        conn = psycopg2.connect(**params)
        
        # 必须设置隔离级别为自动提交，CREATE DATABASE 才能在事务块外执行
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()

        # 检查数据库是否已存在
        cursor.execute("SELECT 1 FROM pg_database WHERE datname = %s;", (BUSINESS_DB_NAME,))
        exists = cursor.fetchone()

        if not exists:
            print(f"Creating database '{BUSINESS_DB_NAME}'...")
            cursor.execute(f"CREATE DATABASE {BUSINESS_DB_NAME};")
            print(f"✅ Database '{BUSINESS_DB_NAME}' created successfully.")
        else:
            print(f"Database '{BUSINESS_DB_NAME}' already exists.")

        cursor.close()
        conn.close()
    
    except psycopg2.OperationalError as e:
        print(f"❌ Database initialization failed. Operational Error: {e}")
        print("Hint: Check if user/password in DATABASE_URL are correct.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ An unexpected error occurred during database initialization: {e}")
        sys.exit(1)

if __name__ == "__main__":
    ensure_database_exists()