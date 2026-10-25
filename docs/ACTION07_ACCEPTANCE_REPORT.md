# Informe de aceptación — Acción 07: operadores dinámicos de primer orden

Fecha de aceptación: 27 de agosto de 2026. Entorno: MATLAB R2026a Update 4.

## Resultado

La Acción 07 queda implementada y aceptada como formulación y benchmark del
software. La corrida canónica es
`runs/run_20260827_000911_242_action07_dynamic_operators`, contiene `SUCCESS`
y aprobó **30/30 verificaciones especializadas**. La regresión completa terminó
con **101 pruebas aprobadas, cero fallidas y cero incompletas**.

La aceptación no asigna datos aerodinámicos que Version 0 no contiene. En la
turbina canónica `Kaero=Caero=0` y el estado queda registrado como
`zero_unprovided_physical_coefficients`. La rigidez de tren y los dos objetivos
Rayleigh siguen etiquetados como benchmarks numéricos no calibrados.

## Giroscopía distribuida y rígida

La contribución de cada pala se integra con la misma interpolación cinemática
Timoshenko usada por su masa. Para cada sección se suman:

\[
2B_{CG}^TmS(\Omega)B_{CG}
\quad\text{y}\quad
S(J_{CG}\Omega),
\]

que representan Coriolis traslacional y momento angular centroidal. La
contribución del cubo usa la matriz espacial del cuerpo en el maestro 130,
incluido su offset cuando exista. Góndola, torre y cimentación se excluyen por
su declaración explícita `rotating=false`; la fuente versionada ahora almacena
esa clasificación sin depender de la heurística histórica del número de nodo.

En 12 RPM las normas de Frobenius son `1.718598e5` para las palas distribuidas
y `5.063984e6` para el cubo. Las normas por pala son `99209.622`, `99219.879`
y `99240.373`, con dispersión relativa `3.0992e-4`, menor que `1e-3`.

Las verificaciones obtuvieron:

- antisimetría de `G`: error 0;
- `G(0)=0` exactamente;
- `G(-Omega)=-G(Omega)`: error 0;
- `G(2*Omega)=2G(Omega)`: error 0;
- potencia normalizada `|v^TGv|`: `2.795e-20`;
- disco rígido contra matriz analítica: error 0;
- frecuencias forward/backward del disco: error `5.396e-16`;
- elemento distribuido contra solución cerrada: error `5.296e-17`.

No se agregó aquí ningún término `Omega^2`: la tangente centrífuga continúa
perteneciendo exclusivamente a la Acción 06.

## Amortiguamiento

Rayleigh se calibra a partir de dos pares `(frecuencia, zeta)`. El caso de
software usa `0.2 Hz` y `2.0 Hz`, ambos con `zeta=0.01`, y obtiene

\[
\alpha=0.02284794657\;s^{-1},\qquad
\beta=0.001446863119\;s.
\]

El error máximo al recuperar los dos objetivos es `1.735e-18`. La rigidez de
referencia es `Ke`, no la tangente geométrica variable con RPM. Estructura,
cimentación, tren y aerodinámica se almacenan por separado; su suma reproduce
`C` exactamente.

El amortiguador 129–130 usa el mismo operador con brazo geométrico que el
resorte aceptado en la Acción 06. El residuo cinemático bajo movimiento rígido
es `2.776e-17` y la potencia artificial `4.474e-16`. Los componentes mecánicos
pasivos son simétricos y sus formas cuadráticas de prueba son no negativas.

## Aerodinámica y consistencia del equilibrio

Una única `loadFcn` alimenta la fuerza externa de Newton y, cuando no existe
una tangente analítica, sus derivadas centrales. La convención es

\[
K_{aero}=-\partial f_a/\partial q,\qquad
C_{aero}=-\partial f_a/\partial\dot q.
\]

La derivación usa refinamiento `h`/`h/2` y conserva matrices no simétricas. El
benchmark polinómico sintético produjo errores `3.583e-8` en `Kaero` y
`3.397e-8` en `Caero`, con razón de convergencia `4.000`, propia del esquema
central de segundo orden. La norma de la parte no simétrica fue `5.941`, por
lo que se comprobó que no se simetriza silenciosamente. Las matrices explícitas
de ceros se reconocen como fuente intencional proporcionada.

El benchmark estático sintético convergió con residuo `3.121e-10`. La tangente
usada por Newton contiene `Kaero`; al construir los operadores se retira de
`Kg` y se suma una sola vez como componente nombrado. El error de esa identidad
es 0.

## Identidades y artefactos

Para `[0,6,12] RPM`, todas las matrices completas y reducidas son dispersas y
finitas. El máximo error de `D=C+G` es `1.457e-18`; las sumas de componentes de
`C` y `K` tienen error 0.

La corrida contiene `action07_matrices.mat`, `action07_validation.csv`,
`action07_operating_points.csv`, `action07_gyro_components.csv`,
`action07_damping.csv`, `action07_aerodynamic_benchmark.csv` y los artefactos
reproducibles comunes. La corrida fallida de desarrollo se movió de forma
recuperable a `/tmp/tesis_codigos_action07_failed_runs_20260827`.

Los resultados prueban formulaciones, signos, trazabilidad y ensamblaje. No
deben presentarse como predicción dinámica calibrada hasta identificar
amortiguamiento físico, rigidez del tren, offsets reales y derivadas
aerodinámicas del aerogenerador.
