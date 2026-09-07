#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Generating Xcode project"
xcodegen generate

DERIVED_DATA=$(mktemp -d)
trap 'rm -rf "$DERIVED_DATA"' EXIT

echo "==> Building Release (arm64)"
xcodebuild -project Vestige.xcodeproj -scheme Vestige -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA" \
  build

APP_PATH="$DERIVED_DATA/Build/Products/Release/Vestige.app"

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "$APP_PATH"
codesign -dv "$APP_PATH"

VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString)
OUT_DIR="dist"
mkdir -p "$OUT_DIR"
ZIP_PATH="$OUT_DIR/Vestige-$VERSION-macos-arm64.zip"

echo "==> Zipping to $ZIP_PATH"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "==> Done: $ZIP_PATH"
