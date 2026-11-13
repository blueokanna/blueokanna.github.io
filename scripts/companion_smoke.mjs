// Render the release VRM in an isolated browser; never uses a logged-in profile.
import http from 'node:http';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {readFile,mkdir} from 'node:fs/promises';
import assert from 'node:assert/strict';
import {launchBrowser,observeAppReadiness,navigateToApp} from './browser_app.mjs';
const root=fileURLToPath(new URL('../build/web/',import.meta.url));
const output=fileURLToPath(new URL('../build/qa/companion/',import.meta.url));
await mkdir(output,{recursive:true});
const types={'.html':'text/html','.js':'text/javascript','.json':'application/json','.glb':'model/gltf-binary','.wasm':'application/wasm','.ttf':'font/ttf','.png':'image/png','.svg':'image/svg+xml'};
const server=http.createServer(async(req,res)=>{
  try {
    const url=new URL(req.url,'http://localhost'),filename=path.resolve(root,'.'+decodeURIComponent(url.pathname==='/'?'/index.html':url.pathname));
    if(!filename.startsWith(root))throw new Error('Invalid path');
    const body=await readFile(filename);res.writeHead(200,{'Content-Type':types[path.extname(filename)]||'application/octet-stream'});res.end(body);
  }catch{res.writeHead(404);res.end();}
});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const address=`http://127.0.0.1:${server.address().port}`;
let browser;
try{
  browser=await launchBrowser();const page=await browser.newPage(),errors=[];
  page.on('pageerror',error=>errors.push(error.message));
  await page.setViewport({width:640,height:640,deviceScaleFactor:1});
  await page.goto(address+'/companion/index.html#idle');
  await page.waitForSelector('body[data-ready="true"]',{timeout:30000});
  assert.equal(await page.$eval('body',node=>node.dataset.modelAuthor),'木子恶魔');
  assert.equal(await page.$eval('#status',node=>getComputedStyle(node).display),'none');
  assert.ok(await page.$eval('#scene',canvas=>canvas.getContext('webgl2')),'Real WebGL2 canvas');
  const before=await page.screenshot();await new Promise(resolve=>setTimeout(resolve,450));
  assert.notDeepEqual(await page.screenshot(),before,'Joint animation changes the rendered frame');
  await page.evaluate(()=>{dispatchEvent(new PageTransitionEvent('pagehide',{persisted:true}));dispatchEvent(new PageTransitionEvent('pageshow',{persisted:true}));});
  const restored=await page.screenshot();await new Promise(resolve=>setTimeout(resolve,250));
  assert.notDeepEqual(await page.screenshot(),restored,'Back-forward cache resume keeps the renderer alive');
  const metadata=JSON.parse(await readFile(path.join(root,'companion/model-info.json'),'utf8'));
  for(const {name} of metadata.clips){
    await page.evaluate(mood=>postMessage(JSON.stringify({type:'companion-state',mood,reduced:true,compact:false}),location.origin),name);
    await page.waitForSelector(`body[data-mood="${name}"]`);
    await new Promise(resolve=>setTimeout(resolve,80));
    await page.screenshot({path:path.join(output,name+'.png')});
  }
  // Let the actual spring bones settle while entering and leaving sleep.
  for(const mood of ['sleep','wake','dance']){
    await page.evaluate(mood=>postMessage(JSON.stringify({type:'companion-state',mood,reduced:false,compact:false}),location.origin),mood);
    await page.waitForSelector(`body[data-mood="${mood}"]`);
    await new Promise(resolve=>setTimeout(resolve,450));
    await page.screenshot({path:path.join(output,mood+'-transition.png')});
    await new Promise(resolve=>setTimeout(resolve,1800));
    await page.screenshot({path:path.join(output,mood+'-live.png')});
  }
  await page.evaluate(()=>postMessage(JSON.stringify({type:'companion-state',mood:'idle',reduced:true}),location.origin));
  await page.waitForSelector('body[data-mood="idle"]');await page.focus('#scene');
  const front=await page.screenshot();
  for(let i=0;i<6;i++)await page.keyboard.press('ArrowRight');
  await new Promise(resolve=>setTimeout(resolve,100));
  const side=await page.screenshot({path:path.join(output,'side.png')});assert.notDeepEqual(side,front);
  for(let i=0;i<6;i++)await page.keyboard.press('ArrowRight');
  await new Promise(resolve=>setTimeout(resolve,100));
  assert.notDeepEqual(await page.screenshot({path:path.join(output,'back.png')}),side);
  await page.evaluate(()=>dispatchEvent(new MessageEvent('message',{origin:'https://invalid.example',source:window,data:JSON.stringify({type:'companion-state',mood:'eat'})})));
  assert.equal(await page.$eval('body',node=>node.dataset.mood),'idle');
  // Exercise both directions of the Flutter/iframe bridge at a known free time.
  const app=await browser.newPage();await observeAppReadiness(app);
  app.on('pageerror',error=>errors.push(error.message));
  await app.evaluateOnNewDocument(()=>{
    const NativeDate=Date;window.testNow=NativeDate.parse('2026-11-13T14:00:00+08:00');
    window.Date=class extends NativeDate {
      constructor(...args){super(...(args.length?args:[window.testNow]));}
      static now(){return window.testNow;}
    };
  });
  await app.setViewport({width:1440,height:1000});await navigateToApp(app,address+'/#/zh-CN/about');
  await app.waitForFunction(()=>document.querySelectorAll('iframe').length>0);
  const interactive=app.frames().find(frame=>frame.url().includes('/companion/index.html'));
  await interactive.waitForSelector('body[data-ready="true"]');
  await app.evaluate(()=>{window.bridgeMessages=[];addEventListener('message',e=>window.bridgeMessages.push(e.data));});
  await interactive.click('#scene');
  try {await interactive.waitForSelector('body[data-mood="happy"]',{timeout:5000});}
  catch(error){console.log('Bridge diagnostic',await app.evaluate(()=>({now:Date.now(),messages:window.bridgeMessages,visibility:document.visibilityState})),await interactive.$eval('body',node=>node.dataset.mood));await app.screenshot({path:path.join(output,'bridge-failure.png')});throw error;}
  await interactive.evaluate(()=>{window.gestures=[];for(const name of ['pointerdown','pointerup','click','dblclick'])document.querySelector('#scene').addEventListener(name,e=>window.gestures.push({name,detail:e.detail}));});
  await interactive.click('#scene',{count:2});
  try {await interactive.waitForSelector('body[data-mood="celebrate"]',{timeout:5000});}
  catch(error){console.log('Double-click diagnostic',await app.evaluate(()=>window.bridgeMessages),await interactive.evaluate(()=>({gestures:window.gestures,mood:document.body.dataset.mood})));throw error;}
  for(const [time,mood] of [['23:45','sleep'],['08:00','wake'],['08:02','wash'],['08:30','eat']]){
    await app.evaluate(value=>{window.testNow=Date.parse('2026-11-14T'+value+':00+08:00');},time);
    await interactive.waitForSelector(`body[data-mood="${mood}"]`,{timeout:5000});
    if(mood==='sleep'){
      await interactive.click('#scene');await new Promise(resolve=>setTimeout(resolve,400));
      assert.equal(await interactive.$eval('body',node=>node.dataset.mood),'sleep','Petting respects scheduled sleep');
    }
  }
  await app.close();
  // Failure stays inside the 3D frame while the application becomes usable.
  const failurePage=await browser.newPage();await observeAppReadiness(failurePage);
  await failurePage.setRequestInterception(true);
  failurePage.on('request',req=>new URL(req.url()).pathname.endsWith('/blue.vrm')?req.respond({status:503,body:''}):req.continue());
  await navigateToApp(failurePage,address+'/#/zh-CN/about');
  await failurePage.waitForFunction(()=>document.querySelectorAll('iframe').length>0);
  const scene=failurePage.frames().find(frame=>frame.url().includes('/companion/index.html'));
  assert.ok(scene,'About embeds the 3D scene');await scene.waitForSelector('#status button');
  assert.equal(await failurePage.$('#boot'),null,'3D failure does not block Flutter startup');
  assert.deepEqual(errors,[]);
  console.log(`3D checks passed: ${metadata.clips.length} clips, live motion, side/back geometry, click bridge, China schedule, origin filtering, isolated load failure.`);
}finally{
  await browser?.close();server.closeAllConnections();await new Promise(resolve=>server.close(resolve));
}
