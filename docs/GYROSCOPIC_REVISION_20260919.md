# Revisión energética de la giroscopía — 19 de septiembre de 2026

## Estado y alcance

Implementación, verificación y documentación matemática completadas. Este registro técnico se mantiene separado del PDF matemático: sus pruebas, comparaciones y detalles de trazabilidad no forman parte del documento científico.

La referencia primaria consultada fue Leonard Meirovitch, *Principles and Techniques of Vibrations*, Prentice Hall, 1997, sección 4.4, ecuaciones (4.51)–(4.70), y las secciones 4.7 y 7.17. Se sigue su procedimiento de expansión energética alrededor de un movimiento estacionario. Las matrices seccionales de seis grados de libertad son una especialización derivada para este modelo, no una fórmula literal atribuida al libro.

Se mantienen: masa consistente, inercia de referencia, pequeñas perturbaciones, velocidad prescrita constante y operadores congelados en un azimut. No se ha convertido el modelo en una formulación no lineal geométricamente exacta ni en un análisis periódico de Floquet. Los coeficientes mecánicos y el sismo de los casos de aceptación son datos de benchmark, no una calibración experimental de una turbina comercial.

## Qué cambió

Para W = skew(Ω), J centroidal y centro de masa sobre la línea de referencia, el bloque rotacional corrotante es ahora:

`Gtheta,c = J*W + W*J - skew(J*Omega)`.

Se obtiene como `G = A - A'`, donde A es la derivada mixta velocidad–posición de la energía cinética. Se conservan el tensor completo y los productos de inercia. Se incluyen también los acoplamientos debidos a un offset del centro de masa. En ejes principales, con giro sobre el eje 1, el coeficiente transversal es `(J2+J3-J1)*Omega`.

No bastaba sustituir ese bloque dentro del ensamblaje anterior. Se corrigió la cadena completa:

1. Expansión de la energía cinética física: masa M, derivada mixta A, giroscopía G, fuerza centrífuga y su tangente.
2. Integración consistente de sección a elemento mediante cuatro puntos de Gauss.
3. Transporte de las contribuciones rotantes a las coordenadas inerciales de ensamblaje, sin rotar artificialmente torre o góndola.
4. Restricciones raíz–cubo dependientes del tiempo, incluyendo Tdot y Tddot.
5. Transformación a marcos homólogos de pala y multiblade, incluyendo todas sus derivadas temporales.
6. Recuperación de desplazamientos, velocidades, aceleraciones y reacciones sísmicas con la misma cinemática.

En el instante de referencia, con Wn como generador nodal:

```text
D_in      = Gc - 2*M*Wn
massRate  = Wn*M - M*Wn
G_in      = Gc - M*Wn - Wn*M
Ktransport= -Gc*Wn + M*Wn^2
D_total   = C + G_in + massRate
```

`G_in` es antisimétrica; `massRate` es simétrica y no es amortiguamiento material. El cubo centrado tiene `Gtheta,in = -skew(J*Omega)`. Esta expresión y la corrotante no son alternativas elegibles: corresponden a coordenadas diferentes conectadas por un transporte explícito.

Para q = T(t) z:

```text
Mr = T'*M*T
Dr = T'*(D*T + 2*M*Tdot)
Kr = T'*(K*T + D*Tdot + M*Tddot)
```

Se separan `Ktransport`, `massRate`, `constraintD` y `constraintK` en los operadores guardados. El equilibrio estático se vuelve a resolver con la fuerza centrífuga corregida; las diferencias de resultados no pueden atribuirse exclusivamente a G.

## Archivos principales

Implementación física:

- `+elements/rotating_section_operators.m` — expansión energética seccional.
- `+elements/timoshenko_gyroscopic_matrix.m` — integración distribuida consistente.
- `+assembly/rotating_mass_gyroscopic_matrix.m` — contribución rígida corrotante.
- `+assembly/transport_rotating_operators.m` — transporte inercial.
- `+assembly/assemble_gyroscopic_matrix.m` — ensamblaje por componentes rotantes.
- `+equilibrium/centrifugal_loads.m` — fuerza y tangente centrífugas.
- `+assembly/build_operating_matrices.m` — operadores completos y reducidos.
- `+rigid/rotating_constraint_derivatives.m` — restricciones raíz–cubo.
- `+rotor/blade_frame_transformation.m` — base homóloga temporal.
- `+dynamics/recover_full_response.m` y `+dynamics/run_seismic_analysis.m` — recuperación física.

Se actualizaron el coordinador, metadatos y verificaciones dependientes de estas identidades. No se relajaron tolerancias para obtener aceptación. La condición anterior de marco homólogo constante se sustituyó por una comprobación independiente de sus derivadas.

