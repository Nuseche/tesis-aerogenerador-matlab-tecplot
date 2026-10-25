# Plan autocontenido de continuación desde el estado actual

**Proyecto:** modelo estructural, rotodinámico y sísmico de un aerogenerador  
**Fecha de corte:** 19 de septiembre de 2026  
**Repositorio de cálculo:** `/Users/nuseche/Desktop/Tesis_codigos`  
**Directorio editorial:** `/Users/nuseche/Documents/ChatGPT/Tesis`  
**Entorno verificado:** MATLAB R2026a Update 4  
**Estado global:** revisión energética giroscópica implementada y verificada
el 19 de septiembre: 143/143 pruebas, nuevas corridas especializadas 08 y 09
exitosas y documento matemático independiente. Los informes anteriores
no han sido regenerados con esta revisión y conservan carácter histórico.

## Revisión que supersede el estado rotodinámico anterior — 19/09/2026

- Registro técnico, alcance y reproducción: `docs/GYROSCOPIC_REVISION_20260919.md`.
- Formulación matemática LaTeX: `docs/formulacion_matematica_20260919/FORMULACION_MATEMATICA.tex`.
- Barrido nuevo: `runs/run_20260919_182410_438_gyro_energy_corrected_20260919`.
- Sismo nuevo: `runs/run_20260919_183052_480_gyro_corrected_seismic_20260919`, 30/30 verificaciones.
- Evidencia comparativa, regresión y copia previa: `runs/gyro_revision_20260919_comparison/`.

La giroscopía, fuerza/tangente centrífugas, transporte inercial, restricciones
temporales y recuperación sísmica utilizan ahora una cadena energética y
cinemática consistente. A 0 rpm se conserva exactamente la comparación
histórica; con giro cambian operadores y resultados. El modelo sigue siendo
de pequeñas perturbaciones a azimut congelado, no un análisis de Floquet.
Las aceptaciones y cifras antiguas que siguen se mantienen como trazabilidad;
no constituyen una nueva aceptación del informe integral con estas ecuaciones.

**Estado histórico hasta el 09/09/2026:** Acciones 02–10 aceptadas; cierre editorial y paquete MECOM
sincronizados el 31 de agosto de 2026; informe integral recompuesto como
documento LaTeX nativo de estilo MECOM y reeditado el 9 de septiembre de 2026
para concentrarlo exclusivamente en resultados, ecuaciones e interpretación.

## 0. Cierre ejecutado

Este plan fue completado. Las instrucciones futuras de las secciones 7–13 se
conservan como trazabilidad del proceso, pero su estado pendiente queda
supersedido por la evidencia siguiente:

- Acción 09: `run_20260831_163238_997_action09_seismic_newmark`, `SUCCESS`,
  30/30 puertas especializadas y recarga independiente;
- Acción 10: `run_20260831_165045_307_action10_full_acceptance`, `SUCCESS`,
  649/649 requisitos, 8/8 suites y 8/8 artefactos con SHA-256;
- regresión final: 126/126, cero fallos e incompletas;
- artículo MECOM: versión metodológica con benchmarks aceptados, 9 páginas A4,
  PDF inspeccionado visualmente y paquete final regenerado desde el mismo
  estado.
- informe ampliado de resultados:
  `docs/resultados_integrales/INFORME_RESULTADOS_COMPLETOS.md`, con descripción
  de la conversión de malla, demostración por rango–nulidad y espectro de los
  seis modos rígidos, inserción de sismo y viento, formulación completa del
  problema de autovalores, métricas relativas, límites físicos y 30 figuras de
  resultados;
- evidencia complementaria reproducible en
  `docs/resultados_integrales/evidence/`, generada por
  `tools/generate_comprehensive_evidence.m`, y catálogo gráfico regenerable con
  `tools/generate_comprehensive_figures.py`.
- informe integral LaTeX en
  `docs/resultados_integrales/latex/INFORME_RESULTADOS_COMPLETOS_MECOM.tex`,
  con la misma clase `amca`, formato A4, una columna, Times, caja de texto de
  16×24 cm, portada, jerarquía de títulos y pies de figura del documento MECOM;
- PDF LaTeX canónico en
  `output/pdf/INFORME_RESULTADOS_COMPLETOS_MECOM.pdf`: 40 páginas A4, 30
  figuras consecutivas, índice, nomenclatura, bibliografía y revisión visual
  completa; excluye suites, hashes, conteos de pruebas y auditoría de
  artefactos. Se reconstruye con `tools/build_complete_results_latex.py` y Tectonic.

## 1. Propósito y regla de uso

Este documento permite continuar el proyecto sin depender de la conversación
previa. Resume el estado comprobado directamente en el sistema de archivos,
separa resultados aceptados de los antecedentes de desarrollo y conserva el
orden de implementación, las pruebas y los artefactos que se usaron para cerrar
las Acciones 09 y 10 y actualizar la entrega MECOM 2026.

La fuente de verdad para el solver es el estado actual de
`/Users/nuseche/Desktop/Tesis_codigos`. Los informes y corridas se consideran
evidencia solo si contienen resultados reproducibles y un marcador `SUCCESS`.
Una prueba verde demuestra únicamente lo que efectivamente cubre; no sustituye
una aceptación especializada ausente.

