# Informe de aceptación — Acción 09: sismo y Newmark

**Fecha:** 31 de agosto de 2026  
**Entorno:** MATLAB R2026a Update 4, MACA64  
**Corrida canónica:** `runs/run_20260831_163238_997_action09_seismic_newmark`  
**Estado:** aceptada como verificación numérica; no es un análisis sísmico de diseño.

## 1. Alcance aceptado

La Acción 09 integra respuesta sísmica relativa multicomponente con Newmark de
aceleración promedio constante, en operadores físicos congelados a 0 y 12 RPM.
Recupera cinemática absoluta completa, fuerzas generalizadas de restricción,
reacciones en los GDL fijos y fuerzas incrementales de extremo de los 133
elementos Timoshenko activos. La integración temporal no aplica una
transformación MBC congelada.

El registro canónico tiene dos componentes analíticas suaves con `ag/vg/ug` en
SI. Está etiquetado como `synthetic_verification_not_design_accelerogram`.
La rigidez del tren, los objetivos Rayleigh y los coeficientes aerodinámicos
siguen etiquetados como benchmark/no calibrados.

## 2. Evidencia de aceptación

La corrida canónica contiene `SUCCESS`, `manifest.hasAction09=true` y
`manifest.action09Passed=true`. Las 30 verificaciones especializadas fueron
críticas y pasaron. Las métricas principales fueron:

| Verificación | Resultado | Puerta |
|---|---:|---:|
| Preservación de `ag/vg/ug` suministrados | `0` | `<=1e-12` |
| Compatibilidad de `GammaKinematic` | `0` | `<=1e-12` |
| Proyección de masa consistente | `3.8771e-17` | `<=1e-12` |
| Identidad y signo de fuerza sísmica | `0` | `<=1e-14` |
| Residuo dinámico máximo | `6.1205e-13` | `<=1e-9` |
| Balance energético del modelo | `1.0584e-12` | `<=1e-6` |
| Identidad de cinemática absoluta | `4.4345e-17` | `<=1e-12` |
| Equilibrio proyectado de restricciones | `6.2262e-13` | `<=1e-9` |
| Error SDOF en la malla fina | `2.1861e-6` | `<=1e-4` |
| Orden temporal mínimo SDOF | `1.9975` | `>=1.9` |
| Error de superposición | `4.0711e-14` | `<=1e-10` |
| Error elemental local/global hacia atrás | `3.1941e-17` | `<=1e-12` |
| Error de ensamblaje de fuerzas elementales | `2.6422e-14` | `<=1e-12` |
| Orden temporal mínimo del modelo completo | `2.0017` | `>=1.8` |
| Diferencia relativa entre mallas finas | `3.0719e-4` | `<=1e-3` |
| Diferencia de máximos entre mallas finas | `2.3236e-4` | `<=1 %` |
| Norma `G` a 0 RPM | `0` | `=0` |
| Norma `G` a 12 RPM | `5.0669e6` | `>0` |

La convergencia usó `dt=[0.02, 0.01, 0.005, 0.0025, 0.00125] s`; el paso de
producción permanece en `0.01 s`. Las dos puertas finas son independientes:
una compara la forma de onda y otra el máximo del canal físico nodo 129,
componente `uy`.

La suite específica `tests/test_action09_seismic_newmark.m` pasó 9/9. La
regresión completa posterior pasó **126/126**, con cero fallos y cero pruebas
incompletas, y quedó guardada en `tests/latest_results.mat`.

## 3. Artefactos auditados

La corrida contiene los siete CSV especializados, `time_history.csv` con
canales identificados por nodo/componente/unidad, `time_extrema.csv`, el MAT
completo y `figures/response.png`. El tensor completo de fuerzas elementales
permanece en MAT; el CSV contiene solo envolventes.

Se recargaron `configuration.mat`, `model_snapshot.mat` y `results.mat`, y se
regeneraron las tablas y la figura mediante `post.export_action09` sin volver a
ensamblar el modelo. La figura fue inspeccionada visualmente: muestra respuestas
`uy` de góndola, rotor y las tres puntas, junto con las dos aceleraciones del
terreno, con unidades y leyendas legibles.

Hashes SHA-256 de la evidencia principal:

| Archivo | SHA-256 |
|---|---|
| `action09_matrices.mat` | `5421145eba1316c79d8d4664acbd79bfec874d44a2ddceb22d2ae29ef1ee6ff9` |
| `action09_validation.csv` | `b26abe3cb0ed704eea2d85802bd79ad6f3723a0c79fcca4988ea18d2f7717411` |
| `figures/response.png` | `de4656cd536c8acfe862fb288d709e587fdec6dffe87d68ae4fbf3628e8eb3a0` |
| `tests/latest_results.mat` | `40228b4713304acad90d67fe8a87ae813ea44e92ce0f77f1d8f585ffc728eab8` |

## 4. Observaciones y límites

- El cálculo valida el solver linealizado a velocidad constante y punto
  operativo congelado; no es un análisis de Floquet.
- No se seleccionó un acelerograma real, espectro objetivo, escalamiento
  normativo ni combinación direccional de diseño.
- `scaleFactor` se conserva deliberadamente como un escalar único para todas
  las componentes; cualquier escalamiento direccional futuro deberá declararse
  como una ampliación del esquema y volver a validarse.
- Las fuerzas internas son incrementales alrededor del equilibrio operativo;
  no vuelven a sumar la precarga estática.
- `KOmega=0` es coherente con el ledger actual porque la contribución
  centrífuga ya está incluida una sola vez en `Kg`.
- La validación global emitió un aviso no fatal de falta de convergencia de
  `eigs` al estimar un autovalor de amortiguamiento. El código detecta el `NaN`
  devuelto por ARPACK y usa un cálculo directo determinista; la puerta global
  correspondiente y la regresión completa pasaron.

Con estas limitaciones explícitas, la Acción 09 queda aceptada como benchmark
numérico reproducible y puede ser consumida por la validación integral de la
Acción 10.
