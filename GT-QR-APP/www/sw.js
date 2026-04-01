/* GT-QURANRADIO Service Worker v2.1 */
const CACHE  = 'qr-v2';
const RUNTIME= 'qr-rt-v2';

const PRECACHE = ['./', './index.html',
  'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css',
  'https://fonts.googleapis.com/css2?family=Tajawal:wght@300;400;500;700;800;900&display=swap'];

self.addEventListener('install', e => e.waitUntil(
  caches.open(CACHE).then(c=>c.addAll(PRECACHE)).then(()=>self.skipWaiting())
));

self.addEventListener('activate', e => e.waitUntil(
  caches.keys().then(keys=>Promise.all(
    keys.filter(k=>[CACHE,RUNTIME].indexOf(k)===-1).map(k=>caches.delete(k))
  )).then(()=>self.clients.claim())
));

self.addEventListener('fetch', e=>{
  if (e.request.method!=='GET') return;
  const url = new URL(e.request.url);
  // Never cache audio streams
  if ([':8005',':8196',':8440'].some(p=>url.host.includes(p)) ||
      ['.mp3','.m3u8','.aac','.ogg'].some(x=>url.pathname.endsWith(x))) return;
  // HTML: network first
  if (url.pathname.endsWith('.html')||url.pathname==='/') {
    e.respondWith(fetch(e.request).then(r=>{
      const c=r.clone(); caches.open(CACHE).then(cache=>cache.put(e.request,c)); return r;
    }).catch(()=>caches.match(e.request)));
    return;
  }
  // Static assets: cache first
  e.respondWith(caches.match(e.request).then(hit=>{
    if (hit) return hit;
    return fetch(e.request).then(r=>{
      if (!r||r.status!==200) return r;
      const c=r.clone(); caches.open(RUNTIME).then(cache=>cache.put(e.request,c)); return r;
    });
  }));
});