El directorio no contiene actualmente un repositorio `.git`. Por tanto, la
trazabilidad depende de informes, manifiestos, corridas, hashes y copias
externas. Antes de introducir cambios extensos en las Acciones 09–10 se
recomienda inicializar control de versiones o, si ello no está autorizado,
crear un snapshot fechado con inventario y hashes SHA-256. Esta operación no
debe alterar las corridas canónicas aceptadas.

No se debe presentar como dato físico calibrado ningún valor que el legado no
proporcione. En particular, deben mantenerse visibles las etiquetas de
benchmark, hipótesis o dato ausente.

## 2. Fuentes y entregables existentes

### 2.1 Material científico de entrada

- Modelo de tesis:
  `/Users/nuseche/Downloads/Modelo_tesis.pdf`.
- Propuesta de tesis:
  `/Users/nuseche/Downloads/Desktop/Tesis/Propuesta_de_tesis_final.pdf`.
- Artículo MECOM 2023 de referencia:
  `/Users/nuseche/Downloads/2023 MECOM 2023 6595-25594-1-PB.pdf`.
- Plantilla original MECOM:
  `/Users/nuseche/Downloads/Completo_work_MECOM`.
- Código MATLAB heredado:
  `/Users/nuseche/Desktop/Tesis_codigos/Codigos_sergio`.
- Copia inmutable y manifiesto del legado:
  `/Users/nuseche/Desktop/Tesis_codigos/legacy`.

### 2.2 Entrega MECOM actualmente compilada

La entrega final reproducible está en:

`/Users/nuseche/Documents/ChatGPT/Tesis/output/mecom_2026`.

El PDF canónico tiene nueve páginas A4, 272 459 bytes y cumple el rango de
4–10 páginas y el límite de 2 MB. El ZIP final es:

`/Users/nuseche/Documents/ChatGPT/Tesis/output/Completo_work_MECOM_2026_Useche.zip`.

Se adoptó la versión metodológica de autoría individual con benchmarks
numéricos del solver, etiquetados como verificaciones y no como predicción de
una turbina comercial. El PDF se recompiló desde la misma fuente incluida en
el paquete, se inspeccionaron visualmente sus nueve páginas y el ZIP pasó
`unzip -t` con 11/11 archivos. Su SHA-256 es
`d9d35c7fb86b5e64461aa7a86a23d2b9c3f5897243d5b41e687e1bf8f1bc50ac`.

El paquete del 22 de agosto se preservó como
`Completo_work_MECOM_2026_Useche_HISTORICO_20260822.zip`, con su hash original
`0a8ee84d8bc02ae8efba44b2620ac0e63f4e2eb6d0dd361792a02980686d3361`.
La variante comparativa con título y autoría distintos permanece sin cambios.

## 3. Arquitectura vigente

La arquitectura solicitada ya está establecida:

- `main.m` es el único coordinador;
- los paquetes `+elements`, `+assembly`, `+rigid`, `+equilibrium`, `+modal`,
  `+rotor` y `+dynamics` realizan los cálculos;
- `+validation` contiene puertas de aceptación;
- `+post` exporta tablas y figuras;
- `+io` carga datos, crea corridas y persiste resultados;
- `cases` contiene una configuración por caso reproducible;
- `tests` contiene la regresión MATLAB;
- `runs` conserva las corridas canónicas y sus artefactos.

La malla heredada tiene 138 nodos y 137 elementos antes de retirar conectores
artificiales. El modelo nuevo conserva 828 GDL completos; después de las MPC
quedan 810 coordenadas independientes y, con la base fija, 804 GDL de análisis.

La línea base al inicio del cierre era 107/107. Después de integrar las suites
de las Acciones 09 y 10, la regresión final del 31 de agosto terminó con:

- **126 pruebas aprobadas**;
- **0 fallidas**;
- **0 incompletas**.

El resultado quedó persistido en `tests/latest_results.mat`, cuyo SHA-256 es
`65873aa621ce5295a41447706f11dc470ac39773eb81a2c9bd7434dea9c1267b`.
Incluye las suites específicas de Acción 09 e integral de Acción 10.

## 4. Estado por acción

| Acción | Estado real | Evidencia principal | Trabajo restante |
|---|---|---|---|
| 01. Base, legado y datos | Implementada operativamente | `legacy/`, `data/`, manifiestos y validadores de entrada | Crear un informe autónomo solo si se exige simetría documental con las demás acciones |
| 02. Timoshenko 3D | Aceptada | 31/31; corrida `run_20260826_210833_538_action02_timoshenko` | Ninguno funcional; reutilizar sus métricas en tesis/MECOM |
| 03. Restricciones rígidas | Aceptada | 34/34; corrida `run_20260826_231211_426_action03_rigid_constraints` | Ninguno funcional |
| 04. Masas rígidas | Aceptada | 40/40; corrida `run_20260826_232027_996_action04_rigid_bodies` | Sustituir offsets colocalizados si aparecen datos físicos nuevos |
| 05. Formulación de masa | Aceptada | 36/36; corrida `run_20260826_232719_219_action05_mass_formulation` | Ninguno funcional |
| 06. Equilibrio y centrifugación | Aceptada como benchmark | 29/29; corrida `run_20260826_234708_429_action06_equilibrium` | Calibrar tren de potencia para una predicción física |
| 07. Operadores dinámicos | Aceptada como formulación/benchmark | 30/30; corrida `run_20260827_000911_242_action07_dynamic_operators` | Aportar aerodinámica y amortiguamiento físicos si se desea predicción |
| 08. MBC, QEP y Campbell | Aceptada | 32/32; corrida `run_20260827_090201_148_action08_mbc_qep_campbell`; regresión 107/107 | Ninguno algorítmico; no sobreafirmar estabilidad del espectro no calculado |
| 09. Sismo y Newmark | Aceptada como benchmark | 30/30; corrida `run_20260831_163238_997_action09_seismic_newmark` | Sustituir el registro sintético por demanda normativa si se busca diseño |
| 10. Validación integral | Aceptada | 649/649; corrida `run_20260831_165045_307_action10_full_acceptance`; regresión 126/126 | Ninguno funcional |

