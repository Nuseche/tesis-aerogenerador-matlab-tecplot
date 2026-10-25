import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {Presentation,PresentationFile,FileBlob} from '@oai/artifact-tool';

const WORK='/Users/nuseche/Documents/ChatGPT/Tesis/output/presentacion_sensibilidad_20261014';
const ROOT='/Users/nuseche/Desktop/Tesis_codigos';
const SKILL='/Users/nuseche/.codex/plugins/cache/openai-primary-runtime/presentations/26.930.11008/skills/presentations';
const RUNTIME='/Users/nuseche/.cache/codex-runtimes/codex-primary-runtime/dependencies';
process.env.RUNTIME_NODE_MODULES=RUNTIME+'/node/node_modules';
process.env.RUNTIME_NODE=RUNTIME+'/node/bin/node';
process.env.RUNTIME_PYTHON=RUNTIME+'/python/bin/python3';
process.env.RUNTIME_BIN_DIR=RUNTIME+'/bin/override';
const {resolvePresentationFont,finalizePresentation}=await import(pathToFileURL(path.join(SKILL,'container_tools/artifact_tool_utils.mjs')).href);
const family=resolvePresentationFont({fontFamily:'Arial'});
const data=JSON.parse(await fs.readFile(ROOT+'/docs/sensibilidad_complementaria_20261014/analysis_summary.json','utf8'));
const morris=JSON.parse(await fs.readFile(ROOT+'/docs/sensibilidad_morris_20261006/report_data.json','utf8'));
const oldFig=ROOT+'/postprocessing/tecplot_20261007/figures/';
const newFig=ROOT+'/docs/sensibilidad_complementaria_20261014/figures/';
const newSource=ROOT+'/docs/sensibilidad_complementaria_20261014/analysis_summary.json';
const oldSource=ROOT+'/docs/sensibilidad_morris_20261006/report_data.json';
const presentation=Presentation.create({slideSize:{width:1280,height:720}});
const tables=[];let index=0;
function txt(s,value,x,y,w,h,size=32,bold=false,color='#151515'){
 const sh=s.shapes.add({geometry:'textbox',position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});
 sh.text=value;sh.text.style={typeface:family,fontSize:size,bold,color,autoFit:'none',verticalAlignment:'top',lineSpacing:1.12,insets:{left:0,right:0,top:0,bottom:0}};return sh;
}
function slide(title,notes='',sources=[]){
 const s=presentation.slides.add();s.background.fill='#FFFFFF';index++;
 txt(s,title,64,36,1152,88,44,true);
 txt(s,String(index).padStart(2,'0'),1195,678,40,26,18,false,'#777777');
 s.speakerNotes.textFrame.setText(notes+'\n\nFuentes:\n'+sources.join('\n'));
 return s;
}
async function image(s,p,y=142,h=490){
 s.images.add({blob:new Uint8Array(await fs.readFile(p)),contentType:'image/png',alt:path.basename(p,'.png'),fit:'contain',position:{left:64,top:y,width:1152,height:h}});
}
function caption(s,t,y=631){txt(s,t,68,y,1120,46,24,false,'#444444');}
function table(s,values,widths,{x=64,y=158,w=1152,h=370,size=28}={}){
 const t=s.tables.add({rows:values.length,columns:values[0].length,left:x,top:y,width:w,height:h,columnWidths:widths,values});
 t.borders.assign({style:'solid',fill:'#d2d2d2',width:.8});
 for(let r=0;r<values.length;r++)for(let c=0;c<values[0].length;c++){
  const ce=t.getCell(r,c);ce.fill=r===0?'#eeeeee':'#ffffff';ce.text.style={typeface:family,fontSize:size,bold:r===0,color:'#151515',autoFit:'none',verticalAlignment:'middle'};
 }
 tables.push(index);return t;
}
function paragraphs(s,items,{x=72,y=164,w=1110,step=112,size=32}={}){
 items.forEach((v,i)=>txt(s,v,x,y+i*step,w,step-18,size));
}
const n=v=>Number(v).toFixed(3),pct=v=>Number(v).toFixed(2)+' %';

