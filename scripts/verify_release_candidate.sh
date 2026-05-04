#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/private/tmp/QuantumMechanicsLabDerived}"
CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/QuantumMechanicsLabClangModuleCache}"

export CLANG_MODULE_CACHE_PATH
mkdir -p "$CLANG_MODULE_CACHE_PATH"

cd "$ROOT_DIR"

echo "== SwiftPM tests =="
swift test --disable-sandbox -Xcc -fmodules-cache-path="$CLANG_MODULE_CACHE_PATH"

echo "== Core smoke tests =="
swift run --disable-sandbox -Xcc -fmodules-cache-path="$CLANG_MODULE_CACHE_PATH" QuantumMechanicsLabCoreSmokeTests

echo "== Regenerate Xcode project =="
swift scripts/generate_xcode_project.swift

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if ! git diff --quiet -- QuantumMechanicsLab.xcodeproj scripts/generate_xcode_project.swift; then
    echo "Generated Xcode project is not committed or generator output drifted." >&2
    git diff -- QuantumMechanicsLab.xcodeproj scripts/generate_xcode_project.swift >&2
    exit 1
  fi
fi

echo "== iOS simulator build-for-testing =="
xcodebuild -project QuantumMechanicsLab.xcodeproj \
  -scheme QuantumMechanicsLab \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing

echo "Release candidate validation passed."
