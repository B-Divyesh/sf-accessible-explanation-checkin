const CACHE = 'check-in-shell-v2';
const SHELL = ['/', '/manifest.webmanifest', '/doorway.svg', '/assets/hero-classroom-768.avif', '/assets/hero-classroom-1536.avif', '/assets/hero-classroom-768.webp', '/assets/hero-classroom-1536.webp', '/assets/hero-classroom-768.jpg'];
self.addEventListener('install', event => event.waitUntil((async () => {
  const cache = await caches.open(CACHE);
  const root = await fetch('/');
  const html = await root.clone().text();
  const builtAssets = [...html.matchAll(/(?:src|href)="(\/assets\/[^\"]+)"/g)].map(match => match[1]);
  await cache.put('/', root);
  await cache.addAll([...SHELL.slice(1), ...builtAssets]);
  await self.skipWaiting();
})()));
self.addEventListener('activate', event => event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key !== CACHE).map(key => caches.delete(key)))).then(() => self.clients.claim())));
self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET' || new URL(request.url).pathname.startsWith('/api/')) return;
  event.respondWith(fetch(request).then(response => {
    if (response.ok && new URL(request.url).origin === location.origin) caches.open(CACHE).then(cache => cache.put(request, response.clone()));
    return response;
  }).catch(async () => (await caches.match(request)) || (request.mode === 'navigate' ? caches.match('/') : Response.error())));
});