{
 const s=presentation.slides.add();s.background.fill='#FFFFFF';index++;
 txt(s,'Sensibilidad del aerogenerador',70,170,1100,100,60,true);
 txt(s,'Método, resultados y comprobación de efectos combinados',74,288,1090,112,38);
 txt(s,'Nicolás Andrés Useche Castillo',74,472,1060,42,30);
 txt(s,'Actualización del 14 de octubre de 2026',74,536,1090,38,28,false,'#555555');
 s.speakerNotes.textFrame.setText('Presentación para discusión de tesis. Resultados deterministas del modelo existente a azimut congelado. Morris del 6 de octubre y comprobación complementaria del 14 de octubre de 2026.');
}
{
 const s=slide('Pregunta y alcance del estudio','La pregunta compara la influencia de propiedades de palas y velocidad en respuestas modales. La superficie de la turbina es ilustrativa. La malla del solver es de vigas y cuerpos rígidos. Se conserva el eje real 129–130 y la orientación nominal.',[oldSource,ROOT+'/postprocessing/tecplot_20261007/catalog.json']);
 s.images.add({blob:new Uint8Array(await fs.readFile(oldFig+'turbina_3d.png')),contentType:'image/png',alt:'Modelo del aerogenerador generado en Tecplot',fit:'contain',position:{left:55,top:144,width:605,height:475}});
 txt(s,'Influencia de masa/inercia, rigidez de palas y velocidad del rotor',690,166,510,134,34,true);
 txt(s,'Cada escenario recalcula el equilibrio y las propiedades modales',690,330,510,122,32);
 txt(s,'Giro prescrito, azimut congelado y espectro parcial',690,489,510,112,30);
}
{
 const s=slide('Parámetros y dominio exploratorio','Los factores de masa escalan masa por longitud e inercias de todas las palas a geometría fija. La rigidez escala conjuntamente EA, GAy, GAz, GJ, EIy y EIz. El factor de velocidad multiplica 12 rpm. Los rangos son escenarios aprobados, no incertidumbres medidas.',[ROOT+'/+sensitivity/apply_parameters.m',ROOT+'/+sensitivity/config_morris.m']);
 table(s,[['Factor','Propiedades que cambian','Intervalo'],['Masa/inercia','Masa e inercias de las tres palas','0.90–1.10'],['Rigidez','Seis rigideces seccionales de palas','0.90–1.10'],['Velocidad','Velocidad angular prescrita','10.8–13.2 rpm']],[244,628,280],{h:330,size:29});
 paragraphs(s,['Nominal de los factores: 1.00','Geometría y restantes parámetros físicos: valores existentes'],{y:535,step:57,size:28});
}
{
 const s=slide('Respuestas modales','Se utiliza q proporcional a phi exp(lambda t), frecuencia amortiguada y crecimiento real. D incluye amortiguamiento, giroscopía y transporte. La frecuencia no informa por sí sola la estabilidad.',[ROOT+'/+sensitivity/summarize_morris.m']);
 table(s,[['Respuesta','Definición','Interpretación'],['Frecuencia','f = |Im λ| / (2π) [Hz]','Oscilaciones por segundo'],['Crecimiento','γ = Re λ [s⁻¹]','Evolución de la amplitud'],['Amortiguamiento','ζ = −Re λ / |λ|','Decaimiento relativo']],[265,427,460],{h:348,size:29});
 txt(s,'La forma modal describe el patrón de movimiento acoplado',72,552,1120,78,32,true);
}
{
 const s=slide('Grupos seguidos por sus formas','Los números son ramas de la referencia. Los grupos se construyen por proximidad de raíces en el dominio y seguimiento de subespacios. Su respuesta es una media de frecuencias, no un autovector promedio. La identidad no se redefine ordenando frecuencias en cada caso.',[oldSource,ROOT+'/+sensitivity/track_modes.m']);
 table(s,[['Grupo','f nominal [Hz]','Mayor influencia Morris','Estado'],['1+2','0.158','Ninguna aceptada','Ruido'],['3','0.231','Masa/inercia','Aceptado'],['4+5','0.409','Masa/inercia','Giro no resuelto'],['6+7','0.587','Velocidad','Aceptado'],['8+9','0.844','Masa/inercia','Aceptado'],['10+11','1.225','Masa/inercia','Aceptado'],['12','1.595','Sin estimadores','Frontera espectral']],[135,230,443,344],{y:143,h:425,size:26});
 caption(s,'10+11 reúne dos ramas. La respuesta del grupo es su frecuencia media',592);
}
{
 const s=slide('Etapas del análisis','Las 99 evaluaciones iniciales incluyen varias campañas locales y de verificación. El Morris tiene 170 evaluaciones. La nueva etapa reutiliza 58 puntos distintos y añade 6 puntos y 3 controles, sin modificar intervalos ni rutinas físicas. No se interpretan refinamiento de malla ni paso temporal como parámetros inciertos.',[ROOT+'/docs/sensibilidad_20261005/LEEME.md',oldSource,newSource]);
 table(s,[['Etapa','Qué se estudia','Evidencia'],['Sensibilidad local','8 factores, pasos 2 %, 1 % y 0.5 %','Diferencias centrales'],['Morris','3 factores dentro de ±10 %','40 trayectorias, 170 evaluaciones'],['Comprobación actual','Rejilla completa de 4³ puntos','6 puntos y 3 controles nuevos']],[286,483,383],{h:367,size:28});
 txt(s,'La campaña Morris original conserva sus estimadores y sus registros',72,570,1100,76,30);
}
{
 const s=slide('Una trayectoria cambia un factor por segmento','Primera trayectoria real. Las coordenadas del diseño recorren cuatro niveles. Cada tramo conserva los otros dos factores. El paso normalizado es 2/3 y el paso del factor físico es 0.13333. Los segmentos representan escenarios independientes, no tiempo.',[ROOT+'/runs/sensitivity/morris_20261006/morris_vertices.csv']);
 await image(s,newFig+'trayectoria_legible.png',142,482);
 caption(s,'40 trayectorias producen 40 efectos elementales por factor y respuesta');
}
{
 const s=slide('Indicadores de Morris','Morris 1991 emplea media y desviación estándar de efectos elementales. Campolongo et al. 2007 presentan mu estrella para evitar cancelación de signos. Los filtros adicionales de ruido, seguimiento y prefijos son decisiones de implementación.',['https://stat.cmu.edu/technometrics/90-00/vol-33-02/v3302161.pdf','https://doi.org/10.1016/j.envsoft.2006.10.004',ROOT+'/+sensitivity/morris_statistics.m']);
 table(s,[['Indicador','Qué resume','Cómo se interpreta'],['μ','Media con signo','Dirección media del efecto'],['μ*','Media de valores absolutos','Magnitud media de influencia'],['σ','Dispersión de efectos','Variación según la posición del dominio']],[190,444,518],{h:354,size:29});
 txt(s,'σ puede combinar curvatura e interacción entre factores',72,553,1120,70,32,true);
}
{
 const s=slide('Masa y rigidez tienen sentidos opuestos','Estimadores originales de Morris divididos por el ancho físico 0.20. Círculos masa, diamantes rigidez y cuadrados velocidad. Marcador lleno aceptado, vacío no resuelto. Grupo 12 excluido. No se reinterpretan los símbolos vacíos como cero.',[oldSource,ROOT+'/docs/sensibilidad_complementaria_20261014/figure_catalog.json']);
 await image(s,newFig+'influencia_firmada_grupos.png',132,501);
 caption(s,'El giro reduce la frecuencia de 3 y aumenta las de 6+7, 8+9 y 10+11');
}
{
 const s=slide('Estabilización de la influencia media','Prefijos 10, 20 y 40 del mismo diseño, con el mismo agrupamiento final. Cambio máximo de mu estrella de 20 a 40 entre las 14 influencias aceptadas: 0.796225 %. Umbral de prefijos 10 %. No es convergencia espacial ni garantía asintótica.',[oldSource,ROOT+'/runs/sensitivity/morris_20261006/morris_estimators.csv']);
 await image(s,newFig+'convergencia_legible.png',133,492);
 caption(s,'14 influencias aceptadas. Cambio máximo de 20 a 40: 0.80 %');
}
{
 const s=slide('Resolución frente al ruido numérico','La media absoluta debe superar diez veces su envolvente empírica. Los índices de la figura se explican debajo. Repetición, QEP estricto y directo frente a continuación proporcionan la envolvente, que no es una cota rigurosa del error en todo el dominio.',[ROOT+'/runs/sensitivity/morris_20261006/morris_noise.csv',oldSource]);
 await image(s,newFig+'ruido_legible.png',127,473);
 caption(s,'Las tres influencias de 10+11 superan ampliamente el filtro de ruido');
}
{
 const s=slide('Dispersión de efectos en el grupo 10+11','Dos indicadores de dispersión de frecuencia aceptados en la campaña Morris: masa y rigidez en 10+11. Los criterios se aplican a sigma por separado de mu estrella. La velocidad no supera ruido ni cambio de prefijos. La dispersión describe los efectos elementales, no la distribución física de frecuencias.',[oldSource]);
 table(s,[['Factor','σ','σ / bσ','Cambio 20–40','Estado'],['Masa/inercia','0.00445','20.52','6.31 %','Aceptada'],['Rigidez','0.00283','13.07','8.22 %','Aceptada'],['Velocidad','0.00173','7.97','14.94 %','No resuelta']],[330,185,180,247,210],{h:335,size:28});
 txt(s,'La dispersión motivó comprobar curvatura y efectos combinados',72,554,1120,87,31,true);
}
{
 const s=slide('Participación predominante de palas en 10 y 11','Participaciones cuadráticas de masa y rigidez elástica nominal. No son una descomposición de toda la energía rotacional. Esta evidencia independiente respalda sensibilidad a propiedades de palas, sin convertir los modos en movimientos aislados de un componente.',[ROOT+'/runs/sensitivity/initial_20261005/local/modal_energy_evidence.csv']);
 await image(s,newFig+'participaciones_legibles.png',132,490);
 caption(s,'Las participaciones de referencia respaldan la interpretación mecánica');
}
{
 const s=slide('Magnitudes orientativas para el grupo 10+11','Se calcula delta f aproximadamente f0 multiplicado por mu/0.20 y por delta del factor. Son secantes medias del dominio, no derivadas locales certificadas ni evaluaciones nuevas de factores al 1 %. Frecuencia nominal del grupo 1.2254297847 Hz.',[oldSource]);
 table(s,[['Factor que aumenta 1 %','Cambio relativo de f','Cambio [Hz]'],['Masa/inercia','−0.383 %','−0.00469'],['Rigidez','+0.359 %','+0.00439'],['Velocidad','+0.184 %','+0.00225']],[510,352,290],{h:320,size:31});
 paragraphs(s,['Frecuencia nominal: 1.22543 Hz','Ejemplos basados en pendientes medias de secante'],{y:531,step:64,size:29});
}
{
 const s=slide('Comprobación sobre las 64 combinaciones','Se reutilizaron 58 combinaciones distintas de Morris. Se resolvieron 6 faltantes, QEP estricto y continuación en un nuevo punto, y una repetición nominal. Los nueve casos convergieron. Costo de solve 77.485 s, con límite operacional de 300 s. Se verificaron 175 huellas de fuente sin cambios.',[newSource,ROOT+'/runs/sensitivity/grid_completion_20261014/case_status.csv']);
 table(s,[['Componente','Cantidad'],['Puntos existentes reutilizados','58'],['Puntos faltantes resueltos','6'],['Controles nuevos','3'],['Combinaciones de la rejilla completa','64']],[818,334],{h:355,size:31});
 txt(s,'Los grupos originales se mantienen. La rama 12 sigue excluida',72,558,1120,82,31,true);
}
{
 const s=slide('Intervalos observados en la rejilla completa','Mínimos y máximos calculados entre los 64 puntos. No son cuantiles, intervalos de confianza ni extremos certificados del dominio continuo. Las combinaciones modifican simultáneamente los tres factores.',[newSource]);
 const rs=data.frequencyRanges.filter(r=>r.allGridVerticesValid);
 table(s,[['Grupo','Nominal [Hz]','Mínimo [Hz]','Máximo [Hz]'],...rs.map(r=>[r.group,n(r.nominalFrequencyHz),n(r.minimumHz),n(r.maximumHz)])],[196,319,319,318],{h:382,size:30});
 caption(s,'Los intervalos describen escenarios calculados dentro de los rangos aprobados',590);
}
{
 const s=slide('Compensación parcial entre masa y rigidez','Se toman las cuatro combinaciones diagonales xi_rho=xi_K a cada una de las cuatro velocidades. Cada curva usa como origen su propia frecuencia al factor 0.90. La variación normalizada por f0 queda entre 0.404 y 0.423 %, mientras las entradas abarcan 0.90 a 1.10. No establece una ley de compensación universal ni una identificación única.',[newSource,ROOT+'/docs/sensibilidad_complementaria_20261014/equal_factor_compensation.csv']);
 await image(s,newFig+'compensacion_rejilla.png',137,476);
 caption(s,'Variación diagonal: 0.40–0.42 % de f₀ entre factores iguales 0.90 y 1.10');
}
{
 const s=slide('Contraste de efectos combinados','Contraste rectangular en los extremos de los factores i,j, con el tercero fijo. Si f es aditiva en estos dos factores, el contraste es cero aunque exista curvatura individual. Un contraste resuelto demuestra no aditividad en esos puntos y respuesta, sin atribuir un término concreto del operador. Se propaga la envolvente como b=4 eta y se exige |I| >=10b.',[newSource]);
 txt(s,'Iᵢⱼ = f₊₊ − f₊₋ − f₋₊ + f₋₋',82,152,1100,90,44,true);
 table(s,[['Par en 10+11','|I| [Hz]','Señal / b','Lectura'],['Masa–rigidez','0.00926–0.00940','26.5–26.9','Supera el umbral'],['Masa–velocidad','0.00356–0.00362','10.2–10.3','Apenas sobre el umbral'],['Rigidez–velocidad','0.00331–0.00342','9.5–9.8','No resuelto']],[390,292,215,255],{y:280,h:283,size:26});
 caption(s,'Umbral empírico: 10. Cada par se examina con cuatro valores del tercer factor',602);
}
{
 const s=slide('Efectos combinados del grupo 10+11','Las líneas describen cuatro contrastes calculados para cada par. El eje horizontal indica el factor que permanece fijo, distinto entre curvas. Puntos llenos superan la puerta de ruido; vacíos no. El par masa–velocidad es marginal y depende de la envolvente empírica. La escala es porcentaje de f0, no porcentaje de varianza explicada.',[newSource,ROOT+'/docs/sensibilidad_complementaria_20261014/mixed_contrasts.csv']);
 await image(s,newFig+'contrastes_interaccion.png',129,492);
 caption(s,'Masa–rigidez: −0.756 a −0.767 % de f₀, con contraste resuelto');
}
{
 const s=slide('Conclusiones respaldadas','La clasificación de dominancia se limita a tres factores y dominio ±10 %. Los signos detallados se refieren a estimadores originales aceptados. La rejilla conserva la clasificación por magnitud de las secantes de extremo para los cinco grupos principales. La interacción masa-rigidez se demuestra por contraste finito en 10+11 y cuatro velocidades, con la envolvente empírica declarada.',[oldSource,newSource]);
 paragraphs(s,[
 'Masa/inercia domina 3, 4+5, 8+9 y 10+11 entre los tres factores',
 'Velocidad domina 6+7 y su efecto cambia de signo según el grupo',
 'Masa y rigidez pueden compensar parcialmente una frecuencia',
 '10+11 presenta un contraste masa–rigidez numéricamente resuelto'
 ],{y:151,step:115,size:33});
}
{
 const s=slide('Límites de interpretación','La envolvente procede de controles concretos, no de una prueba rigurosa del error de todo el dominio. La convergencia de malla previa corresponde al rotor detenido. El módulo de refinamiento actual no permite rotor girando; no se alteró esa limitación. Las raíces retornadas tienen parte real negativa pero el espectro y análisis congelados no prueban estabilidad de todo el ciclo.',[ROOT+'/+sensitivity/evaluate_case.m',newSource,oldSource]);
 paragraphs(s,[
 'Los rangos de entrada son escenarios exploratorios',
 'El análisis representa un azimut fijo y un espectro parcial',
 'La convergencia espacial en operación sigue pendiente',
 'Los resultados requieren contraste experimental para validación'
 ],{y:160,step:110,size:33});
}
{
 const s=slide('Decisiones para la siguiente etapa','Las propuestas son decisiones científicas pendientes, no campañas ejecutadas. Para estabilidad periódica se requiere un análisis adecuado al sistema periódico. Las propiedades del conjunto existente no equivalen a una turbina comercial calibrada. Cambiar el número de ramas permite estudiar el cierre espectral, pero debe verificarse identidad y costo.',[ROOT+'/docs/sensibilidad_morris_20261006/SECCION_MORRIS_REVISION.tex',newSource]);
 paragraphs(s,[
 'Justificar rangos físicos con fuentes o mediciones',
 'Verificar frecuencias y sensibilidades con refinamiento en operación',
 'Contrastar varias respuestas para identificar masa y rigidez',
 'Acordar el alcance de las afirmaciones sobre estabilidad'
 ],{y:158,step:111,size:33});
}
{
 const s=slide('Apéndice: curvatura individual y ruido','C=f(next)-2f(center)+f(previous) a pasos iguales. En 10+11 se resolvieron 6 de 32 contrastes de masa/inercia. Los otros contrastes no superaron diez veces 4eta. No se concluye linealidad a partir de ausencia de resolución. Estas diferencias no separan curvatura de todos los órdenes ni establecen monotonicidad continua.',[ROOT+'/docs/sensibilidad_complementaria_20261014/pure_curvature.csv']);
 txt(s,'Cᵢ = fᵢ₊₁ − 2fᵢ + fᵢ₋₁',82,150,1090,80,42,true);
 table(s,[['Factor, grupo 10+11','Contrastes','Superan el umbral'],['Masa/inercia','32','6'],['Rigidez','32','0'],['Velocidad','32','0']],[550,252,350],{y:277,h:284,size:30});
 caption(s,'Ausencia de resolución permite conservar la limitación sobre curvatura',602);
}
{
 const s=slide('Apéndice: residuos y controles','Residuos máximos sobre la rejilla de 64 puntos. La norma dual de masa escala fuerzas y momentos. Se verificó grupo cerrado y métricas de seguimiento con ref de masa nominal. Las 17 pruebas del módulo y regresión 155/155 son evidencia histórica, no pruebas ejecutadas hoy. Hoy se verifican los 9 casos y los 175 hashes del código existente.',[newSource,ROOT+'/runs/sensitivity/grid_completion_20261014/grid_residuals.csv']);
 table(s,[['Comprobación','Resultado'],['Residuo de equilibrio máximo','9.94 × 10⁻⁹'],['Residuo QEP dual de masa máximo','4.05 × 10⁻⁹'],['Residuo derecho máximo','4.93 × 10⁻¹⁶'],['Residuo izquierdo máximo','3.57 × 10⁻¹⁴'],['Huellas de fuentes verificadas','175 sin cambios']],[795,357],{h:402,size:29});
 caption(s,'Controles nuevos: repetición nominal, QEP estricto y continuación',602);
}
{
 const s=slide('Apéndice: comparación de secantes','Se comparan mu/0.20 de Morris y media de secantes entre extremos 0.90 y 1.10 en las 16 combinaciones del resto de factores. Los pasos y las ponderaciones son distintos, por lo que no se exige igualdad numérica. Son medias descriptivas de un diseño definido, sin interpretación probabilística física.',[oldSource,newSource]);
 const gs=['3','4+5','6+7','8+9','10+11'];const ps=['blade_density','blade_stiffness','rotor_speed'];
 const vals=gs.map(g=>[g,...ps.map(p=>{
  const a=morris.statistics.find(r=>r.response==='frequency'&&r.group===g&&r.parameter===p);
  const b=data.endpointSlopes.find(r=>r.group===g&&r.parameter===p);
  return (a.acceptedMean?(a.mu/.20).toFixed(3):'No resuelto')+' / '+b.meanNormalizedSlope.toFixed(3);
 })]);
 table(s,[['Grupo','Masa/inercia','Rigidez','Velocidad'],...vals],[160,330,300,362],{h:365,size:27});
 caption(s,'Cada celda: Morris / secante de extremos. El grupo 4+5 conserva su reserva',590);
}
{
 const s=slide('Referencias y datos reproducibles','Las referencias respaldan el método de cribado y la extensión mu estrella. Datos de sensibilidad en el solver existente, carpetas initial_20261005, morris_20261006 y grid_completion_20261014. Las figuras anteriores vienen de Tecplot 2025 R2. El usuario autorizó generar nuevas figuras monocromáticas con otro motor ante la licencia expirada. Los nuevos gráficos identifican su motor en figure_catalog.json.',[
 'https://doi.org/10.1080/00401706.1991.10484804','https://doi.org/10.1016/j.envsoft.2006.10.004',newSource,oldSource]);
 paragraphs(s,[
 'Morris (1991)\nFactorial Sampling Plans for Preliminary Computational Experiments',
 'Campolongo, Cariboni y Saltelli (2007)\nAn effective screening design for sensitivity analysis of large models',
 'Datos, configuraciones y aceptación\nCampañas local, Morris y rejilla complementaria del proyecto'
 ],{y:156,step:151,size:31});
}