## 5. Resultados aceptados que no deben perderse

### 5.1 Elemento y masa

- `M` y `Ke` flexibles: dispersas, finitas y simétricas, `828×828`.
- Convergencia a 64 elementos:
  - desplazamiento `6.103e-5`;
  - primera frecuencia `3.643e-5`;
  - segunda frecuencia `5.838e-4`.
- Frecuencia aislada de torre: `0.7196683 Hz`.
- Frecuencias aisladas de palas: `0.4194551–0.4194880 Hz`.
- Convención local aceptada: el punto auxiliar define `e3`,
  `e2=e3×e1` y la pala usa `Jx=Jy+Jz` como regla explícita.

### 5.2 Restricciones y cuerpos rígidos

- Nodo maestro de góndola: 129.
- Nodo maestro del rotor/cubo: 130.
- Raíces 21, 57 y 93: esclavas del maestro 130.
- Los maestros 129 y 130 permanecen cinemáticamente independientes; su unión
  se representa mediante operador de tren y no mediante una MPC rígida.
- Los GDL de un cuerpo rígido no son modos adicionales. El ensamblaje
  libre-libre tiene seis modos rígidos globales; la base fija no conserva
  modos nulos.
- Los offsets de CG de góndola y cubo permanecen en cero por hipótesis explícita
  de colocalización, no porque su posición real haya sido identificada.
- La masa total aceptada, incluyendo masas rígidas, es `2,601,611.1528 kg`.

### 5.3 Equilibrio, rotación y aerodinámica

- La rigidez geométrica se obtiene del equilibrio corrotacional.
- El ledger evita duplicar un término centrífugo entre `Kg` y `KOmega`.
- La giroscopía distribuida de palas y la rígida del cubo están implementadas.
- `G(0)=0`, `G(-Omega)=-G(Omega)` y `G(2Omega)=2G(Omega)` se verifican.
- Error de benchmark giroscópico distribuido: `5.296e-17`.
- Error de frecuencias forward/backward del disco: `5.396e-16`.
- Las cargas aerodinámicas físicas no están disponibles. El caso canónico usa
  `Kaero=Caero=0` con estado `zero_unprovided_physical_coefficients`.
- Los benchmarks de tangentes aerodinámicas son sintéticos y no constituyen
  una predicción de carga.

### 5.4 MBC, QEP y Campbell

- La mezcla multiblade se realiza después de convertir cada pala a marcos
  locales homólogos mediante `H`.
- Error máximo `P^-1P`: `7.160e-16`.
- Error de `Pdot`: `4.811e-11`; error de `Pddot`: `2.101e-6`.
- Residuo QEP derecho máximo: `2.505e-16`.
- Residuo QEP izquierdo máximo: `7.494e-14`.
- Error de biortogonalidad fuera de diagonal: `7.602e-11`.
- MAC efectivo mínimo Campbell: `0.8289`.
- MAC subespacial mínimo: `0.9693`.
- El Campbell aceptado usa nueve velocidades `0:1.5:12 RPM`, 12 ramas y una
  formulación congelada en un azimut de referencia. No es un análisis de
  Floquet.
- `eigs` calcula raíces objetivo, no el espectro completo del lápiz; solo se
  puede afirmar que ninguna raíz **calculada** resultó inestable.

## 6. Hipótesis y datos todavía ausentes

Estas limitaciones deben aparecer en toda corrida final, informe, tesis y
artículo:

1. La rigidez y el amortiguamiento del tren 129–130 usados en los casos son
   benchmarks numéricos, no datos calibrados.
2. Los centros de masa se consideran colocalizados con sus maestros porque el
   legado no entrega offsets verificados.
3. Los elementos de transición tipo 4 se conservan como hipótesis heredada;
   no representan una caracterización identificada del eje o cojinetes.
4. Los objetivos Rayleigh son numéricos y no provienen de medición modal.
5. No existen coeficientes aerodinámicos físicos ni una ley seguidora calibrada.
6. No se ha seleccionado todavía un acelerograma real, espectro objetivo,
   escalamiento normativo ni combinación direccional de diseño.
7. Los casos de 12 RPM verifican el algoritmo a velocidad constante y azimut
   congelado; no reproducen por sí solos variación periódica completa.
8. La cimentación flexible existente es demostrativa y sus resultados
   históricos son anteriores a las correcciones de las Acciones 02–08.
9. Los resultados actuales validan el solver; no son aún una predicción
   publicable de una turbina comercial concreta.

