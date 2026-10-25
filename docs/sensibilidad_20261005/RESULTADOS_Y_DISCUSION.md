# Resultados y discusión de la sensibilidad local

**Fecha:** 5 de octubre de 2026. **Modelo:** revisión energética de septiembre, masa consistente, giro nominal prescrito y azimut congelado. **Alcance:** benchmark numérico, sin calibración experimental ni estabilidad de Floquet.

La evidencia permite identificar tendencias locales de la densidad, rigidez de palas y velocidad del rotor en algunos grupos modales. No permite todavía clasificar de manera completa todos los parámetros físicos. Las derivadas de conexiones y apoyo que no superan los filtros no demuestran irrelevancia física.

## Evidencia reproducida y ejecución

Se completaron 99 casos: 52 del estudio modal principal, 10 del tren de potencia, 12 del apoyo flexible, 3 de malla, 6 de convergencia/amplitud sísmica, 4 de interacción y 12 de parámetros mecánicos en respuesta temporal. Todas esas evaluaciones terminaron correctamente. Se documenta aparte un intento piloto de equilibrio a 1e-10 que falló por búsqueda de línea; no se usó como resultado nominal.

La regresión final dio **155 aprobadas, 0 fallidas y 0 incompletas**, incluyendo doce pruebas del módulo. La comparación de hashes confirmó que las 148 fuentes MATLAB existentes en el snapshot energético de septiembre siguen idénticas. La continuación histórica de nueve velocidades reprodujo las doce frecuencias de septiembre con diferencia relativa máxima **6.323e-15**. Las formas correlacionaron con MAC prácticamente unitario.

Los casos principales de salto 0→12 rpm tomaron aproximadamente 7.65 s en promedio, incluyendo una referencia de continuación más costosa. El estudio se mantiene separado de `main.m` y no sobrescribe corridas previas. Configuraciones, datos actualizados, estados, opciones, huellas, tiempos y errores quedan en MAT/CSV/JSON.

## Parámetros y respuestas

Todos los parámetros son factores de nominal 1; la tabla completa de procedencia y dependencias está en `local/parameters.csv`. Los valores nominales dimensionales están en `nominal_sections.csv`, `nominal_bodies.csv`, `nominal_drivetrain.csv` y en los archivos de apoyo. Los pasos de diferenciación son exploratorios.

| Factor | Definición física y unidad original | Dominio local usado | Dependencias conservadas |
|---|---|---|---|
| Velocidad | Omega/Omega0; Omega0=12 rpm=1.256637 rad/s | 0.98–1.02 | Equilibrio, términos Omega/Omega², transporte, Tdot/Tddot y MBC |
| Densidad de palas | Masa lineal kg/m e inercias seccionales kg m | 0.98–1.02 | Todas las inercias y m escalan juntas, geometría fija |
| Densidad de torre/transición | Igual definición, rho0=7850 kg/m³ | 0.98–1.02 | m/Jx/Jy/Jz vinculadas |
| Densidad de góndola/cubo | Masa kg y tensor centroidal kg m² | 0.98–1.02 | Un único factor por cuerpo, tensor completo, offsets existentes |
| Rigidez de torre/palas | EA/GA [N], EI/GJ [N m²] | 0.98–1.02 | Escalamiento proporcional de seis componentes, masa fija |
| Amortiguamiento estructural | Dos razones Rayleigh nominales 0.01 a 0.2 y 2 Hz | 0.98–1.02 | Ambas razones escalan juntas; frecuencias ancla fijas |
| Rigidez del tren | Traslación N/m y rotación N m/rad; dato ilustrativo | 0.98–1.02 | Matriz relativa y geometría de la conexión fijas |
| K/C del apoyo | Matrices del caso flexible heredado | 0.99–1.01 | Un factor positivo por matriz; M del apoyo fija |
| Amplitud del sismo | Factor del registro sintético existente | 0.99–1.01 | Se escalan ag/vg/ug consistentemente |

