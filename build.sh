#!/bin/sh
# Tanzanite variant build script by @noticesa
# (overlay sources & platform keys: ukriu / AOSP, see LICENSE files)
# Build HyperUnlocked (tanzanite variant) into a flashable zip.
# Output: ./Tanzanite-HyperUnlocked.zip (same folder as this script).
# Overlays are compiled to a staging dir, the repo stays clean.
# Upstream tools/aapt+zipalign are x86_64-only; on-device we fall back
# to native Termux aapt/zipalign. Signing uses apksigner against the
# repo platform keys (signapk.jar bundles an x86_64-only .so).
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
STAGE="$ROOT/.build"
OUT="$ROOT/Tanzanite-HyperUnlocked.zip"

# pick runnable binaries (repo tools first, system fallback)
if [ -x "$ROOT/tools/aapt" ] && "$ROOT/tools/aapt" version >/dev/null 2>&1; then
    AAPT="$ROOT/tools/aapt"
else
    AAPT="aapt"
fi
if [ -x "$ROOT/tools/zipalign" ] && "$ROOT/tools/zipalign" >/dev/null 2>&1; then
    ZIPALIGN="$ROOT/tools/zipalign"
else
    ZIPALIGN="zipalign"
fi
command -v "$AAPT" >/dev/null 2>&1 || { echo "missing: $AAPT" >&2; exit 1; }
command -v "$ZIPALIGN" >/dev/null 2>&1 || { echo "missing: $ZIPALIGN" >&2; exit 1; }
command -v java >/dev/null 2>&1 || { echo "missing: java" >&2; exit 1; }
command -v zip >/dev/null 2>&1 || { echo "missing: zip" >&2; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "missing: openssl" >&2; exit 1; }
command -v apksigner >/dev/null 2>&1 || { echo "missing: apksigner" >&2; exit 1; }

rm -rf "$STAGE"
mkdir -p "$STAGE/apk" "$STAGE/module"

echo "[-] Preparing platform keystore..."
openssl pkey -inform DER \
    -in "$ROOT/tools/keys/platform.pk8" \
    -out "$STAGE/key.pem" 2>/dev/null
openssl pkcs12 -export \
    -out "$STAGE/platform.p12" \
    -inkey "$STAGE/key.pem" \
    -in "$ROOT/tools/keys/platform.x509.pem" \
    -password pass:android -name platform 2>/dev/null
rm -f "$STAGE/key.pem"

echo "[-] Building overlays with $AAPT..."
for folder in "$ROOT"/overlay/*/; do
    [ -d "$folder" ] || continue
    NAME=$(basename "$folder")
    "$AAPT" package -f \
        -F "$STAGE/apk/HyperUnlocked-${NAME}-unalign.apk" \
        -M "${folder}/AndroidManifest.xml" \
        -S "${folder}/res" \
        -I "$ROOT/tools/android.jar"
    "$ZIPALIGN" -f -p 4 \
        "$STAGE/apk/HyperUnlocked-${NAME}-unalign.apk" \
        "$STAGE/apk/HyperUnlocked-${NAME}-unsigned.apk"
    apksigner sign \
        --ks "$STAGE/platform.p12" --ks-pass pass:android \
        --out "$STAGE/apk/HyperUnlocked-${NAME}.apk" \
        "$STAGE/apk/HyperUnlocked-${NAME}-unsigned.apk"
    echo "[-] overlay built: HyperUnlocked-${NAME}.apk"
done
rm -f "$STAGE"/apk/*-unalign.apk "$STAGE"/apk/*-unsigned.apk

echo "[-] Building WebUI..."
if [ ! -f "$ROOT/module/webroot/index.html" ] || [ -n "$(find "$ROOT/webui/src" "$ROOT/webui/index.html" -newer "$ROOT/module/webroot/index.html" 2>/dev/null)" ]; then
    command -v node >/dev/null 2>&1 || { echo "missing: node" >&2; exit 1; }
    (cd "$ROOT/webui" && [ -d node_modules ] || npm install --no-audit --no-fund)
    # NOTE: vite's bin shebang needs /usr/bin/env (absent on Termux),
    # so invoke it through node directly.
    (cd "$ROOT/webui" && node ./node_modules/vite/bin/vite.js build)
    cp -f "$ROOT/webui/dist/index.html" "$ROOT/module/webroot/index.html"
else
    echo "[-] WebUI up to date, skipping."
fi

echo "[-] Staging module..."
cp -r "$ROOT"/module/* "$STAGE/module/"
cp "$ROOT/LICENSE" "$ROOT/LICENSE_NOTICE.txt" "$STAGE/module/"
mkdir -p "$STAGE/module/system/product/overlay"
mv "$STAGE"/apk/HyperUnlocked-*.apk "$STAGE/module/system/product/overlay/"

echo "[-] Zipping..."
rm -f "$OUT"
cd "$STAGE/module" && zip -r -9 "$OUT" ./* >/dev/null
rm -rf "$STAGE"

echo "[-] Done: $OUT ($(du -h "$OUT" | cut -f1))"
