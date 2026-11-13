/** Continuous motion in the author's VRM coordinate system (fractions of height).
 * This module changes poses, never the model's geometry or body proportions.
 */
export const activities=Object.freeze(['idle','wave','dance','read','write','game','eat','wash','wake','sleep','bedtime','celebrate','think','shy','happy','confused','surprised']);
export const activityDuration=name=>name==='sleep'?7:name==='dance'?5:4.8;
export function sampleActivity(name,time){
  const p=time/activityDuration(name)*Math.PI*2,s=Math.sin(p),c=Math.cos(p),b=Math.sin(2*p);
  const frame={root:[0,0,0],lift:.002*b,bones:{head:[.012*b,.035*s,.012*s],spine:[.012*b,0,.01*s],leftUpperLeg:[0,0,0],rightUpperLeg:[0,0,0],leftLowerLeg:[0,0,0],rightLowerLeg:[0,0,0]},
    hands:{left:[.15,.26,.045],right:[-.15,.26,.045]},expressions:{blink:Math.exp(-((((time%4.8)-3.5)/.07)**2)),happy:0,surprised:0,aa:0},grip:0};
  const {bones,hands,expressions}=frame;
  switch(name){
    case 'wave':hands.left=[.18+.02*b,.48,.06];bones.head=[0,.06,-.035];expressions.happy=.22;break;
    case 'dance':frame.lift=.008*(1-c);frame.root=[0,.09*s,.035*s];hands.left=[.19,.31+.055*s,.07];hands.right=[-.19,.31-.055*s,.07];bones.head=[.025*b,-.07*s,-.035*s];bones.leftUpperLeg=[.09*s,0,0];bones.rightUpperLeg=[-.09*s,0,0];expressions.happy=.28;break;
    case 'read':bones.head=[.09,.01*s,0];hands.left=[.10,.32,.12];hands.right=[-.10,.32,.12];break;
    case 'write':bones.head=[.10,-.03,.025];hands.left=[.10,.32,.12];hands.right=[-.045+.012*s,.37,.13+.008*b];frame.grip=.3;break;
    case 'game':bones.head=[.06,.025*s,.012*b];hands.left=[.095,.32,.12];hands.right=[-.095,.32,.12];frame.grip=.25;break;
    case 'eat':hands.left=[.12,.33,.12];hands.right=[-.075,.395+.025*(1+c),.10];bones.head=[.06+.03*c,0,0];frame.grip=.3;expressions.aa=.08*(1+Math.sin(p*4));expressions.happy=.12;break;
    case 'wash':hands.right=[-.065+.009*Math.sin(6*p),.42,.12];bones.head=[.04,.01*s,0];frame.grip=.3;expressions.aa=.12;break;
    case 'wake':hands.left=[.16,.50+.012*s,.04];hands.right=[-.16,.50+.012*s,.04];bones.head=[-.06+.02*c,0,0];bones.spine=[-.035,0,.02*s];expressions.blink=Math.max(expressions.blink,.55+.4*(1-c)/2);expressions.aa=.12*(1-c);break;
    case 'sleep':frame.root=[.05,0,Math.PI/2];frame.lift=0;bones.head=[.035,0,-.05];bones.spine=[.03+.006*s,0,0];hands.left=[.10,.32,.12];hands.right=[-.10,.32,.12];bones.leftUpperLeg=[-.18,0,0];bones.rightUpperLeg=[-.14,0,0];bones.leftLowerLeg=[.32,0,0];bones.rightLowerLeg=[.27,0,0];expressions.blink=1;break;
    case 'bedtime':hands.right=[-.07,.44,.11];bones.head=[.06+.03*s,0,.035];expressions.blink=Math.max(expressions.blink,.4+.45*(1-c)/2);expressions.aa=.15*(1-c);break;
    case 'celebrate':hands.left=[.18,.48+.015*b,.06];hands.right=[-.18,.48+.015*b,.06];frame.lift=.018*(1-c);expressions.happy=.7;expressions.aa=.12;break;
    case 'think':hands.right=[-.08,.43,.11];bones.head=[.03,.08,.06];break;
    case 'shy':hands.left=[.075,.34,.12];hands.right=[-.075,.34,.12];bones.head=[.09,.06*s,.025];expressions.happy=.2;break;
    case 'happy':frame.lift=.005*(1-c);hands.left=[.17,.28+.012*b,.06];hands.right=[-.17,.28-.012*b,.06];bones.head=[0,0,.035*s];expressions.happy=.65;break;
    case 'confused':hands.left=[.21,.38,.08];bones.head=[.02,.04*s,.10*s];expressions.surprised=.15;break;
    case 'surprised':hands.left=[.12,.445,.105];hands.right=[-.12,.445,.105];bones.head=[-.035,0,0];expressions.surprised=.6;expressions.aa=.18;break;
  }
  return frame;
}
