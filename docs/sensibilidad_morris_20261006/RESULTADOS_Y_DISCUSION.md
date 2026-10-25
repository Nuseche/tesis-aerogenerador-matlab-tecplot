# Resultados de la segunda etapa: Morris exploratorio

**Fecha:** 6 de octubre de 2026. **Autorización:** el autor aprobó los escenarios de ±10 % y un presupuesto de 30 minutos. La primera etapa se conserva en `docs/sensibilidad_20261005`; esta entrega tiene configuración, huellas y resultados propios.

## Ejecución y alcance

Se completaron 40 trayectorias de las 40 previstas. Se guardaron 170 evaluaciones satisfactorias, incluidos diez controles, y 0 fallos de modelo. El tiempo acumulado de las evaluaciones fue 20.28 minutos; esto no incluye preparación ni postprocesamiento. Estado de la campaña: completada=True, detenida por presupuesto=False. La semilla del diseño es 6706.

Los factores de masa e inercias de las palas, rigidez seccional de las palas y velocidad del rotor se muestrearon en [0.90,1.10]. La velocidad equivale a 10.8–13.2 rpm. El dominio es un conjunto de escenarios mecánicos aprobado; no constituye incertidumbre experimental ni una distribución física conjunta. Las dependencias masa–inercia y entre las seis rigideces seccionales permanecen consistentes, con geometría fija.

Para el grupo 10–11 se conservaron 58 combinaciones distintas entre los vértices válidos; se mantienen las evaluaciones repetidas como evidencia de reproducibilidad. La máxima diferencia de frecuencia entre repeticiones de la misma combinación fue 0 Hz.

La integración usa las rutinas físicas existentes y vuelve a calcular el equilibrio. Las respuestas son centroides de grupos o ramas aisladas bajo la convención exp(λt): frecuencia |Im λ|/(2π), crecimiento Re λ y amortiguamiento −Re λ/|λ|. El espectro es parcial y el azimut está congelado; las conclusiones no describen estabilidad de Floquet. Esta campaña global se limita a los indicadores modales.

## Estimadores y controles

Cada trayectoria tiene cuatro puntos y tres aristas, una por factor, sobre una malla de cuatro niveles. En la coordenada x∈[0,1], el factor es ξ=0.90+0.20x; el paso firmado tiene magnitud 2/3, equivalente a 0.13333 del factor. Se guarda cada efecto EE=(y_fin−y_inicio)/(Δx s_y), con escala fija nominal. μ es su media firmada, μ* su media absoluta y σ su desviación estándar muestral. Son adimensionales después del escalamiento. μ* no es un porcentaje máximo de variación de la respuesta ni un índice de Sobol.

Los prefijos de 10, 20 y 40 pertenecen al mismo diseño. El agrupamiento usa la unión de proximidades de TODOS los puntos observados para mantener la misma definición de respuesta entre prefijos. Se exigen grupos cerrados, correlación con el nominal y correlación entre extremos. No se omiten efectos inválidos al promediar. La envolvente de ruido se obtiene en el nominal y dos esquinas, con repetición, QEP estricto y continuación; sigue siendo empírica y no una cota rigurosa de todo el dominio.

La media absoluta debe superar diez veces su envolvente propagada y cambiar como máximo un 10 % entre los dos últimos prefijos para aceptarse. La dispersión tiene su propio control de ruido y estabilización. La convergencia de prefijos es un diagnóstico finito, no una garantía asintótica.

## Evidencia numérica

El máximo residuo de equilibrio fue 9.942e-09; los máximos residuos derechos e izquierdos del QEP fueron 4.93e-16 y 3.572e-14. En norma dual de masa, que combina fuerzas y momentos de manera compatible con unidades, el máximo fue 4.051e-09. Estas medidas no son por sí solas cotas de error de autovalores. Las 17 pruebas del módulo pasaron, con 0 fallos. La regresión anterior de 155 pruebas se conserva; no se presenta como una nueva ejecución de esa suite.

La mayor parte real de las raíces calculadas fue -0.012382 s⁻¹. Este dato solo se refiere al subconjunto de autovalores efectivamente calculado y no basta para concluir estabilidad del sistema periódico completo.

## Frecuencias: resultados e interpretación

