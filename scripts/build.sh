#!/usr/bin/env bash
# Decode an official Stremio Android TV APK, overlay MPV dialogue downmix, sign.
# Package stays com.stremio.one. Uninstall the official app before installing.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR="$ROOT/vendor"
WORK="$ROOT/work"
DIST="$ROOT/dist"
SIGNING="$ROOT/signing"
CATALOG="$ROOT/scripts/catalog.py"

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

lookup() {
  python3 "$CATALOG" "$ROOT" "$@"
}

fetch_upstream() {
  mkdir -p "$VENDOR"
  if [[ -f "$UPSTREAM_APK" ]]; then
    local have
    have="$(sha256_of "$UPSTREAM_APK")"
    if [[ "$have" == "$SHA256" ]]; then
      echo "upstream apk ok ($ABI $SHA256)"
      return
    fi
    echo "upstream apk hash mismatch, re-downloading" >&2
  fi
  echo "downloading $URL"
  curl -fL --retry 3 -o "$UPSTREAM_APK" "$URL"
  local have
  have="$(sha256_of "$UPSTREAM_APK")"
  if [[ "$have" != "$SHA256" ]]; then
    echo "download hash $have, expected $SHA256" >&2
    exit 1
  fi
}

decode() {
  mkdir -p "$(dirname "$DECODED")"
  if [[ -d "$DECODED" && "${1:-}" != "force" ]]; then
    echo "reusing $DECODED (pass --clean to decode again)"
    return
  fi
  rm -rf "$DECODED"
  echo "apktool decode ($VERSION $ABI)"
  apktool d -f "$UPSTREAM_APK" -o "$DECODED"
}

apply_overlay() {
  local common="$ROOT/overlay/common"
  local verdir="$ROOT/overlay/$OVERLAY"
  if [[ ! -d "$verdir" ]]; then
    echo "no overlay for $VERSION (expected overlay/$OVERLAY)." >&2
    echo "Port the MPV hooks from overlay/1.10.4 into overlay/$OVERLAY, then rebuild." >&2
    exit 1
  fi
  echo "copy overlay common + $OVERLAY"
  if [[ -d "$common" ]]; then
    cp -a "$common/." "$DECODED/"
  fi
  cp -a "$verdir/." "$DECODED/"
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
  mkdir -p "$DIST" "$(dirname "$UNSIGNED")"
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

load_apk() {
  local version="$1" abi="$2"
  eval "$(lookup apk "$version" "$abi")"
  UPSTREAM_APK="$VENDOR/$FILENAME"
  DECODED="$WORK/$VERSION/$ABI/apktool"
  UNSIGNED="$WORK/$VERSION/$ABI/unsigned.apk"
  ALIGNED="$WORK/$VERSION/$ABI/aligned.apk"
  OUT_APK="$DIST/stremio-androidtv-downmix-${VERSION}-${ABI}.apk"
}

build_one() {
  load_apk "$1" "$2"
  fetch_upstream
  if [[ "$CLEAN" == 1 ]]; then
    decode force
  else
    decode
  fi
  apply_overlay
  ensure_keystore
  rebuild
}

CLEAN=0
VERSION=""
ABI=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean) CLEAN=1 ;;
    --version)
      VERSION="${2:?}"
      shift
      ;;
    --abi)
      ABI="${2:?}"
      shift
      ;;
    --list)
      lookup list
      exit 0
      ;;
    -h|--help)
      cat <<EOF
usage: $0 [--version VER] [--abi ABI|all] [--clean]

  --version  catalog version (default: catalog default)
  --abi      armeabi-v7a, arm64-v8a, x86, x86_64, or all
             aliases: arm, arm64, x64
  --clean    decode the official apk from scratch
  --list     show catalog

DEX overlay is per Stremio version and shared across ABIs.
Native libs come from each official apk.
EOF
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 1
      ;;
  esac
  shift
done

need apktool
need zipalign
need apksigner
need keytool
need curl
need python3

if [[ -z "$VERSION" ]]; then
  VERSION="$(lookup default-version)"
fi
if [[ -z "$ABI" ]]; then
  ABI="armeabi-v7a"
fi
ABI="$(lookup canonical-abi "$ABI")"

if [[ "$ABI" == "all" ]]; then
  for one in $(lookup abis "$VERSION"); do
    echo "======== $VERSION $one ========"
    build_one "$VERSION" "$one"
  done
else
  build_one "$VERSION" "$ABI"
fi
