import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {Presentation, PresentationFile} from '@oai/artifact-tool';

const WORK='/Users/nuseche/Documents/ChatGPT/Tesis/output/presentacion_comparativa_20261020';
const ROOT='/Users/nuseche/Desktop/Tesis_codigos';
const DOCS=ROOT+'/docs/entradas_reales_20261020';
const SKILL='/Users/nuseche/.codex/plugins/cache/openai-primary-runtime/presentations/26.1020.11127/skills/presentations';
const RUNTIME='/Users/nuseche/.cache/codex-runtimes/codex-primary-runtime/dependencies';
Object.assign(process.env,{RUNTIME_NODE_MODULES:RUNTIME+'/node/node_modules',RUNTIME_NODE:RUNTIME+'/node/bin/node',RUNTIME_PYTHON:RUNTIME+'/python/bin/python3',RUNTIME_BIN_DIR:RUNTIME+'/bin/override'});
const {resolvePresentationFont,finalizePresentation}=await import(pathToFileURL(SKILL+'/container_tools/artifact_tool_utils.mjs').href);
const family=resolvePresentationFont({fontFamily:'Arial'});
const s=JSON.parse(await fs.readFile(DOCS+'/analysis_summary.json','utf8'));
const report=JSON.parse(await fs.readFile(DOCS+'/report_values.json','utf8'));
const p=Presentation.create({slideSize:{width:1280,height:720}});
let index=0;const nativeTables=[];
function text(sl,value,x,y,w,h,size=30,bold=false,color='#151515'){
 const a=sl.shapes.add({geometry:'textbox',position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});
 a.text=value;a.text.style={typeface:family,fontSize:size,bold,color,autoFit:'none',verticalAlignment:'top',lineSpacing:1.1,insets:{left:0,right:0,top:0,bottom:0}};return a;
}
function slide(title,notes='',sources=[]){
 const a=p.slides.add();a.background.fill='#ffffff';index++;
 text(a,title,64,34,1152,100,42,true);text(a,String(index).padStart(2,'0'),1195,680,45,24,18,false,'#777777');
 a.speakerNotes.textFrame.setText(notes+'\n\nFuentes:\n'+sources.join('\n'));return a;
}
function lines(a,items,{y=158,step=114,size=31}={}){items.forEach((v,i)=>text(a,v,72,y+i*step,1120,step-15,size));}
function table(a,values,widths,{y=158,h=360,size=28}={}){
 const t=a.tables.add({rows:values.length,columns:values[0].length,left:64,top:y,width:1152,height:h,columnWidths:widths,values});
 t.borders.assign({style:'solid',fill:'#d2d2d2',width:.8});
 for(let r=0;r<values.length;r++)for(let c=0;c<values[0].length;c++){
  const ce=t.getCell(r,c);ce.fill=r===0?'#eeeeee':'#ffffff';ce.text.style={typeface:family,fontSize:size,bold:r===0,color:'#151515',autoFit:'none',verticalAlignment:'middle'};
 }
 nativeTables.push(index);
}
async function figure(a,name,caption){
 a.images.add({blob:new Uint8Array(await fs.readFile(DOCS+'/figures/'+name+'.png')),contentType:'image/png',alt:name,fit:'contain',position:{left:64,top:140,width:1152,height:465}});
 text(a,caption,70,618,1120,58,24,false,'#444444');
}
const format=(n,d=3)=>Number(n).toFixed(d);
{
 const a=slide('Sismo, viento y sensibilidad','Comparación determinista con registros reales independientes y carga eólica prescrita. Complementa la presentación modal del 14 de octubre; no reemplaza sus resultados Morris.',[DOCS+'/analysis_summary.json']);
 text(a,'Comparación de entradas medidas\ny respuesta del modelo existente',74,180,1100,152,44,true);
 text(a,'Nicolás Andrés Useche Castillo',76,440,1100,46,30);
 text(a,'Actualización del 20 de octubre de 2026',76,516,1100,40,28,false,'#555555');
}
{
 const a=slide('Alcance de la comparación','El autor autorizó registros independientes y empuje medio como parámetro. El modelo conserva 12 rpm, azimut fijo, base fija y valores heredados de amortiguamiento/conexiones. El viento no se extrapola físicamente de 70 m al buje: su historia se utiliza como proxy uniforme autorizado. Los operadores se recalculan por factor mecánico, alrededor del equilibrio heredado, sin actualizarlo por empuje finito.',[ROOT+'/config_default.m',DOCS+'/scripts/snapshot_input_case.m']);
 lines(a,['Registros reales de fuentes independientes; sin simultaneidad observada','Viento convertido a empuje axial prescrito con valor medio libre','Operadores congelados: comparación estructural exploratoria','La respuesta no incluye retroalimentación aerodinámica'],{step:111,size:31});
}
{
 const a=slide('Literatura y disponibilidad de datos','Wang et al. publican datos del caso sismo-viento, pero el viento es sintético Davenport y los archivos se distribuyen en Origin OPJU. No se atribuyen sus entradas al caso real DTU. Meng et al. fundamentan la importancia del amortiguamiento aerodinámico, no reproducido aquí. DTU proporciona mediciones de campo; OpenSees distribuye registros PEER procesados.',[
 'https://doi.org/10.1080/13632469.2026.2671807','https://doi.org/10.5281/zenodo.19347779',
 'https://doi.org/10.1016/j.renene.2020.05.181','https://doi.org/10.11583/DTU.16743739',DOCS+'/sources/earthquake_provenance.json']);
 table(a,[['Referencia','Entradas disponibles','Uso en el estudio'],['Wang et al., 2026','Sismo PEER + viento sintético','Referencia reproducible; archivo OPJU'],['Meng et al., 2020','Mesa sísmica + viento de laboratorio','Importancia del amortiguamiento aero.'],['DTU, NM92','Viento medido a 25 Hz','Historia de viento utilizada'],['OpenSees / PEER','Acelerogramas procesados','Entradas sísmicas sin escalar']],[295,445,412],{h:402,size:26});
}
{
 const a=slide('Registros utilizados','El viento corresponde al canal sónico longitudinal s70u a 70 m, 2005-11-19 00:00 según cabecera, zona horaria no indicada. Primer archivo en orden lexicográfico. No se seleccionó por respuesta favorable. Los tres registros sísmicos pertenecen a dos terremotos, uno de ellos en dos estaciones.',[DOCS+'/tables/wind_catalog.json',DOCS+'/tables/earthquake_catalog.json']);
 await figure(a,'entradas_medidas','DTU: media 6,134 m/s; turbulencia longitudinal 4,25 %. Arleta: PGA 0,308 g');
}
{
 const a=slide('Del viento medido al empuje parametrizado','Media cuadrática calculada con las 15000 muestras originales. Se interpola linealmente U²/<U²>, no se cuadran las velocidades después de interpolar. La condición inicial es el equilibrio lineal del empuje medio con los mismos operadores congelados. Las fuerzas se aplican en el maestro 130 y se proyectan mediante Tc transpuesta. No hay coeficiente de empuje calibrado ni fuerza medida aplicada.',[DOCS+'/scripts/snapshot_input_case.m']);
 text(a,'F(t) = F̄ · U(t)² / ⟨U²⟩',78,180,1100,72,44,true);
 lines(a,['F̄ permanece como parámetro; la respuesta se entrega por 1 kN medio','Carga axial en el buje, según el eje 129–130 del modelo','Misma historia de viento para cada perturbación mecánica'],{y:294,step:102,size:31});
 text(a,'Fref = '+format(s.referenceMeanThrustKN,1)+' kN es una escala de comparación calculada, sin valor de diseño',78,610,1110,58,26,false,'#444444');
}
{
 const a=slide('Contenido frecuencial de las entradas','PSD Welch de la fluctuación del empuje y de la aceleración del suelo, ambas normalizadas por la integral de su PSD. Ventanas de 20 s y solape 50 %. Las amplitudes no representan fuerzas iguales ni energías iguales. Los estimadores tienen diferente número de segmentos. Líneas verticales: frecuencias nominales de los grupos 3, 6+7 y 10+11.',[DOCS+'/tables/spectral_summary.json']);
 await figure(a,'contenido_frecuencial','Las formas espectrales ayudan a interpretar la excitación; la participación modal también importa');
}
{
 const a=slide('Respuesta ante los acelerogramas reales','Una componente horizontal por vez; gráfico en global X. Se conservan amplitudes y duraciones originales. Tres estaciones/registros de dos terremotos; no es una muestra de peligro sísmico de un emplazamiento. El máximo no puede ordenarse únicamente por PGA.',[DOCS+'/tables/nominal_earthquakes.csv',DOCS+'/tables/earthquake_intensities.csv']);
 await figure(a,'respuesta_sismos_reales','Desplazamiento relativo y aceleración absoluta de góndola; registros sin escalar');
}
{
 const a=slide('Verificación numérica','Recuperación optimizada contrastada con la rutina sísmica existente; cambios de chunk y pasos temporales. Los filtros de sensibilidad son por respuesta. La convergencia de góndola no certifica automáticamente aceleraciones de puntas. No se realizó convergencia espacial con rotor girando.',[DOCS+'/tables/time_convergence.csv',DOCS+'/tables/case_audit.csv',DOCS+'/analysis_summary.json']);
 const refined=report.refinedTangent;
 table(a,[['Control','Resultado','Interpretación'],['Casos de comparación',String(s.caseCount),'Fuentes físicas previas conservadas'],['Recuperación de respuesta','Diferencia relativa < 5 × 10⁻¹¹','Rutina existente y recuperación por canales'],['Residuo dinámico máximo',Number(s.maximumDynamicResidual).toExponential(2),'Equilibrio dinámico discretizado'],['Verificación de la Hessiana',refined?String(refined.successfulCases)+' casos':'Sin refinar','Misma energía y equilibrio original'],['Sensibilidades locales aceptadas',report.acceptedLocal+' de '+report.totalLocal,'Filtros de h, tiempo y paso de Hessiana']],[420,300,432],{h:414,size:25});
 text(a,'Es una verificación numérica; falta la validación experimental del modelo',72,638,1120,40,27,true);
}
{
 const a=slide('Sensibilidad según la entrada','La tangente heredada no resolvió las pendientes al refinar h de 1 % a 0,125 %. La tabla final contrasta h=0,25 % y 0,5 %, Newmark 0,0025 y 0,005 s y pasos internos de Hessiana multiplicados por 20 y 40. Se conserva el equilibrio original y la energía física; solo se refina numéricamente la Hessiana dinámica. Gráfico RMS, que incluye la media eólica. Viento por unidad de empuje medio, sin equilibrio operativo aeroelástico.',[DOCS+'/tables/refined_local_sensitivities.csv',DOCS+'/refined_tangent_summary.json']);
 await figure(a,report.refinedTangent?'sensibilidad_refinada':'refinamiento_sensibilidad',report.refinedTangent?'Símbolos llenos: filtros numéricos superados; símbolos vacíos: sensibilidad no aceptada':'Las pendientes no se aceptan mientras dependen del paso');
}
{
 const a=slide('Orientación de la acción sísmica','Comparación de un mismo acelerograma aplicado en X y en Y. La dirección del rotor y el viento está documentada en analysis_summary.json. Los registros no se presentan como dos componentes simultáneas ni como su orientación geográfica real en el emplazamiento.',[DOCS+'/tables/direction_comparison.csv',DOCS+'/analysis_summary.json']);
 await figure(a,'efecto_direccion','Aplicar el mismo registro en otra dirección cambia la excitación del sistema acoplado');
}
{
 const a=slide('Combinación y momento de llegada','Se superponen historias temporales completas con los mismos operadores lineales. El viento ya existe al llegar el sismo. Se evalúan 29 llegadas: 0, 20, ..., 540 y 559,98 s; el último instante evita extrapolar las muestras medidas. Cada máximo usa la misma ventana sísmica de 39,98 s. La franja mínimo-máximo no es un intervalo probabilístico. Los resultados dependen de F̄, que permanece libre.',[DOCS+'/tables/arrival_phase_comparison.csv']);
 await figure(a,'combinacion_y_llegada','La combinación de máximos separados pierde la información de fase de las historias');
}
{
 const a=slide('Sensibilidad a las amplitudes de entrada','Sismo alineado y llegada en t=0. Eje horizontal: empuje medio dividido por Fref. Se modifican las amplitudes de las entradas con los mismos operadores; no se reconstruye la Hessiana. Se diferencia el máximo combinado mediante perturbaciones de amplitud de 0,5 % y 1 %. La normalización del empuje no está definida en cero. No son porcentajes probabilísticos de contribución.',[DOCS+'/tables/input_amplitude_sensitivities.csv']);
 await figure(a,'sensibilidad_amplitudes','La dependencia respecto de amplitudes puede estudiarse sin aceptar pendientes mecánicas no resueltas');
}
{
 const a=slide('Conclusiones comparativas','Conclusiones restringidas al modelo y entradas seleccionadas. Fref es una normalización calculada y no un umbral de seguridad, un empuje calibrado o una estimación de viento extremo. Las propiedades del modelo y su amortiguamiento siguen sin calibración experimental.',[DOCS+'/report_values.json',DOCS+'/analysis_summary.json']);
 lines(a,report.presentationConclusions,{y:153,step:116,size:30});
}
{
 const a=slide('Cierre del alcance actual','Se cierra la comparación estructural determinista con empuje medio parametrizado. El siguiente cierre físico exige el coeficiente de empuje o un modelo aerodinámico específico, y evolución de operadores si se pretende una simulación de operación durante toda la historia. Las figuras nuevas fueron generadas en MATLAB con el estilo monocromático autorizado; las históricas de Tecplot se mantienen en sus entregables.',[DOCS+'/LEEME.md','https://doi.org/10.11583/DTU.16743739','https://doi.org/10.1080/13632469.2026.2671807','https://doi.org/10.1016/j.renene.2020.05.181']);
 lines(a,['Comparación reproducible: registros, hipótesis, tablas y controles trazables','Pendiente para valores de servicio: identificar el empuje medio o la aerodinámica','Pendiente para operación real: evolución del giro y acoplamiento aeroelástico','Los resultados Morris anteriores conservan su alcance y sus filtros'],{step:112,size:31});
}
await fs.mkdir(WORK+'/.build/rendered',{recursive:true});
await fs.writeFile(WORK+'/.build/presentation.json',JSON.stringify(p.toProto()));
for(const [i,a] of p.slides.items.entries()){
 const stem='slide-'+String(i+1).padStart(2,'0');
 const png=await p.export({slide:a,format:'png',scale:1});await fs.writeFile(WORK+'/.build/rendered/'+stem+'.png',new Uint8Array(await png.arrayBuffer()));
 const layout=await a.export({format:'layout'});await fs.writeFile(WORK+'/.build/rendered/'+stem+'.json',await layout.text());
}
const candidate=WORK+'/.build/candidate_v3.pptx';await(await PresentationFile.exportPptx(p)).save(candidate);
const finalPath=WORK+'/entrega/Resultados_comparativos_20261020.pptx';
const result=await finalizePresentation({workspaceDir:WORK,candidatePath:candidate,finalPath,
 pythonExecutable:RUNTIME+'/python/bin/python3',integrityValidatorPath:SKILL+'/container_tools/inspect_presentation_package_integrity.py',layoutValidatorPath:SKILL+'/container_tools/inspect_presentation_layout_geometry.py',
 layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-bullet-geometry','--validate-heading-fit',...nativeTables.flatMap(n=>['--require-native-table-slide',String(n)])],
 requiredNativeTableOwnerSlides:nativeTables,fontPolicy:{basis:'design',families:[family]},verifyArtifactToolImport:true,receiptPath:WORK+'/.build/validation_v3.json'});
await fs.writeFile(WORK+'/.build/build_result.json',JSON.stringify({slides:index,font:family,nativeTables,finalPath,result},null,2));
console.log(JSON.stringify({slides:index,finalPath}));
