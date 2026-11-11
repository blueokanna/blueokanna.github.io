const params = new URLSearchParams(location.search);
const languages = ['zh-CN', 'zh-TW', 'en', 'ja', 'de', 'fr', 'es', 'ru', 'pt', 'it'];
const status = document.getElementById('status');
const label = document.getElementById('status-label');
const post = params.get('post');
let settings = {};
let synchronized = false;

function updateSettings(next) {
  const lang = languages.includes(next.lang) ? next.lang : 'en';
  const theme = /^(light|dark)-[0-9a-f]{6}$/.test(next.theme || '') ? next.theme : 'light-3c6839';
  const dark = theme.startsWith('dark-');
  document.documentElement.lang = lang;
  document.documentElement.style.colorScheme = dark ? 'dark' : 'light';
  if (/^#[0-9a-f]{6}$/i.test(next.foreground || '')) document.body.style.color = next.foreground;
  label.textContent = next.unavailable || 'GitHub Discussions';
  status.querySelector('a').textContent = next.linkLabel || 'GitHub ↗';
  // Custom themes need HTTPS; HTTP previews use the built-in themes.
  const custom = new URL(`giscus/${theme}.css`, location.href);
  settings = {lang, theme: custom.protocol === 'https:' ? custom.href : dark ? 'transparent_dark' : 'light'};
  document.querySelector('iframe.giscus-frame')?.contentWindow?.postMessage({giscus: {setConfig: settings}}, 'https://giscus.app');
}
updateSettings(Object.fromEntries(params));
const report = () => parent.postMessage(JSON.stringify({type: 'pulselink-comments', height: document.body.scrollHeight}), location.origin);
new ResizeObserver(report).observe(document.body);
window.addEventListener('message', event => {
  if (event.origin === location.origin && event.source === parent && typeof event.data === 'string') {
    try {
      const data = JSON.parse(event.data);
      if (data.type === 'pulselink-comments-config') updateSettings(data);
    } catch (_) { /* Unrelated messages are not configuration. */ }
    return;
  }
  const frame = document.querySelector('iframe.giscus-frame');
  if (event.origin !== 'https://giscus.app' || event.source !== frame?.contentWindow) return;
  const height = event.data?.giscus?.resizeHeight;
  if (typeof height === 'number' && Number.isFinite(height) && height > 0) {
    if (!synchronized) {
      synchronized = true;
      // The first resize confirms giscus has hydrated and can receive config.
      frame.contentWindow.postMessage({giscus: {setConfig: settings}}, 'https://giscus.app');
    }
    frame.style.height = Math.min(height, 4800) + 'px';
    status.hidden = true;
    report();
  }
});
(async () => {
  try {
    const response = await fetch('comments.json', {cache: 'no-cache'});
    if (!response.ok) return;
    const c = await response.json();
    if (!c.repoId || !c.categoryId || !c.category || !/^[-\w]+\/[-\w.]+$/.test(c.repo || '') || !/^[-\w]+$/.test(post || '')) return;
    if (post === 'guestbook' && (!Number.isSafeInteger(c.guestbookNumber) || c.guestbookNumber < 1)) return;
    const script = document.createElement('script');
    script.src = 'https://giscus.app/client.js'; script.async = true; script.crossOrigin = 'anonymous';
    const config = {
      repo: c.repo, 'repo-id': c.repoId, category: c.category, 'category-id': c.categoryId,
      mapping: post === 'guestbook' ? 'number' : 'specific',
      term: post === 'guestbook' ? String(c.guestbookNumber) : 'pulselink/post/' + post,
      strict: '1', 'reactions-enabled': '0', 'emit-metadata': '1', 'input-position': 'top',
      theme: settings.theme, lang: settings.lang,
    };
    for (const [key, value] of Object.entries(config)) script.setAttribute('data-' + key, value);
    document.body.appendChild(script);
    parent.postMessage(JSON.stringify({type: 'pulselink-comments-ready'}), location.origin);
  } catch (_) { report(); }
})();
