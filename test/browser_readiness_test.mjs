import {test} from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {mkdtemp, readFile, rm, rmdir} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {launchBrowser, observeAppReadiness, navigateToApp, collectBrowserDiagnostics} from '../scripts/browser_app.mjs';

test('browser readiness uses the application lifecycle', {timeout:30000}, async t => {
  let pending = 0;
  const server = http.createServer((req, res) => {
    if (req.url === '/pending') {
      pending++;
      // Keep the response headers pending, like an unreachable asset host.
      res.on('close', () => pending--);
      return;
    }
    res.writeHead(req.url === '/missing' ? 404 : 200, {'Content-Type':'text/html'});
    // A controlled browser fixture, not a substitute for the release app check.
    res.end(`<!doctype html><div id="boot">Loading</div><flutter-view></flutter-view><script>
      if (location.pathname === '/ready') {
        fetch('/pending').then(r => r.text());
        setTimeout(() => {
          window.dispatchEvent(new Event('pulselink-ready'));
          document.getElementById('boot').remove();
        }, 80);
      }
    </script>`);
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  let browser;
  t.after(async () => {
    await browser?.close();
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  });
  browser = await launchBrowser();
  const page = await browser.newPage();
  await observeAppReadiness(page);
  const origin = `http://127.0.0.1:${server.address().port}`;

  await t.test('a ready page passes while an unrelated response remains pending', async () => {
    await navigateToApp(page, `${origin}/ready`, {timeout:3000});
    assert.ok(pending > 0);
    const legacyPage = await browser.newPage();
    try {
      await assert.rejects(legacyPage.goto(`${origin}/ready`, {
        waitUntil:'networkidle0', timeout:700,
      }), {name:'TimeoutError'});
    } finally { await legacyPage.close(); }
  });
  await t.test('reload observes the new document readiness event', async () => {
    await navigateToApp(page, undefined, {reload:true, timeout:3000});
    assert.equal(await page.evaluate(() => document.getElementById('boot')), null);
  });
  await t.test('a failed startup cannot inherit readiness from the previous document', async () => {
    await assert.rejects(navigateToApp(page, `${origin}/broken`, {timeout:400}),
      /Flutter did not finish startup/);
  });
  await t.test('missing documents still fail', async () => {
    await assert.rejects(navigateToApp(page, `${origin}/missing`, {timeout:400}), /Document failed: 404/);
  });
  await t.test('failure artifacts identify pending requests and preserve the page', async () => {
    const directory = await mkdtemp(path.join(os.tmpdir(), 'pulselink-browser-'));
    try {
      const diagnostics = collectBrowserDiagnostics(page, directory);
      await navigateToApp(page, `${origin}/ready`, {timeout:3000});
      await diagnostics.capture(new Error('Regression fixture'), 'fixture stage');
      const report = JSON.parse(await readFile(path.join(directory, 'failure.json'), 'utf8'));
      assert.equal(report.phase, 'fixture stage');
      assert.ok(report.pending.some(request => request.url.endsWith('/pending')));
      assert.match(await readFile(path.join(directory, 'failure.html'), 'utf8'), /flutter-view/);
      assert.ok((await readFile(path.join(directory, 'failure.png'))).length > 0);
    } finally {
      for (const name of ['failure.json', 'failure.html', 'failure.png']) {
        await rm(path.join(directory, name), {force:true});
      }
      await rmdir(directory);
    }
  });
});
