#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  GT-QURANRADIO  –  Android APK Build Script
#  يتطلب: Node.js ≥ 18 | JDK 17 | Android SDK (ANDROID_HOME)
# ═══════════════════════════════════════════════════════════════
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   GT-QURANRADIO  –  Android APK Builder      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Check dependencies ──
command -v node  >/dev/null || { echo "❌ Node.js غير مثبت. حمّله من: https://nodejs.org"; exit 1; }
command -v java  >/dev/null || { echo "❌ JDK 17 غير مثبت."; exit 1; }
[ -n "$ANDROID_HOME" ] || { echo "❌ ANDROID_HOME غير محدد. ثبّت Android SDK وحدد المتغير."; exit 1; }

echo "✅ Node $(node -v) | Java $(java -version 2>&1 | head -1 | awk '{print $3}') | SDK: $ANDROID_HOME"

# ── 2. Install Capacitor packages ──
echo ""
echo "📦 تثبيت حزم Capacitor..."
npm install --save-exact \
  @capacitor/core@6 \
  @capacitor/cli@6 \
  @capacitor/android@6 \
  @capacitor/splash-screen@6 \
  @capacitor/status-bar@6

# ── 3. Copy icons to www/icons ──
echo ""
echo "🖼️  نسخ الأيقونات..."
mkdir -p www/icons
for size in 72 96 128 144 152 180 192 384 512; do
  SRC="GT-QR-icons/all/${size}x${size}/GT-QURANRADIO-LOGO.png"
  DST="www/icons/icon-${size}.png"
  [ -f "$SRC" ] && cp "$SRC" "$DST" && echo "   ✓ icon-${size}.png" || echo "   ⚠ missing: $SRC (ضع أيقونة ${size}px يدوياً)"
done
# fallback 32px
[ -f "GT-QR-icons/all/32x32/GT-QURANRADIO-LOGO.png" ] && cp "GT-QR-icons/all/32x32/GT-QURANRADIO-LOGO.png" "www/icons/icon-32.png"

# ── 4. Init Capacitor (if not already) ──
if [ ! -f "capacitor.config.json" ] || [ ! -d "android" ]; then
  echo ""
  echo "🔧 تهيئة Capacitor..."
  npx cap init "Quran Radio" "net.gnutux.quranradio" --web-dir www || true
fi

# ── 5. Add Android platform ──
if [ ! -d "android" ]; then
  echo ""
  echo "📱 إضافة منصة Android..."
  npx cap add android
fi

# ── 6. Copy Android resource icons ──
echo ""
echo "🎨 نسخ أيقونات Android..."
MIPMAP_DIR="android/app/src/main/res"
declare -A SIZES=([mipmap-mdpi]=48 [mipmap-hdpi]=72 [mipmap-xhdpi]=96 [mipmap-xxhdpi]=144 [mipmap-xxxhdpi]=192)
for FOLDER in "${!SIZES[@]}"; do
  SIZE="${SIZES[$FOLDER]}"
  mkdir -p "$MIPMAP_DIR/$FOLDER"
  SRC="www/icons/icon-${SIZE}.png"
  [ -f "$SRC" ] && cp "$SRC" "$MIPMAP_DIR/$FOLDER/ic_launcher.png" \
                && cp "$SRC" "$MIPMAP_DIR/$FOLDER/ic_launcher_round.png" \
                && echo "   ✓ $FOLDER (${SIZE}px)"
done

# ── 7. Patch AndroidManifest for internet & audio ──
MANIFEST="android/app/src/main/AndroidManifest.xml"
if ! grep -q "INTERNET" "$MANIFEST"; then
  sed -i 's|<manifest|<manifest xmlns:tools="http://schemas.android.com/tools"|' "$MANIFEST"
  sed -i 's|<uses-permission android:name="android.permission.INTERNET"/>||' "$MANIFEST"
  sed -i 's|<application|<uses-permission android:name="android.permission.INTERNET"/>\n    <application|' "$MANIFEST"
fi

# usesCleartextTraffic for http streams
grep -q "usesCleartextTraffic" "$MANIFEST" || \
  sed -i 's|android:label="@string/app_name"|android:label="@string/app_name"\n        android:usesCleartextTraffic="true"|' "$MANIFEST"

# ── 8. Set app name ──
STRINGS_FILE="android/app/src/main/res/values/strings.xml"
[ -f "$STRINGS_FILE" ] && sed -i 's|<string name="app_name">.*</string>|<string name="app_name">Quran Radio</string>|' "$STRINGS_FILE"

# ── 9. Set theme color ──
COLORS_FILE="android/app/src/main/res/values/colors.xml"
if [ -f "$COLORS_FILE" ]; then
  sed -i 's|<color name="colorPrimary">.*</color>|<color name="colorPrimary">#0b1426</color>|' "$COLORS_FILE"
  sed -i 's|<color name="colorPrimaryDark">.*</color>|<color name="colorPrimaryDark">#0b1426</color>|' "$COLORS_FILE"
fi

# ── 10. Sync web assets ──
echo ""
echo "🔄 مزامنة ملفات الويب..."
npx cap sync android

# ── 11. Build APK ──
echo ""
echo "🔨 بناء APK (Debug)..."
cd android
chmod +x gradlew
./gradlew assembleDebug --no-daemon --stacktrace 2>&1 | tail -30
cd ..

APK_PATH="android/app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK_PATH" ]; then
  mkdir -p output
  cp "$APK_PATH" "output/QuranRadio-v2.0-debug.apk"
  SIZE=$(du -sh "output/QuranRadio-v2.0-debug.apk" | cut -f1)
  echo ""
  echo "╔══════════════════════════════════════════════╗"
  echo "║  ✅ APK جاهز!                                ║"
  echo "║  📁 output/QuranRadio-v2.0-debug.apk ($SIZE)  ║"
  echo "╚══════════════════════════════════════════════╝"
else
  echo "❌ فشل بناء APK. راجع الأخطاء أعلاه."
  exit 1
fi

# ── Optional: Release build instructions ──
echo ""
echo "📋 لبناء APK نهائي موقّع (Release):"
echo "   1. أنشئ keystore: keytool -genkey -v -keystore quranradio.jks \\"
echo "        -alias quranradio -keyalg RSA -keysize 2048 -validity 10000"
echo "   2. أضف إلى android/app/build.gradle:"
echo "        signingConfigs { release { storeFile file('../quranradio.jks') ... } }"
echo "   3. شغّل: cd android && ./gradlew assembleRelease"
