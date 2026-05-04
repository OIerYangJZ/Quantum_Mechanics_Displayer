#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

: "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM to the Apple Developer Team ID.}"

APP_BUNDLE_ID="${APP_BUNDLE_ID:-io.github.oieryangjz.quantummechanicslab}"
MARKETING_VERSION="${MARKETING_VERSION:-0.1.0}"
CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION:-$(date +%Y%m%d%H%M)}"
CONFIGURATION="${CONFIGURATION:-Release}"
CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/QuantumMechanicsLabClangModuleCache}"
ARCHIVE_PATH="${ARCHIVE_PATH:-/private/tmp/QuantumMechanicsLabArchives/QuantumMechanicsLab-${MARKETING_VERSION}-${CURRENT_PROJECT_VERSION}.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-/private/tmp/QuantumMechanicsLabExport}"
EXPORT_OPTIONS_PATH="${EXPORT_OPTIONS_PATH:-/private/tmp/QuantumMechanicsLabExportOptions.plist}"
EXPORT_METHOD="${EXPORT_METHOD:-app-store-connect}"
UPLOAD_TO_TESTFLIGHT="${UPLOAD_TO_TESTFLIGHT:-0}"

if [[ "$UPLOAD_TO_TESTFLIGHT" == "1" ]]; then
  : "${ASC_KEY_ID:?Set ASC_KEY_ID for App Store Connect API authentication.}"
  : "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID for App Store Connect API authentication.}"
  : "${ASC_KEY_PATH:?Set ASC_KEY_PATH to the private .p8 key path.}"
  EXPORT_DESTINATION="upload"
else
  EXPORT_DESTINATION="export"
fi

export CLANG_MODULE_CACHE_PATH
mkdir -p "$(dirname "$ARCHIVE_PATH")" "$EXPORT_PATH" "$CLANG_MODULE_CACHE_PATH"

cat > "$EXPORT_OPTIONS_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>${EXPORT_DESTINATION}</string>
  <key>manageAppVersionAndBuildNumber</key>
  <false/>
  <key>method</key>
  <string>${EXPORT_METHOD}</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>teamID</key>
  <string>${DEVELOPMENT_TEAM}</string>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
PLIST

echo "== Regenerate Xcode project =="
swift scripts/generate_xcode_project.swift

echo "== Archive ${APP_BUNDLE_ID} ${MARKETING_VERSION} (${CURRENT_PROJECT_VERSION}) =="
xcodebuild -project QuantumMechanicsLab.xcodeproj \
  -scheme QuantumMechanicsLab \
  -configuration "$CONFIGURATION" \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  PRODUCT_BUNDLE_IDENTIFIER="$APP_BUNDLE_ID" \
  MARKETING_VERSION="$MARKETING_VERSION" \
  CURRENT_PROJECT_VERSION="$CURRENT_PROJECT_VERSION" \
  CODE_SIGN_STYLE=Automatic \
  clean archive

export_args=(
  xcodebuild
  -exportArchive
  -archivePath "$ARCHIVE_PATH"
  -exportOptionsPlist "$EXPORT_OPTIONS_PATH"
  -exportPath "$EXPORT_PATH"
  -allowProvisioningUpdates
)

if [[ "$UPLOAD_TO_TESTFLIGHT" == "1" ]]; then
  export_args+=(
    -authenticationKeyPath "$ASC_KEY_PATH"
    -authenticationKeyID "$ASC_KEY_ID"
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"
  )
fi

echo "== Export archive (${EXPORT_DESTINATION}) =="
"${export_args[@]}"

if [[ "$UPLOAD_TO_TESTFLIGHT" == "1" ]]; then
  echo "Archive uploaded for TestFlight processing."
else
  echo "Archive exported to ${EXPORT_PATH}."
fi
