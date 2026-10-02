#!/bin/sh
# Builds Bitper.app (menu bar only, mic permission via Info.plist).
set -e
cd "$(dirname "$0")"
APP=Bitper.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp AppIcon.icns "$APP/Contents/Resources/"
swiftc -O -parse-as-library -target "$(uname -m)-apple-macos14.0" Bitper.swift -o "$APP/Contents/MacOS/Bitper"
cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>local.bitper</string>
  <key>CFBundleName</key><string>Bitper</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleExecutable</key><string>Bitper</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSMicrophoneUsageDescription</key><string>Record speech for local transcription with whisper.cpp.</string>
</dict></plist>
EOF
"$APP/Contents/MacOS/Bitper" --selftest
# Sign with a stable local certificate so macOS keeps the Accessibility (typing)
# permission across rebuilds. Ad-hoc signatures change every build and lose it.
IDENTITY="Bitper Local Signing"
if ! security find-certificate -c "$IDENTITY" >/dev/null 2>&1; then
    echo "Creating local signing certificate \"$IDENTITY\" (one time)"
    tmp=$(mktemp -d)
    /usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/CN=$IDENTITY" \
        -addext "extendedKeyUsage=codeSigning" -addext "keyUsage=critical,digitalSignature" \
        -keyout "$tmp/key.pem" -out "$tmp/cert.pem" 2>/dev/null
    /usr/bin/openssl pkcs12 -export -inkey "$tmp/key.pem" -in "$tmp/cert.pem" -out "$tmp/id.p12" -passout pass:bitper
    security import "$tmp/id.p12" -k "$HOME/Library/Keychains/login.keychain-db" -P bitper -T /usr/bin/codesign >/dev/null
    rm -rf "$tmp"
fi
codesign --force --sign "$IDENTITY" "$APP" 2>/dev/null || {
    echo "Warning: signing with \"$IDENTITY\" failed; using an ad-hoc signature (typing permission resets on each build)."
    codesign --force --sign - "$APP"
}
echo "Built $APP — run: open $APP"