Se aceptaron 14 indicadores de media absoluta de frecuencia. La tabla conserva también estimadores rechazados para distinguir falta de resolución, seguimiento incompleto y estabilización insuficiente. Los CSV incluyen cada bandera por separado.

| Parámetro | Grupo | μ | μ* | σ | Cambio μ* 20→40 | Aceptación de μ* |
|---|---|---:|---:|---:|---:|---|
| densidad de palas | 1+2 | -0.041636 | 0.041636 | 0.0025335 | 0.99 % | no |
| densidad de palas | 3 | -0.11221 | 0.11221 | 0.010523 | 0.51 % | sí |
| densidad de palas | 4+5 | -0.11335 | 0.11335 | 0.0066974 | 0.20 % | sí |
| densidad de palas | 6+7 | -0.061607 | 0.061607 | 0.0039786 | 0.18 % | sí |
| densidad de palas | 8+9 | -0.085457 | 0.085457 | 0.0049506 | 0.04 % | sí |
| densidad de palas | 10+11 | -0.076531 | 0.076531 | 0.0044494 | 0.15 % | sí |
| densidad de palas | 12 | no resuelto | no resuelto | no resuelto | — | no |
| rigidez de palas | 1+2 | 0.0076606 | 0.0076606 | 0.002363 | 1.60 % | no |
| rigidez de palas | 3 | 0.076949 | 0.076949 | 0.0065196 | 0.80 % | sí |
| rigidez de palas | 4+5 | 0.078861 | 0.078861 | 0.0036799 | 0.36 % | sí |
| rigidez de palas | 6+7 | 0.048659 | 0.048659 | 0.0023486 | 0.40 % | sí |
| rigidez de palas | 8+9 | 0.072957 | 0.072957 | 0.0029122 | 0.20 % | sí |
| rigidez de palas | 10+11 | 0.071719 | 0.071719 | 0.0028349 | 0.24 % | sí |
| rigidez de palas | 12 | no resuelto | no resuelto | no resuelto | — | no |
| velocidad del rotor | 1+2 | -0.013967 | 0.013967 | 0.0033207 | 0.49 % | no |
| velocidad del rotor | 3 | -0.059519 | 0.059519 | 0.0072616 | 0.38 % | sí |
| velocidad del rotor | 4+5 | -0.034353 | 0.034353 | 0.0013691 | 0.90 % | no |
| velocidad del rotor | 6+7 | 0.069234 | 0.069234 | 0.0020155 | 0.15 % | sí |
| velocidad del rotor | 8+9 | 0.022953 | 0.022953 | 0.0015497 | 0.05 % | sí |
| velocidad del rotor | 10+11 | 0.036778 | 0.036778 | 0.0017289 | 0.05 % | sí |
| velocidad del rotor | 12 | no resuelto | no resuelto | no resuelto | — | no |


Para el grupo 3, los indicadores aceptados son densidad de palas: μ*=0.11221, μ=-0.11221; rigidez de palas: μ*=0.076949, μ=0.076949; velocidad del rotor: μ*=0.059519, μ=-0.059519.

Para el grupo 4+5, los indicadores aceptados son densidad de palas: μ*=0.11335, μ=-0.11335; rigidez de palas: μ*=0.078861, μ=0.078861.

Para el grupo 6+7, los indicadores aceptados son velocidad del rotor: μ*=0.069234, μ=0.069234; densidad de palas: μ*=0.061607, μ=-0.061607; rigidez de palas: μ*=0.048659, μ=0.048659.

Para el grupo 8+9, los indicadores aceptados son densidad de palas: μ*=0.085457, μ=-0.085457; rigidez de palas: μ*=0.072957, μ=0.072957; velocidad del rotor: μ*=0.022953, μ=0.022953.

Para el grupo 10+11, los indicadores aceptados son densidad de palas: μ*=0.076531, μ=-0.076531; rigidez de palas: μ*=0.071719, μ=0.071719; velocidad del rotor: μ*=0.036778, μ=0.036778.

La velocidad presenta signos medios opuestos: positivos en los grupos 6+7, 8+9, 10+11 y negativos en 3. Por tanto, el incremento de velocidad no eleva todas las frecuencias seleccionadas. La ecuación cuadrática contiene simultáneamente operadores giroscópicos, transporte y cambios de la tangente en equilibrio; el signo depende del grupo. Atribuirlo exclusivamente a una rigidez adicional positiva omitiría esa competencia. Separar cuantitativamente las contribuciones exigiría un estudio diagnóstico adicional, sin alterar la formulación final.

