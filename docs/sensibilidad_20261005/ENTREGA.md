# Entrega del estudio inicial

- `DIAGNOSTICO_Y_PLAN.md`: auditoría de ecuaciones, capacidades, datos y plan.
- `LEEME.md`: ejecución, dependencias, controles y reanudación por versión.
- `parameter_registry_complete.csv`: parámetros, unidades, fuentes y dependencias; las propiedades nominales por sección y cuerpo están en los CSV de cada campaña.
- `RESULTADOS_Y_DISCUSION.md`: tablas aceptadas, mecanismos, hipótesis y límites.
- `SECCION_SENSIBILIDAD_REVISION.tex`: documento autónomo compilado con el editor nativo.
- `seccion_para_incorporar.tex`: fragmento de sección; requiere integrar referencias y revisar antes de incorporarlo.
- `PROPUESTA_EXTENSION.md`: decisión pendiente sobre dominio global y presupuesto.
- `regression_results_final.mat`: 155/155; `module_tests_final.mat`: 12/12.
- `core_preservation.csv`: las 148 fuentes MATLAB previas siguen intactas.
- `source_snapshot_20261005.tar.gz`: versión inicial de las evaluaciones crudas.
- `source_snapshot_final_20261005.tar.gz`: versión final del módulo y postprocesamiento.
- `DELIVERY_MANIFEST.csv`: tamaño y SHA-256 de los archivos entregados, incluidos los resultados crudos.
- `delivery_audit.json`: auditoría final de los 99 casos, conservación del código y entradas, regresión y compilación.
- `finalize_delivery.py`: reproducción de esa auditoría sin resolver nuevos casos.

Resultados: `/Users/nuseche/Desktop/Tesis_codigos/runs/sensitivity/initial_20261005`.
Figuras verificadas: `figures_revision`, en PNG y PDF vectorial. Son cuatro figuras con sensibilidad modal, barridos de un grupo, convergencia temporal y sensibilidad sísmica.

Todas las campañas conservan `campaign.mat/json`, estados, huellas y un MAT por evaluación. Los resultados iniciales crudos se mantienen. Los CSV de aceptación, los grupos que cruzan el corte y la huella final de postprocesamiento prevalecen sobre clasificaciones preliminares. La reanudación de una campaña requiere su misma versión de código; use su snapshot o una carpeta nueva con la versión final.

El paquete está integrado en el solver activo mediante `+sensitivity`, casos separados y una entrada en README; `main.m` y las fuentes físicas previas no se modificaron. El estudio local no es global ni probabilístico. La interacción a ±1 % permanece no resuelta y el dominio global no se ha ejecutado.
