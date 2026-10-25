# Decisión propuesta para una segunda etapa

Esta etapa no está autorizada ni ejecutada. El estudio local y su verificación están entregados por separado.

**Opción propuesta:** dominio exploratorio de factores 0.90–1.10 para densidad de palas, rigidez de palas y velocidad nominal del rotor. Los dos primeros mantienen las dependencias del módulo; el tercero equivale a 10.8–13.2 rpm. Estos límites son una propuesta de escenarios para discutir, no intervalos medidos ni incertidumbre experimental.

**Método propuesto:** cribado Morris con comparación de estimadores entre 10, 20 y 40 trayectorias, semilla guardada, seguimiento de grupos completos y registro explícito de fallos. Las medias de efectos elementales describirían el dominio numérico elegido, no probabilidades físicas. No se supondrán independencia física ni distribuciones de fabricación. Los rangos vinculados requerirían un diseño sobre variables independientes coherentes.

**Costo:** 40(3+1)=160 evaluaciones básicas; unos 20 minutos de solve según el costo local observado. Propuesta de límite de 30 minutos, incluyendo comprobaciones. Si la resolución modal o los residuos no permiten interpretar el muestreo, se detiene la clasificación, se conserva la evidencia y se documenta lo que falta. Un método global no corrige el piso de precisión del solver.

**Alternativa:** proporcionar rangos físicos con fuentes antes de cualquier campaña global. Esto permitiría reformular el dominio y determinar si un estudio probabilístico Sobol tiene sentido. Sin esos datos, no se presentarán intervalos de confianza o probabilidades de respuesta de la turbina.

La decisión requerida del autor es aceptar o sustituir el dominio propuesto y fijar un presupuesto. La ficha `cases/config_sensitivity_extended_pending.m` permanece deshabilitada.
