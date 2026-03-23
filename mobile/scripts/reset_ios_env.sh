#!/usr/bin/env bash
set -euo pipefail

echo "==> [1/6] 清理 Flutter 构建缓存"
flutter clean

echo "==> [2/6] 清理 iOS Pods/锁文件/软链接"
rm -rf ios/Pods ios/.symlinks ios/Podfile.lock

echo "==> [3/6] 重新拉取 Dart 依赖"
flutter pub get

echo "==> [4/6] 重新安装 CocoaPods"
cd ios
pod repo update
pod install --verbose
cd ..

echo "==> [5/6] 清理 Xcode DerivedData（可选但推荐）"
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "==> [6/6] 输出检查项"
echo "请确认："
echo "  - 使用的是 Runner.xcworkspace（不是 .xcodeproj）"
echo "  - Xcode -> Signing & Capabilities 配置正确"
echo "  - 若仍报 GeneratedPluginRegistrant/audio_session 相关错误，执行："
echo "      flutter build ios -v"
