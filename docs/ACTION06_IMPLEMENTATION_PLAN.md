# Plan de implementación — Acción 06: equilibrio, centrifugación y tangente geométrica

Fecha: 26 de agosto de 2026. Prerrequisitos aceptados: Acciones 02–05.

## 1. Objetivo

Resolver un estado de equilibrio reproducible para gravedad y velocidad de
rotor, reevaluando las cargas dependientes de la configuración, y construir la
tangente dinámica sin contar dos veces la rigidez asociada a centrifugación.

## 2. Corrección del estado heredado

La implementación anterior usaba `fint=Ke*q`, evaluaba las cargas una sola vez
en la geometría inicial y declaraba convergencia Newton tras una corrección.
Además, `centrifugalIncludedInKg=true` se fijaba sin una prueba del origen de
los términos. Esa ruta no constituye un equilibrio no lineal aceptable.

## 3. Modelo no lineal adoptado

Se implementará un elemento corrotacional que construye un marco actual a
partir del cordón deformado y de la orientación media de los nodos. Al retirar
el movimiento rígido, la rigidez Timoshenko aceptada actúa sobre coordenadas
puramente deformacionales:

\[
U_e=\frac{1}{2}q_{def}^T K_{e,local}q_{def}.
\]

La fuerza interna y la tangente se obtienen como primera y segunda derivadas
centrales de la misma energía escalar. En `q=0` la tangente coincide exactamente
con `Ke`; las rotaciones y traslaciones rígidas se eliminan antes de evaluar la
energía. El modelo admite grandes rotaciones rígidas y pequeñas deformaciones,
pero no reemplaza una teoría de viga geometrícamente exacta con actualización
completa de tensiones para regímenes de deformación grande.

La matriz geométrica clásica auxiliar se actualizará por integración de las
derivadas de las funciones de traslación Timoshenko, incluyendo `phiY/phiZ`.

## 4. Cargas

### Gravedad

La gravedad es carga muerta consistente, ensamblada con la masa elemental y
las masas espaciales de cuerpos rígidos.

### Centrifugación

Para `AΩ=||Ω||²I-ΩΩᵀ`:

\[
f_\Omega(q)=\int N_u^T m A_\Omega(x+N_uq-p)\,ds,
\]

\[
K_{load,\Omega}=\frac{\partial f_\Omega}{\partial q}
=\int N_u^T mA_\Omega N_u\,ds.
\]

Se usarán las mismas funciones Timoshenko de traslación para fuerza y
Jacobiano. Los cuerpos rígidos usarán el mapa de velocidad/desplazamiento de su
CG. Las cargas se recalcularán en cada iteración.

## 5. Newton y continuación

El residuo será

\[
R(q)=f_{ext}(q)-f_{int}(q),
\]

y la matriz de corrección

\[
K_R=K_{int}-\frac{\partial f_{ext}}{\partial q}.
\]

Se añadirá búsqueda lineal por reducción del residuo. La continuación siempre
partirá de 0 RPM, aunque la lista solicitada no lo incluya; las velocidades
positivas y negativas formarán ramas desde el estado cero.

## 6. Prevención de doble conteo

La tangente final de equilibrio se guardará como fuente primaria. Para el
análisis linealizado:

\[
K_g+K_\Omega=K_{eq}-K_e.
\]

El término completo se almacenará una sola vez en `Kg` y `KOmega=0`, acompañado
por un libro de fuentes que identifica fuerza interna y Jacobiano centrífugo.
No se dependerá de un booleano sin evidencia.

## 7. Verificaciones

- `fint(0)=0` y `Kt(0)=Ke`.
- Tangente interna y Jacobiano centrífugo contra diferencias finitas.
- Escalamiento de fuerza y Jacobiano con `Omega²`.
- Carga centrífuga nula en el eje.
- Benchmark de barra/truss con solución no lineal de referencia.
- Benchmark de columna comprimida: pérdida de rigidez con signo correcto.
- Convergencia Newton monotónica o controlada por búsqueda lineal.
- Continuación que comienza en 0 RPM.
- Separación de axiales por estado de gravedad, incremento centrífugo y total.
- Equilibrio global de fuerzas y momentos.
- Simetría, finitud y dispersión de la tangente.
- Identidad `Ke+Kg+KOmega=tangentFull` y `KOmega=0` cuando el Jacobiano ya está
  incluido.

## 8. Caso canónico y límites

La corrida Acción 06 usará base fija, masa consistente, gravedad y una malla de
RPM `[0,6,12]`. Como los maestros 129 y 130 deben permanecer independientes y
la fuente no proporciona rigidez de eje, el caso de aceptación declarará una
rigidez de tren **de benchmark numérico**, idéntica en todas las comparaciones y
no calibrada. Los desplazamientos y axiales integrados probarán el solver, pero
no se publicarán como predicción física de la turbina. Los offsets de cuerpos y
la transición tipo 4 también siguen pendientes de calibración.

## 9. Artefactos

```text
runs/run_..._action06_equilibrium/
├── SUCCESS
├── action06_matrices.mat
├── action06_validation.csv
├── action06_equilibrium.csv
├── action06_axial_forces.csv
├── action06_continuation.csv
└── archivos reproducibles comunes
```
