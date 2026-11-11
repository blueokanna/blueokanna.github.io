import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const html = readFileSync(new URL('../web/comments.html', import.meta.url), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const config = JSON.parse(readFileSync(new URL('../web/comments.json', import.meta.url), 'utf8'));

async function load(query, settings = config) {
  const attributes = {};
  const link = {};
  const status = { hidden: false, prepend() {}, querySelector: () => link };
  const frame = { contentWindow: {}, style: {} };
  let message;
  let inserted = false;
  const document = {
    documentElement: { style: {} },
    body: { scrollHeight: 360, appendChild() { inserted = true; } },
    getElementById: () => status,
    querySelector: () => frame,
    createElement: () => ({ setAttribute(key, value) { attributes[key] = value; } }),
  };
  vm.runInNewContext(script, {
    document, location: { search: query, origin: 'https://www.pulselink.top' },
    URLSearchParams, ResizeObserver: class { observe() {} },
    parent: { postMessage() {} },
    window: { addEventListener(type, listener) { if (type === 'message') message = listener; } },
    fetch: async () => ({ ok: true, json: async () => settings }),
  });
  await new Promise(setImmediate);
  return { attributes, status, frame, message, inserted };
}

test('article translations share an exact, stable discussion term', async () => {
  for (const lang of ['ja', 'de', 'zh-CN']) {
    const { attributes } = await load(`?post=segmeris-guide&lang=${lang}&theme=dark`);
    assert.equal(attributes['data-term'], 'pulselink/post/segmeris-guide');
    assert.equal(attributes['data-mapping'], 'specific');
    assert.equal(attributes['data-strict'], '1');
    assert.equal(attributes['data-category-id'], config.categoryId);
    assert.equal(attributes['data-lang'], lang);
    assert.equal(attributes['data-theme'], 'dark');
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
