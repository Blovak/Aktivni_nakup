/* global self, caches */

const CACHE_VERSION = "2026-10-30-1";
const SHELL_CACHE = `aktivni-nakup-shell-${CACHE_VERSION}`;
const STATIC_CACHE = `aktivni-nakup-static-${CACHE_VERSION}`;
const ACTIVE_CACHES = new Set([SHELL_CACHE, STATIC_CACHE]);
const APP_SHELL = [
  "/",
  "/offline",
  "/manifest.webmanifest",
  "/icons/icon-192.svg",
  "/icons/icon-512.svg",
];
const SHELL_PAGES = ["/", "/offline"];

async function cacheAppShell() {
  const shellCache = await caches.open(SHELL_CACHE);
  const staticCache = await caches.open(STATIC_CACHE);
  const versionedAssets = new Set();

  await Promise.all(
    SHELL_PAGES.map(async (pageUrl) => {
      const response = await fetch(pageUrl, { cache: "reload" });

      if (!response.ok) {
        throw new Error(`Shell request failed: ${pageUrl}`);
      }

      await shellCache.put(pageUrl, response.clone());
      const html = await response.text();

      for (const match of html.matchAll(
        /(?:src|href)="(\/_next\/static\/[^"?]+(?:\?[^" ]*)?)"/gu,
      )) {
        versionedAssets.add(match[1]);
      }
    }),
  );

  await shellCache.addAll(
    APP_SHELL.filter((assetUrl) => !SHELL_PAGES.includes(assetUrl)),
  );
  await staticCache.addAll([...versionedAssets]);
}

self.addEventListener("install", (event) => {
  event.waitUntil(cacheAppShell());
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((cacheNames) =>
        Promise.all(
          cacheNames
            .filter((cacheName) => !ACTIVE_CACHES.has(cacheName))
            .map((cacheName) => caches.delete(cacheName)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener("message", (event) => {
  if (event.data?.type === "SKIP_WAITING") {
    void self.skipWaiting();
  }
});

self.addEventListener("fetch", (event) => {
  const { request } = event;

  if (request.method !== "GET") {
    return;
  }

  const requestUrl = new URL(request.url);

  if (requestUrl.origin !== self.location.origin) {
    return;
  }

  if (
    requestUrl.pathname === "/api" ||
    requestUrl.pathname.startsWith("/api/")
  ) {
    return;
  }

  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request).catch(async () => {
        const cachedPage = await caches.match(request, {
          ignoreSearch: true,
        });
        const offlineResponse = await caches.match("/offline");

        return cachedPage ?? offlineResponse ?? Response.error();
      }),
    );
    return;
  }

  if (requestUrl.pathname.startsWith("/_next/static/")) {
    event.respondWith(
      caches.match(request).then(async (cachedResponse) => {
        if (cachedResponse) {
          return cachedResponse;
        }

        const networkResponse = await fetch(request);

        if (networkResponse.ok) {
          const cache = await caches.open(STATIC_CACHE);
          await cache.put(request, networkResponse.clone());
        }

        return networkResponse;
      }),
    );
    return;
  }

  if (APP_SHELL.includes(requestUrl.pathname)) {
    event.respondWith(
      caches
        .match(request)
        .then((cachedResponse) => cachedResponse ?? fetch(request)),
    );
  }
});
