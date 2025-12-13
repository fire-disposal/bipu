#!/usr/bin/env python3
"""
数据库迁移创建脚本
使用方法:
    python create_migration.py "迁移描述"
"""
import sys
import subprocess
import os

def create_migration(message):
    """创建数据库迁移"""
    if not message:
        print("请提供迁移描述")
        print("用法: python create_migration.py '迁移描述'")
        return
    
    # 切换到backend目录
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(backend_dir)
    
    # 生成迁移命令
    cmd = [
        "alembic", 
        "revision", 
        "--autogenerate", 
        "-m", 
        message
    ]
    
    print(f"执行命令: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print("迁移创建成功!")
        print(result.stdout)
        
        if result.stderr:
            print("警告信息:")
            print(result.stderr)
            
    except subprocess.CalledProcessError as e:
        print("迁移创建失败!")
        print("错误输出:")
        print(e.stderr)
        print("标准输出:")
        print(e.stdout)
        sys.exit(1)
    except FileNotFoundError:
        print("错误: 未找到alembic命令")
        print("请确保已安装alembic: pip install alembic")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("请提供迁移描述")
        print("用法: python create_migration.py '迁移描述'")
        sys.exit(1)
    
    migration_message = " ".join(sys.argv[1:])
    create_migration(migration_message)