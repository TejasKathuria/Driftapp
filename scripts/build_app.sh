#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Building Drift for macOS..."

APP_NAME="Drift"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Clean up previous build
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

# Compile Swift sources with Clang module cache redirected to /tmp
echo "📦 Compiling Swift sources..."
mkdir -p /tmp/clang-cache

swiftc -O \
  -module-cache-path /tmp/clang-cache \
  -Xcc -fmodules-cache-path=/tmp/clang-cache \
  Sources/Models/*.swift \
  Sources/Services/*.swift \
  Sources/Views/*.swift \
  Sources/App/*.swift \
  Sources/main.swift \
  -o "${MACOS_DIR}/${APP_NAME}"

# Copy Resources
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Create Info.plist
cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Drift</string>
    <key>CFBundleIdentifier</key>
    <string>com.tejaskathuria.drift</string>
    <key>CFBundleName</key>
    <string>Drift</string>
    <key>CFBundleDisplayName</key>
    <string>Drift Lyrics</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Drift reads current track information from Spotify and Apple Music to display synchronized lyrics.</string>
</dict>
</plist>
EOF

chmod +x "${MACOS_DIR}/${APP_NAME}"
echo "✨ Successfully built ${BUNDLE_DIR}!"
