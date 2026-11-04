#!/bin/bash
# Compila Ctrl V + para macOS (app universal arm64 + x86_64) y la empaqueta en un .zip.
# Requiere las Command Line Tools de Xcode (swiftc).  Uso:  bash macos/build.sh
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
DIST="$AQUI/../dist"
TMP="$(mktemp -d)"
APP="$TMP/CtrlVPlus.app"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$DIST"

for arch in arm64 x86_64; do
    swiftc -O -swift-version 5 \
        -target "$arch-apple-macos13.0" \
        -framework Cocoa -framework ApplicationServices -framework ServiceManagement \
        "$AQUI/Sources/main.swift" -o "$TMP/CtrlVPlus-$arch"
done
lipo -create "$TMP/CtrlVPlus-arm64" "$TMP/CtrlVPlus-x86_64" -output "$APP/Contents/MacOS/CtrlVPlus"
cp "$AQUI/Info.plist" "$APP/Contents/Info.plist"

# Firma ad-hoc (necesaria para ejecutar en Apple Silicon; no es una firma de desarrollador)
codesign --force --deep --sign - "$APP"

PAQ="$TMP/CtrlVPlus-macOS"
mkdir -p "$PAQ"
cp -R "$APP" "$PAQ/"
cp "$AQUI/install.sh" "$AQUI/uninstall.sh" "$PAQ/"
chmod +x "$PAQ/install.sh" "$PAQ/uninstall.sh"

rm -f "$DIST/CtrlVPlus-macOS.zip"
(cd "$TMP" && ditto -c -k --keepParent "CtrlVPlus-macOS" "$DIST/CtrlVPlus-macOS.zip")
echo "Listo: $DIST/CtrlVPlus-macOS.zip"
