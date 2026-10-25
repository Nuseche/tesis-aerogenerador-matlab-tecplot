# Informe de aceptación — Acción 03: restricciones rígidas exactas

Fecha de aceptación: 26 de agosto de 2026. Entorno: MATLAB R2026a Update 4.

## Resultado

La Acción 03 queda implementada y aceptada. La corrida canónica es
`runs/run_20260826_231211_426_action03_rigid_constraints`, terminó con 34 de
34 verificaciones especializadas aprobadas y contiene el marcador `SUCCESS`.
La regresión completa terminó con 77 pruebas aprobadas, cero fallidas y cero
incompletas; siete de ellas pertenecen a la nueva suite unitaria de esta acción.

La corrida está aislada de las masas concentradas de góndola y cubo, gravedad,
rotación, equilibrio, tren de potencia, aerodinámica, análisis modal y sismo.
Su único objetivo físico-numérico es sustituir los conectores penalizados por
ecuaciones cinemáticas exactas y demostrar la reducción por congruencia.

## Topología aceptada

- El nodo 129 conserva seis GDL independientes como maestro de góndola.
- El nodo 130 conserva otros seis GDL independientes como maestro de rotor.
- Las raíces 21, 57 y 93 son esclavas exclusivamente del nodo 130.
- Los nodos 129 y 130 no se atan entre sí; cualquier tren de potencia deberá
  incorporarse mediante un operador explícito y trazable.
- Los conectores tipo 3 heredados 134–137 se retiran completamente.
- Los elementos tipo 4, IDs 125–133, se conservan provisionalmente como una
  transición flexible y aportan `26488.7969281 kg` de masa distribuida. Esta
  retención es una hipótesis heredada declarada, no una calibración física.

Una lista vacía de restricciones ahora produce la identidad. Ya no existe una
restricción oculta inferida por reconocer números de nodo.

## Ecuaciones y reducción

Para cada raíz esclava se aplica

\[
u_s=u_m-S(x_s-x_m)\theta_m,\qquad \theta_s=\theta_m,
\]

y se construye la matriz dispersa `qFull=Tc*qReduced`. Los operadores se
reducen mediante

\[
M_r=T_c^TMT_c,\qquad K_{er}=T_c^TK_eT_c,
\]

las cargas mediante `Tc'*fFull` y los desplazamientos se recuperan mediante
`Tc*qReduced`.

## Resultados numéricos

| Magnitud | Resultado |
|---|---:|
| GDL completos | 828 |
| GDL independientes | 810 |
| GDL libres con base fija | 804 |
| Dimensión de `Tc` | 828×810 |
| No nulos de `Tc` | 846 |
| Rango estructural de `Tc` | 810 |
| Residuo cinemático máximo | 0 |
| Error energético de masa | `2.920e-16` |
| Error energético de rigidez | `1.359e-16` |
| Error de trabajo virtual | 0 |
| Filas reducidas desconectadas | 0 |

`M`, `Ke`, `Mr` y `Ker` permanecen dispersas, finitas y simétricas. Las
identidades maestro–esclavo se verifican directamente como identidades de
filas de `Tc`, por lo que la comprobación cubre todas las coordenadas reducidas
y funciona con IDs nodales no contiguos o reordenados.

## Condiciones de apoyo sobre esclavos

Una SPC aplicada a una traslación esclava excéntrica puede transformarse en
una ecuación lineal acoplada. Fijar por separado todas sus columnas
sobre-restringiría el sistema. Esta versión rechaza explícitamente ese caso con
`rigid:reduce_system:DependentSPCNotSupported` hasta que se componga una
segunda transformación de espacio nulo. La base canónica está en el nodo 1,
que es independiente, y sus seis SPC se reducen exactamente.

## Pruebas negativas y de generalidad

La suite especializada cubre lista vacía, IDs no contiguos y reordenados,
seis movimientos maestros puros, movimiento mixto, autorrestricción, esclavo
duplicado, cadena de restricciones, nodo desconocido, ID no entero, intento de
atar 129–130 y SPC acoplada sobre un esclavo. También comprueba recuperación,
reducción de carga, trabajo virtual, congruencia y topología del modelo real.

## Artefactos reproducibles

La corrida canónica contiene `action03_matrices.mat`,
`action03_validation.csv`, `action03_constraint_map.csv`,
`action03_summary.csv`, el resumen de validación global, configuración,
instantánea del modelo, operadores, resultados, manifiesto, log y `SUCCESS`.

La Acción 04 puede ahora agregar las matrices espaciales 6×6 de góndola y cubo
en los maestros antes de aplicar esta misma `Tc`, sin modificar la cinemática
aceptada aquí.
