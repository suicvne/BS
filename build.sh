#!/bin/sh
set -eu

cd "$(dirname "$0")"

SWIFTPM_CACHE_DIR=.build/swiftpm-cache \
CLANG_MODULE_CACHE_PATH=.build/module-cache \
swift build --scratch-path .build/scratch

APP_BUNDLE=".build/app/BSTextEditor.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"

mkdir -p "$APP_MACOS"
cp .build/scratch/debug/BSTextEditor "$APP_MACOS/BSTextEditor"
cp Support/Info.plist "$APP_CONTENTS/Info.plist"
printf "APPL????" > "$APP_CONTENTS/PkgInfo"
chmod +x "$APP_MACOS/BSTextEditor"

echo "Built $APP_BUNDLE"