## Verificación independiente

Regresión final: **143 aprobadas, 0 fallidas y 0 incompletas**. Se agregaron 17 pruebas físicas, además de adaptar las comprobaciones existentes a las ecuaciones corregidas:

- Siete pruebas de energía y rotación. Una implementación independiente de la energía usa exponenciales matriciales y diferencias centrales con extrapolación de Richardson; contrasta masa, derivadas mixtas, giroscopía, fuerza y rigidez centrífugas, incluyendo anisotropía, eje no principal y excentricidad. Incluye el caso traslacional del ejemplo 4.4 de Meirovitch y comparaciones con las ecuaciones de Euler.
- Cinco pruebas de marcos y restricciones: derivadas temporales por diferencias finitas y equivalencia de residuos completos/reducidos.
- Cinco pruebas de recuperación sísmica: cinemática física independiente, proyección de fuerzas, movimiento absoluto, apoyos y compatibilidad con mapas constantes.

Resultado MATLAB persistido en `runs/gyro_revision_20260919_comparison/regression_results.mat`. La verificación numérica no sustituye la validación experimental ni cubre un modelo temporal periódico que todavía no se integra.

## Corridas nuevas y comparación histórica

### Barrido rotodinámico

Nueva corrida con marcador `SUCCESS`:

`runs/run_20260919_182410_438_gyro_energy_corrected_20260919`

Nueve velocidades: 0, 1.5, 3, 4.5, 6, 7.5, 9, 10.5 y 12 rpm. Pasaron las comprobaciones especializadas de MBC, QEP y seguimiento modal. El equilibrio se recalculó en cada velocidad.

La ejecución del código anterior se conserva en:

`/Users/nuseche/Documents/ChatGPT/Tesis/tmp/gyro_revision_20260919_tNQzVp/baseline/runs/run_20260919_181625_802_gyro_before_20260919`

`tools/compare_gyroscopic_runs.m` compara las corridas guardadas sin resolverlas nuevamente. Usa el mismo sistema físico completo y una única métrica de masa para ambas bases. La asignación global se basa en MAC, no en el orden de las frecuencias.

- A 0 rpm: M, K, G, D, equilibrio y las doce frecuencias seleccionadas son exactamente iguales entre versiones.
- La masa y el mapa instantáneo de restricciones permanecen iguales en las nueve velocidades.
- De 108 correspondencias, 100 admiten identificación individual según los criterios declarados. Las ocho restantes se señalan como mezcla o agrupamiento modal; no se presentan como equivalencias individuales inequívocas.
- A 12 rpm, la primera rama histórica se empareja con la segunda nueva: 0.145471352 → 0.160195340 Hz, cambio +10.121572 %, MAC 0.957168. Comparar índices sin emparejar formas ocultaría ese intercambio.
- Los modos 10–11 a 12 rpm se tratan como subespacio, con MAC subespacial mínimo 0.998808350.
- Las raíces calculadas tienen parte real negativa, pero `spectrumComplete=false`: esto no demuestra estabilidad del espectro completo ni estabilidad de Floquet.

Los cambios porcentuales son diferencias frente a una implementación histórica, **no errores frente a una solución física exacta**. Los CSV distinguen los bloques dimensionalmente homogéneos de las normas globales de operadores, que mezclan unidades generalizadas.

### Respuesta sísmica

Nueva corrida con marcador `SUCCESS`:

`runs/run_20260919_183052_480_gyro_corrected_seismic_20260919`

Pasaron **30/30 verificaciones especializadas** a 0 y 12 rpm. El sismo es el mismo benchmark analítico de dos componentes del caso Acción 09. Indicadores obtenidos:

| Indicador | Valor | Criterio del caso |
|---|---:|---:|
| Residual dinámico relativo | 5.50548e-13 | ≤ 1e-9 |
| Proyección del equilibrio completo | 5.55313e-13 | ≤ 1e-9 |
| Balance energético discreto del sistema congelado | 1.05838e-12 | ≤ 1e-6 |
| Orden temporal observado, SDOF | 1.99752 | ≥ 1.9 |
| Orden temporal observado, canal uy del nodo 129 | 2.00147 | ≥ 1.8 |
| Diferencia relativa entre pasos 0.0025 y 0.00125 s, canal seleccionado | 3.15588e-4 | ≤ 1e-3 |

La comparación histórica sísmica usa la corrida `run_20260831_163238_997_action09_seismic_newmark`. `tools/compare_seismic_revision.m` verificó igualdad exacta de tiempos y cinemáticas del suelo; no interpoló ni reintegró. `seismic_channels.csv` contiene 60 filas: cinco nodos, tres componentes, dos magnitudes y dos velocidades; cada canal tiene 101 muestras a paso 0.01 s.

