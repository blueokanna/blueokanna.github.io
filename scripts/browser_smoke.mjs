// Optional release-build browser QA. Uses an isolated headless profile.
import http from 'node:http';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {readFile, mkdir, readdir} from 'node:fs/promises';
import assert from 'node:assert/strict';
import {launchBrowser, observeAppReadiness, navigateToApp, collectBrowserDiagnostics} from './browser_app.mjs';
const root = fileURLToPath(new URL('../build/web/', import.meta.url));
const screenshots = fileURLToPath(new URL('../build/qa/browser/', import.meta.url));
await mkdir(screenshots, {recursive: true});
const types = {'.html':'text/html','.js':'text/javascript','.css':'text/css', '.json':'application/json',
  '.png':'image/png','.svg':'image/svg+xml','.ttf':'font/ttf','.wasm':'application/wasm'};
const server = http.createServer(async (req, res) => {
  try {
    const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    const file = path.resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
    if (!file.startsWith(root)) { res.writeHead(403); res.end(); return; }
    const body = await readFile(file);
    res.writeHead(200, {'Content-Type':types[path.extname(file)] || 'application/octet-stream'});
    res.end(body);
  } catch (_) { res.writeHead(404); res.end(); }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const address = `http://127.0.0.1:${server.address().port}`;
let browser, diagnostics;
let phase = 'launch';
try {
  browser = await launchBrowser();
  console.log(`Browser: ${await browser.version()}`);
  const page = await browser.newPage();
  diagnostics = collectBrowserDiagnostics(page, screenshots);
  await observeAppReadiness(page);
  await page.evaluateOnNewDocument(() => {
    if (!localStorage.getItem('flutter.mode')) localStorage.setItem('flutter.mode', JSON.stringify('dark'));
    localStorage.setItem('flutter.paused', 'false');
  });
  await page.setViewport({width:1440,height:1000,deviceScaleFactor:1});
  phase = 'home startup';
  console.log(`Checking ${phase}`);
  await navigateToApp(page, address);
  await page.waitForFunction(()=>Array.from(document.querySelectorAll('iframe')).some(frame=>frame.src.includes('/companion/index.html')));
  const homeCompanions=page.frames().filter(frame=>frame.url().includes('/companion/index.html'));
  assert.equal(homeCompanions.length,1,'Home renders the 3D model without a duplicate dock');
  await homeCompanions[0].waitForSelector('body[data-ready="true"]',{timeout:30000});
  await page.screenshot({path:path.join(screenshots,'home.png')});
  const before = await page.screenshot();
  const backgroundBefore = await page.screenshot({clip:{x:0,y:140,width:80,height:800}});
  await new Promise(resolve => setTimeout(resolve, 1200));
  const after = await page.screenshot();
  assert.notDeepEqual(before,after,'The visible hero must animate after loading.');
  assert.notDeepEqual(backgroundBefore,await page.screenshot({clip:{x:0,y:140,width:80,height:800}}),
    'The page background must animate independently of the character.');
  for (const [name, route, width] of [
    ['projects','/zh-CN/projects',1440], ['article','/zh-CN/posts/segmeris-guide',390],
    ['about','/zh-CN/about',1440], ['friends','/zh-CN/friends',1440],
    ['project-detail','/de/projects/courierust',768],
    ['home-mobile','/zh-CN',390], ['studio-mobile','/zh-CN/studio',390],
  ]) {
    phase = `${name} deep-link refresh`;
    console.log(`Checking ${phase}`);
    await page.setViewport({width,height:1000,deviceScaleFactor:1});
    await navigateToApp(page, `${address}/#${route}`);
    await navigateToApp(page, undefined, {reload:true});
    assert.equal(new URL(page.url()).hash, '#' + route, 'Refreshing a deep link must retain its route.');
    await new Promise(resolve => setTimeout(resolve, 500));
    if(name==='about'||name==='home-mobile'){
      const companions=page.frames().filter(frame=>frame.url().includes('/companion/index.html'));
      assert.equal(companions.length,1,`${name} renders one full character without a duplicate dock`);
      await companions[0].waitForSelector('body[data-ready="true"]',{timeout:30000});
    }
    await page.screenshot({path:path.join(screenshots,`${name}.png`)});
  }
  assert.deepEqual(diagnostics.errors,[],'Browser JavaScript errors');
  console.log('Release browser smoke passed: boot, visible motion, desktop/mobile/tablet deep-link refresh.');
  if (process.env.CHECK_GISCUS === '1') {
    // Serve the unpublished build under its intended HTTPS origin inside this
    // isolated browser. GitHub and giscus remain unmodified live services.
    const previewOrigin = 'https://www.pulselink.top';
    await page.setCacheEnabled(false);
    await page.setRequestInterception(true);
    page.on('request', async request => {
      const url = new URL(request.url());
      if (url.origin === previewOrigin) {
        try {
          const file = path.resolve(root, '.' + (url.pathname === '/' ? '/index.html' : decodeURIComponent(url.pathname)));
          if (!file.startsWith(root)) throw new Error('Invalid asset path');
          await request.respond({status:200,headers:{'Access-Control-Allow-Origin':'*'},
            contentType:types[path.extname(file)] || 'application/octet-stream',body:await readFile(file)});
        } catch (_) { await request.respond({status:404,body:''}); }
      } else { await request.continue(); }
    });
    await page.setViewport({width:1200,height:1000,deviceScaleFactor:1});
    for (const mode of ['dark', 'light']) {
      phase = `${mode} live comments`;
      console.log(`Checking ${phase}`);
      await page.evaluate(value => localStorage.setItem('flutter.mode',JSON.stringify(value)),mode);
      await navigateToApp(page, `${previewOrigin}/#/zh-CN/about`);
      await navigateToApp(page, undefined, {reload:true});
      const semantics = await page.$('pierce/flt-semantics-placeholder');
      await semantics?.evaluate(element => element.click());
      await page.waitForSelector('pierce/flt-semantics', {timeout:10000});
      await page.mouse.move(600,800);
      await page.mouse.wheel({deltaY:900});
      try {
        await page.locator('aria/加载评论').setTimeout(10000).click();
      } catch (error) {
        console.log(await page.$$eval('pierce/flt-semantics', elements => elements.map(e=>({label:e.getAttribute('aria-label'),text:e.textContent,role:e.getAttribute('role')})).filter(e=>e.label||e.text)));
        await page.screenshot({path:path.join(screenshots,'comments-load-diagnostic.png')});
        throw error;
      }
      let host;
      for (let i=0;i<60;i++) {
        host=page.frames().find(frame=>frame.url().includes('/comments.html?'));
        if(host) break;
        await new Promise(resolve=>setTimeout(resolve,200));
      }
      assert.ok(host,'Flutter must mount the comments host.');
      await host.waitForSelector('#status[hidden]',{timeout:30000});
      const iframe=await host.$('iframe.giscus-frame');
      const frame=await iframe.contentFrame();
      const theme=new URL(host.url()).searchParams.get('theme');
      assert.ok((await readdir(path.join(root,'giscus'))).includes(theme+'.css'));
      await frame.waitForFunction(()=>getComputedStyle(document.querySelector('main')).getPropertyValue('--color-canvas-default').trim()==='transparent');
      await new Promise(resolve=>setTimeout(resolve,1000));
      await page.mouse.wheel({deltaY:550});
      await new Promise(resolve=>setTimeout(resolve,400));
      await page.screenshot({path:path.join(screenshots,`comments-${mode}.png`)});
      assert.equal(await frame.evaluate(()=>getComputedStyle(document.body).backgroundColor),'rgba(0, 0, 0, 0)');
      console.log(`Integrated ${mode} comment theme: ${theme}`);
      if (mode === 'light') {
        await page.setViewport({width:390,height:1000,deviceScaleFactor:1});
        await page.mouse.move(190,750);
        await page.mouse.wheel({deltaY:1000});
        await new Promise(resolve=>setTimeout(resolve,600));
        await frame.waitForFunction(()=>getComputedStyle(document.querySelector('main')).getPropertyValue('--color-canvas-default').trim()==='transparent');
        assert.ok(await frame.evaluate(()=>document.documentElement.scrollWidth <= innerWidth + 1),
          'Comments must fit a narrow mobile viewport.');
        await page.screenshot({path:path.join(screenshots,'comments-mobile.png')});
      }
    }
    console.log('Live giscus embed passed: custom light/dark CSS loaded; root background is transparent.');
  }
} catch (error) {
  try { await diagnostics?.capture(error, phase); }
  catch (captureError) { console.error('Could not save diagnostics:', captureError); }
  throw error;
} finally {
  try { await browser?.close(); }
  finally {
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
}