## 7. Estado preciso de la Acción 09

### 7.1 Código implementado y aceptado

Los siguientes cambios quedaron integrados y cubiertos por pruebas:

- `+io/load_accelerogram.m`
  - conserva `ag`, `vg` y `ug` en SI;
  - registra si velocidad/desplazamiento fueron proporcionados o integrados;
  - aplica interpolación común;
  - incorpora `scaleFactor`;
  - obliga a resolver explícitamente una corrección de línea base incompatible
    con `vg/ug` suministrados mediante `error`, `reintegrate` o `preserve`.
- `+dynamics/influence_vector.m`
  - separa influencia absoluta completa y campo relativo compatible;
  - conserva el residuo de compatibilidad con `Tc`.
- `+dynamics/run_seismic_analysis.m`
  - proyecta la fuerza inercial consistente como
    `Tc'*Mfull*Rfull` cuando dispone de matrices completas;
  - distingue `GammaKinematic` de `GammaEffective`;
  - rechaza una fuerza adicional reducida cuya distribución completa sea
    ambigua cuando se solicitan reacciones;
  - calcula fuerza generalizada de restricción y residuo proyectado.
- `+dynamics/newmark_integrate.m`
  - impone por defecto la condición de estabilidad incondicional;
  - reutiliza factorización para paso constante usando un `dt` algorítmico
    único;
  - calcula trabajo y energía mediante incrementos compatibles con Newmark.
- `+dynamics/recover_full_response.m`
  - recupera desplazamiento, velocidad y aceleración absoluta completos;
  - separa fuerzas de restricción completas y reacciones en GDL fijos.
- `+dynamics/recover_element_forces.m`
  - recupera fuerzas de extremo locales y globales Timoshenko;
  - guarda axial, cortantes, torsión y momentos;
  - etiqueta el resultado como incremento linealizado alrededor del equilibrio.

El documento de diseño ya existe en
`docs/ACTION09_IMPLEMENTATION_PLAN.md`.

### 7.2 Evidencia de desarrollo y cierre aceptado

Durante el desarrollo se ejecutaron 15 pruebas focalizadas —11 de dinámica,
una de modelo completo y las de E/S relacionadas— y todas pasaron. La suite
final incorporó nueve pruebas etiquetadas específicamente como Acción 09 y la
regresión completa creció a 126/126.

El benchmark SDOF armónico con condiciones iniciales exactas produjo:

| `dt` | Error máximo de desplazamiento |
|---:|---:|
| `0.040` | `2.8681e-4` |
| `0.020` | `7.1800e-5` |
| `0.010` | `1.7886e-5` |
| `0.005` | `4.4727e-6` |

Los órdenes observados fueron `1.9980`, `2.0052` y `1.9996`. El residuo
dinámico máximo fue `2.93e-13` y el error de balance energético `2.86e-13`.
Los parámetros Newmark condicionalmente estables fueron rechazados con el
identificador esperado y `ag/vg/ug` se preservaron con error cero.

En una ejecución corta multicomponente del modelo real de 804 GDL:

| Métrica | 0 RPM | 12 RPM |
|---|---:|---:|
| Residuo dinámico | `8.04e-13` | `5.46e-13` |
| Balance energético | `8.30e-13` | `2.45e-13` |
| Equilibrio proyectado | `8.06e-13` | `5.33e-13` |
| Error de proyección de masa | `3.88e-17` | `3.88e-17` |
| Identidad de fuerza sísmica | `5.10e-17` | `5.10e-17` |
| Identidad cinemática absoluta | `0` | `3.72e-17` |

También se obtuvo `G(0)=0` y `||G(12 RPM)||_F=5.119e6`. El hecho de que
`KOmega(12 RPM)=0` es correcto para el ledger actual porque
`centrifugalIncludedInKg=true`; la norma de fuerzas axiales centrífugas es
`4.266e7`. El futuro validador debe comprobar que esta contribución aparezca
exactamente una vez y no exigir que `KOmega` sea no nula.

Se recuperaron fuerzas para 133 elementos. El error global de ensamblaje fue
`3.26e-14`. El máximo relativo local/global llegó a `3.13e-12` en canales cuya
fuerza resultante era casi nula. Por ello, la puerta crítica debe utilizar
además un error hacia atrás normalizado con una escala como
`||Ke||*||qe||`; el error relativo convencional debe conservarse como
diagnóstico, no convertirse en fallo espurio por dividir entre una magnitud
insignificante.

Un benchmark separado de consistencia algebraica obtuvo proyección de masa
`3.877e-17`, compatibilidad cinemática cero, residuo proyectado de reacciones
`2.430e-13`, separación entre influencias efectiva/cinemática de `2.3866 %`,
error elemental local/global `4.751e-16` y error de ensamblaje `1.597e-16`.
Las diferencias con los máximos anteriores obedecen al caso y a la
normalización empleada; ambas verificaciones deben documentarse en la suite.

Un estudio temporal previo del aerogenerador completo mostró que `dt=0.02 s`
no basta: el máximo de punta de pala cambió `1.13 %` al pasar a `0.01 s`.
Entre `0.005` y `0.0025 s`, el máximo error de las cuatro métricas ensayadas
fue `6.75e-4`. Esto justifica una puerta de convergencia fina de `1e-3`.

