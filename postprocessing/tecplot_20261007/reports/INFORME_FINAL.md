# Registro final de la revisión gráfica

Fecha: 8 de octubre de 2026.

Se sustituyeron completamente los 34 esquemas cinemáticos por construcciones espaciales originales en Tecplot, tomando como referencia la composición de Wasmer y Betsch. Se revisaron envolventes, secciones, directores, bases, vectores de posición, transporte y conexiones. La turbina conserva la malla interior real de vigas. Las 124 figuras de la biblioteca son monocromáticas, sin títulos o pies incorporados.

## Documentos comprobados

| Fuente | Páginas | Compilación |
|---|---:|---|
| tesis_cinematica_20260929/tesis_autocontenida.tex | 81 | Correcta |
| tesis_cinematica_20260929/tesis_modelo.tex | 81 | Correcta |
| formulacion_revista_20260919/FCEFyN_ES.tex | 17 | Correcta |
| formulacion_revista_20260919/FCEFyN_EN.tex | 17 | Correcta |
| formulacion_matematica_20260919/FORMULACION_MATEMATICA.tex | 18 | Correcta |
| sensibilidad_morris_20261006/SECCION_MORRIS_REVISION.tex | 12 | Correcta |
| sensibilidad_20261005/SECCION_SENSIBILIDAD_REVISION.tex | 6 | Correcta |
| manuscrito_integrado_20260919/MANUSCRITO_INTEGRADO.tex | 30 | Correcta |
| FCEFyN_Formulacion_Bilingue/FCEFyN_ES.tex | 17 | Correcta |
| FCEFyN_Formulacion_Bilingue/FCEFyN_EN.tex | 17 | Correcta |
| FCEFyN_Overleaf/FCEFyN_ES.tex | 17 | Correcta |
| FCEFyN_Overleaf/FCEFyN_EN.tex | 17 | Correcta |

Las 5 parejas de versiones equivalentes tienen el mismo texto extraído de sus PDF. Se comprobaron 168 inclusiones de figuras contra las huellas de la biblioteca. No quedan referencias bibliográficas o numeraciones indefinidas. Los registros conservan avisos menores de composición tipográfica que no recortan ni solapan el contenido.

## Comprobaciones

- 428 archivos protegidos del solver, propiedades y resultados permanecieron idénticos por SHA-256; cero campañas nuevas.
- Coordenadas y conectividad comprobadas contra la geometría guardada; 138 nodos y 133 vigas.
- Marcos ortonormales y dextrógiros; eje real 129–130 preservado. Residuos MPC de las formas individuales comprobados.
- 124 exportaciones nativas con archivos, dimensiones, páginas y huellas verificadas; los PNG tienen R=G=B en todos sus píxeles.
- 90 páginas renderizadas con Poppler e inspeccionadas, incluyendo las páginas con figuras y las comparaciones en su tamaño final. Montajes en `qa/documents/`; inspección de todas las figuras por separado en `qa/checked_*.png` y vistas ampliadas.
- Prueba independiente de regeneración desde DAT y macro, sin MAT ni solver: correcta. Datos idénticos y 12 píxeles de antialias distintos sobre 10.7 millones; delta medio de 8 bits 4.086e-05.

## Correcciones de publicación

Se ampliaron y separaron paneles que quedaban pequeños. Se apartaron leyendas de los ejes, se preservaron los grises en la exportación vectorial y se eliminó el margen de página completo que reducía el dibujo en LaTeX. Las vistas 3D transparentes se incorporan mediante los PNG nativos sin pérdidas, porque EPS vuelve opacas las superficies y oculta vectores interiores.

La etiqueta de convergencia temporal se corrigió a desplazamiento global Y del nodo 129, conforme a los datos. Se restauraron dos archivos faltantes del manuscrito integrado (`resultados_operativos.tex` y `apendices.tex`) exclusivamente desde la evidencia persistida y la formulación existente. Se repararon sus referencias y dos desbordes de composición. La versión modular de capítulos se sincronizó con la autocontenida; las copias bilingües expandidas se sincronizaron con sus fuentes modulares.

## Reconciliación del artículo de formulación

Se recuperó el manuscrito español ampliado de Overleaf, que contenía nueve figuras y explicaciones ausentes en la copia compacta. Se conservaron sus 84 bloques matemáticos y se alineó la traducción inglesa. Ambas ediciones contienen once figuras: las nueve funciones explicativas originales y dos vistas adicionales para giro nominal y cortante. Todas son monocromáticas y sus pies se mantienen en LaTeX. La fuente canónica modular, las dos distribuciones autocontenidas y los PDF de salida están sincronizados. La versión anterior permanece en `archive/paper_before_figure_reconciliation_20261008.zip`. Comprobaciones en `reports/paper_reconciliation.json` y `reports/paper_visual_pages.json`.

## Alcance y pendientes concretos

Los perfiles exteriores y carcasas son ilustrativos. Reproducir una turbina comercial específica requiere CAD, perfiles, cuerda y distribución de torsión aerodinámica que no están disponibles. La prueba de Tecplot observada vence el 13 de octubre: futuras regeneraciones requieren una licencia vigente. Los operadores a azimut congelado no establecen estabilidad periódica; no se ejecutó un análisis Floquet para completar ese vacío. Los indicadores no resueltos y el grupo 12 excluido se conservan explícitamente.

La base de capítulos no se presenta como una tesis institucional terminada. El artículo de formulación sigue siendo matemático. No quedan pendientes de compilación, exportación o sustitución de las figuras de los documentos actuales enumerados arriba; los informes históricos inventariados se conservan como históricos.

Detalles reproducibles: `catalog.json`, `reports/final_checks.json`, `reports/numerical_checks.json`, `reports/kinematics_geometry_checks.json`, `reports/portable_check.json`, `reports/export_checks.json`, `reports/document_checks.json` y el inventario anterior en `reports/original_figure_inventory.json`.
