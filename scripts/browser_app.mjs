import assert from 'node:assert/strict';
import {existsSync} from 'node:fs';
import {mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';
import puppeteer from 'puppeteer';

export function launchBrowser() {
  const executablePath = process.env.PUPPETEER_EXECUTABLE_PATH || [
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    '/usr/bin/google-chrome', '/usr/bin/chromium',
  ].find(existsSync);
  return puppeteer.launch({
    headless: true, executablePath, protocolTimeout: 30000,
    args: process.env.CI ? ['--no-sandbox'] : [],
  });
}

export async function observeAppReadiness(page) {
  // Installed before navigation so even a warm-cache startup cannot race the
  // observer. This flag belongs to the document and resets on every reload.
  await page.evaluateOnNewDocument(() => {
    window.__pulselinkSmokeReady = false;
    window.addEventListener('pulselink-ready', () => {
      window.__pulselinkSmokeReady = true;
    }, {once: true});
  });
}

export async function navigateToApp(page, url, {
  reload = false, timeout = 90000, navigationTimeout = 30000,
} = {}) {
  // Network idleness is not application readiness: optional font/image/service
  // requests can remain pending after Flutter has painted usable content.
  const options = {waitUntil: 'domcontentloaded', timeout: navigationTimeout};
  const response = reload ? await page.reload(options) : await page.goto(url, options);
  assert.ok(!response || response.ok(), `Document failed: ${response?.status()} ${page.url()}`);
  try {
    const ready = await page.waitForFunction(() =>
      window.__pulselinkSmokeReady === true &&
      document.querySelector('flutter-view') !== null &&
      document.getElementById('boot') === null,
    {timeout, polling: 100});
    await ready.dispose();
  } catch (cause) {
    throw new Error(`Flutter did not finish startup within ${timeout} ms: ${page.url()}`, {cause});
  }
}

export function collectBrowserDiagnostics(page, directory) {
  const pending = new Map();
  const failures = [], responses = [], consoleMessages = [], errors = [];
  const append = (list, value) => { if (list.length < 200) list.push(value); };
  page.on('request', request => pending.set(request, {
    url: request.url(), method: request.method(), type: request.resourceType(), started: Date.now(),
  }));
  page.on('requestfinished', request => pending.delete(request));
  page.on('requestfailed', request => {
    append(failures, {...pending.get(request), url: request.url(), error: request.failure()?.errorText});
    pending.delete(request);
  });
  page.on('response', response => {
    if (response.status() >= 400) append(responses, {url: response.url(), status: response.status()});
  });
  page.on('console', message => {
    if (['error', 'warn'].includes(message.type())) {
      append(consoleMessages, {type: message.type(), text: message.text().slice(0, 4000)});
    }
  });
  page.on('pageerror', error => append(errors, error.message));
  return {
    errors,
    async capture(error, phase) {
      await mkdir(directory, {recursive: true});
      // Save request evidence first, even if the renderer cannot take a screenshot.
      await writeFile(path.join(directory, 'failure.json'), JSON.stringify({
        phase, url: page.url(), error: String(error.stack || error),
        cause: error.cause ? String(error.cause.stack || error.cause) : undefined,
        pending: [...pending.values()].map(({started, ...request}) =>
          ({...request, elapsedMs: Date.now() - started})),
        failures, responses, consoleMessages, errors,
      }, null, 2));
      const results = await Promise.allSettled([
        page.screenshot({path: path.join(directory, 'failure.png')}),
        page.content().then(html => writeFile(path.join(directory, 'failure.html'), html)),
      ]);
      for (const result of results) {
        if (result.status === 'rejected') console.error('Diagnostic capture:', result.reason.message);
      }
      console.error(`Browser diagnostics saved to ${directory}`);
    },
  };
}
