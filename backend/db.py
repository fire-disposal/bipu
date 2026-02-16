import os
import sys
import shutil
import subprocess
from dotenv import load_dotenv

# 加载环境变量 (读取 .env 中的 DATABASE_URL 等)
load_dotenv()

def run_command(command):
    """运行系统命令的辅助函数"""
    try:
        print(f"🚀 正在执行: {' '.join(command)}")
        # 使用 shell=False 以避免参数丢失问题，在 Linux/Windows 下均适用
        subprocess.run(command, check=True, shell=False)
    except subprocess.CalledProcessError as e:
        print(f"❌ 命令执行失败: {e}")
        sys.exit(1)

def migrate():
    """应用迁移脚本到数据库 (Django migrate)"""
    print("⬆️  正在升级数据库结构...")
    run_command(["uv", "run", "alembic", "upgrade", "head"])

def makemigrations(message):
    """生成新的迁移脚本 (Django makemigrations)"""
    if not message:
        print("💡 错误: 请提供迁移描述，例如: python db.py makemigrations 'add_user_table'")
        return
    print(f"📝 正在生成迁移脚本: {message}...")
    run_command(["uv", "run", "alembic", "revision", "--autogenerate", "-m", f'"{message}"'])

def stamp_head():
    """强制将数据库标记为最新版本 (不执行 SQL)"""
    print("🏷️  正在强制对齐版本号到最新...")
    run_command(["uv", "run", "alembic", "stamp", "head"])

def show_history():
    """查看迁移历史"""
    run_command(["uv", "run", "alembic", "history", "--verbose"])

def reinit():
    """
    危险操作：清空所有迁移脚本和本地数据库结构，重新初始化。
    """
    # 核心安全检查：防止在生产环境误删
    env = os.getenv("APP_ENV", "development").lower()
    if env != "development":
        print(f"🛑 危险！当前环境为 {env}，'reinit' 命令仅限 development 环境使用！")
        return

    print("⚠️  警告：此操作将删除 alembic/versions 下所有脚本，并要求你手动重置数据库 schema！")
    confirm = input("确定要继续吗？(y/N): ").lower()
    if confirm != 'y':
        print("❌ 操作已取消。")
        return

    # 1. 删除所有旧的迁移文件
    versions_dir = os.path.join("alembic", "versions")
    if os.path.exists(versions_dir):
        print("🗑️  清理旧的迁移脚本...")
        for filename in os.listdir(versions_dir):
            if filename.endswith(".py"):
                file_path = os.path.join(versions_dir, filename)
                os.remove(file_path)
    
    print("✨ 旧脚本已清理。")
    print("📢 下一步请手动在数据库中执行: 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'")
    
    # 询问是否立即生成新的初始脚本
    make_now = input("是否现在生成全新的初始化脚本？(y/N): ").lower()
    if make_now == 'y':
        makemigrations("initial_schema")
        print("✅ 已生成初始脚本。请接着运行 'uv run db.py migrate'")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("""
🌟 Alembic 快捷工具 (Django 风格)
用法: python db.py [命令]

可用命令:
  makemigrations "描述"  - 生成新迁移脚本
  migrate               - 应用迁移到数据库
  stamp                 - 强行将数据库标记为最新版
  history               - 查看迁移历史记录
  reinit                - [危险] 重置所有脚本并重来
        """)
        sys.exit(0)

    cmd = sys.argv[1]
    
    if cmd == "migrate":
        migrate()
    elif cmd == "makemigrations":
        msg = sys.argv[2] if len(sys.argv) > 2 else ""
        makemigrations(msg)
    elif cmd == "stamp":
        stamp_head()
    elif cmd == "history":
        show_history()
    elif cmd == "reinit":
        reinit()
    else:
        print(f"❓ 未知命令: {cmd}")