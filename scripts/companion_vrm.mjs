import * as T from 'three';
import {sampleActivity,activities} from './companion_activities.mjs';
import {createProps} from './companion_props.mjs';
const quaternion=values=>new T.Quaternion().setFromEuler(new T.Euler(...values));
const vector=values=>new T.Vector3().fromArray(values);
const smooth=t=>t*t*(3-2*t);

/** Only the reviewed skin-eyelid and mouth morphs may drive daily routines.
 * The author's "relaxed" morph is a comic white-eye effect, not a sleepy lid.
 * Reset first so a previous expression cannot remain active during a transition.
 */
export function applyCompanionExpressions(manager,weights){
  const weight=name=>Number.isFinite(weights[name])?T.MathUtils.clamp(weights[name],0,1):0;
  const happy=weight('happy');
  manager.resetValues();
  manager.setValue('happy',happy);
  manager.setValue('blink',weight('blink')*(1-happy));
  manager.setValue('aa',weight('aa')*(1-happy));
}

/** Two-bone IK rotates joints only. The effector is clamped to actual reach. */
export function solveArm(upper,lower,hand,target,hint){
  const start=upper.getWorldPosition(new T.Vector3()),elbow=lower.getWorldPosition(new T.Vector3()),end=hand.getWorldPosition(new T.Vector3());
  const a=start.distanceTo(elbow),b=elbow.distanceTo(end);
  if(a<1e-6||b<1e-6)return;
  const direction=target.clone().sub(start);const distance=T.MathUtils.clamp(direction.length(),Math.abs(a-b)+1e-5,a+b-1e-5);
  if(direction.lengthSq()<1e-12)direction.copy(end).sub(start);
  if(direction.lengthSq()<1e-12)direction.set(0,-1,0);
  direction.normalize();
  const bend=hint.clone().sub(start);bend.addScaledVector(direction,-bend.dot(direction));
  if(bend.lengthSq()<1e-8){bend.set(Math.abs(direction.x)<.9?1:0,Math.abs(direction.x)<.9?0:1,0);bend.addScaledVector(direction,-bend.dot(direction));}
  bend.normalize();
  const along=(a*a+distance*distance-b*b)/(2*distance),away=Math.sqrt(Math.max(0,a*a-along*along));
  const desiredElbow=start.clone().addScaledVector(direction,along).addScaledVector(bend,away);
  const desiredHand=start.clone().addScaledVector(direction,distance);
  const turn=(bone,from,to)=>{
    const world=bone.getWorldQuaternion(new T.Quaternion());
    world.premultiply(new T.Quaternion().setFromUnitVectors(from.normalize(),to.normalize()));
    const parent=bone.parent.getWorldQuaternion(new T.Quaternion()).invert();
    bone.quaternion.copy(parent.multiply(world));bone.updateMatrixWorld(true);
  };
  turn(upper,elbow.clone().sub(start),desiredElbow.clone().sub(start));
  const updatedElbow=lower.getWorldPosition(new T.Vector3()),updatedHand=hand.getWorldPosition(new T.Vector3());
  turn(lower,updatedHand.sub(updatedElbow),desiredHand.sub(updatedElbow));
}

