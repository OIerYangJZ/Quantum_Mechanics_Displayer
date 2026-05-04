#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/QuantumMechanicsLab.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
BINARY_NAME="QuantumMechanicsLabApp"

cd "$ROOT_DIR"
swift build --product "$BINARY_NAME"

mkdir -p "$MACOS_DIR"
cp "$ROOT_DIR/.build/arm64-apple-macosx/debug/$BINARY_NAME" "$MACOS_DIR/$BINARY_NAME"
chmod +x "$MACOS_DIR/$BINARY_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>QuantumMechanicsLabApp</string>
  <key>CFBundleIdentifier</key>
  <string>local.quantum-mechanics-lab</string>
  <key>CFBundleName</key>
  <string>Quantum Mechanics Lab</string>
  <key>CFBundleDisplayName</key>
  <string>Quantum Mechanics Lab</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>15.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "Packaged $APP_DIR"
echo "Run with: open \"$APP_DIR\""
