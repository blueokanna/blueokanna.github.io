import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
import {VRMLoaderPlugin} from '@pixiv/three-vrm';
import {CompanionVrm} from './companion_vrm.mjs';
import {activities} from './companion_activities.mjs';
const canvas = document.getElementById('scene'), status = document.getElementById('status');
const scene = new THREE.Scene(), camera = new THREE.OrthographicCamera(-2,2,2,-2,.1,30);
camera.position.set(0, .5, 4);
let renderer, actor, model, reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
let visible = true, compact = false, currentMood = '', frame = 0, previousTime = 0, disposed = false, failed = false;
let modelHeight = 1, targetZoom = 1;
const aliases = {search:'think',empty:'confused',loading:'think',saved:'happy',error:'confused',finished:'celebrate',explore:'surprised'};
let requested = /^[a-z]+$/.test(location.hash.slice(1)) ? location.hash.slice(1) : 'idle';
let controls;
const send = action => { if (window.parent !== window) parent.postMessage(JSON.stringify({type:'companion-action',action}),location.origin); };
const fail = () => {
  failed = true;
  cancelAnimationFrame(frame); frame = 0;
  status.replaceChildren(); status.hidden = false;
  status.append(document.createTextNode('3D 角色暂时无法加载。正文仍可正常阅读。'));
  const retry = document.createElement('button'); retry.textContent='重试 3D';
  retry.addEventListener('click',()=>location.reload()); status.append(retry);
};
function render(time = performance.now()) {
  frame = 0;
  if (disposed || failed || !renderer) return;
  const dt = Math.min(.06, Math.max(0, (time - previousTime) / 1000)); previousTime=time;
  if (!reduced) actor?.update(dt);
  camera.zoom=THREE.MathUtils.lerp(camera.zoom,targetZoom,reduced?1:1-Math.exp(-dt*5));
  camera.updateProjectionMatrix();
  controls?.update(); renderer.render(scene,camera);
  if (!reduced && visible && !document.hidden) frame=requestAnimationFrame(render);
}
function wakeRender() {
  if (!frame && !disposed && !failed && visible && !document.hidden) { previousTime=performance.now(); frame=requestAnimationFrame(render); }
}
function updateMood() {
  if (!model) return;
  const next = activities.includes(requested) ? requested : (aliases[requested] || 'idle');
  if (next !== currentMood) {
    const first=!currentMood;
    actor.select(next,reduced||first);currentMood=next;
    if(reduced||first)actor.update(0,true);
    resize();
    document.body.dataset.mood=next;
  }
  wakeRender();
}
window.addEventListener('message',event=>{
  if(event.source!==parent || event.origin!==location.origin || typeof event.data!=='string' || event.data.length>512)return;
  try {
    const data=JSON.parse(event.data);
    if(data.type!=='companion-state' || typeof data.mood!=='string')return;
    const freeze = data.reduced===true && !reduced;
    requested=data.mood; reduced=data.reduced===true; compact=data.compact===true;
    if(freeze && actor) actor.update(0,true);
    if(controls) controls.enableRotate=!compact;
    document.getElementById('hint').hidden=compact;
    updateMood();
  } catch { /* Ignore unrelated messages. */ }
});
const resize = () => {
  if(!renderer)return;
  const width=Math.max(1,canvas.clientWidth),height=Math.max(1,canvas.clientHeight);
  renderer.setSize(width,height,false);
  const halfHeight=Math.max(modelHeight*.61,(actor?.radius||.66)/(width/height));
  camera.left=-halfHeight*width/height;camera.right=halfHeight*width/height;
  camera.top=halfHeight;camera.bottom=-halfHeight;
  targetZoom=currentMood==='sleep'?Math.min(1,(camera.right-camera.left)/(modelHeight*1.18)):1;
  camera.updateProjectionMatrix();wakeRender();
};
const observer=new ResizeObserver(resize);observer.observe(canvas);
const intersection=new IntersectionObserver(entries=>{visible=entries[0].isIntersecting;if(visible)wakeRender();else{cancelAnimationFrame(frame);frame=0;}});intersection.observe(canvas);
document.addEventListener('visibilitychange',()=>{if(document.hidden){cancelAnimationFrame(frame);frame=0;}else wakeRender();});
let pointer, held, holdTimer, clickTimer;
canvas.addEventListener('pointerdown',event=>{
  pointer={x:event.clientX,y:event.clientY,time:performance.now()}; held=false;
  clearTimeout(holdTimer);holdTimer=setTimeout(()=>{if(pointer){held=true;send('shy');}},650);
});
canvas.addEventListener('pointermove',event=>{
  if(pointer && Math.hypot(event.clientX-pointer.x,event.clientY-pointer.y)>6){clearTimeout(holdTimer);pointer=null;}
});
canvas.addEventListener('pointerup',()=>{
  clearTimeout(holdTimer);
  if(pointer && !held){clearTimeout(clickTimer);clickTimer=setTimeout(()=>send(compact?'open':'pet'),250);}
  pointer=null;
});
canvas.addEventListener('pointercancel',()=>{clearTimeout(holdTimer);pointer=null;});
canvas.addEventListener('dblclick',()=>{clearTimeout(clickTimer);send(compact?'open':'celebrate');});
canvas.addEventListener('keydown',event=>{
  if(event.key==='Enter'||event.key===' '){event.preventDefault();send(compact?'open':'pet');}
  if(controls && ['ArrowLeft','ArrowRight'].includes(event.key)){
    event.preventDefault();const offset=camera.position.clone().sub(controls.target);
    offset.applyAxisAngle(new THREE.Vector3(0,1,0),event.key==='ArrowLeft'?Math.PI/12:-Math.PI/12);
    camera.position.copy(controls.target).add(offset);wakeRender();
  }
});
canvas.addEventListener('webglcontextlost',event=>{event.preventDefault();fail();});
window.addEventListener('pageshow',wakeRender);
window.addEventListener('pagehide',event=>{
  // A document in the back-forward cache will resume without reinitialization.
  // Keep its GPU resources alive, but do not keep drawing or handling a hold.
  if(event.persisted){cancelAnimationFrame(frame);frame=0;clearTimeout(holdTimer);clearTimeout(clickTimer);pointer=null;return;}
  disposed=true;cancelAnimationFrame(frame);clearTimeout(holdTimer);clearTimeout(clickTimer);
  observer.disconnect();intersection.disconnect();controls?.dispose();
  const geometries=new Set(),materials=new Set(),textures=new Set(),bitmaps=new Set();
  model?.traverse(node=>{if(node.geometry)geometries.add(node.geometry);if(node.material)for(const material of [].concat(node.material))materials.add(material);});
  for(const material of materials){
    for(const value of Object.values(material))if(value?.isTexture)textures.add(value);
    for(const uniform of Object.values(material.uniforms||{}))if(uniform.value?.isTexture)textures.add(uniform.value);
    material.dispose();
  }
  for(const texture of textures){if(texture.source?.data)bitmaps.add(texture.source.data);texture.dispose();}
  for(const bitmap of bitmaps)bitmap.close?.();
  for(const geometry of geometries)geometry.dispose();
  renderer?.dispose();renderer?.forceContextLoss();
});
try {
  renderer=new THREE.WebGLRenderer({canvas,alpha:true,antialias:true,powerPreference:'low-power'});
  renderer.setPixelRatio(Math.min(devicePixelRatio,1.75));renderer.outputColorSpace=THREE.SRGBColorSpace;
  renderer.toneMapping=THREE.NoToneMapping;
  scene.add(new THREE.HemisphereLight(0xffffff,0xc4c8dc,2));
  const key=new THREE.DirectionalLight(0xffffff,2);key.position.set(-3,5,7);scene.add(key);
  controls=new OrbitControls(camera,canvas);controls.target.set(0,.5,0);controls.enablePan=false;controls.enableZoom=false;
  controls.minPolarAngle=.4;controls.maxPolarAngle=2.35;controls.enableDamping=false;
  controls.addEventListener('change',wakeRender);
  const fetchAsset=async (url, binary=false) => {
    const abort=new AbortController(),timer=setTimeout(()=>abort.abort(),60000);
    try { const r=await fetch(url,{signal:abort.signal});if(!r.ok)throw new Error('Asset unavailable');return await (binary?r.arrayBuffer():r.json()); }
    finally {clearTimeout(timer);}
  };
  const revision=__COMPANION_MODEL_HASH__;
  const loader=new GLTFLoader().register(parser=>new VRMLoaderPlugin(parser));
  const result=await Promise.all([fetchAsset('./blue.vrm?v='+revision,true).then(bytes=>loader.parseAsync(bytes,'')),fetchAsset('./model-info.json?v='+revision)]);
  if(!disposed){
    const vrm=result[0].userData.vrm;
    if(!vrm)throw Error('Missing VRM humanoid');
    actor=new CompanionVrm(vrm);model=actor.root;modelHeight=actor.height;scene.add(model);
    controls.target.copy(actor.viewCenter);camera.position.copy(controls.target).add(new THREE.Vector3(0,0,modelHeight*4));controls.update();
    document.body.dataset.modelAuthor=result[1].author;
    updateMood();status.hidden=true;document.body.dataset.ready='true';
    resize();if(parent!==window)parent.postMessage(JSON.stringify({type:'companion-ready'}),location.origin);
  }
} catch(error) { console.error('3D companion initialization failed',error);fail(); }
