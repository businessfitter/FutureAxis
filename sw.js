/* Future Axis Ledger: offline shell. Pages and code load fresh from the network when online
   (so updates arrive immediately); the cached copy is only used when the phone is offline.
   Data calls to Supabase are never cached. */
const CACHE = "fa-shell-v1";
const SHELL = ["/", "/config.js", "/manifest.webmanifest", "/icons/icon-192.png", "/icons/icon-512.png", "/icons/apple-touch-icon.png"];
self.addEventListener("install", e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting())); });
self.addEventListener("activate", e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener("fetch", e => {
  const r = e.request, u = new URL(r.url);
  if (r.method !== "GET" || /supabase\.co$/.test(u.hostname) || u.pathname.startsWith("/rest/") || u.pathname.startsWith("/auth/")) return;
  const sameOrigin = u.origin === self.location.origin, lib = /cdnjs\.cloudflare\.com|cdn\.jsdelivr\.net|fonts\.(googleapis|gstatic)\.com/.test(u.hostname);
  if (!sameOrigin && !lib) return;
  if (lib){ /* libraries and fonts: cache first */
    e.respondWith(caches.match(r).then(hit => hit || fetch(r).then(res => { const cp = res.clone(); caches.open(CACHE).then(c => c.put(r, cp)); return res; })));
    return; }
  /* own files: network first, cache as fallback */
  e.respondWith(fetch(r).then(res => { if (res.ok){ const cp = res.clone(); caches.open(CACHE).then(c => c.put(r, cp)); } return res; })
    .catch(() => caches.match(r).then(hit => hit || (r.mode === "navigate" ? caches.match("/") : undefined))));
});