Estas cifras se conservan como trazabilidad de desarrollo. La aceptación final
se sustenta en la corrida canónica y la suite descritas a continuación.

### 7.3 Componentes completados

Se completaron:

- `cases/config_action09_seismic_newmark.m`;
- una rama `action09Only` en `main.m`;
- conservación de `elementCache` en esa rama;
- `+validation/run_seismic_newmark_suite.m`;
- `tests/test_action09_seismic_newmark.m`;
- `+post/export_action09.m` y su conexión en `export_all.m`;
- persistencia `action09_matrices.mat` y campos de manifiesto en
  `+io/save_results.m`;
- canales de salida identificados por nodo/componente, no solo por índice
  reducido;
- decisión documentada de mantener `scaleFactor` escalar en el benchmark
  canónico, sin impedir una futura extensión por componente;
- corrida canónica `run_..._action09_seismic_newmark`;
- inspección visual de `figures/response.png`;
- recarga independiente de los artefactos;
- `docs/ACTION09_ACCEPTANCE_REPORT.md`;
- regresión completa posterior a la nueva suite.

La corrida histórica `run_20260825_162921_948_seismic_demo` no se reutilizó
como aceptación porque precede las correcciones de las Acciones 02–08.

La corrida canónica
`run_20260831_163238_997_action09_seismic_newmark` contiene `SUCCESS`, 30/30
puertas especializadas, artefactos recargables y figura inspeccionada. Por
tanto, Acción 09 queda marcada como **aceptada como benchmark numérico**.

## 8. Trazabilidad de implementación ejecutada para cerrar la Acción 09

### Paso 9.1. Congelar el punto de partida

1. Conservar `tests/latest_results.mat` con el resultado 107/107.
2. Registrar en el informe de desarrollo que los cambios parciales descritos en
   7.1 ya existen.
3. No modificar las corridas canónicas 02–08.
4. Ejecutar antes de cada bloque:

```matlab
cd('/Users/nuseche/Desktop/Tesis_codigos')
addpath(pwd)
r = runtests('tests/test_dynamics_newmark.m');
assertSuccess(r)
```

### Paso 9.2. Crear el caso canónico

Crear `cases/config_action09_seismic_newmark.m` con:

- `analysis.type="action09_seismic_newmark"`;
- base fija y masa consistente;
- puntos de operación 0 y 12 RPM;
- punto primario rotante a 12 RPM;
- dos componentes sísmicas sintéticas suaves con `ag/vg/ug` analíticas;
- `baselineCorrection="none"` para no invalidar las series analíticas;
- `scaleFactor` explícito;
- `beta=1/4`, `gamma=1/2`, `dt=0.01 s` para producción;
- mallas `0.02`, `0.01`, `0.005` para convergencia;
- tren, Rayleigh y aerodinámica con sus estados de calibración;
- figuras y canales físicos habilitados.

El registro sintético debe quedar etiquetado como benchmark. Un ejemplo robusto
es definir desplazamientos del suelo proporcionales a `sin(omega*t)^3`, cuyas
velocidad y aceleración se obtienen analíticamente y comienzan sin salto.

El canal de convergencia principal debe resolverse por identidad física —nodo
maestro de góndola 129, componente `uy`— y no codificando su índice reducido.
En el estado auditado corresponde al GDL de análisis 746, pero ese número puede
cambiar al modificar restricciones.

### Paso 9.3. Integrar la rama en `main.m`

La rama de Acción 09 debe:

1. ensamblar y conservar `elementCache`;
2. añadir masas rígidas y construir `Tc`;
3. resolver el barrido de equilibrio 0/12 RPM;
4. preparar operadores completos y reducidos en ambos puntos;
5. ejecutar primero el caso estacionario y después el rotante;
6. recuperar estados completos y absolutos;
7. recuperar fuerzas elementales del caso rotante;
8. llamar a la suite especializada;
9. fijar `results.meta.analysisScope` a una descripción que incluya
   “respuesta sísmica linealizada, multicomponente, punto operativo congelado”.

No se debe introducir la formulación MBC congelada dentro de la integración
temporal salvo que se derive y valide expresamente. La Acción 09 puede integrar
los operadores físicos reducidos de cada punto operativo.

### Paso 9.4. Completar la suite especializada

Crear `+validation/run_seismic_newmark_suite.m` con verificaciones críticas de:

1. preservación y unidades de `ag/vg/ug`;
2. política de línea base con cinemática proporcionada;
3. compatibilidad `Tc*GammaKinematic=RCompatible`;
4. identidad
   `Mr*GammaEffective=Tc'*Mfull*Rfull`;
5. signo y suma de la fuerza sísmica;
6. rechazo de parámetros Newmark condicionalmente estables;
7. SDOF de excitación de base con solución cerrada;
8. orden temporal `>=1.9`;
9. superposición multicomponente;
10. residuos dinámicos estacionario y rotante;
11. balance energético algorítmico;
12. cinemática absoluta reducida/completa;
13. `Tc'*constraintForcesFull≈0`;
14. reacciones de apoyo separadas de fuerzas MPC;
15. fuerzas elementales local/global, error hacia atrás y ensamblaje;
16. convergencia del modelo completo;
17. presencia de `G` a 12 RPM y ausencia a 0 RPM;
18. finitud y dispersidad de todos los operadores y resultados;
19. trazabilidad del registro, configuración y punto operativo.

