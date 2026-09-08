#!/usr/bin/env bash
# Decode official Stremio Android TV 1.10.4, overlay MPV dialogue downmix, sign.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR="$ROOT/vendor"
WORK="$ROOT/work"
DIST="$ROOT/dist"
SIGNING="$ROOT/signing"
OVERLAY="$ROOT/overlay"

PACKAGE="com.stremio.one.downmix"
VERSION="1.10.4"
UPSTREAM_URL="https://dl.strem.io/android/v1.10.4-androidTV/com.stremio.one-1.10.4-31048580-armeabi-v7a.apk"
UPSTREAM_SHA="e18a5405bb53e12a903ff477457318b8f8d3c8e1995e0a4c3ff5d8893d1ccf0b"
UPSTREAM_APK="$VENDOR/com.stremio.one-1.10.4-31048580-armeabi-v7a.apk"
DECODED="$WORK/apktool"
UNSIGNED="$WORK/unsigned.apk"
ALIGNED="$WORK/aligned.apk"
OUT_APK="$DIST/stremio-androidtv-downmix-${VERSION}.apk"
KS="$SIGNING/downmix.jks"
KS_ALIAS="downmix"
KS_PASS="changeit"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing tool: $1" >&2
    exit 1
  }
}

sha256_of() {
  sha256sum "$1" | awk '{print $1}'
}

fetch_upstream() {
  mkdir -p "$VENDOR"
  if [[ -f "$UPSTREAM_APK" ]]; then
    local have
    have="$(sha256_of "$UPSTREAM_APK")"
    if [[ "$have" == "$UPSTREAM_SHA" ]]; then
      echo "upstream apk ok ($UPSTREAM_SHA)"
      return
    fi
    echo "upstream apk hash mismatch, re-downloading" >&2
  fi
  echo "downloading official apk"
  curl -fsSL "$UPSTREAM_URL" -o "$UPSTREAM_APK"
  local have
  have="$(sha256_of "$UPSTREAM_APK")"
  if [[ "$have" != "$UPSTREAM_SHA" ]]; then
    echo "download hash $have, expected $UPSTREAM_SHA" >&2
    exit 1
  fi
}

decode() {
  mkdir -p "$WORK"
  if [[ -d "$DECODED" && "${1:-}" != "force" ]]; then
    echo "reusing $DECODED (pass --clean to decode again)"
    return
  fi
  rm -rf "$DECODED"
  echo "apktool decode"
  apktool d -f "$UPSTREAM_APK" -o "$DECODED"
}

rename_package() {
  python3 - "$DECODED" <<'PY'
import re, sys
from pathlib import Path
root = Path(sys.argv[1])
pat = re.compile(r"com\.stremio\.one(?!\.downmix)")
nfiles = 0
for p in root.rglob("*"):
    if not p.is_file():
        continue
    if p.suffix.lower() not in {".xml", ".yml", ".yaml", ".smali", ".txt"}:
        continue
    text = p.read_text(encoding="utf-8", errors="ignore")
    new = pat.sub("com.stremio.one.downmix", text)
    if new != text:
        p.write_text(new, encoding="utf-8")
        nfiles += 1
print(f"renamed package in {nfiles} files")
yml = root / "apktool.yml"
if yml.exists():
    t = yml.read_text(encoding="utf-8")
    t = re.sub(r"^apkFileName:.*$", "apkFileName: com.stremio.one.downmix-1.10.4.apk", t, count=1, flags=re.M)
    yml.write_text(t, encoding="utf-8")
PY
}

apply_overlay() {
  echo "copy overlay smali"
  cp -a "$OVERLAY/." "$DECODED/"
}

ensure_keystore() {
  mkdir -p "$SIGNING"
  if [[ -f "$KS" ]]; then
    return
  fi
  echo "creating $KS"
  keytool -genkeypair \
    -keystore "$KS" \
    -alias "$KS_ALIAS" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$KS_PASS" -keypass "$KS_PASS" \
    -dname "CN=stremio-androidtv-downmix"
}

rebuild() {
  mkdir -p "$DIST" "$WORK"
  echo "apktool build"
  apktool b "$DECODED" -o "$UNSIGNED"
  echo "zipalign"
  zipalign -f 4 "$UNSIGNED" "$ALIGNED"
  echo "sign"
  apksigner sign \
    --ks "$KS" \
    --ks-key-alias "$KS_ALIAS" \
    --ks-pass "pass:$KS_PASS" \
    --key-pass "pass:$KS_PASS" \
    --out "$OUT_APK" \
    "$ALIGNED"
  apksigner verify --verbose "$OUT_APK" >/dev/null
  echo "wrote $OUT_APK"
  echo "sha256 $(sha256_of "$OUT_APK")"
}

CLEAN=0
for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN=1 ;;
    -h|--help)
      echo "usage: $0 [--clean]"
      echo "  --clean   decode the official apk from scratch"
      exit 0
      ;;
    *)
      echo "unknown arg: $arg" >&2
      exit 1
      ;;
  esac
done

need apktool
need zipalign
need apksigner
need keytool
need python3
need curl

fetch_upstream
if [[ "$CLEAN" == 1 ]]; then
  decode force
else
  decode
fi
rename_package
apply_overlay
ensure_keystore
rebuild