A 0 rpm los 30 canales son exactamente iguales. A 12 rpm:

| Canal | Pico anterior | Pico nuevo | Cambio de pico |
|---|---:|---:|---:|
| Desplazamiento relativo, nodo 56, z | 3.460612 mm | 5.030317 mm | +45.3592 % |
| Desplazamiento relativo, nodo 92, z | 1.543641 mm | 2.091007 mm | +35.4594 % |
| Aceleración absoluta, nodo 92, z | 0.21389544 m/s² | 0.20702714 m/s² | −3.2111 % |
| Aceleración absoluta, nodo 130, y | 0.04528433 m/s² | 0.03538368 m/s² | −21.8633 % |

El máximo cambio relativo L2 de la historia de desplazamiento es 167.4797 % (nodo 92, z); no significa que el pico crezca ese porcentaje. El máximo cambio L2 de aceleración es 56.8834 % en el mismo nodo/componente. Estos indicadores comparan dos implementaciones del modelo congelado, no errores contra una referencia experimental.

## Documento matemático y reproducción

Fuentes: `docs/formulacion_matematica_20260919/FORMULACION_MATEMATICA.tex`, `giroscopia.tex`, `amca.cls` y `modelo.pdf`. Se entrega un documento independiente con formato AMCA/MECOM y derivación energética detallada, sin capítulo de tests ni resultados. No se modificó el abstract del artículo MECOM ni sus versiones históricas.

PDF final: `output/pdf/FORMULACION_MATEMATICA_ROTODINAMICA_20260919.pdf`, 18 páginas A4, 159475 bytes. Se inspeccionaron las 18 páginas renderizadas después de la última compilación: sin solapes ni recortes. La compilación no presenta desbordamientos ni referencias indefinidas; conserva un aviso de espaciado bajo en una entrada bibliográfica sin defecto visual. SHA-256: `8cdb212220b150d85808dcb1fa4e65e33489746efe924c6c56543ad60c8cf156`.

Paquete editable: `output/FORMULACION_MATEMATICA_ROTODINAMICA_20260919_LaTeX.zip`, cinco archivos, integridad comprobada con `unzip -t`. SHA-256: `4791ff85ccce0171bdc989bcf727b457e9af68ad9f799c51e7698f3167414d39`.

Desde la raíz del proyecto, en MATLAB:

```matlab
addpath(pwd); addpath('cases'); addpath('tests'); addpath('tools');
run_all_tests(fullfile(tempdir,'gyro_regression_reproduced.mat'));
cfg=config_action08_mbc_qep_campbell();
cfg.output.makeFigures=false;
cfg.run.identifier="gyro_energy_corrected_reproduction";
main(cfg);
cfg=config_action09_seismic_newmark();
cfg.output.makeFigures=false;
cfg.run.identifier="gyro_corrected_seismic_reproduction";
main(cfg);
```

Para compilar, desde el directorio de fuentes LaTeX:

```sh
tectonic --keep-logs FORMULACION_MATEMATICA.tex
```

## Preservación y límites de la aceptación

Se conservaron las corridas e informes previos. El snapshot previo de código está en `runs/gyro_revision_20260919_comparison/source_before.tar.gz`, SHA-256 `90ae35daa74a9d3d0430b13ac2e87cdac15d2502b89c430ce9d3ae50cfd191b6`. No se sobrescribió `tests/latest_results.mat` histórico; la regresión nueva tiene archivo propio.

El código posterior, casos, pruebas y utilidades se conservan además en `runs/gyro_revision_20260919_comparison/source_after.tar.gz`, SHA-256 `c65cd278a293b35ab26ecc8a39ade2e0e80c88a72de74d0743329879464b8222`; las fuentes matemáticas se entregan en el ZIP separado. El SHA-256 de `regression_results.mat` es `f908c216d0b7f2403ab5c4599c0a02c603666a85cb488b44fda3bb97c8b16bab`.

Una primera corrida nueva, `run_20260919_182230_750_gyro_energy_corrected_20260919`, falló por una condición obsoleta que exigía constante el marco homólogo de pala. Se conserva como intento fallido, no como evidencia de aceptación. La corrida nueva citada arriba terminó después de sustituir esa condición por la derivada cinemática correcta y su verificación independiente.

Las aceptaciones anteriores de Acciones 02–10 son históricas. La revisión actual cuenta con regresión completa y nuevas corridas especializadas 08 y 09; no se presenta el informe integral antiguo ni la aceptación 10 de agosto como si se hubieran regenerado con estas ecuaciones. Su actualización editorial y la comparación contra otro modelo físico independiente son trabajos distintos.
