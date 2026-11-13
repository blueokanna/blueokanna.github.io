'use strict';
// Retire the historical Flutter cache without navigating an editor session.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil((async () => {
  for (const key of await caches.keys()) {
    if (['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest'].includes(key)) {
      await caches.delete(key);
    }
  }
  await self.registration.unregister();
})()));
