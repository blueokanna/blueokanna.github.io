// Orthogonal views and detail shots of the current source model for visual QA.
import {launchBrowser} from './browser_app.mjs';
import {readFile,mkdir} from 'node:fs/promises';
import http from 'node:http';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {activities} from './companion_activities.mjs';
const root=fileURLToPath(new URL('../web/',import.meta.url)),output=fileURLToPath(new URL('../build/qa/vrm/',import.meta.url));
await mkdir(output,{recursive:true});
const server=http.createServer(async(req,res)=>{try{const name=path.resolve(root,'.'+new URL(req.url,'http://localhost').pathname);if(!name.startsWith(root))throw Error();const body=await readFile(name);res.setHeader('Content-Type',name.endsWith('.html')?'text/html':name.endsWith('.js')?'text/javascript':name.endsWith('.json')?'application/json':'application/octet-stream');res.end(body);}catch{res.writeHead(404);res.end();}});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));let browser;
try{
  browser=await launchBrowser();const page=await browser.newPage();await page.setViewport({width:760,height:860,deviceScaleFactor:1});
  page.on('pageerror',e=>console.error(e.message));page.on('console',msg=>{if(msg.type()==='error')console.error(msg.text());});
  await page.goto(`http://127.0.0.1:${server.address().port}/companion/index.html#idle`);
  await page.waitForSelector('body[data-ready="true"]',{timeout:30000});
  await page.evaluate(()=>{document.body.style.background='#eeeaf1';postMessage(JSON.stringify({type:'companion-state',mood:'idle',reduced:true}),location.origin);});
  await new Promise(r=>setTimeout(r,100));await page.screenshot({path:path.join(output,'front.png')});
  await page.focus('#scene');
  for(const [name,steps] of [['three-quarter',3],['side',3],['back',6]]){for(let i=0;i<steps;i++)await page.keyboard.press('ArrowRight');await new Promise(r=>setTimeout(r,100));await page.screenshot({path:path.join(output,name+'.png')});}
  for(let i=0;i<12;i++)await page.keyboard.press('ArrowRight');
  for(const mood of activities){
    await page.evaluate(mood=>postMessage(JSON.stringify({type:'companion-state',mood,reduced:true}),location.origin),mood);
    await page.waitForSelector(`body[data-mood="${mood}"]`);await new Promise(r=>setTimeout(r,100));
    await page.screenshot({path:path.join(output,'activity-'+mood+'.png')});
  }
  console.log(output);
}finally{await browser?.close();server.closeAllConnections();await new Promise(r=>server.close(r));}
