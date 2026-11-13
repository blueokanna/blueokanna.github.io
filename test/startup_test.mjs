import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFile} from 'node:fs/promises';
const guard=await readFile(new URL('../web/startup_guard.js',import.meta.url),'utf8');
const worker=await readFile(new URL('../web/retire_service_worker.js',import.meta.url),'utf8');
function environment(url='https://www.pulselink.top/#/zh-CN/studio') {
  const navigations=[],deleted=[],unregistered=[],nodes=new Map();
  for(const id of ['boot','boot-message','retry','recover'])nodes.set(id,{hidden:true,textContent:''});
  const location=Object.assign(new URL(url),{replace:value=>navigations.push(value)});
  const registrations=['flutter_service_worker.js','other-worker.js'].map(name=>({
    active:{scriptURL:location.origin+'/'+name},unregister:async()=>unregistered.push(name),
  }));
  const listeners={};
  const context={location,URL,Set,Date,Promise,setTimeout:fn=>{fn();},
    navigator:{serviceWorker:{getRegistrations:async()=>registrations}},
    caches:{keys:async()=>['flutter-app-cache','flutter-temp-cache','flutter-app-manifest','user-drafts'],delete:async key=>deleted.push(key)},
    document:{getElementById:id=>nodes.get(id)},addEventListener:(name,fn)=>{listeners[name]=fn;},
  };context.window=context;
  return {context,navigations,deleted,unregistered,nodes,listeners};
}
test('startup retires only Flutter caches without navigating or touching drafts',async()=>{
  const e=environment();vm.runInNewContext(guard,e.context);await e.context.pulseStartup;
  assert.deepEqual(e.navigations,[]);
  assert.deepEqual(e.unregistered,['flutter_service_worker.js']);
  assert.deepEqual(e.deleted,['flutter-app-cache','flutter-temp-cache','flutter-app-manifest']);
});
test('recovery is explicit, preserves route and shows useful startup failure',async()=>{
  const e=environment();vm.runInNewContext(guard,e.context);await e.context.pulseStartup;
  e.context.pulseStartupFailure();assert.equal(e.nodes.get('recover').hidden,false);
  assert.equal(e.nodes.get('retry').hidden,false);assert.deepEqual(e.navigations,[]);
  await e.context.pulseRecover();assert.equal(e.navigations.length,1);
  const destination=new URL(e.navigations[0]);assert.equal(destination.hash,'#/zh-CN/studio');
  assert.ok(destination.searchParams.has('recovery'));
});
test('canonical redirect preserves route and requires HTTPS',()=>{
  const e=environment('http://blueokanna.github.io/?x=1#/zh-CN/friends');
  vm.runInNewContext(guard,e.context);
  assert.deepEqual(e.navigations,['https://www.pulselink.top/?x=1#/zh-CN/friends']);
});
test('migration worker unregisters without reloading existing editors',async()=>{
  const handlers={},deleted=[];let unregistered=0,skipped=0;
  vm.runInNewContext(worker,{self:{addEventListener:(name,fn)=>{handlers[name]=fn;},
    skipWaiting:()=>skipped++,registration:{unregister:async()=>unregistered++},
    clients:{matchAll:()=>{throw new Error('Must never navigate editor clients');}}},
    caches:{keys:async()=>['flutter-app-cache','drafts'],delete:async key=>deleted.push(key)}});
  handlers.install();let pending;handlers.activate({waitUntil:promise=>{pending=promise;}});await pending;
  assert.equal(skipped,1);assert.equal(unregistered,1);assert.deepEqual(deleted,['flutter-app-cache']);
});
