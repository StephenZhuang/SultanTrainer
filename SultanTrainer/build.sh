#!/bin/bash
set -e

cd "$(dirname "$0")"

PROJECT="SultanTrainer.xcodeproj"
SCHEME="SultanTrainer"
BUILD_DIR="./build"

echo "开始构建..."

xcodebuild -project "$PROJECT" \
           -scheme "$SCHEME" \
           -configuration Debug \
           -derivedDataPath "$BUILD_DIR" \
           build

APP_PATH=$(find "$BUILD_DIR/Build/Products/Debug" -name "*.app" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "构建失败：未找到.app文件"
    exit 1
fi

mkdir -p ~/Applications
rm -rf ~/Applications/SultanTrainer.app
cp -R "$APP_PATH" ~/Applications/SultanTrainer.app

echo "构建成功！"
echo "已安装到 ~/Applications/SultanTrainer.app"
echo "可通过 Spotlight 或 Launchpad 启动"