export class CompanionVrm {
  constructor(vrm){
    this.vrm=vrm;this.time=Date.now()/1000;this.age=1;this.mood='';
    vrm.scene.updateMatrixWorld(true);
    const box=new T.Box3().setFromObject(vrm.scene);this.height=box.max.y-box.min.y;
    if(!Number.isFinite(this.height)||this.height<.01||this.height>20)throw Error('Invalid avatar bounds');
    this.viewCenter=box.getCenter(new T.Vector3());
    this.radius=Math.hypot(box.max.x-box.min.x,box.max.z-box.min.z)/2+.035*this.height;
    this.root=new T.Group();this.root.name='CompanionActor';this.root.add(vrm.scene);
    this.center=(box.min.y+box.max.y)/2;vrm.scene.position.y=-this.center;this.root.position.y=this.center;
    this.bones=Object.fromEntries(Object.entries(vrm.humanoid.normalizedHumanBones).map(([name,value])=>[name,value.node]));
    for(const name of ['head','hips','leftUpperArm','leftLowerArm','leftHand','rightUpperArm','rightLowerArm','rightHand'])if(!this.bones[name])throw Error('Required humanoid bone missing: '+name);
    this.props=createProps(vrm.scene,this.height);
  }
  select(mood,snap=false){
    if(!activities.includes(mood))mood='idle';
    if(mood===this.mood)return;
    this.from=this.current;this.mood=mood;this.age=snap||!this.from?1:0;
  }
  update(dt,snap=false){
    if(!this.mood)this.select('idle',true);
    if(!snap)this.time+=dt;
    this.age=snap?1:Math.min(1,this.age+dt/.85);
    const target=sampleActivity(this.mood,this.time),from=this.from||target,w=smooth(this.age);
    const blend=(a,b)=>T.MathUtils.lerp(a,b,w),current={root:[],lift:blend(from.lift,target.lift),bones:{},hands:{},expressions:{},grip:blend(from.grip,target.grip)};
    const blendRotation=(a,b)=>quaternion(a).slerp(quaternion(b),w);
    const rootQ=blendRotation(from.root,target.root);current.root=new T.Euler().setFromQuaternion(rootQ).toArray().slice(0,3);
    this.root.quaternion.copy(rootQ);this.root.position.y=this.center+current.lift*this.height;
    this.vrm.humanoid.resetNormalizedPose();
    for(const [name,angles] of Object.entries(target.bones)){
      const q=blendRotation(from.bones[name],angles);current.bones[name]=new T.Euler().setFromQuaternion(q).toArray().slice(0,3);
      this.bones[name]?.quaternion.copy(q);
    }
    for(const side of ['left','right']){
      current.hands[side]=target.hands[side].map((value,index)=>blend(from.hands[side][index],value));
      for(const finger of ['Index','Middle','Ring','Little'])for(const part of ['Proximal','Intermediate','Distal']){
        const bone=this.bones[side+finger+part];if(bone)bone.rotation.z=(side==='left'?-1:1)*current.grip*.6;
      }
    }
    this.root.updateMatrixWorld(true);
    for(const side of ['left','right']){
      const sign=side==='left'?1:-1;
      const targetWorld=this.vrm.scene.localToWorld(vector(current.hands[side]).multiplyScalar(this.height));
      const hint=this.vrm.scene.localToWorld(new T.Vector3(sign*.42,.35,-.08).multiplyScalar(this.height));
      solveArm(this.bones[side+'UpperArm'],this.bones[side+'LowerArm'],this.bones[side+'Hand'],targetWorld,hint);
    }
    for(const [name,value] of Object.entries(target.expressions)){
      current.expressions[name]=blend(from.expressions[name]||0,value);
    }
    // This asset's happy morph already closes eyes and opens the mouth. Its
    // override flags are all "none", so prevent additive eyelid/mouth overshoot.
    applyCompanionExpressions(this.vrm.expressionManager,current.expressions);
    if(snap){this.vrm.humanoid.update();this.root.updateMatrixWorld(true);this.vrm.springBoneManager?.reset();}
    this.vrm.update(snap?0:Math.min(dt,.033));
    const hands=Object.fromEntries(['left','right'].map(side=>[side,this.vrm.scene.worldToLocal(this.vrm.humanoid.getRawBoneNode(side+'Hand').getWorldPosition(new T.Vector3()))]));
    // The head's local mouth anchor follows nods without stretching the arms.
    const mouth=this.vrm.scene.worldToLocal(this.vrm.humanoid.getRawBoneNode('head').localToWorld(new T.Vector3(0,.025,.20).multiplyScalar(this.height)));
    this.props.update(this.mood,dt,hands,mouth,snap);
    this.current=current;
  }
}
