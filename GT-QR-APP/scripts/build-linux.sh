#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  GT-QURANRADIO  –  Linux AppImage / DEB Builder
#  يتطلب: Node.js ≥ 18 | npm
# ═══════════════════════════════════════════════════════════════
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   GT-QURANRADIO  –  Linux AppImage Builder   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Check dependencies ──
command -v node >/dev/null || { echo "❌ Node.js غير مثبت."; exit 1; }
echo "✅ Node $(node -v)"

# ── 2. Copy icons ──
echo ""
echo "🖼️  نسخ الأيقونات..."
mkdir -p www/icons
for size in 32 72 96 128 144 152 180 192 384 512; do
  SRC="GT-QR-icons/all/${size}x${size}/GT-QURANRADIO-LOGO.png"
  DST="www/icons/icon-${size}.png"
  [ -f "$SRC" ] && cp "$SRC" "$DST" && echo "   ✓ icon-${size}.png"
done

# ── 3. Setup Electron project ──
echo ""
echo "📦 إعداد مشروع Electron..."
cp electron-package.json electron/package.json

# Install electron deps in electron/
cd electron
npm install --legacy-peer-deps
cd ..

# Copy www into build context
mkdir -p build-res
[ -f "www/icons/icon-512.png" ] && cp "www/icons/icon-512.png" build-res/

# ── 4. Copy deb scripts ──
mkdir -p scripts
cat > scripts/after-install.sh << 'POSTINST'
#!/bin/bash
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true
POSTINST

cat > scripts/after-remove.sh << 'POSTRM'
#!/bin/bash
update-desktop-database /usr/share/applications 2>/dev/null || true
POSTRM

chmod +x scripts/after-install.sh scripts/after-remove.sh

# ── 5. Build AppImage ──
echo ""
echo "🔨 بناء AppImage..."
cd electron
./node_modules/.bin/electron-builder --linux AppImage --config "../electron-package.json" 2>&1 | tail -40
cd ..

# ── 6. Also build .deb (optional) ──
echo ""
echo "🔨 بناء .deb package..."
cd electron
./node_modules/.bin/electron-builder --linux deb --config "../electron-package.json" 2>&1 | tail -20
cd ..

# ── 7. Collect outputs ──
mkdir -p output
find electron/dist-electron -name "*.AppImage" -exec cp {} output/ \; 2>/dev/null || true
find electron/dist-electron -name "*.deb"      -exec cp {} output/ \; 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✅ الملفات جاهزة في مجلد output/           ║"
ls output/ 2>/dev/null | sed 's/^/║  📦 /'
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "📋 تشغيل AppImage:"
echo "   chmod +x output/*.AppImage"
echo "   ./output/*.AppImage"
echo ""
echo "📋 تثبيت .deb:"
echo "   sudo dpkg -i output/*.deb"
echo "   sudo apt-get install -f  # لحل التبعيات"
