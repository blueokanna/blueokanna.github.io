import {launchBrowser, observeAppReadiness, navigateToApp, collectBrowserDiagnostics} from './browser_app.mjs';
import {mkdir} from 'node:fs/promises';
const directory='build/qa/live'; await mkdir(directory,{recursive:true});
const browser=await launchBrowser();
try {
 const page=await browser.newPage();await page.setViewport({width:1440,height:1000});
 const diagnostics=collectBrowserDiagnostics(page,directory);await observeAppReadiness(page);
 try {
  await navigateToApp(page,'https://www.pulselink.top/#/zh-CN/friends',{timeout:45000});
  await page.screenshot({path:directory+'/friends.png'});
  console.log(JSON.stringify({url:page.url(),result:'ready',errors:diagnostics.errors}));
 } catch(e) {await diagnostics.capture(e,'live desktop startup');throw e;}
} finally {await browser.close();}
