#!/bin/bash

# iOS 一键打包脚本（临时账户）
# 使用方法：./ios_quick_build.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}==================================${NC}"
    echo -e "${BLUE}${BOLD}$1${NC}"
    echo -e "${BLUE}==================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# 开始
print_header "iOS 快速打包工具"

# 检查 Flutter
print_step "检查 Flutter 环境..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter 未安装，请先安装 Flutter"
    exit 1
fi
print_success "Flutter 已安装：$(flutter --version | head -1)"

# 检查 Xcode
print_step "检查 Xcode 环境..."
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode 未安装，请先在 App Store 安装 Xcode"
    exit 1
fi
print_success "Xcode 已安装：$(xcodebuild -version | head -1)"

# 检查 CocoaPods
print_step "检查 CocoaPods..."
if ! command -v pod &> /dev/null; then
    print_yellow "CocoaPods 未安装，正在安装..."
    sudo gem install cocoapods
fi
print_success "CocoaPods 已安装：$(pod --version)"

# 获取 Flutter 依赖
print_step "获取 Flutter 依赖..."
flutter pub get

# 安装 iOS 依赖
print_step "安装 iOS Pods..."
cd ios
pod install
cd ..

# 检查可用设备
print_step "检测可用设备..."
echo ""
flutter devices
echo ""

# 选择设备
print_step "请选择设备类型:"
echo "1) 真机 (推荐 - 支持蓝牙)"
echo "2) 模拟器 (不支持蓝牙)"
read -p "请输入选项 (1/2): " device_choice

if [ "$device_choice" = "1" ]; then
    print_success "将使用真机运行"
    echo ""
    echo -e "${YELLOW}请确保:${NC}"
    echo "  1. iPhone 已通过数据线连接"
    echo "  2. iPhone 已信任此电脑"
    echo "  3. iPhone 蓝牙已开启"
    echo ""
    read -p "按回车继续..."
    
    # 获取真机 ID
    device_id=$(flutter devices | grep "iPhone" | grep -v "simulator" | grep -v "disconnected" | awk '{print $NF}' | tr -d '()' | head -1)
    
    if [ -z "$device_id" ]; then
        print_error "未检测到已连接的真机"
        echo ""
        echo -e "${YELLOW}请检查:${NC}"
        echo "  1. 数据线连接是否正常"
        echo "  2. iPhone 是否已信任此电脑"
        echo "  3. iPhone 是否已解锁"
        exit 1
    fi
    
    print_success "检测到设备：$device_id"
    run_cmd="flutter run -d $device_id"
else
    print_yellow "使用模拟器运行（蓝牙功能不可用）"
    run_cmd="flutter run"
fi

echo ""
print_header "准备运行"

echo -e "${YELLOW}即将执行：${run_cmd}${NC}"
echo ""
echo -e "${YELLOW}提示:${NC}"
echo "  - 首次运行需要配置 Apple ID 签名"
echo "  - Xcode 会自动打开，请按提示操作"
echo "  - 在 iPhone 上需要信任开发者证书"
echo ""

read -p "按回车开始运行..."

# 运行应用
eval $run_cmd