Se calculan frecuencia amortiguada, parte real del autovalor y razón de amortiguamiento, centroides de grupos, desplazamientos de equilibrio y máximos temporales. Los máximos usan los ejes globales, uy de maestros 129/130 y uz de puntas 56/92/128, ventana 0–1 s. El estudio temporal mecánico compara únicamente densidad y rigidez de palas, seleccionadas por la evidencia modal; no establece una clasificación exhaustiva de la respuesta sísmica.

## Metodología y filtros

Con xi=p/p0 y xi0=1, la derivada central es `[y(1+h)-y(1-h)]/(2h)`. Para frecuencias no nulas se usa S=(1/y0)dy/dxi. Para crecimiento sigma=Re(lambda), la escala es |lambda0| [s^-1]; para desplazamiento estático se usa max(|q0|,1 mm). No se divide por una tasa de crecimiento pequeña. Cada fila conserva su escala, convención, ruido y estados de aceptación.

Se recalcula el equilibrio en cada caso: las derivadas son totales para el modelo implementado. Se conservan los términos de giro, masa y transporte; no se introduce guiñada. La asignación usa MAC complejo con masa física nominal común, proximidad de raíces complejas y asignación global. Los grupos próximos requieren MAC subespacial mínimo 0.95; las ramas individuales requieren MAC 0.8 y margen 0.05. El umbral de agrupamiento relativo 0.10 es conservador y no demuestra multiplicidad exacta.

Se contrastan h=0.02/0.01/0.005. La derivada debe concordar entre pasos consecutivos dentro de 2 %, con piso absoluto documentado. La señal entre extremos debe superar diez veces la estimación de ruido obtenida de repetición, QEP más estricto y cambio de continuación. Es una comprobación empírica, no una cota rigurosa de error en todo el dominio.

La rama 12 tiene separación compleja relativa de aproximadamente 0.0325 respecto a la 13; su grupo atraviesa el corte de doce ramas. Aunque existen dieciséis representantes calculados como margen, se excluyen sus derivadas individuales y centroides incompletos. Esta revisión retiró tres sensibilidades de frecuencia inicialmente candidatas. Los resultados de la revisión final prevalecen sobre el conteo preliminar.

## Resultados de frecuencia aceptados

Los cinco indicadores siguientes pasan todos los filtros con h=0.005. Son centroides de grupos completos; los índices identifican formas nominales seguidas y no posiciones fijas en una lista ordenada de frecuencias.

| Factor | Grupo | Frecuencia media nominal [Hz] | S | Diferencia de derivada entre h=0.01 y 0.005 |
|---|---:|---:|---:|---:|
| Velocidad del rotor | 6+7 | 0.587499 | +0.338624 | 1.21 % |
| Velocidad del rotor | 10+11 | 1.225430 | +0.179155 | 0.94 % |
| Densidad de palas | 10+11 | 1.225430 | −0.380798 | 0.45 % |
| Rigidez de palas | 8+9 | 0.843920 | +0.356037 | 1.45 % |
| Rigidez de palas | 10+11 | 1.225430 | +0.354654 | 0.83 % |

**Observación:** mayor densidad reduce la frecuencia media del grupo 10+11; mayor rigidez la aumenta. La velocidad eleva los centroides de los grupos 6+7 y 10+11 dentro del entorno estudiado. El mayor |S| aceptado por factor es 0.381 para densidad de palas, 0.356 para rigidez de palas y 0.339 para velocidad. Se comparan respuestas distintas; esa lista no es una clasificación universal de importancia.

**Comprobación mecánica:** `modal_energy_evidence.csv` muestra que las formas 10/11 tienen, respectivamente, fracciones de masa de palas de aproximadamente 96.2/93.4 % y fracciones elásticas de palas de 97.8/86.5 %. Su localización respalda la influencia de las propiedades de palas. Estas fracciones son formas cuadráticas de referencia, no un balance de toda la energía del sistema rotante.

