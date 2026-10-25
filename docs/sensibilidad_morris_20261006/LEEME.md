# Ejecución y reanudación de Morris

Caso aprobado: `cases/config_sensitivity_morris_approved.m`. La configuración separa el dominio exploratorio de las propiedades físicas originales. `cases/config_sensitivity_extended_pending.m` permanece como ficha histórica no ejecutable de la propuesta; no es la entrada de esta etapa.

```matlab
addpath('/Users/nuseche/Desktop/Tesis_codigos');
addpath('/Users/nuseche/Desktop/Tesis_codigos/cases');
folder='/Users/nuseche/Desktop/Tesis_codigos/runs/sensitivity/morris_20261006';
campaign=sensitivity.run_morris_study(folder,"2026-10-07 01:48:29");
```

La marca UTC representa el inicio de la preparación de la campaña del 6 de octubre, a las 20:48:29 de Bogotá. Es parte de la configuración guardada y del presupuesto. Repetir esta llamada con la misma versión reutiliza los MAT existentes, incluidos fallos; no vuelve a resolverlos. El cambio de configuración, código, datos o versión MATLAB impide reanudar la misma carpeta. No cambie el inicio para extender el presupuesto de la campaña original. Para una futura campaña con presupuesto autorizado, use una carpeta nueva y el inicio correspondiente.

`campaign.mat/json` contiene la semilla y todos los casos, de modo que el diseño es recuperable incluso si la ejecución se interrumpe antes de guardar `morris_design.mat`. El diseño también está en `morris_vertices.csv` y `morris_edges.csv`. El ejecutor deja estados pendientes al agotarse el presupuesto; la comprobación se hace antes de iniciar cada evaluación.

Los checkpoints a 10, 20 y 40 trayectorias se generan durante la ejecución. Para reanalizar los casos almacenados, sin nuevos solves:

```matlab
saved=load(fullfile(folder,'campaign.mat'),'campaign');
summary=sensitivity.summarize_morris(saved.campaign);
run('/Users/nuseche/Desktop/Tesis_codigos/docs/sensibilidad_morris_20261006/export_results.m');
```

Luego `python3 build_delivery.py` genera la discusión a partir de `report_data.json` y conserva los archivos LaTeX que ya existen. Solo crea la plantilla inicial si faltan; la opción explícita `--replace-latex` reemplaza la versión ilustrada por esa plantilla inicial. `python3 revision_reunion/expand_document.py` sincroniza las figuras Tecplot existentes, sin nuevas evaluaciones del modelo. Las figuras ahora son dependencias externas del proyecto. Para conservar la actualización del 14 de octubre después de esa sincronización, ejecute `../sensibilidad_complementaria_20261014/scripts/update_documentation.py`.

La fuente anterior a esta ampliación se conserva en `revision_reunion/source_before_edit.txt`. `revision_reunion/revision_provenance.json` identifica la revisión ilustrada inicial. Después de la integración Tecplot, las figuras son archivos externos: el compilador nativo no accede a esas dependencias y el documento se verifica con el Tectonic ya instalado en el proyecto. Después de cualquier cambio de fuente, confirme esa compilación y actualice su huella en `latex_compilation.json` antes de ejecutar `audit_delivery.py`, que comprueba fuentes, resultados y compilación y escribe el manifiesto SHA-256.

La comprobación complementaria del 14 de octubre está en `../sensibilidad_complementaria_20261014/RESULTADOS_Y_VERIFICACION.md`. Su generador `scripts/update_documentation.py` conserva el mismo documento y actualiza el cuerpo equivalente. La campaña original Morris no se prolonga cambiando su fecha: los nueve casos complementarios tienen carpeta y huellas propias. Las exportaciones nuevas de MATLAB están autorizadas como alternativa ante la licencia Tecplot vencida.

Use `morris_summary.mat` para análisis MATLAB. Si se importan CSV, fuerce `group` a texto; etiquetas como `10+11` no deben interpretarse numéricamente. Los grupos son conjuntos de ramas de la referencia, no índices de frecuencia ordenada en cada punto. `allEffectsValid`, `meanEffectResolved`, `muStarConverged`, `dispersionResolved` y `sigmaConverged` deben conservarse al interpretar la tabla. Las aristas inválidas permanecen explícitas; no las elimine para recalcular una clasificación optimista.

Las figuras usan escalas adimensionales de respuesta y exportan PNG y PDF vectorial. `morris_dominio` muestra puntos calculados; su color mezcla el efecto de los tres factores y no debe interpretarse como un barrido de un solo parámetro.
