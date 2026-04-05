/* ═══════════════════════════════════════════════════════════════
   GT-QURANRADIO v2.1 – Service Worker (صفحة الإصدارات)
   Copyright (C) 2026 SalehGNUTUX | GPL-3.0
   https://github.com/SalehGNUTUX/GT_QURANRADIO
═══════════════════════════════════════════════════════════════ */

const CACHE_NAME = 'qr-release-v1';
const RUNTIME_CACHE = 'qr-release-runtime-v1';

// الملفات الأساسية للتخزين المسبق (صفحة الإصدارات فقط)
const PRECACHE_URLS = [
  './',
  './index.html',
  'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css'
];

// تثبيت الـ Service Worker وتخزين الملفات الأساسية
self.addEventListener('install', event => {
  console.log('[SW] تثبيت Service Worker لإصدار 2.1');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('[SW] تخزين الملفات الأساسية');
        return cache.addAll(PRECACHE_URLS);
      })
      .then(() => self.skipWaiting())
  );
});

// تنشيط الـ Service Worker وحذف الكاش القديم
self.addEventListener('activate', event => {
  console.log('[SW] تنشيط Service Worker');
  const cacheWhitelist = [CACHE_NAME, RUNTIME_CACHE];
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (!cacheWhitelist.includes(cacheName)) {
            console.log('[SW] حذف الكاش القديم:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// استراتيجية التحميل: Network First للملفات الأساسية، Cache First للأصول الثابتة
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  
  // تجاهل طلبات التحليلات والإعلانات
  if (url.hostname.includes('analytics') || url.hostname.includes('google')) {
    return;
  }
  
  // طلبات HTML (صفحة الإصدارات) - Network First
  if (url.pathname === '/' || url.pathname.endsWith('.html')) {
    event.respondWith(
      fetch(event.request)
        .then(response => {
          const responseClone = response.clone();
          caches.open(CACHE_NAME).then(cache => {
            cache.put(event.request, responseClone);
          });
          return response;
        })
        .catch(() => {
          return caches.match(event.request);
        })
    );
    return;
  }
  
  // الملفات الثابتة (CSS, JS, Fonts, Icons) - Cache First
  if (url.pathname.match(/\.(css|js|woff2?|ttf|eot|png|ico|svg|jpg|jpeg|webp)$/)) {
    event.respondWith(
      caches.match(event.request)
        .then(cachedResponse => {
          if (cachedResponse) {
            return cachedResponse;
          }
          return fetch(event.request).then(response => {
            if (!response || response.status !== 200) {
              return response;
            }
            const responseClone = response.clone();
            caches.open(RUNTIME_CACHE).then(cache => {
              cache.put(event.request, responseClone);
            });
            return response;
          });
        })
    );
    return;
  }
  
  // الطلبات الأخرى (مثل الصور الخارجية) - تمرير مباشر
  return;
});

// إشعارات الدفع (للإصدارات المستقبلية)
self.addEventListener('push', event => {
  if (!event.data) return;
  
  const data = event.data.json().catch(() => ({ title: 'GT_QURANRADIO', body: event.data.text() }));
  
  event.waitUntil(
    data.then(d => {
      self.registration.showNotification(d.title || 'GT_QURANRADIO', {
        body: d.body || 'الإصدار 2.1 متاح الآن!',
        icon: 'GT-QR-icons/all/192x192/GT-QURANRADIO-LOGO.png',
        badge: 'GT-QR-icons/all/96x96/GT-QURANRADIO-LOGO.png',
        dir: 'rtl',
        lang: 'ar',
        data: { url: d.url || '/' }
      });
    })
  );
});

// فتح الرابط عند النقر على الإشعار
self.addEventListener('notificationclick', event => {
  event.notification.close();
  const urlToOpen = event.notification.data?.url || '/';
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then(windowClients => {
        for (let client of windowClients) {
          if (client.url === urlToOpen && 'focus' in client) {
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});
