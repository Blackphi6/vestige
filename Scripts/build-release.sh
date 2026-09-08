#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Generating Xcode project"
xcodegen generate

DERIVED_DATA=$(mktemp -d)
SPARKLE_BIN_DIR=$(mktemp -d)
trap 'rm -rf "$DERIVED_DATA" "$SPARKLE_BIN_DIR"' EXIT

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

echo "==> Generating Sparkle appcast"
SPARKLE_VERSION="2.9.6" # keep in sync with project.yml's Sparkle package pin
curl -fsSL -o "$SPARKLE_BIN_DIR/Sparkle.tar.xz" \
  "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz"
tar -xf "$SPARKLE_BIN_DIR/Sparkle.tar.xz" -C "$SPARKLE_BIN_DIR"
SIGN_UPDATE="$SPARKLE_BIN_DIR/bin/sign_update"

# CI has no Keychain, so the private key comes from $SPARKLE_PRIVATE_KEY (a GitHub
# Actions secret) piped to stdin; a local dev machine falls back to its Keychain entry
# from `generate_keys`.
if [ -n "${SPARKLE_PRIVATE_KEY:-}" ]; then
  SIGNATURE=$(echo "$SPARKLE_PRIVATE_KEY" | "$SIGN_UPDATE" --ed-key-file - -p "$ZIP_PATH")
else
  SIGNATURE=$("$SIGN_UPDATE" -p "$ZIP_PATH")
fi

FILE_SIZE=$(stat -f%z "$ZIP_PATH")
BUILD_NUMBER=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleVersion)
PUB_DATE=$(date -u "+%a, %d %b %Y %H:%M:%S +0000")
APPCAST_PATH="$OUT_DIR/appcast.xml"

cat > "$APPCAST_PATH" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Vestige</title>
    <link>https://github.com/Blackphi6/vestige</link>
    <description>Vestige release feed</description>
    <language>ja</language>
    <item>
      <title>Version $VERSION</title>
      <pubDate>$PUB_DATE</pubDate>
      <sparkle:version>$BUILD_NUMBER</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
      <enclosure
        url="https://github.com/Blackphi6/vestige/releases/download/v$VERSION/Vestige-$VERSION-macos-arm64.zip"
        length="$FILE_SIZE"
        type="application/octet-stream"
        sparkle:edSignature="$SIGNATURE" />
    </item>
  </channel>
</rss>
EOF

echo "==> Done: $ZIP_PATH, $APPCAST_PATH"
