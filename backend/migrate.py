#!/usr/bin/env python3
"""
数据库迁移管理脚本
使用方法:
    python migrate.py upgrade    # 升级到最新版本
    python migrate.py downgrade  # 降级到上一版本
    python migrate.py current    # 显示当前版本
    python migrate.py history    # 显示迁移历史
"""
import sys
import subprocess
import os

def run_alembic_command(command, *args):
    """运行alembic命令"""
    # 切换到backend目录
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(backend_dir)
    
    # 构建命令
    cmd = ["alembic", command] + list(args)
    
    print(f"执行命令: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(result.stdout)
        
        if result.stderr:
            print("警告信息:")
            print(result.stderr)
            
    except subprocess.CalledProcessError as e:
        print("命令执行失败!")
        print("错误输出:")
        print(e.stderr)
        print("标准输出:")
        print(e.stdout)
        sys.exit(1)
    except FileNotFoundError:
        print("错误: 未找到alembic命令")
        print("请确保已安装alembic: pip install alembic")
        sys.exit(1)

def main():
    """主函数"""
    if len(sys.argv) < 2:
        print("请提供命令")
        print("用法:")
        print("  python migrate.py upgrade [revision]     # 升级数据库")
        print("  python migrate.py downgrade [revision]   # 降级数据库")
        print("  python migrate.py current               # 显示当前版本")
        print("  python migrate.py history               # 显示迁移历史")
        print("  python migrate.py check                 # 检查数据库状态")
        sys.exit(1)
    
    command = sys.argv[1]
    args = sys.argv[2:] if len(sys.argv) > 2 else []
    
    # 支持的命令
    supported_commands = ["upgrade", "downgrade", "current", "history", "check", "heads", "branches"]
    
    if command not in supported_commands:
        print(f"不支持的命令: {command}")
        print(f"支持的命令: {', '.join(supported_commands)}")
        sys.exit(1)
    
    run_alembic_command(command, *args)

if __name__ == "__main__":
    main()