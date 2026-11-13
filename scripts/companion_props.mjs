import * as T from 'three';

/** Separate scene props. No changes to the artist's mesh or textures. */
export function createProps(parent,height){
  const groups={},materials={};
  for(const [name,color] of Object.entries({white:'#fff6ec',blue:'#78bce1',navy:'#293654',wood:'#bc8b53',paper:'#f6ecd6'}))materials[name]=new T.MeshStandardMaterial({color,roughness:.85});
  const group=name=>{const g=new T.Group();g.name='Activity_'+name;g.visible=false;g.scale.setScalar(height);parent.add(g);groups[name]=g;return g;};
  const mesh=(g,geometry,material,p=[0,0,0],scale=[1,1,1])=>{const m=new T.Mesh(geometry,materials[material]);m.position.set(...p);m.scale.set(...scale);g.add(m);return m;};
  const ball=(g,material,p,scale)=>mesh(g,new T.SphereGeometry(1,24,16),material,p,scale);
  const box=(g,material,p,scale)=>mesh(g,new T.BoxGeometry(1,1,1),material,p,scale);
  const bowl=group('bowl');
  mesh(bowl,new T.LatheGeometry([[.015,-.035],[.04,-.03],[.075,.015],[.078,.03],[.070,.03],[.064,.012],[.035,-.022],[.015,-.027]].map(p=>new T.Vector2(...p)),32),'white');
  ball(bowl,'paper',[0,.014,0],[.068,.014,.068]);
  mesh(bowl,new T.TorusGeometry(.075,.003,8,32),'blue',[0,.03,0]).rotation.x=Math.PI/2;
  const sticks=group('sticks');for(const x of [-.006,.006])mesh(sticks,new T.CylinderGeometry(.002,.002,.13,8),'wood',[x,.065,0]);
  ball(sticks,'white',[0,.133,0],[.009,.007,.008]);
  const brush=group('brush');box(brush,'blue',[0,.045,0],[.009,.09,.009]);box(brush,'white',[0,.096,.006],[.016,.025,.012]);
  const book=group('book');
  for(const sign of [-1,1]){
    box(book,'blue',[sign*.065,0,0],[.13,.009,.15]).rotation.z=sign*.12;
    box(book,'paper',[sign*.063,.008,0],[.118,.01,.14]).rotation.z=sign*.12;
    for(let i=0;i<5;i++)box(book,'navy',[sign*.065,.014,-.045+i*.02],[.084,.0008,.001]);
  }
  const pencil=group('pencil');mesh(pencil,new T.CylinderGeometry(.003,.003,.095,8),'wood',[0,.047,0]);
  mesh(pencil,new T.ConeGeometry(.003,.012,8),'navy',[0,-.006,0]).rotation.z=Math.PI;
  const gamepad=group('gamepad');ball(gamepad,'navy',[0,0,0],[.12,.026,.055]);
  for(const x of [-.07,.07])ball(gamepad,'blue',[x,.025,.005],[.011,.006,.011]);
  box(gamepad,'white',[-.06,.027,-.02],[.027,.003,.007]);box(gamepad,'white',[-.06,.027,-.02],[.007,.003,.027]);
  const pillow=group('pillow');ball(pillow,'white',[0,0,0],[.18,.07,.12]);
  const placements={book:[0,.32,.155],gamepad:[0,.32,.15],pillow:[-.16,.70,-.17]};
  for(const [name,position] of Object.entries(placements))groups[name].position.fromArray(position).multiplyScalar(height);
  book.rotation.x=.30;
  const visibleFor={eat:['bowl','sticks'],wash:['brush'],read:['book'],write:['book','pencil'],game:['gamepad'],sleep:['pillow']};
  return {
    update(mood,dt,hands,mouth,snap=false){
      const visible=visibleFor[mood]||[];
      for(const [name,g] of Object.entries(groups)){
        const target=visible.includes(name)?1:0;
        const amount=snap?target:T.MathUtils.damp(g.userData.amount||0,target,12,dt);
        g.userData.amount=amount;g.visible=amount>.002;g.scale.setScalar(height*Math.max(.001,amount));
      }
      for(const name of ['sticks','brush','pencil']){
        const g=groups[name];g.position.copy(hands.right);
        const target=name==='pencil'?book.position.clone().add(new T.Vector3(-.025,.012,.015).multiplyScalar(height)):mouth;
        const direction=target.clone().sub(g.position).normalize();
        // Pencil tip lies along local -Y; chopsticks and brush point along +Y.
        g.quaternion.setFromUnitVectors(new T.Vector3(0,name==='pencil'?-1:1,0),direction);
      }
      bowl.position.copy(hands.left).add(new T.Vector3(0,.025,.025).multiplyScalar(height));
    },
  };
}
