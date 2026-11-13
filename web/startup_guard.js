(() => {
  'use strict';
  const productionHosts = new Set(['www.pulselink.top', 'pulselink.top', 'blueokanna.github.io']);
  if (productionHosts.has(location.hostname) &&
      (location.protocol !== 'https:' || location.hostname !== 'www.pulselink.top')) {
    location.replace('https://www.pulselink.top' + location.pathname + location.search + location.hash);
    return;
  }
  const legacyCaches = new Set(['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest']);
  const retire = async () => {
    if ('serviceWorker' in navigator) {
      for (const registration of await navigator.serviceWorker.getRegistrations()) {
        const worker = registration.active || registration.waiting || registration.installing;
        if (worker && new URL(worker.scriptURL).origin === location.origin &&
            new URL(worker.scriptURL).pathname.endsWith('/flutter_service_worker.js')) {
          await registration.unregister();
        }
      }
    }
    if ('caches' in window) {
      for (const key of await caches.keys()) if (legacyCaches.has(key)) await caches.delete(key);
    }
  };
  // No automatic reload: a navigation discards in-memory credentials and drafts.
  window.pulseStartup = retire().catch(() => {});
  window.pulseStartupFailure = () => {
    const message = document.getElementById('boot-message');
    if (message) message.textContent = '页面启动未完成。可以重新加载，或清理旧版缓存后重试。';
    for (const id of ['retry', 'recover']) {
      const button = document.getElementById(id); if (button) button.hidden = false;
    }
  };
  window.pulseRecover = async () => {
    await Promise.race([retire().catch(() => {}), new Promise(resolve => setTimeout(resolve, 3000))]);
    const url = new URL(location.href); url.searchParams.set('recovery', Date.now().toString());
    location.replace(url.href);
  };
  window.addEventListener('error', event => {
    if (document.getElementById('boot') && (event.target?.tagName === 'SCRIPT' || event.error)) {
      window.pulseStartupFailure();
    }
  }, true);
})();
