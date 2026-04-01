# 📻 مشغّل الإذاعات القرآنية | GT-QURANRADIO v2.0

تطبيق لاستماع الإذاعات القرآنية — متاح كـ **موقع PWA** + **تطبيق Android APK** + **Linux AppImage**.

---

## 📁 هيكل المشروع

```
GT-QURANRADIO/
├── www/                        # ملفات الويب (مشتركة بين الكل)
│   ├── index.html              # الواجهة الرئيسية (Mobile-First)
│   ├── sw.js                   # Service Worker
│   └── icons/                  # أيقونات (تُنسخ تلقائياً أثناء البناء)
│
├── electron/                   # تطبيق Linux (Electron)
│   ├── main.js                 # العملية الرئيسية
│   └── preload.js              # Bridge للواجهة
│
├── scripts/
│   ├── build-android.sh        # بناء APK
│   ├── build-linux.sh          # بناء AppImage/DEB
│   └── build-all.sh            # بناء الكل
│
├── GT-QR-icons/                # الأيقونات الأصلية (انسخ مجلدك هنا)
├── capacitor.config.json       # إعدادات Capacitor (Android)
├── electron-package.json       # إعدادات electron-builder
└── package.json
```

---

## 🌐 تشغيل الموقع (PWA)

```bash
# بدون تثبيت — فقط افتح index.html في المتصفح
# أو استخدم serve للعرض المحلي:
npx serve www
# ثم افتح http://localhost:3000
```

لتثبيت كـ PWA: افتح في Chrome/Edge → زر "تثبيت التطبيق" في شريط العناوين.

---

## 🤖 بناء Android APK

### المتطلبات

| الأداة | الإصدار | التثبيت |
|--------|---------|---------|
| Node.js | ≥ 18 | https://nodejs.org |
| JDK | 17 | `sudo apt install openjdk-17-jdk` |
| Android SDK | API 34 | Android Studio أو command-line tools |
| ANDROID_HOME | متغير بيئة | انظر أدناه |

### إعداد Android SDK

```bash
# Ubuntu/Debian
sudo apt install openjdk-17-jdk
# تحميل Android command-line tools
# من: https://developer.android.com/studio#command-line-tools-only

# بعد الاستخراج:
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# قبول الرخص وتثبيت المنصة
sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

### تشغيل البناء

```bash
# انسخ مجلد GT-QR-icons إلى جذر المشروع، ثم:
chmod +x scripts/*.sh
bash scripts/build-android.sh
# النتيجة: output/QuranRadio-v2.0-debug.apk
```

### تثبيت على الجهاز

```bash
# تفعيل USB Debugging على الهاتف ثم:
adb install output/QuranRadio-v2.0-debug.apk
```

### بناء APK موقّع (للنشر)

```bash
# 1. إنشاء Keystore
keytool -genkey -v \
  -keystore quranradio.jks \
  -alias quranradio \
  -keyalg RSA -keysize 2048 -validity 10000

# 2. إضافة إعدادات التوقيع في android/app/build.gradle:
#    signingConfigs {
#        release {
#            storeFile     file('../../quranradio.jks')
#            storePassword 'كلمة_المرور'
#            keyAlias      'quranradio'
#            keyPassword   'كلمة_المرور'
#        }
#    }
#    buildTypes { release { signingConfig signingConfigs.release } }

# 3. البناء
cd android && ./gradlew assembleRelease
```

---

## 🐧 بناء Linux AppImage / DEB

### المتطلبات

```bash
# Node.js ≥ 18
node --version  # يجب أن يكون v18+

# تبعيات النظام
sudo apt install libgtk-3-dev libwebkit2gtk-4.0-dev libappindicator3-dev \
                 libdbusmenu-glib-dev librsvg2-dev fakeroot dpkg
```

### تشغيل البناء

```bash
chmod +x scripts/*.sh
bash scripts/build-linux.sh

# النتيجة في output/:
#   QuranRadio-2.0.0-linux.AppImage
#   QuranRadio-2.0.0-amd64.deb
```

### تشغيل AppImage

```bash
chmod +x output/QuranRadio-*.AppImage
./output/QuranRadio-*.AppImage
```

### تثبيت DEB

```bash
sudo dpkg -i output/QuranRadio-*.deb
sudo apt-get install -f  # حل التبعيات إن وُجدت
# ثم ابحث عنه في القائمة أو: quran-radio
```

---

## 🏗️ بناء الكل دفعة واحدة

```bash
bash scripts/build-all.sh --all
# أو تفاعلياً:
bash scripts/build-all.sh
```

---

## ⚙️ التخصيص

### تغيير قائمة الإذاعات الافتراضية
افتح `www/index.html` وعدّل مصفوفة `DEFAULTS` في أول `<script>`.

### تغيير الأيقونة
ضع أيقوناتك في `GT-QR-icons/all/{size}x{size}/GT-QURANRADIO-LOGO.png`
أو ضع أيقوناتك مباشرة في `www/icons/icon-{size}.png`.

### تغيير معرف التطبيق
- في `capacitor.config.json`: غيّر `appId`
- في `electron-package.json`: غيّر `appId`

---

## 🎵 مميزات التطبيق

- **Mobile-First** — تصميم أولوية الهاتف مع تنقل بالسحب (Swipe)
- **PWA** — قابل للتثبيت من المتصفح
- **35+ إذاعة** جاهزة مسبقاً
- **Visualizer** — موجات صوتية حية
- **Media Session API** — التحكم من شاشة القفل
- **البحث** والتصفية
- **استيراد/تصدير** JSON
- **Offline support** عبر Service Worker
- **Tray icon** في Linux
- دعم **Safe Area** لجميع الهواتف

---

## 📋 متطلبات النظام النهائية

| المنصة | الحد الأدنى |
|--------|------------|
| Android | API 22 (Android 5.1) |
| Linux   | Ubuntu 18.04 / أي توزيعة حديثة x64 |
| Web     | Chrome 80+ / Firefox 75+ / Safari 14+ |

---

تطوير **GNUTUX** — 🕌 خيركم من تعلّم القرآن وعلّمه
