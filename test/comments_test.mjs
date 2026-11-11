import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const html = readFileSync(new URL('../web/comments.html', import.meta.url), 'utf8');
const script = readFileSync(new URL('../web/comments.js', import.meta.url), 'utf8');
const config = JSON.parse(readFileSync(new URL('../web/comments.json', import.meta.url), 'utf8'));

async function load(query, settings = config) {
  const attributes = {};
  const link = {};
  const status = { hidden: false, prepend() {}, querySelector: () => link };
  const sent = [];
  const frame = { contentWindow: { postMessage(...args) { sent.push(args); } }, style: {} };
  const parent = { postMessage() {} };
  let message;
  let inserted = false;
  const document = {
    documentElement: { style: {} },
    body: { style: {}, scrollHeight: 360, appendChild() { inserted = true; } },
    getElementById: () => status,
    querySelector: () => frame,
    createElement: () => ({ setAttribute(key, value) { attributes[key] = value; } }),
  };
  vm.runInNewContext(script, {
    document, location: { search: query, origin: 'https://www.pulselink.top', href: 'https://www.pulselink.top/comments.html' },
    URL, URLSearchParams, ResizeObserver: class { observe() {} },
    parent,
    window: { addEventListener(type, listener) { if (type === 'message') message = listener; } },
    fetch: async () => ({ ok: true, json: async () => settings }),
  });
  await new Promise(setImmediate);
  return { attributes, status, frame, message, inserted, sent, parent };
}

test('article translations share an exact, stable discussion term', async () => {
  for (const lang of ['ja', 'de', 'zh-CN']) {
    const { attributes } = await load(`?post=segmeris-guide&lang=${lang}&theme=dark-a8d29c`);
    assert.equal(attributes['data-term'], 'pulselink/post/segmeris-guide');
    assert.equal(attributes['data-mapping'], 'specific');
    assert.equal(attributes['data-strict'], '1');
    assert.equal(attributes['data-category-id'], config.categoryId);
    assert.equal(attributes['data-lang'], lang);
    assert.equal(attributes['data-theme'], 'https://www.pulselink.top/giscus/dark-a8d29c.css');
  }
});
test('guestbook uses the existing discussion number', async () => {
  const { attributes } = await load('?post=guestbook&lang=en');
  assert.equal(attributes['data-mapping'], 'number');
  assert.equal(attributes['data-term'], '1');
});
test('malformed post names or incomplete configuration do not load giscus', async () => {
  assert.equal((await load('?post=%3Cscript%3E')).inserted, false);
  assert.equal((await load('?post=segmeris-guide', { ...config, categoryId: '' })).inserted, false);
});
test('only the correct giscus origin and window can resize the embed', async () => {
  const page = await load('?post=guestbook');
  const event = { origin: 'https://giscus.app', source: page.frame.contentWindow, data: { giscus: { resizeHeight: 800 } } };
  page.message({ ...event, origin: 'https://untrusted.example' });
  page.message({ ...event, source: {} });
  assert.equal(page.status.hidden, false);
  page.message(event);
  assert.equal(page.frame.style.height, '800px');
  assert.equal(page.status.hidden, true);
});


test('theme updates preserve the embed and reject spoofed configuration', async () => {
  const page = await load('?post=guestbook');
  const before = page.sent.length;
  const event = {origin: 'https://www.pulselink.top', source: page.parent,
    data: JSON.stringify({type: 'pulselink-comments-config', theme: 'dark-a8d29c', lang: 'ja'})};
  page.message({...event, source: {}});
  page.message({...event, origin: 'https://untrusted.example'});
  assert.equal(page.sent.length, before);
  page.message(event);
  assert.equal(page.sent.at(-1)[0].giscus.setConfig.lang, 'ja');
  assert.equal(page.sent.at(-1)[0].giscus.setConfig.theme, 'https://www.pulselink.top/giscus/dark-a8d29c.css');
  assert.equal(page.sent.at(-1)[1], 'https://giscus.app');
});

test('host background stays transparent and theme URLs cannot be injected', async () => {
  assert.match(html, /background:transparent!important/);
  const {attributes} = await load('?post=guestbook&theme=https://untrusted.example/a.css');
  assert.match(attributes['data-theme'], /^https:\/\/www\.pulselink\.top\/giscus\/light-[0-9a-f]{6}\.css$/);
});

test('the first ready resize resends the latest theme exactly once', async () => {
  const page = await load('?post=guestbook');
  page.message({origin:'https://www.pulselink.top', source:page.parent,
    data:JSON.stringify({type:'pulselink-comments-config',theme:'dark-a8d29c',lang:'de'})});
  const count = page.sent.length;
  const ready = {origin:'https://giscus.app',source:page.frame.contentWindow,
    data:{giscus:{resizeHeight:500}}};
  page.message(ready);
  assert.equal(page.sent.length,count+1);
  assert.equal(page.sent.at(-1)[0].giscus.setConfig.lang,'de');
  assert.match(page.sent.at(-1)[0].giscus.setConfig.theme,/dark-a8d29c\.css$/);
  page.message(ready);
  assert.equal(page.sent.length,count+1);
});