await fs.mkdir(WORK+'/.build/rendered',{recursive:true});
await fs.mkdir(WORK+'/entrega',{recursive:true});
await fs.writeFile(WORK+'/.build/presentation.json',JSON.stringify(presentation.toProto()));
for(let i=0;i<presentation.slides.items.length;i++){
 const s=presentation.slides.items[i];
 const b=await presentation.export({slide:s,format:'png',scale:1});
 await fs.writeFile(WORK+'/.build/rendered/slide-'+String(i+1).padStart(2,'0')+'.png',new Uint8Array(await b.arrayBuffer()));
 const layout=await s.export({format:'layout'});
 await fs.writeFile(WORK+'/.build/rendered/slide-'+String(i+1).padStart(2,'0')+'.json',await layout.text());
}
const candidate=WORK+'/.build/candidate_v5.pptx';
await(await PresentationFile.exportPptx(presentation)).save(candidate);
const finalPath=WORK+'/entrega/Sensibilidad_aerogenerador_20261014.pptx';
const result=await finalizePresentation({workspaceDir:WORK,candidatePath:candidate,finalPath,
 pythonExecutable:RUNTIME+'/python/bin/python3',
 integrityValidatorPath:SKILL+'/container_tools/inspect_presentation_package_integrity.py',
 layoutValidatorPath:SKILL+'/container_tools/inspect_presentation_layout_geometry.py',
 layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-bullet-geometry','--validate-heading-fit',...tables.flatMap(n=>['--require-native-table-slide',String(n)])],
 requiredNativeTableOwnerSlides:tables,fontPolicy:{basis:'design',families:[family]},verifyArtifactToolImport:true,
 receiptPath:WORK+'/.build/validation_v5.json'});
await fs.writeFile(WORK+'/.build/build_result.json',JSON.stringify({slides:index,font:family,nativeTableSlides:tables,finalPath,result},null,2));
console.log(JSON.stringify({slides:index,font:family,nativeTableSlides:tables,finalPath}));
