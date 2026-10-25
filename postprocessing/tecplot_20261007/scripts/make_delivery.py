"""Package and describe verified native Tecplot products, not simulation data."""
from common import *
from html import escape
import zipfile
from collections import Counter

def gallery(catalog):
    data=json.dumps(catalog,ensure_ascii=False).replace('<','\\u003c')
    html=r'''<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Figuras del proyecto · Tecplot</title><style>
*{box-sizing:border-box}body{margin:0;background:#f4f4f4;color:#161616;font:16px/1.5 system-ui,sans-serif}header,main{max-width:1360px;margin:auto;padding:30px}header{padding-bottom:10px}h1{font-size:30px;font-weight:600;line-height:1.2}p{max-width:90ch}input,select,button{font:inherit;padding:10px 14px;border:1px solid #999;border-radius:5px;background:white;color:black}input{min-width:260px;flex:1}nav{display:flex;gap:14px;flex-wrap:wrap;margin:20px 0}a{color:#111;text-underline-offset:4px}#grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,540px),1fr));gap:24px}article{padding:20px;background:white;border:1px solid #d0d0d0;border-radius:8px}article h2{font-size:18px;margin:0 0 12px;font-weight:600}.visual{border:0;padding:0;display:block;width:100%;cursor:zoom-in}.visual img{width:100%;height:340px;object-fit:contain;background:white}.links{display:flex;flex-wrap:wrap;gap:18px;margin:16px 0}.small,summary{font-size:14px;color:#444}summary{cursor:pointer}details p{font-size:14px;overflow-wrap:anywhere}dialog{width:min(96vw,1500px);max-height:96vh;padding:24px;border:1px solid #666;border-radius:8px}dialog::backdrop{background:#000a}dialog img{display:block;width:100%;max-height:76vh;object-fit:contain}dialog .top{display:flex;justify-content:space-between;align-items:center;gap:15px;margin-bottom:12px}dialog h2{font-size:18px;margin:0}.counts{color:#555}footer{max-width:1360px;margin:auto;padding:30px}.badge{font-size:13px;color:#555;margin-bottom:12px}
</style><header><h1>Figuras del proyecto</h1><p>Ilustraciones espaciales, malla de vigas y resultados almacenados. Dibujos nuevos en escala de grises, generados en Tecplot. Las descripciones aparecen fuera de las imágenes. Pulsa una figura para ampliarla.</p><nav><input id="search" aria-label="Buscar figura" placeholder="Buscar por tema o identificador"><select id="category" aria-label="Filtrar representación"><option value="">Todas las representaciones</option></select></nav><p id="count" class="counts"></p></header><main id="grid"></main><footer><a href="README.md">Regeneración y formatos</a> · <a href="reports/INFORME_FINAL.md">Comprobaciones y alcance</a> · <a href="catalog.json">Catálogo completo</a></footer><dialog id="lightbox"><div class="top"><h2 id="dialogtitle"></h2><button id="close" aria-label="Cerrar ampliación">Cerrar</button></div><img id="large" alt=""></dialog><script>
const catalog=__DATA__;const names={conceptual_spatial_mechanics:'Mecánica espacial · esquema',computational_beam_mesh:'Malla computacional de vigas',result:'Resultados almacenados',conceptual:'Flujo de procesamiento',deformed_beam_mesh:'Deformada o modo individual',exploratory_design:'Diseño exploratorio',illustrative_3D_envelope_with_actual_1D_mesh:'Turbina 3D con vigas interiores'};const grid=document.querySelector('#grid'),search=document.querySelector('#search'),category=document.querySelector('#category'),dialog=document.querySelector('#lightbox');
function element(tag,text,cls){const e=document.createElement(tag);if(text)e.textContent=text;if(cls)e.className=cls;return e}
Object.keys(names).forEach(k=>{const o=element('option',names[k]);o.value=k;category.append(o)});
function draw(){const term=search.value.toLocaleLowerCase();const items=catalog.filter(r=>(!category.value||r.representation===category.value)&&(!term||(r.id+' '+r.purpose).toLocaleLowerCase().includes(term)));document.querySelector('#count').textContent=items.length+' de '+catalog.length+' figuras';grid.replaceChildren();for(const r of items){const card=element('article');card.append(element('h2',r.purpose),element('div',names[r.representation]||r.representation,'badge'));const button=element('button',null,'visual');button.setAttribute('aria-label','Ampliar '+r.purpose);const img=element('img');img.src='figures/'+r.id+'.png';img.alt=r.purpose;img.loading='lazy';button.append(img);button.onclick=()=>{document.querySelector('#large').src=img.src;document.querySelector('#large').alt=img.alt;document.querySelector('#dialogtitle').textContent=r.purpose;dialog.showModal()};card.append(button);const links=element('div',null,'links');for(const [label,url] of [['PDF','figures/'+r.id+'.pdf'],['PNG','figures/'+r.id+'.png'],['Paquete Tecplot',r.package],['Datos',r.dataset],['Macro',r.macro]]){const link=element('a',label);link.href=url;links.append(link)}card.append(links);const detail=element('details');detail.append(element('summary','Fuente, unidades y uso en documentos'));detail.append(element('p','Unidades: '+JSON.stringify(r.units)));detail.append(element('p','Fuentes: '+r.sources.join(' · ')));detail.append(element('p','Configuración: '+JSON.stringify(r.configuration)));detail.append(element('p','Uso: '+(r.installed_in?.map(d=>d.document).join(' · ')||'Disponible en la biblioteca para documentos de resultados.')));detail.append(element('p',(r.notes||[]).join(' ')));if(r.publication_export?.EPS_limitation)detail.append(element('p',r.publication_export.EPS_limitation));card.append(detail,element('p',r.id,'small'));grid.append(card)}}search.oninput=draw;category.onchange=draw;document.querySelector('#close').onclick=()=>dialog.close();draw();</script></html>'''.replace('__DATA__',data)
    (HERE/'galeria.html').write_text(html)

