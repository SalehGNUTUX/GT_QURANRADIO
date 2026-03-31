/* ════════════════════════════════════════════
   GT-QURANRADIO  Service Worker  v2.0
   Quran Radio PWA – GNUTUX
════════════════════════════════════════════ */

const CACHE_NAME    = 'qr-v2';
const RUNTIME_CACHE = 'qr-runtime-v2';

// Core assets to pre-cache on install
const PRECACHE_URLS = [
  './',
  './index.html',
  'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css',
  'https://fonts.googleapis.com/css2?family=Tajawal:wght@300;400;500;700;800;900&display=swap'
];

// ── Install: pre-cache shell ──
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

// ── Activate: clean up old caches ──
self.addEventListener('activate', event => {
  const keep = [CACHE_NAME, RUNTIME_CACHE];
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(k => !keep.includes(k)).map(k => caches.delete(k))
      ))
      .then(() => self.clients.claim())
  );
});

// ── Fetch: Network-first for audio streams, Cache-first for assets ──
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // Skip non-GET and cross-origin audio streams (let them pass through)
  if (event.request.method !== 'GET') return;

  // Audio streams: always network (never cache)
  const audioExts = ['.mp3', '.aac', '.ogg', '.m3u8', '.ts', '.opus'];
  if (audioExts.some(ext => url.pathname.endsWith(ext)) || url.port === '8005' || url.port === '8196' || url.port === '8440') {
    return; // pass through to network
  }

  // For same-origin HTML – network first, fallback to cache
  if (url.origin === self.location.origin && url.pathname.endsWith('.html')) {
    event.respondWith(
      fetch(event.request)
        .then(res => {
          const clone = res.clone();
          caches.open(CACHE_NAME).then(c => c.put(event.request, clone));
          return res;
        })
        .catch(() => caches.match(event.request))
    );
    return;
  }

  // For fonts & CDN assets – cache first, then network
  if (url.origin !== self.location.origin || url.pathname.match(/\.(woff2?|ttf|eot|css|png|ico|svg|webp|jpg|jpeg)$/)) {
    event.respondWith(
      caches.match(event.request).then(cached => {
        if (cached) return cached;
        return fetch(event.request).then(res => {
          if (!res || res.status !== 200 || res.type === 'error') return res;
          const clone = res.clone();
          caches.open(RUNTIME_CACHE).then(c => c.put(event.request, clone));
          return res;
        });
      })
    );
    return;
  }

  // Default: network with cache fallback
  event.respondWith(
    fetch(event.request)
      .then(res => {
        const clone = res.clone();
        caches.open(RUNTIME_CACHE).then(c => c.put(event.request, clone));
        return res;
      })
      .catch(() => caches.match(event.request))
  );
});

// ── Background Sync placeholder ──
self.addEventListener('sync', event => {
  if (event.tag === 'sync-stations') {
    // Reserved for future use
  }
});

// ── Push notifications placeholder ──
self.addEventListener('push', event => {
  if (!event.data) return;
  const data = event.data.json().catch(() => ({ title: 'Quran Radio', body: event.data.text() }));
  event.waitUntil(
    data.then(d => self.registration.showNotification(d.title || 'Quran Radio', {
      body: d.body || '',
      icon: './GT-QR-icons/all/192x192/GT-QURANRADIO-LOGO.png',
      badge: './GT-QR-icons/all/96x96/GT-QURANRADIO-LOGO.png',
      dir: 'rtl',
      lang: 'ar'
    }))
  );
});