**Interpretación:** la competencia entre inercia y rigidez explica los signos de densidad y rigidez. En un problema conservativo simple, un escalamiento uniforme da sensibilidades ±1/2; aquí las fracciones no son unitarias, se cambia el equilibrio y aparecen términos de giro/transporte y amortiguamiento. Por ello no corresponde exigir ±1/2 ni atribuir la desviación a un solo mecanismo. La sensibilidad positiva a Omega recoge conjuntamente contribuciones de orden Omega/Omega² y cambios de estado. No se separó el efecto de cada bloque ni se mantuvo artificialmente fijo el equilibrio.

Un ejemplo de compensación local, para el centroide 10+11, es `d ln(f) ≈ -0.3808 d xi_rho +0.3547 d xi_K +0.1792 d xi_Omega`. A velocidad fija, un aumento de densidad de 1 % puede compensarse, a primer orden, con un aumento de rigidez de aproximadamente 1.07 %. Es una relación local de esa respuesta; no identifica un material ni garantiza la misma compensación en aceleraciones o en otras ramas.

## Amortiguamiento y conexiones

El factor de amortiguamiento presenta sensibilidades aceptadas de zeta de aproximadamente 1.052 en la rama 4, 1.022 en el grupo 6+7 y 1.030 en el grupo 10+11. Las derivadas escaladas de sigma son negativas en los indicadores aceptados, consistentes con mayor decaimiento de esas raíces. G es antisimétrica y su forma de potencia instantánea se anula; no debe confundirse con disipación estructural. massRate y los términos de transporte/restricciones tienen un papel distinto de C.

No quedó un indicador frecuencial aceptado para densidad de torre, góndola, cubo, rigidez de torre, rigidez del tren o K/C del apoyo. En algunos casos la señal es pequeña frente al ruido; en otros falla la concordancia de pasos o la identidad está agrupada/truncada. **No equivale a sensibilidad cero.** Por ejemplo, la rama 4 tiene alrededor de 22 % de energía elástica de referencia en el tren; su derivada local de frecuencia no superó las puertas. El comportamiento en conexiones más flexibles queda fuera del dominio actual.

## Respuesta sísmica y convergencia temporal

El escalamiento de amplitud dio S≈1 para desplazamientos y aceleraciones de los cinco canales; el máximo apartamiento observado fue del orden de 6e-9. Verifica la linealidad del punto operativo congelado y la actualización coherente de ag/vg/ug, sin constituir validación sísmica de diseño.

Al comparar 0.0025 con 0.00125 s, la mayor diferencia relativa L2 de desplazamiento entre canales fue **3.617e-4** y la mayor diferencia relativa de pico **2.378e-4**. Para uy del nodo 129, la diferencia L2 fue aproximadamente 3.156e-4. Los residuos proyectados dinámicos son del orden de 1e-12. Son respuestas de un registro analítico corto y de operadores congelados.

Cuatro indicadores mecánicos pasan ruido y convergencia del paso, con h=0.005 y dt=0.00125 s:

| Factor | Nodo, canal global | Respuesta | S |
|---|---|---|---:|
| Densidad de palas | 128, uz | Pico de aceleración absoluta | +0.34213 |
| Rigidez de palas | 56, uz | Pico de aceleración absoluta | −1.03611 |
| Rigidez de palas | 128, uz | Pico de desplazamiento relativo | −0.16306 |
| Rigidez de palas | 128, uz | Pico de aceleración absoluta | −0.37885 |

**Observación:** rigidez reduce esos máximos y densidad aumenta la aceleración del canal 128. **Interpretación respaldada por las ecuaciones:** densidad modifica tanto M y las inercias de giro como la carga de base `-T' M R ag`; no equivale a variar masa bajo una fuerza prescrita constante. Rigidez modifica la transferencia dinámica y la precarga. **Hipótesis pendiente:** una atribución precisa a resonancia o contribución de una rama exige descomponer la respuesta. Un registro de 1 s tiene contenido transitorio amplio; no se concluye resonancia únicamente comparando las dos frecuencias de la función de entrada con el Campbell.