def main():
    cat=json.loads((HERE/'catalog.json').read_text());checks=json.loads((HERE/'reports/final_checks.json').read_text());docs=json.loads((HERE/'reports/document_checks.json').read_text());visual=json.loads((HERE/'reports/document_visual_pages.json').read_text());portable=json.loads((HERE/'reports/portable_check.json').read_text())
    assert visual['status']=='visually_inspected',visual['status'];assert all(d['exit_code']==0 for d in docs)
    gallery(cat)
    readme=r'''# Biblioteca Tecplot del proyecto

__FIGURE_COUNT__ figuras vigentes; todos los píxeles de los PNG son exactamente grises (R=G=B). La galería permite buscar, ampliar y abrir el PDF, los datos y el paquete nativo de cada figura. Los dibujos anteriores se conservan en `archive/` y no forman parte de esta entrega.

## Regeneración en este proyecto

Desde `/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007`:

```sh
../../.venv-tecplot/bin/python scripts/regenerate.py
../../.venv-tecplot/bin/python scripts/integrate_documents.py
../../.venv-tecplot/bin/python scripts/verify_documents.py
../../.venv-tecplot/bin/python scripts/document_qa.py
../../.venv-tecplot/bin/python scripts/final_checks.py
```

`regenerate.py` convierte los MAT/CSV/JSON ya almacenados y ejecuta macros oficiales de Tecplot. No importa ni llama MATLAB, el ensamblador o el solver. `--prepare-only` conserva los datos y macros sin exportar; `--only concept_particula-seccion` limita la exportación a identificadores del catálogo.

## Regeneración desde el paquete independiente

El ZIP de figuras contiene los datos convertidos, macros y scripts. Con Python y las dependencias indicadas en `reports/python_requirements.txt`, y Tecplot con licencia válida:

```sh
python scripts/regenerate.py --export-only
```

Este comando ajusta las rutas de los macros a la carpeta extraída. No requiere los MAT originales ni el solver. Para otra instalación puede definirse `TESIS_TECPLOT` con la ruta al ejecutable. Una nueva conversión desde MAT requiere las fuentes originales del proyecto; sus rutas y huellas están en `catalog.json`.

La regeneración desde un paquete separado se ejecutó con la figura de sección de viga. El DAT permaneció idéntico y el macro sólo cambió sus rutas; se observaron diferencias mínimas de antialias, sin cambio de geometría, cámara o texto. El número exacto de píxeles y la tolerancia están en `reports/portable_check.json`. Los LPK incorporan los datos y se abren directamente en Tecplot.

## Exportaciones

- Gráficas y líneas de malla: EPS vectorial y PDF vectorial, con fuentes incrustadas y recorte del BoundingBox nativo.
- Escenas con transparencias: PNG de Tecplot de 4000 píxeles; turbina, 4200 píxeles. El PDF contiene estos mismos píxeles mediante compresión sin pérdidas. Esta conversión sólo crea un contenedor; no dibuja la figura con otro motor.
- Los EPS vectoriales de escenas transparentes se conservan como variantes nativas, pero vuelven opacas las superficies. Para publicación de esas escenas se debe usar el PDF o PNG entregado. Es una limitación documentada por Tecplot.
- No hay títulos ni pies dentro de las imágenes. Ejes, unidades, identificadores, símbolos de panel y leyendas forman parte de la figura cuando son necesarios. Las descripciones se mantienen en LaTeX.

## Fuentes, formatos y alcance

Cada figura tiene DAT, PLT binario, LAY, LPK, macro, PNG, EPS y PDF. El catálogo conserva fuentes, huellas SHA-256, unidades, configuración, limitaciones y referencias exactas a los documentos en que se instaló. `reports/installed_figures.json` lista las copias incluidas en LaTeX.

La instalación es Tecplot 360 EX 2025 R2, 2025.2.2.88532. La prueba activa observada vence el 13 de octubre de 2026. PyTecplot autónomo devolvió licencia caducada y la conexión requirió TecPLUS vigente; la vía verificada usa macros oficiales por lotes. No se cambió ni eludió la licencia.

Los proyectos LaTeX con imágenes externas se compilaron con Tectonic. El editor nativo se abrió, pero su compilador no pudo acceder a los PDF externos de este proyecto. Se mantuvieron las figuras y dependencias; registros completos en `logs/latex_*`.

La carpeta de tesis reúne la base de capítulos de formulación del proyecto. El artículo bilingüe conserva su alcance exclusivamente matemático. Las campañas y las figuras de resultados se mantienen en sus documentos correspondientes. Autoría y estructura se conservan.

## Criterios científicos

138 nodos y 133 vigas: 19 de torre, 105 de pala y 9 de transición. El eje real de giro conecta 129–130 y conserva la inclinación existente. Las cuatro conexiones heredadas de penalización tipo 3 se excluyen de la vista y se documentan como reemplazadas por la compatibilidad del modelo vigente. Ninguna superficie ilustrativa añade GDL, rigidez o masa al solver.

Las carcasas y los perfiles exteriores de pala son ilustrativos; no hay CAD ni perfiles aerodinámicos suficientes para reproducir una turbina comercial concreta. Los marcos de viga se calculan desde las coordenadas y los puntos auxiliares independientes.

Equilibrio corregido y campañas operativas de septiembre se distinguen del ROM histórico estacionario sin gravedad ni precarga. El análisis modal a azimut congelado no es Floquet. Los 16 modos complejos individuales se muestran en fases 0° y 90°, con máxima traslación compleja normalizada a 1 y amplificación de 10 m; la deformada de equilibrio usa factor 20. Nunca se promedian autovectores para crear un modo de grupo.

Sensibilidad local: 6 indicadores aceptados y 26 no resueltos, identificados mediante marcadores llenos y vacíos. Morris: 40 trayectorias, 160 vértices más 10 controles, 14 medias y 2 dispersiones aceptadas; grupo 12 excluido, sin estimador sustituido por cero. El dominio de frecuencia muestra 16 evaluaciones reales, sin interpolar respuestas. Estas campañas son exploratorias, no distribuciones de incertidumbre probabilística.

## Referencias consultadas

- Wasmer, P. y Betsch, P. (2024), *A projection-based quaternion discretization of the geometrically exact beam model*, IJNME 125(20), e7538. https://doi.org/10.1002/nme.7538. Se consultó su figura 1 para la composición de envolvente, línea de referencia, posición y directores. Los dibujos de esta biblioteca son originales; conservan el director 1 longitudinal del proyecto.
- Bir, G. S. (2008), *Multiblade Coordinate Transformation and Its Application to Wind Turbine Analysis*, NREL/CP-500-42553. https://www.nlr.gov/docs/fy08osti/42553.pdf. Referencia de transformaciones ya usada por el proyecto.
- Tecplot, *Translucency and Lighting*: https://tecplot.azureedge.net/products/360/current/help/users_manual/translucency.html. La exportación vectorial no conserva translucencia.
- Tecplot, *Exporting Images and Animations*: https://tecplot.com/2021/09/15/exporting-tecplot-images-and-animations/. PNG para las escenas 3D con transparencias y vectores para las gráficas.
'''
    (HERE/'README.md').write_text(readme.replace('__FIGURE_COUNT__',str(len(cat))))
    rows='\n'.join(f'| {Path(d["source"]).parent.name}/{Path(d["source"]).name} | {d["pages"]} | Correcta |' for d in docs)
    report=f'''# Registro final de la revisión gráfica

Fecha: 8 de octubre de 2026.\n\nSe sustituyeron completamente los 34 esquemas cinemáticos por construcciones espaciales originales en Tecplot, tomando como referencia la composición de Wasmer y Betsch. Se revisaron envolventes, secciones, directores, bases, vectores de posición, transporte y conexiones. La turbina conserva la malla interior real de vigas. Las {len(cat)} figuras de la biblioteca son monocromáticas, sin títulos o pies incorporados.

## Documentos comprobados

| Fuente | Páginas | Compilación |
|---|---:|---|
{rows}

Las {len(checks['equivalent_editions'])} parejas de versiones equivalentes tienen el mismo texto extraído de sus PDF. Se comprobaron {checks['installed_graphic_references']} inclusiones de figuras contra las huellas de la biblioteca. No quedan referencias bibliográficas o numeraciones indefinidas. Los registros conservan avisos menores de composición tipográfica que no recortan ni solapan el contenido.

## Comprobaciones

- {checks['protected_files_checked']} archivos protegidos del solver, propiedades y resultados permanecieron idénticos por SHA-256; cero campañas nuevas.
- Coordenadas y conectividad comprobadas contra la geometría guardada; 138 nodos y 133 vigas.
- Marcos ortonormales y dextrógiros; eje real 129–130 preservado. Residuos MPC de las formas individuales comprobados.
- {len(cat)} exportaciones nativas con archivos, dimensiones, páginas y huellas verificadas; los PNG tienen R=G=B en todos sus píxeles.
- {len(visual['page_renders'])} páginas renderizadas con Poppler e inspeccionadas, incluyendo las páginas con figuras y las comparaciones en su tamaño final. Montajes en `qa/documents/`; inspección de todas las figuras por separado en `qa/checked_*.png` y vistas ampliadas.
- Prueba independiente de regeneración desde DAT y macro, sin MAT ni solver: correcta. Datos idénticos y {portable['raster_changed_pixels']} píxeles de antialias distintos sobre 10.7 millones; delta medio de 8 bits {portable['raster_mean_absolute_delta_8bit']:.6g}.

## Correcciones de publicación

Se ampliaron y separaron paneles que quedaban pequeños. Se apartaron leyendas de los ejes, se preservaron los grises en la exportación vectorial y se eliminó el margen de página completo que reducía el dibujo en LaTeX. Las vistas 3D transparentes se incorporan mediante los PNG nativos sin pérdidas, porque EPS vuelve opacas las superficies y oculta vectores interiores.

La etiqueta de convergencia temporal se corrigió a desplazamiento global Y del nodo 129, conforme a los datos. Se restauraron dos archivos faltantes del manuscrito integrado (`resultados_operativos.tex` y `apendices.tex`) exclusivamente desde la evidencia persistida y la formulación existente. Se repararon sus referencias y dos desbordes de composición. La versión modular de capítulos se sincronizó con la autocontenida; las copias bilingües expandidas se sincronizaron con sus fuentes modulares.

## Reconciliación del artículo de formulación

Se recuperó el manuscrito español ampliado de Overleaf, que contenía nueve figuras y explicaciones ausentes en la copia compacta. Se conservaron sus 84 bloques matemáticos y se alineó la traducción inglesa. Ambas ediciones contienen once figuras: las nueve funciones explicativas originales y dos vistas adicionales para giro nominal y cortante. Todas son monocromáticas y sus pies se mantienen en LaTeX. La fuente canónica modular, las dos distribuciones autocontenidas y los PDF de salida están sincronizados. La versión anterior permanece en `archive/paper_before_figure_reconciliation_20261008.zip`. Comprobaciones en `reports/paper_reconciliation.json` y `reports/paper_visual_pages.json`.

## Alcance y pendientes concretos

Los perfiles exteriores y carcasas son ilustrativos. Reproducir una turbina comercial específica requiere CAD, perfiles, cuerda y distribución de torsión aerodinámica que no están disponibles. La prueba de Tecplot observada vence el 13 de octubre: futuras regeneraciones requieren una licencia vigente. Los operadores a azimut congelado no establecen estabilidad periódica; no se ejecutó un análisis Floquet para completar ese vacío. Los indicadores no resueltos y el grupo 12 excluido se conservan explícitamente.

La base de capítulos no se presenta como una tesis institucional terminada. El artículo de formulación sigue siendo matemático. No quedan pendientes de compilación, exportación o sustitución de las figuras de los documentos actuales enumerados arriba; los informes históricos inventariados se conservan como históricos.

Detalles reproducibles: `catalog.json`, `reports/final_checks.json`, `reports/numerical_checks.json`, `reports/kinematics_geometry_checks.json`, `reports/portable_check.json`, `reports/export_checks.json`, `reports/document_checks.json` y el inventario anterior en `reports/original_figure_inventory.json`.
'''
    (HERE/'reports/INFORME_FINAL.md').write_text(report)
    subprocess.run([sys.executable,'-m','pip','freeze'],stdout=(HERE/'reports/python_requirements.txt').open('w'),check=True)
    with zipfile.ZipFile(HERE/'packages/figuras_tecplot_y_automatizacion.zip','w',zipfile.ZIP_DEFLATED) as z:
        for r in cat:
            for rel in [r['dataset'],r['macro'],r['layout'],r['package'],*r['exports'],'data/'+r['id']+'.plt']:z.write(HERE/rel,rel)
        for folder in ['scripts','reports','logs']:
            for p in (HERE/folder).iterdir():
                if p.is_file() and p.name!='delivery_checks.json':z.write(p,str(p.relative_to(HERE)))
        for name in ['README.md','galeria.html','catalog.json']:z.write(HERE/name,name)
    with zipfile.ZipFile(HERE/'packages/documentos_actualizados.zip','w',zipfile.ZIP_DEFLATED) as z:
        seen=set()
        for d in docs:
            p=Path(d['source']);base=p.parent;prefix='tesis_capitulos' if base==THESIS else str(base.relative_to(ROOT))
            paths=[q for q in base.rglob('*') if q.is_file() and q.suffix in ['.tex','.cls','.bib','.bst','.md'] and not any(part.startswith('qa') or part in ['template','archive','figures'] for part in q.relative_to(base).parts)]
            paths += [Path(d['pdf'])]
            paths += [q for q in (base/'filesFCEFyN-class').glob('*.pdf')]
            paths += [q for q in base.rglob('*') if q.is_file() and q.suffix in ['.png','.jpg','.jpeg'] and not any(part.startswith('qa') or part in ['template','archive','figures','tecplot'] for part in q.relative_to(base).parts)]
            paths += [Path(r['installed_file']) for r in json.loads((HERE/'reports/installed_figures.json').read_text()) if r['document']==str(p)]
            for q in paths:
                name=prefix+'/'+str(q.relative_to(base))
                if name not in seen:z.write(q,name);seen.add(name)
        z.write(HERE/'reports/INFORME_FINAL.md','INFORME_FINAL.md')
    print('Gallery, report and two reproducible delivery ZIPs saved.')
if __name__=='__main__':
    import sys
    main()
