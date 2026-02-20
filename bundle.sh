#!/bin/bash
set -euo pipefail

APP_NAME="ImagePasteFix"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
SIGN_IDENTITY="Apple Development: Colin Weir (2KKL3U47W2)"

# Build
swift build -c release

# Clean previous bundle
rm -rf "$APP_BUNDLE"

# Create .app structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "ImagePasteFix/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy app icon
cp "ImagePasteFix/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Sign
codesign --force --sign "$SIGN_IDENTITY" --timestamp --options runtime "$APP_BUNDLE"

# Install
rm -rf "/Applications/$APP_NAME.app"
cp -r "$APP_BUNDLE" /Applications/

echo "Installed /Applications/$APP_NAME.app (signed)"
echo "Run:  open /Applications/$APP_NAME.app"
