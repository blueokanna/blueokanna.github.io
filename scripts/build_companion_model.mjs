/** Verify and describe the licensed original VRM. Never regenerate its shape. */
import {readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {activities,activityDuration} from './companion_activities.mjs';
const provenance=JSON.parse(await readFile(new URL('../content/companion-model.json',import.meta.url),'utf8'));
if(provenance.file!=='blue.vrm')throw Error('Unexpected companion asset path');
const bytes=await readFile(new URL('../web/companion/blue.vrm',import.meta.url));
const sha256=createHash('sha256').update(bytes).digest('hex');
if(sha256!==provenance.sha256)throw Error('Original model checksum mismatch');
if(bytes.length>24_000_000||bytes.readUInt32LE(0)!==0x46546c67||bytes.readUInt32LE(4)!==2||bytes.readUInt32LE(8)!==bytes.length)throw Error('Invalid VRM container');
const gltf=JSON.parse(bytes.subarray(20,20+bytes.readUInt32LE(12)).toString('utf8'));
const vrm=gltf.extensions?.VRMC_vrm;
if(!vrm||vrm.meta.name!==provenance.name||!vrm.meta.authors.includes(provenance.author)||!gltf.skins?.length)throw Error('Unexpected model identity or missing skin');
for(const entry of [...(gltf.buffers||[]),...(gltf.images||[])])if(entry.uri)throw Error('The model must embed all buffers and textures');
const metadata={...provenance,format:'VRM 1.0',animationType:'Runtime humanoid quaternion animation, two-bone arm IK, original expression morphs and spring bones',
  clips:activities.map(name=>({name,duration:activityDuration(name),loop:true,source:'runtime'})),
  stats:{bytes:bytes.length,meshes:gltf.meshes.length,skins:gltf.skins.length,humanoidBones:Object.keys(vrm.humanoid.humanBones).length,expressions:Object.keys(vrm.expressions.preset).length+Object.keys(vrm.expressions.custom||{}).length},
};
await writeFile(new URL('../web/companion/model-info.json',import.meta.url),JSON.stringify(metadata,null,2)+'\n');
console.log(JSON.stringify({name:metadata.name,author:metadata.author,sha256,...metadata.stats},null,2));