### Paso 9.5. Usar criterios cuantitativos

| Verificación | Puerta recomendada |
|---|---:|
| Preservación de serie suministrada | `<=1e-12` relativa |
| Compatibilidad cinemática | `<=1e-12` |
| Proyección de masa consistente | `<=1e-12` |
| Identidad de fuerza de base | `<=1e-14` |
| Error SDOF en malla fina | `<=1e-4` |
| Orden temporal SDOF | `>=1.9` |
| Superposición lineal | `<=1e-10` |
| Residuo dinámico máximo, excepto estado inicial | `<=1e-9` |
| Balance energético SDOF | `<=1e-8` |
| Balance energético modelo completo | `<=1e-6` |
| Equilibrio proyectado completo | `<=1e-9` |
| Error hacia atrás elemental | `<=1e-12` |
| Ensamblaje de fuerzas de viga | `<=1e-12` |
| Orden de convergencia del modelo completo | `>=1.8` |
| Diferencia relativa entre mallas finas | `<=1e-3` |
| Diferencia de máximos entre mallas finas | `<=1 %` |

El balance energético compatible se debe presentar como exacto para
`beta=1/4`, `gamma=1/2`. Otros parámetros pueden introducir disipación
algorítmica y requieren un término energético adicional; no deben evaluarse con
la misma identidad sin explicación.

### Paso 9.6. Crear pruebas unitarias específicas

Crear `tests/test_action09_seismic_newmark.m` con pruebas pequeñas y una prueba
canónica. Debe cubrir, al menos:

- series `ag/vg/ug` con conversión y escalamiento;
- error ante línea base incompatible;
- diferencia esperada entre `GammaKinematic` y `GammaEffective`;
- proyección de masa completa;
- rechazo de `beta=0.1`, `gamma=0.1`;
- balance conservativo y amortiguado;
- distribución completa obligatoria de una fuerza adicional;
- recuperación de restricciones y apoyos;
- fuerzas elementales;
- suite canónica completa.

### Paso 9.7. Exportar artefactos legibles

Crear `+post/export_action09.m`. No se debe exportar el tensor completo
`133×12×Nt` a CSV. Ese tensor debe guardarse en MAT; los CSV deben contener
resúmenes y envolventes:

- `action09_validation.csv`;
- `action09_ground_motion.csv`;
- `action09_time_convergence.csv`;
- `action09_sdof_benchmark.csv`;
- `action09_response_extrema.csv`;
- `action09_reactions.csv`;
- `action09_element_forces.csv`.

Los canales deben identificarse con `nodeId`, componente y unidad. Como mínimo:

- base, nodo 1;
- góndola, nodo 129;
- rotor, nodo 130;
- puntas de pala, nodos 56, 92 y 128;
- reacción/momento de base;
- raíz y elemento crítico de torre/palas.

No debe publicarse un índice reducido aislado como si identificara una magnitud
física.

### Paso 9.8. Persistir y recargar

Ampliar `+io/save_results.m` con:

- `action09_matrices.mat`;
- `M/D/K` completos y reducidos del punto estacionario y rotante;
- `Tc`, `Rfull`, `GammaKinematic`, `GammaEffective`;
- registro procesado;
- respuestas estacionaria/rotante;
- resultados de convergencia;
- fuerzas internas completas;
- suite de Acción 09;
- `manifest.hasAction09` y `manifest.action09Passed`.

La recarga debe reproducir tablas, diagnósticos y figuras sin reensamblar.

### Paso 9.9. Ejecutar aceptación

El orden de aceptación será:

```matlab
results = main('cases/config_action09_seismic_newmark.m');
```

Después:

```matlab
addpath(fullfile(pwd,'tests'))
run_all_tests(fullfile(pwd,'tests','latest_results.mat'))
```

Solo se redactará `docs/ACTION09_ACCEPTANCE_REPORT.md` cuando:

- todas las verificaciones especializadas pasen;
- la regresión completa pase sin fallos/incompletas;
- el MAT se recargue correctamente;
- la figura se inspeccione visualmente;
- la interpretación estacionaria/rotante esté documentada.

## 9. Trazabilidad de implementación ejecutada para cerrar la Acción 10

### Paso 10.1. Crear el plan de Acción 10

Antes de modificar validadores, crear
`docs/ACTION10_IMPLEMENTATION_PLAN.md`. Debe mapear cada requisito del plan
director a una prueba, un artefacto y una tolerancia.

Como corrección documental previa, `docs/IMPLEMENTATION_REPORT.md` no debe
presentar 09 y 10 como terminadas: la evidencia auditada no respalda todavía
esa afirmación. El estado de este plan debe prevalecer hasta que existan sus
respectivos informes y corridas de aceptación.

### Paso 10.2. Separar validación previa y posterior

Actualmente `run_validation_suite` se ejecuta después de los análisis. Debe
separarse en:

- **preflight:** datos, malla, secciones, marcos, restricciones, rango y
  propiedades de operadores antes del solve;
- **postflight:** residuos, convergencia, modalidades, energía, reacciones,
  continuidad Campbell y persistencia después del solve.

`main.m` debe detenerse antes del análisis si falla una puerta preflight
crítica.

