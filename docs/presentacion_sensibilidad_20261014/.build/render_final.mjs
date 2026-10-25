import fs from 'node:fs/promises';
import {PresentationFile,FileBlob} from '@oai/artifact-tool';
const W='/Users/nuseche/Documents/ChatGPT/Tesis/output/presentacion_sensibilidad_20261014';
const p=await PresentationFile.importPptx(await FileBlob.load(W+'/entrega/Sensibilidad_aerogenerador_20261014.pptx'));
await fs.mkdir(W+'/.build/final-rendered',{recursive:true});
for(let i=0;i<p.slides.items.length;i++){
 const slide=p.slides.items[i];const b=await p.export({slide,format:'png',scale:1});
 await fs.writeFile(W+'/.build/final-rendered/slide-'+String(i+1).padStart(2,'0')+'.png',new Uint8Array(await b.arrayBuffer()));
}
console.log('Final imported presentation rendered:',p.slides.items.length,'slides');
