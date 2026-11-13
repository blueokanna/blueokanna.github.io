import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import * as T from 'three';
import {activities,sampleActivity} from '../scripts/companion_activities.mjs';
import {VRMExpressionManager,VRMExpression} from '@pixiv/three-vrm';
import {solveArm,applyCompanionExpressions} from '../scripts/companion_vrm.mjs';

test('the published VRM preserves the original artist asset, identity and license metadata',async()=>{
  const file=await readFile(new URL('../web/companion/blue.vrm',import.meta.url));
  const source=JSON.parse(await readFile(new URL('../content/companion-model.json',import.meta.url),'utf8'));
  assert.equal(createHash('sha256').update(file).digest('hex'),source.sha256);
  assert.equal(file.readUInt32LE(0),0x46546c67);assert.equal(file.readUInt32LE(4),2);
  assert.equal(file.readUInt32LE(8),file.length);
  const gltf=JSON.parse(file.subarray(20,20+file.readUInt32LE(12)).toString());
  const vrm=gltf.extensions.VRMC_vrm;
  assert.deepEqual(vrm.meta.authors,['木子恶魔']);
  assert.equal(vrm.meta.name,'蓝色小肥鱼Deepseek');
  assert.equal(vrm.meta.allowRedistribution,false,'Keep embedded terms; separate site authorization does not rewrite them');
  assert.equal(vrm.meta.modification,'prohibited');
  assert.equal(source.authorization.reportedBy,'blueokanna');
  assert.equal(Object.keys(vrm.humanoid.humanBones).length,53);
  assert.ok(vrm.expressions.preset.blink.morphTargetBinds.length);
  assert.ok(vrm.expressions.preset.happy.morphTargetBinds.length);
  assert.ok(gltf.extensions.VRMC_springBone.springs.length);
  assert.ok(gltf.skins.length && gltf.nodes.some(node=>node.skin!==undefined));
  for(const resource of [...gltf.images,...gltf.buffers])assert.equal(resource.uri,undefined,'No external texture or buffer requests');
  const info=JSON.parse(await readFile(new URL('../web/companion/model-info.json',import.meta.url),'utf8'));
  assert.equal(info.format,'VRM 1.0');assert.deepEqual(info.clips.map(clip=>clip.name),activities);
  assert.ok(info.clips.every(clip=>clip.source==='runtime'),'Runtime motion is not presented as author-supplied animation');
});

test('all routines yield finite, bounded, continuous poses and sleeping eyes stay closed',()=>{
  const numbers=value=>typeof value==='number'?[value]:Object.values(value).flatMap(numbers);
  for(const name of activities)for(let time=0;time<14;time+=.013){
    const pose=sampleActivity(name,time),a=numbers(pose),b=numbers(sampleActivity(name,time+.0001));
    assert.ok(a.every(Number.isFinite),name);
    assert.ok(a.every((n,i)=>Math.abs(n-b[i])<.003),name+' must not jump at cycle boundaries');
    assert.ok(Object.values(pose.expressions).every(value=>value>=0 && value<=1));
    assert.equal(pose.expressions.relaxed??0,0,'The comic white-eye effect must never be used for sleepy eyelids');
    if(name==='sleep')assert.equal(pose.expressions.blink,1);
  }
});

test('skin-eyelid expression mixing clears white-eye effects and prevents additive eyelid overshoot',()=>{
  const manager=new VRMExpressionManager();
  for(const name of ['blink','happy','aa','relaxed'])manager.registerExpression(new VRMExpression(name));
  manager.setValue('relaxed',1);
  applyCompanionExpressions(manager,{blink:1,happy:0,relaxed:1});
  assert.equal(manager.getValue('relaxed'),0);
  assert.equal(manager.getValue('blink'),1,'Sleep fully closes the original skin eyelid');
  applyCompanionExpressions(manager,{blink:1,happy:.65,aa:.4});
  assert.equal(manager.getValue('blink')+manager.getValue('happy'),1);
  assert.ok(manager.getValue('aa')+manager.getValue('happy')<=1);
  applyCompanionExpressions(manager,{blink:0,happy:0});
  assert.equal(manager.getValue('blink'),0,'Waking restores the open eye instead of a stale expression');
});

test('arm IK preserves limb length and scale, reaches nearby targets, and safely clamps impossible ones',()=>{
  for(const sign of [-1,1])for(const desired of [[.12,.10,.05],[.25,.2,.2],[0,0,0],[0,0,.08]]){
    const parent=new T.Group(),upper=new T.Bone(),lower=new T.Bone(),hand=new T.Bone();
    parent.position.set(.4,.3,-.1);parent.rotation.set(.2,.5,.1);parent.add(upper);upper.add(lower);lower.add(hand);
    lower.position.x=sign*.091;hand.position.x=sign*.055;parent.updateMatrixWorld(true);
    const origin=upper.getWorldPosition(new T.Vector3());
    const target=parent.localToWorld(new T.Vector3(desired[0]*sign,desired[1],desired[2]));
    const hint=parent.localToWorld(new T.Vector3(sign*.2,-.1,-.1));
    solveArm(upper,lower,hand,target,hint);parent.updateMatrixWorld(true);
    const elbow=lower.getWorldPosition(new T.Vector3()),end=hand.getWorldPosition(new T.Vector3());
    assert.ok(Math.abs(origin.distanceTo(elbow)-.091)<1e-8);
    assert.ok(Math.abs(elbow.distanceTo(end)-.055)<1e-8);
    const expected=T.MathUtils.clamp(target.distanceTo(origin),.03601,.14599);
    assert.ok(Math.abs(origin.distanceTo(end)-expected)<1e-7);
    if(target.distanceTo(origin)>.03601 && target.distanceTo(origin)<.14599)assert.ok(target.distanceTo(end)<1e-7);
    for(const bone of [upper,lower,hand]){assert.deepEqual(bone.scale.toArray(),[1,1,1]);assert.ok(bone.quaternion.toArray().every(Number.isFinite));}
  }
});