### Paso 10.3. Ampliar propiedades matriciales

`check_matrix_properties.m` revisa principalmente `M`, `Ke`, `Kg`, `KOmega` y
`G`. Debe ampliarse a:

- finitud de `C`, `D`, `K`, `Kaero`, `Caero`;
- simetría de componentes mecánicos pasivos;
- semidefinición positiva de amortiguamiento pasivo;
- antisimetría y finitud de `G`;
- identidades `D=C+G` y
  `K=Ke+Kg+KOmega+Kaero`;
- dispersidad global;
- definición positiva estricta de `M` reducida;
- condicionamiento/rango numérico de `Tc`, no solo `sprank` estructural.

Las matrices aerodinámicas no simétricas no deben simetrizarse para satisfacer
una prueba.

### Paso 10.4. Integrar puertas modales y Campbell

La validación global actualmente exige casi solo autovalores finitos. Debe
incorporar:

- residuo QEP derecho e izquierdo;
- error de pares conjugados;
- normalización y biortogonalidad;
- clasificación modal no vacía;
- MAC individual y subespacial;
- continuidad de ramas;
- equivalencia conservativa a 0 RPM;
- declaración de espectro parcial cuando se use `eigs`.

### Paso 10.5. Integrar puertas temporales

La validación temporal debe revisar `q`, `qd`, `qdd`, cinemática absoluta,
fuerzas de restricción, reacciones, fuerzas internas, energía y convergencia.
El balance energético debe ser crítico en los casos que declaran esa puerta;
la tolerancia histórica no crítica de `0.1` debe retirarse.

### Paso 10.6. Mejorar mensajes y trazabilidad

Cada fallo o advertencia debe incluir:

- nombre estable del requisito;
- valor medido;
- tolerancia;
- criticidad;
- acción recomendada;
- archivo/artefacto que contiene la evidencia.

Debe crearse una tabla de trazabilidad global, por ejemplo
`action10_requirement_matrix.csv`, con estados `passed`, `failed`,
`not_applicable` o `unverified`. “No encontrado” no debe convertirse en
“aprobado”.

### Paso 10.7. Crear suite y caso integral

Crear:

- `+validation/run_integral_acceptance_suite.m`;
- `tests/test_action10_integral_validation.m`;
- `cases/config_action10_full_acceptance.m`;
- `+post/export_action10.m`;
- persistencia y manifiesto de Acción 10.

La suite debe reutilizar evidencia especializada 02–09 y añadir controles de
integración, recarga y consistencia entre acciones. No debe volver a interpretar
como calibrados los casos benchmark.

### Paso 10.8. Regenerar corridas finales

Después de cualquier corrección global, regenerar como mínimo:

1. Acción 02 para el elemento/base flexible;
2. Acción 03 para restricciones;
3. Acción 04/05 para masa;
4. Acción 06/07 para punto operativo;
5. Acción 08 para Campbell;
6. Acción 09 para sismo;
7. Acción 10 para auditoría integral.

Si no cambian las formulaciones aceptadas 02–08, se pueden conservar sus
corridas, pero la Acción 10 debe recargarlas y verificar hashes, esquema y
coherencia. Si una corrección altera un operador aguas arriba, todas las
corridas dependientes deben regenerarse.

### Paso 10.9. Aceptar Acción 10

La Acción 10 solo se acepta cuando:

- toda prueba crítica del plan director tiene evidencia directa;
- todas las suites 02–09 pasan;
- la regresión completa pasa;
- no quedan resultados canónicos obsoletos;
- los artefactos se recargan sin ensamblaje;
- se genera `docs/ACTION10_ACCEPTANCE_REPORT.md`;
- se actualizan `README.md` y `docs/IMPLEMENTATION_REPORT.md`.

## 10. Sincronización completada de tesis y MECOM 2026

Esta fase comienza después de aceptar las Acciones 09 y 10.

### 10.1. Auditar afirmaciones del manuscrito

Revisar el `.tex` actual contra el solver aceptado. Deben corregirse al menos
estas posibles discrepancias:

1. No afirmar que el maestro coincide con el centro de masa como hecho medido;
   actualmente es una hipótesis de colocalización por ausencia de offsets.
2. Sustituir la forma sísmica simplificada por la proyección de masa consistente
   cuando corresponda:
   `-Tc'*Mfull*Rfull*ag`.
3. Explicar la diferencia entre `GammaKinematic` y `GammaEffective`.
4. Declarar que `KOmega` puede ser cero en el ledger si su efecto ya está
   incluido en `Kg`.
5. Indicar que MBC/Campbell usa un punto operativo y azimut congelados, no
   Floquet.
6. Limitar la afirmación de estabilidad a raíces calculadas si no se obtiene
   el espectro completo.
7. Diferenciar fuerzas internas incrementales de fuerzas totales con precarga.
8. Mantener explícitos todos los parámetros no calibrados.

### 10.2. Seleccionar resultados publicables

Para un artículo de benchmark se recomiendan:

- una tabla corta de Timoshenko/convergencia;
- un esquema maestro–esclavo coherente con nodos 129/130 y raíces 21/57/93;
- una tabla de conservación de masa/restricciones;
- un Campbell de 12 ramas con advertencia de benchmark;
- una tabla de residuos QEP/MBC;
- una respuesta sísmica sintética con convergencia temporal y balance de
  energía;
