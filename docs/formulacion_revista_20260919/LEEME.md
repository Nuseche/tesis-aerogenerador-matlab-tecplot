# Artículo de formulación matemática · revisión del 8 de octubre de 2026

Las ediciones española e inglesa contienen la misma formulación ampliada, tres apéndices, diez referencias bibliográficas y once figuras explicativas originales generadas en Tecplot. El alcance es matemático; las campañas y sus resultados pertenecen a otros documentos del proyecto.

## Figuras y procedencia de la revisión

Se recuperó como base la versión española ampliada que estaba en `output/latex/FCEFyN_Overleaf/FCEFyN_ES.tex`. Sus nueve temas gráficos se conservaron y se añadieron dos vistas independientes para explicar el giro nominal y el cortante de Timoshenko. La versión inglesa se alineó con este contenido. Se preservaron los 84 bloques de ecuaciones de la fuente ampliada.

Las figuras muestran el modelo del aerogenerador, el cambio de componentes, los sistemas globales, el giro nominal del cubo, los triedros de las raíces, la partícula y la sección de viga, el cortante, las tres configuraciones, la masa seccional, la orientación del elemento y la compatibilidad raíz–cubo. Sus símbolos corresponden a los del texto. Los títulos y pies se definen en LaTeX, fuera de las imágenes.

Las superficies son ilustrativas; la malla física sigue siendo de vigas. El solver y los resultados almacenados no se modificaron. Las escenas nativas de Tecplot con transparencias se incluyen como PDF con el PNG nativo comprimido sin pérdidas. Las opciones `trim` de LaTeX retiran únicamente el margen blanco del marco exportado.

## Compilación verificada

Desde esta carpeta:

```sh
tectonic FCEFyN_ES.tex
tectonic FCEFyN_EN.tex
```

Para Overleaf, importar el ZIP completo, conservar las carpetas, elegir `FCEFyN_ES.tex` o `FCEFyN_EN.tex` como documento principal y seleccionar XeLaTeX en modo normal. Se verificó localmente con Tectonic (XeTeX); esta revisión no se subió a una cuenta de Overleaf.

Se necesitan `FCEFyN-class.cls`, `Referencias.bib`, `filesFCEFyN-class/` y los once PDF de `figures/tecplot/`. La clase, los estilos y el logotipo editoriales se conservan. También se conservan los seis autores, su orden, las filiaciones y los campos editoriales sin asignar.

## Fuentes y regeneración

La fuente canónica editable está en `/Users/nuseche/Desktop/Tesis_codigos/docs/formulacion_revista_20260919/`. Sus archivos principales incluyen `cuerpo_es.tex` y `cuerpo_en.tex`. Las distribuciones de `output/latex/FCEFyN_Formulacion_Bilingue/` y `output/latex/FCEFyN_Overleaf/` incorporan el cuerpo directamente en cada archivo principal.

La biblioteca y la automatización están en `/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/`. `scripts/paper_variants.py` genera las variantes de notación del artículo; `scripts/regenerate.py --export-only` ejecuta las macros de Tecplot con una licencia vigente. `scripts/reconcile_paper.py` documenta la recuperación inicial de la fuente ampliada. Para distribuir futuras ediciones manuales de los cuerpos, usar su función `synchronize()`; no volver a ejecutar la recuperación inicial sobre cambios posteriores sin revisarlos.

La copia anterior a esta reconciliación permanece en `archive/paper_before_figure_reconciliation_20261008.zip` de la biblioteca. Los controles de contenido, compilación y revisión de páginas se encuentran en `reports/paper_content_checks.json`, `reports/document_checks.json` y `reports/paper_visual_pages.json`.