Para el grupo 10–11, al dividir μ entre el ancho 0.20 de cada factor se obtienen pendientes medias de secante normalizadas por la frecuencia nominal: densidad de palas -0.3827, rigidez de palas +0.3586, velocidad del rotor +0.1839. Son coherentes con los signos y magnitudes del estudio local. Estas secantes atraviesan pasos de 0.13333 del factor y no reemplazan sus derivadas infinitesimales. Resolver una influencia en este dominio más amplio no convierte automáticamente en aceptada una derivada local antes rechazada.

El signo de μ informa la dirección media del cambio en las aristas muestreadas; no demuestra monotonicidad de todo el continuo. μ* permite comparar factores con el mismo ancho relativo, únicamente dentro de cada respuesta y dominio. Los intervalos observados por grupo están en `morris_frequency_ranges.csv`; se calculan con vértices cuyo seguimiento es válido.

Los mecanismos son consistentes con el análisis local: la escala de masa modifica la inercia traslacional y rotacional, el peso y las contribuciones asociadas al giro; por ello su efecto total incluye el cambio del equilibrio. La escala de rigidez modifica conjuntamente EA, GAy, GAz, GJ, EIy y EIz. La velocidad modifica términos proporcionales a Ω y Ω², el equilibrio y las derivadas de las restricciones y de MBC. El predominio de las palas en los modos altos seleccionados está respaldado por las participaciones cuadráticas de referencia de la primera etapa; esas participaciones no son una partición de toda la energía del sistema en rotación.

No se extiende la compensación local masa–rigidez a todo el dominio como una identidad. Una media firmada similar y de signo opuesto puede motivar estudiar curvas de compensación; confirmar esas curvas exigiría evaluar directamente combinaciones seleccionadas.

## Dispersión, interacción y límites

Se aceptaron 2 indicadores de dispersión de frecuencia. σ reúne variación del efecto elemental con la posición en el dominio y puede deberse a no linealidad o interacción. Morris no separa esas causas. Una dispersión no resuelta no demuestra ausencia de interacción. La interacción central local anterior, a ±1 %, permanece una evidencia diferente con su propio piso numérico.

Los indicadores de crecimiento y amortiguamiento se exportan en los mismos archivos, con escala fija; no se convierten sus centroides en una clasificación de estabilidad de cada raíz. La truncación espectral, cambios de grupo, el piso del equilibrio y la envolvente empírica limitan las conclusiones. El refinamiento espacial anterior corresponde al rotor detenido; no demuestra convergencia espacial de las sensibilidades globales en rotación. No se ejecutaron trayectorias adicionales, simulaciones sísmicas globales, Sobol ni cambios en hipótesis físicas.

## Reproducción y archivos

Código: `+sensitivity/config_morris.m`, `morris_design.m`, `morris_statistics.m`, `summarize_morris.m` y `run_morris_study.m`. Caso: `cases/config_sensitivity_morris_approved.m`. Los escenarios crudos están en `/Users/nuseche/Desktop/Tesis_codigos/runs/sensitivity/morris_20261006`. `campaign.mat/json` contiene la configuración completa, el diseño y la huella de código/datos/MATLAB. Cada evaluación conserva estado, operadores, factores, opciones, convergencia y error si corresponde. La reanudación exige la misma versión y configuración.

Las tablas principales son `morris_elementary_effects.csv`, `morris_estimators.csv`, `morris_tracking.csv`, `morris_noise.csv`, `morris_residuals.csv` y `morris_frequency_ranges.csv`. Los checkpoints `morris_summary_r10/20/40.mat` conservan la evolución del postprocesamiento; la comparación final recalcula los prefijos con grupos uniformes en el dominio observado. Las figuras PNG y PDF vectoriales están en `figures`.

Referencia primaria del diseño: Morris (1991), [DOI 10.1080/00401706.1991.10484804](https://doi.org/10.1080/00401706.1991.10484804). La evidencia específica, los escalados y los controles de aceptación proceden de esta implementación y de sus resultados guardados.
