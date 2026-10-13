#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_CONFIG="Release"
DERIVED_DATA="./build"
DIST_DIR="./dist"
DMG_NAME="SultanTrainer.dmg"
VOL_NAME="SultanTrainer"

ARCHS_FLAG=""
if [ "${1}" = "--universal" ]; then
    ARCHS_FLAG="ARCHS=arm64,x86_64 ONLY_ACTIVE_ARCH=NO"
    echo "==> 构建通用架构 (arm64 + x86_64)"
else
    echo "==> 构建当前架构 (arm64)"
fi

echo "==> 清理旧的构建产物"
rm -rf "$DERIVED_DATA"

echo "==> 构建 Release"
xcodebuild -project SultanTrainer.xcodeproj \
           -scheme SultanTrainer \
           -configuration "$BUILD_CONFIG" \
           -derivedDataPath "$DERIVED_DATA" \
           $ARCHS_FLAG \
           build

APP_PATH=$(find "$DERIVED_DATA/Build/Products/$BUILD_CONFIG" -name "*.app" -type d | head -1)
if [ -z "$APP_PATH" ]; then
    echo "错误: 未找到构建产物 .app"
    exit 1
fi
echo "==> 构建产物: $APP_PATH"

echo "==> Ad-hoc 签名"
codesign --deep --sign - "$APP_PATH"

STAGING=$(mktemp -d)
trap "rm -rf '$STAGING'" EXIT

cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

mkdir -p "$DIST_DIR"
DMG_PATH="$DIST_DIR/$DMG_NAME"
rm -f "$DMG_PATH"

echo "==> 打包 DMG: $DMG_PATH"
hdiutil create -volname "$VOL_NAME" \
               -srcfolder "$STAGING" \
               -ov \
               -format UDZO \
               "$DMG_PATH"

echo ""
echo "==> 打包完成: $DMG_PATH"
echo "    大小: $(du -h "$DMG_PATH" | cut -f1)"
echo ""
echo "分发给他人时请告知："
echo "  首次打开如提示\"无法验证开发者\"，请右键点击 App → 选择\"打开\" → 再次确认\"打开\""
