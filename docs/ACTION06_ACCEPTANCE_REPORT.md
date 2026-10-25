# Informe de aceptación — Acción 06: equilibrio y centrifugación

Fecha de aceptación: 26 de agosto de 2026. Entorno: MATLAB R2026a Update 4.

## Resultado

La Acción 06 queda implementada y aceptada como benchmark numérico del solver.
La corrida canónica es
`runs/run_20260826_234708_429_action06_equilibrium`, contiene `SUCCESS` y
aprobó 29 verificaciones especializadas. La regresión completa terminó con 94
pruebas aprobadas, cero fallidas y cero incompletas; seis pruebas nuevas
pertenecen a esta acción.

La aceptación no convierte la rigidez de tren usada por el caso en dato físico:
su valor sigue etiquetado `numerical_benchmark_not_physical`. Es necesario para
conectar los maestros 129 y 130 sin sustituir su independencia cinemática por
una restricción rígida.

## Equilibrio corrotacional

Cada viga construye un marco actual y elimina movimiento rígido antes de
evaluar la energía local Timoshenko. La fuerza interna y la tangente son la
primera y segunda derivadas centrales de esa misma energía. El benchmark de
movimiento rígido tiene energía y fuerza axial nulas; el error direccional de
la tangente en el modelo completo es `1.393e-8`, por debajo de `2e-6`.

El solver reevalúa fuerza interna, gravedad, fuerza centrífuga y su Jacobiano en
cada iteración. Newton usa

\[
K_R=K_{int}-\partial f_{ext}/\partial q
\]

y búsqueda lineal. La continuación comienza siempre en 0 RPM y reutiliza el
estado anterior para 6 y 12 RPM.

## Corrección del conector de tren

El resorte 6D 129–130 previo comparaba traslaciones de nodos separados como si
fueran colocalizados. Bajo rotación rígida generaba un momento espurio cercano
a `57 MN·m`. El operador actual usa el brazo geométrico 129–130 en su matriz de
deformación relativa; su energía es nula bajo traslación y rotación rígidas
infinitesimales. Este cambio no ata los maestros: conserva un constitutivo
flexible explícito.

## Carga centrífuga y tangente

La fuerza distribuida y su Jacobiano usan las mismas funciones de traslación
Timoshenko y cuatro puntos de Gauss. Para cuerpos rígidos se emplea el mapa del
CG. Las pruebas confirman:

- error direccional del Jacobiano: `4.516e-10`;
- escalamiento de fuerza con `Omega²`: error 0;
- escalamiento de tangente con `Omega²`: error 0;
- invariancia frente al signo de `Omega`: error 0;
- carga nula de una masa colocalizada sobre el eje.

La matriz geométrica auxiliar se integra con gradientes de las funciones
Timoshenko y recupera el límite Euler–Bernoulli al hacer `GA→infinito`.

## Resultados del barrido

| RPM | Iteraciones | Residuo | Desplazamiento máximo (m) | Norma centrífuga (N) | Balance global |
|---:|---:|---:|---:|---:|---:|
| 0 | 5 | `8.984e-9` | 1.39153 | 0 | `1.535e-3` |
| 6 | 5 | `3.641e-9` | 1.40993 | `5.46551e5` | `1.541e-3` |
| 12 | 6 | `6.586e-9` | 1.46241 | `2.18672e6` | `1.629e-3` |

La norma gravitatoria es `1.195738e7 N`. El axial mínimo de torre a 0 RPM es
`-2.518974e7 N`; la convención es tensión positiva y compresión negativa.
Para cada elemento se guardan axial gravitatorio, incremento centrífugo y
total, verificando que los dos primeros suman el tercero.

El balance global de fuerza y momento queda en `1.63e-3`, no a precisión de
máquina. Esta tolerancia refleja la diferenciación numérica de la energía
corrotacional y la parametrización por vectores de rotación. Es suficiente para
el benchmark estático declarado, pero deberá endurecerse si se adopta un
elemento geométricamente exacto analítico.

## Prevención de doble conteo

La tangente de equilibrio ya contiene el Jacobiano centrífugo con el signo de
carga externa. El operador linealizado guarda

\[
K_g=K_{eq}-K_e,\qquad K_\Omega=0.
\]

La identidad `Ke+Kg+KOmega=tangentFull` tiene error relativo `6.31e-22`. Un
libro de fuentes en los resultados describe cada contribución; el booleano
histórico se conserva solo por compatibilidad y ya no decide por sí solo el
ensamblaje.

## Artefactos y límites

La corrida contiene `action06_matrices.mat`, `action06_validation.csv`,
`action06_equilibrium.csv`, `action06_axial_forces.csv`,
`action06_continuation.csv` y los artefactos reproducibles comunes.

Los desplazamientos no deben presentarse como predicción calibrada: dependen
de una rigidez de tren de benchmark, offsets de cuerpos aún colocalizados y la
transición tipo 4 heredada. Sí validan el algoritmo, las convenciones de signo,
la continuación y la separación de fuentes de rigidez.