- una tabla final de limitaciones y datos necesarios para calibración.

No se debe llenar el artículo con todas las tablas de aceptación; la evidencia
completa permanece en `runs/` y `docs/`.

### 10.3. Actualizar figuras

Las figuras deben generarse desde corridas aceptadas o desde código LaTeX
versionado. Para cada imagen, registrar:

- archivo fuente;
- herramienta de generación;
- corrida/datos de origen;
- unidades y leyendas;
- resolución final.

La figura estructural existente en el artículo está construida directamente en
LaTeX/TikZ. Las figuras numéricas se deben copiar desde la corrida canónica
correspondiente y no desde capturas manuales.

### 10.4. Compilar y verificar

Directorio de trabajo:

`/Users/nuseche/Documents/ChatGPT/Tesis/output/mecom_2026`.

Compilar con la herramienta ya disponible o con TeX tradicional:

```bash
/Users/nuseche/Documents/ChatGPT/Tesis/tmp/tools/tectonic \
  -X compile MECOM_2026_Useche.tex
```

Verificar:

- 4–10 páginas A4;
- PDF menor a 2 MB;
- referencias y DOI resueltos;
- ausencia de texto/figuras cortados;
- ecuaciones y símbolos consistentes;
- metadatos correctos;
- correspondencia entre tablas, figuras y artefactos de corrida;
- ausencia de archivos temporales innecesarios en el ZIP.

### 10.5. Regenerar paquete

El ZIP final debe incluir como mínimo:

- PDF final;
- `.tex`;
- `.bib` y `.bbl`;
- `amca.cls` y `amca.bst`;
- figuras externas realmente usadas;
- `README_ENTREGA.md` actualizado;
- `REVISION_TECNICA.md` actualizado.

Antes de reemplazar el ZIP del 22 de agosto, conservarlo como histórico o
renombrarlo. El paquete final debe recibir una fecha/hash y una lista de
contenido verificada con `unzip -l`.

## 11. Orden de cierre ejecutado

```text
[completado] Mantener verde la línea base 107/107
[completado] Terminar integración de Acción 09
[completado] Ejecutar suite especializada de Acción 09
[completado] Generar y auditar corrida canónica de Acción 09
[completado] Aprobar regresión completa y redactar aceptación 09
[completado] Crear plan e implementar Acción 10
[completado] Ejecutar auditoría integral requisito por requisito
[completado] Regenerar/recargar corridas dependientes
[completado] Actualizar el artículo MECOM con evidencia aceptada
[completado] Compilar, inspeccionar y empaquetar la entrega final
```

La edición cuantitativa se realizó únicamente después de aceptar Acción 09 y
usa las figuras regeneradas desde las corridas canónicas. La revisión
conceptual y la cuantitativa quedaron consolidadas en la misma fuente final.

## 12. Puertas de decisión

### Puerta A — Acción 09 lista

**Aprobada.** Configuración y rama integradas; suite completa; corrida
`SUCCESS`; artefactos recargados; figura inspeccionada; regresión verde e
informe de aceptación escrito.

### Puerta B — Acción 10 lista

**Aprobada.** Matriz de trazabilidad completa; preflight y postflight activos;
cobertura matricial/modal/temporal integral; ninguna verificación crítica sin
evidencia; regresión y recarga completas e informe de aceptación escrito.

### Puerta C — MECOM listo para envío

**Aprobada técnicamente.** Manuscrito sincronizado con el solver aceptado;
alcance físico explícito; resultados reproducibles; PDF visualmente verificado;
plantilla y límites satisfechos; ZIP limpio, fechado e inspeccionado. Cualquier
envío externo sigue siendo una decisión del autor.

## 13. Definición final de terminado

El objetivo completo se considera terminado únicamente cuando se cumplen todos
los puntos siguientes:

1. `main.m` ejecuta casos 02–10 desde configuraciones independientes.
2. Las Acciones 02–10 poseen plan, suite, corrida y reporte de aceptación.
3. Los operadores completos y reducidos tienen propiedades verificadas.
4. Las MPC y masas conservan cinemática y energía.
5. El equilibrio y los operadores rotantes son trazables.
6. QEP, MBC y Campbell cumplen sus puertas numéricas.
7. Newmark reproduce benchmarks, converge en el modelo completo y recupera
   respuesta absoluta, restricciones, reacciones y fuerzas internas.
8. La suite integral prueba y no solo enumera los requisitos del plan director.
9. Toda corrida final puede regenerar tablas y figuras sin reensamblar.
10. `README.md` y `IMPLEMENTATION_REPORT.md` reflejan el estado final.
11. Tesis y MECOM no contienen afirmaciones incompatibles con datos/hipótesis.
12. El PDF y ZIP MECOM finales han sido compilados, inspeccionados y verificados.
13. El informe integral de resultados está disponible como fuente LaTeX y PDF
    compilado con la misma clase y geometría editorial del MECOM.

Las condiciones 1–12 quedaron satisfechas el 31 de agosto de 2026 y la condición
13 el 8 de septiembre de 2026. El
proyecto se describe como **solver aceptado hasta Acción 10 y entrega MECOM
metodológica sincronizada**, manteniendo explícitas las limitaciones de
calibración física y diseño sísmico.
