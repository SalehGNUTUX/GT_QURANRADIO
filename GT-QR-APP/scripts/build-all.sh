#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  GT-QURANRADIO  –  Master Build Script
#  بناء جميع المنصات: Android APK + Linux AppImage/DEB
# ═══════════════════════════════════════════════════════════════
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║        GT-QURANRADIO  –  Full Build Suite v2.0        ║"
echo "║       مشغّل الإذاعات القرآنية – بناء شامل            ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

BUILD_ANDROID=false
BUILD_LINUX=false

# Parse args
for arg in "$@"; do
  case $arg in
    --android) BUILD_ANDROID=true ;;
    --linux)   BUILD_LINUX=true   ;;
    --all)     BUILD_ANDROID=true; BUILD_LINUX=true ;;
  esac
done

# If no args, ask
if ! $BUILD_ANDROID && ! $BUILD_LINUX; then
  echo "ما الذي تريد بناءه؟"
  echo "  [1] Android APK"
  echo "  [2] Linux AppImage/DEB"
  echo "  [3] الكل"
  read -r -p "الخيار (1/2/3): " CHOICE
  case $CHOICE in
    1) BUILD_ANDROID=true ;;
    2) BUILD_LINUX=true   ;;
    3) BUILD_ANDROID=true; BUILD_LINUX=true ;;
    *) echo "خيار غير صالح"; exit 1 ;;
  esac
fi

mkdir -p "$ROOT_DIR/output"

if $BUILD_ANDROID; then
  echo ""
  echo "━━━ 🤖 Android APK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bash "$SCRIPT_DIR/build-android.sh"
fi

if $BUILD_LINUX; then
  echo ""
  echo "━━━ 🐧 Linux AppImage ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bash "$SCRIPT_DIR/build-linux.sh"
fi

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  🎉 اكتمل البناء!  الملفات في مجلد output/         ║"
echo "╚══════════════════════════════════════════════════════╝"
ls "$ROOT_DIR/output/" 2>/dev/null | while read f; do
  SIZE=$(du -sh "$ROOT_DIR/output/$f" 2>/dev/null | cut -f1)
  echo "  📦 $f  ($SIZE)"
done