## Malla, residuos e interacciones

La subdivisión 1/2/4 conserva geometría, secciones constantes, nodos originales y conexiones. Con rotor detenido, la mayor diferencia entre centroides de grupos completos de mallas 2/4 fue **4.604e-4**; la correlación subespacial mínima es prácticamente unitaria. Este resultado no certifica la convergencia espacial de todas las derivadas rotantes. El ruido de la tangente y de la continuación puede dominar una señal más pequeña que ese error de discretización.

El residuo QEP adicional usa la norma dual de masa: `||r||_(M^-1)/(||lambda²Mphi||_(M^-1)+||lambda Dphi||_(M^-1)+||Kphi||_(M^-1))`. Evita comparar fuerzas y momentos con una norma euclidiana sin escala física común. El máximo observado fue aproximadamente 2.4e-8; no es una cota de error de frecuencia. El contraste con la continuación muestra por qué residuos pequeños no bastan para aceptar toda derivada. La auditoría cinemática/energética no identificó candidatos rígidos en las soluciones con base soportada.

Las cuatro combinaciones a ±1 % de densidad y rigidez generan derivadas mixtas, pero ninguna derivada individual admisible supera el umbral de ruido. Además, se ensayó un solo paso mixto. `interaction_resolution.csv` etiqueta estos valores como no resueltos y convergencia no verificada. No se afirma ni existencia ni ausencia de interacción física a partir de ellos.

## Limitaciones y decisión de extensión

Se mantienen offsets colocalizados y la regla seccional existente; faltan datos de calibración del tren y de aerodinámica. El análisis modal usa un espectro parcial a azimut fijo y la respuesta temporal no integra un rotor que avance su orientación. No hay prueba de estabilidad periódica, validación experimental, distribuciones probabilísticas ni incertidumbre real cuantificada. Las conclusiones corresponden a las propiedades heredadas y a las variaciones locales descritas.

Morris sería computacionalmente factible como una segunda fase exploratoria de tres factores, pero requiere la decisión del autor sobre dominio y costo. Con k=3 y r=40, el costo básico es 160 casos; al costo medido de unos 7.65 s/caso, son unos 20.4 minutos de solve, antes de verificaciones adicionales. Sobol no se justifica todavía sin una medida conjunta de entrada. La propuesta concreta está en `PROPUESTA_EXTENSION.md`; **no se ejecutó sensibilidad global ni barrido amplio**.

## Artefactos y versiones

Evidencia bajo `/Users/nuseche/Desktop/Tesis_codigos/runs/sensitivity/initial_20261005`. Figuras verificadas en `figures_revision`, en PNG y PDF vectorial. El módulo y la documentación están en `+sensitivity` y `docs/sensibilidad_20261005`. La fuente LaTeX autónoma se entrega para revisión y no se incorpora automáticamente a los manuscritos.

Los casos crudos se preservan con el snapshot inicial. El postprocesamiento final tiene su propia huella y snapshot porque se corrigió el tratamiento de la frontera espectral; los estados y operadores no se modificaron. La reanudación exige la misma revisión del código; una revisión diferente requiere carpeta nueva. Se conserva el intento piloto fallido y los resultados no aceptados.

Referencias primarias: Tisseur y Meerbergen (2001), [QEP, DOI 10.1137/S0036144500381988](https://doi.org/10.1137/S0036144500381988); Allemang (2003), [MAC: Twenty Years of Use and Abuse](https://www.sandv.com/downloads/0308alle.pdf); Morris (1991), [DOI 10.1080/00401706.1991.10484804](https://doi.org/10.1080/00401706.1991.10484804). El desarrollo energético específico permanece trazado en la formulación de septiembre del proyecto.
