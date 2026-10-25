# Informe de aceptación — Acción 08: MBC, QEP y diagrama Campbell

Fecha de aceptación: 27 de agosto de 2026. Entorno: MATLAB R2026a Update 4.

## Resultado

La Acción 08 queda implementada y aceptada como formulación y benchmark del
software. La corrida canónica es
`runs/run_20260827_090201_148_action08_mbc_qep_campbell`, contiene `SUCCESS`
y aprobó **32/32 verificaciones especializadas**. La regresión completa terminó
con **107 pruebas aprobadas, cero fallidas y cero incompletas**.

El caso resuelve nueve velocidades entre 0 y 12 RPM y conserva 12 ramas por
velocidad. Usa masa consistente, base fija, equilibrio de la Acción 06 y los
operadores dinámicos aceptados en la Acción 07. La rigidez del tren y los
objetivos Rayleigh están etiquetados como benchmarks numéricos; no existen
coeficientes aerodinámicos físicos y, por tanto, `Kaero=Caero=0` queda marcado
como `zero_unprovided_physical_coefficients`.

## Marcos homólogos y MBC compuesto

Antes de la mezcla armónica se aplica la transformación dispersa `H` formada
con los marcos locales aceptados de cada estación y pala:

\[
q_g=Hq_h,\qquad q_h=T_Bz,\qquad P=HT_B.
\]

En la referencia corrotante utilizada por el modelo, `H` es constante. En
consecuencia, `Hdot=Hddot=0`; hacerla girar nuevamente duplicaría términos ya
representados por las derivadas armónicas y por `G`. Los operadores son

\[
\bar M=P^TMP,
\]

\[
\bar D=P^T(DP+2M\dot P),
\]

\[
\bar K=P^T(KP+D\dot P+M\ddot P).
\]

Los errores máximos fueron:

- ortogonalidad de `H`: `1.377e-16`;
- identidad `P^-1 P`: `7.160e-16`;
- derivada primera frente a diferencia central: `4.811e-11`;
- derivada segunda: `2.101e-6`;
- reconstrucción global/local: `2.781e-16`;
- contenido cíclico de los seis movimientos colectivos homólogos: `3.511e-16`.

Como control negativo, la antigua mezcla directa de componentes globales
produce razones cíclico/colectivo entre `2.33` y `2.371e3`. Esto demuestra que
la corrección no es meramente algebraica: evita interpretar como cíclico un
movimiento físicamente colectivo.

## Equivalencia a 0 RPM y QEP

La solución conservativa sin transformar y la solución conservativa MBC
coinciden con error relativo `3.452e-13`. Sus subespacios recuperados tienen
MAC mínimo `0.999999999999998`. Una QEP independiente con amortiguamiento nulo
recupera esas frecuencias con error `6.112e-13`.

La QEP de producción mantiene el Rayleigh referido a `Ke`, aceptado en la
Acción 07. Como la rigidez operativa también contiene `Kg`, no es estrictamente
proporcional a `K` total; su pequeño desplazamiento respecto de la solución
conservativa se registra, pero no se usa para afirmar una equivalencia física
inexistente.

En las nueve velocidades se obtuvieron:

- residuo derecho QEP máximo: `2.505e-16`;
- error máximo de pares conjugados: 0;
- residuo izquierdo máximo: `7.494e-14`;
- error de biortogonalidad fuera de la diagonal: `7.602e-11`;
- máxima parte real de las raíces objetivo calculadas: `-1.181e-2`, sin
  inestabilidad entre las ramas extraídas. Como `eigs` calcula 28 raíces de un
  lápiz de orden 1608, este dato no se presenta como certificación del espectro
  completo.

El benchmark SDOF amortiguado tuvo error `1.110e-16`; el benchmark de
frecuencias forward/backward giroscópicas, `4.236e-16`.

## Seguimiento Campbell

La asignación voraz se sustituyó por una asignación global uno a uno. En el
contraejemplo documentado, la asignación óptima selecciona puntuaciones `0.80`
y `0.85`, suma `1.65`, frente a `1.00` del método voraz. Para dobletes o grupos
casi degenerados se usan ángulos principales y MAC de subespacio. El benchmark
de una base rotada 45 grados obtiene MAC individual `0.5`, pero MAC subespacial
igual a 1.

En el Campbell canónico:

- MAC individual mínimo global: `0.4426`;
- MAC individual mínimo fuera de clusters: `0.8289`;
- MAC subespacial mínimo dentro de clusters: `0.9693`;
- calidad efectiva mínima individual-o-subespacial: `0.8289`;
- toda calidad individual inferior a `0.8` está justificada por un subespacio
  con MAC al menos `0.95`;
- las 108 combinaciones velocidad-rama son finitas y poseen clasificación no
  vacía.

La figura `figures/campbell.png` fue inspeccionada y muestra las 12 ramas sobre
la malla `0:1.5:12 RPM`, incluidas sus aproximaciones y cruces. Es un Campbell
congelado en el azimut de referencia, no un análisis de Floquet.

## Persistencia y artefactos

Cada solución conserva `H`, `P`, `P^-1`, `Pdot`, `Pddot` y los operadores MBC
`M/D/K`. Todos permanecen dispersos y finitos. La recarga independiente de
`action08_matrices.mat` confirmó nueve soluciones, resultado aceptado y error
máximo de identidad almacenado `3.222e-16`, sin reensamblar el modelo.
El archivo de seguimiento exporta también la asignación global y el
identificador de cluster de cada rama.

La corrida contiene:

- `action08_matrices.mat`;
- `action08_validation.csv`;
- `action08_campbell.csv`;
- `action08_qep.csv`;
- `action08_tracking.csv`;
- `action08_mbc_transforms.csv`;
- `action08_homology.csv`;
- `action08_zero_speed.csv`;
- `action08_assignment.csv`;
- `action08_storage.csv`;
- `modal_summary.csv` con clasificación completa;
- `figures/campbell.png` y modos recuperados.

Los resultados prueban la transformación física de coordenadas, el solver QEP,
los modos izquierdos, la biortogonalidad, el seguimiento y la persistencia. No
constituyen aún una predicción calibrada del aerogenerador hasta identificar
rigidez y amortiguamiento del tren, propiedades aerodinámicas y offsets reales.
