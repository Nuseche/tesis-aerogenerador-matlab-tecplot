# Entrega de Morris aprobada el 6 de octubre

- [Resultados y discusión](RESULTADOS_Y_DISCUSION.md): estimadores de 10, 20 y 40 trayectorias, mecanismos y límites.
- [Método y autorización](METODO_Y_AUTORIZACION.md): dominio aprobado, presupuesto y criterios numéricos.
- [Reproducción](LEEME.md): configuración, ejecución y reanudación.
- `SECCION_MORRIS_REVISION.tex`: documento abierto, ampliado en el mismo archivo y compilado con el editor nativo. Contiene ocho figuras vectoriales integradas: proceso de cálculo, trayectoria real, efectos con signo, participaciones de palas, mapa masa–rigidez, filtro de ruido, estabilización y dispersión. Añade ejemplos con unidades, interpretación física y guía para la reunión con el asesor.
- `seccion_para_incorporar.tex`: cuerpo equivalente de la versión ilustrada y de la comprobación del 14 de octubre. Requiere sus carpetas de figuras y las referencias `morris1991` y `campolongo2007`.
- `revision_reunion/`: generador de la versión ilustrada, procedencia de sus datos y respaldo de la fuente anterior a la ampliación. Se preparó únicamente con resultados almacenados, sin nuevas evaluaciones del modelo.
- `module_tests.mat` y `preflight.log`: pruebas de diseño, efectos firmados, funciones con interacción, ruido, convergencia y presupuesto; además de las pruebas previas del módulo.
- `source_snapshot.tar.gz`: versión exacta del código de esta campaña.
- `DELIVERY_MANIFEST.csv` y `delivery_audit.json`: integridad de fuentes, datos y resultados.

Resultados crudos: `/Users/nuseche/Desktop/Tesis_codigos/runs/sensitivity/morris_20261006`.

Cada caso conserva sus factores y estado de operación, opciones, operadores, autovectores y residuos. `campaign.mat/json`, `source_hashes.csv` y el diseño permiten reproducir la ejecución. Se conservan tanto el primer intento de preparación abortado antes de evaluar escenarios como su snapshot; el registro efectivo es `campaign_execution.log`.

Tablas de la campaña: `morris_vertices.csv`, `morris_edges.csv`, `morris_elementary_effects.csv`, `morris_estimators.csv`, `morris_groups.csv`, `morris_tracking.csv`, `morris_noise.csv`, `morris_residuals.csv` y `morris_frequency_ranges.csv`. Los grupos que cruzan el corte espectral y los efectos no resueltos siguen explícitos. Los prefijos se comparan con la misma definición de grupos en el dominio final observado.

Figuras de la entrega inicial verificadas, PNG y PDF vectorial: `figures/morris_influencia`, `morris_convergencia`, `morris_dispersion` y `morris_dominio`. Las ocho figuras de la versión ilustrada están incorporadas en la fuente LaTeX. La dispersión no separa no linealidad de interacción. Los símbolos vacíos indican dispersión sin aceptación numérica.

La primera entrega permanece en `docs/sensibilidad_20261005` y `runs/sensitivity/initial_20261005`, con sus snapshots históricos. La nueva etapa conserva la formulación física previa y usa el caso separado `cases/config_sensitivity_morris_approved.m`.

## Comprobación del 14 de octubre

El documento existente incorpora la rejilla completa de 64 combinaciones y los contrastes finitos de compensación, curvatura y no aditividad. Se reutilizaron 58 puntos y se resolvieron seis faltantes más tres controles, sin cambiar las rutinas físicas. Los resultados, tablas, figuras y scripts están en `docs/sensibilidad_complementaria_20261014` y `runs/sensitivity/grid_completion_20261014`. Los estimadores Morris originales permanecen intactos.

La presentación está en `/Users/nuseche/Documents/ChatGPT/Tesis/output/presentacion_sensibilidad_20261014/entrega`. Las figuras nuevas y las adaptaciones para proyección usan MATLAB, con autorización del usuario ante la licencia Tecplot vencida; su procedencia está explícita. La compilación del documento con imágenes externas usa el compilador Tectonic del proyecto, porque el compilador nativo no accede a esas dependencias.
