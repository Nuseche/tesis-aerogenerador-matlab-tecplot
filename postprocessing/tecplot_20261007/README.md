# Biblioteca Tecplot del proyecto

124 figuras vigentes; todos los píxeles de los PNG son exactamente grises (R=G=B). La galería permite buscar, ampliar y abrir el PDF, los datos y el paquete nativo de cada figura. Los dibujos anteriores se conservan en `archive/` y no forman parte de esta entrega.

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
