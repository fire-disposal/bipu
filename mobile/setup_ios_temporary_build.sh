#!/bin/bash

# iOS 临时账户打包快速设置脚本
# 使用方法：./setup_ios_temporary_build.sh com.yourname.bipupu

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}iOS 临时账户打包设置${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""

# 检查参数
if [ -z "$1" ]; then
    echo -e "${YELLOW}用法 1: 指定 Bundle ID${NC}"
    echo "   ./setup_ios_temporary_build.sh com.yourname.bipupu"
    echo ""
    echo -e "${YELLOW}用法 2: 交互式输入${NC}"
    echo "   ./setup_ios_temporary_build.sh"
    echo ""
    
    read -p "请输入 Bundle ID (例如 com.$(whoami).bipupu): " BUNDLE_ID
    
    if [ -z "$BUNDLE_ID" ]; then
        echo -e "${RED}错误：Bundle ID 不能为空${NC}"
        exit 1
    fi
else
    BUNDLE_ID="$1"
fi

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PBXPROJ="$PROJECT_DIR/ios/Runner.xcodeproj/project.pbxproj"

echo ""
echo -e "${YELLOW}目标 Bundle ID: ${BUNDLE_ID}${NC}"
echo ""

# 检查文件是否存在
if [ ! -f "$PBXPROJ" ]; then
    echo -e "${RED}✗ 错误：找不到 project.pbxproj 文件${NC}"
    echo "  路径：$PBXPROJ"
    exit 1
fi

# 备份原文件
BACKUP_FILE="$PBXPROJ.backup.$(date +%Y%m%d_%H%M%S)"
cp "$PBXPROJ" "$BACKUP_FILE"
echo -e "${GREEN}✓ 已备份原项目文件${NC}"
echo "  备份位置：$BACKUP_FILE"
echo ""

# 替换 Bundle ID
echo -e "${YELLOW}正在修改 Bundle ID...${NC}"

# macOS sed 语法
sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = '"$BUNDLE_ID"';/g' "$PBXPROJ"

echo -e "${GREEN}✓ Bundle ID 已更新${NC}"
echo ""

# 验证修改
echo -e "${YELLOW}验证修改...${NC}"
if grep -q "$BUNDLE_ID" "$PBXPROJ"; then
    echo -e "${GREEN}✓ 验证成功：Bundle ID 已正确设置${NC}"
    echo ""
    echo -e "${GREEN}==================================${NC}"
    echo -e "${GREEN}设置完成！${NC}"
    echo -e "${GREEN}==================================${NC}"
    echo ""
    echo -e "${BLUE}下一步操作：${NC}"
    echo ""
    echo "1. 打开 Xcode 项目:"
    echo -e "   ${YELLOW}open ios/Runner.xcworkspace${NC}"
    echo ""
    echo "2. 在 Xcode 中配置签名:"
    echo "   - 选择 Runner Target"
    echo "   - 进入 'Signing & Capabilities'"
    echo "   - 勾选 'Automatically manage signing'"
    echo "   - 选择你的 Apple ID (没有就点 Add Account)"
    echo ""
    echo "3. 添加 Capabilities (Xcode 会自动处理):"
    echo "   - Background Modes → Bluetooth Central/Peripheral"
    echo ""
    echo "4. 构建并运行:"
    echo -e "   ${YELLOW}flutter clean && flutter pub get && flutter run${NC}"
    echo ""
    echo -e "${YELLOW}提示：连接 iPhone 后，在 flutter run 时选择真机即可${NC}"
else
    echo -e "${RED}✗ 验证失败：Bundle ID 可能未正确设置${NC}"
    echo "请手动检查文件：$PBXPROJ"
    exit 1
fi
