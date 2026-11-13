import {build} from 'esbuild';
import {readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const hash=createHash('sha256').update(await readFile('web/companion/blue.vrm')).digest('hex');
await build({entryPoints:['scripts/companion_scene.mjs'],bundle:true,format:'esm',minify:true,
  define:{__COMPANION_MODEL_HASH__:JSON.stringify(hash)},
  outfile:'web/companion/scene.js',target:['es2022'],legalComments:'eof'});
const revision=createHash('sha256').update(await readFile('web/companion/scene.js')).digest('hex').slice(0,16);
const html=await readFile('web/companion/index.html','utf8');
if(!/src="scene\.js(?:\?v=[a-f0-9]+)?"/.test(html))throw Error('Missing companion script entry');
await writeFile('web/companion/index.html',html.replace(/src="scene\.js(?:\?v=[a-f0-9]+)?"/,`src="scene.js?v=${revision}"`));
