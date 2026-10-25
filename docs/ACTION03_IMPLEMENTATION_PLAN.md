# Plan de implementación — Acción 03: restricciones rígidas exactas

Fecha: 26 de agosto de 2026. Estado inicial: Acción 02 aceptada y reproducida
con 70/70 pruebas y matrices Timoshenko consistentes de 828×828.

## 1. Objetivo

Reemplazar definitivamente los cuatro conectores tipo 3 heredados por una
transformación cinemática dispersa y exacta

\[
q_{full}=T_c q_r,
\]

sin añadir masa ni rigidez penalizada y sin unir artificialmente los maestros
de góndola y rotor.

La Acción 03 se limita a la cinemática y a la reducción por congruencia. Las
masas concentradas de góndola/cubo pertenecen a la Acción 04.

## 2. Decisiones físicas y topológicas

1. El nodo 129 es el maestro de referencia de la góndola.
2. El nodo 130 es el maestro cinemático del rotor/cubo.
3. Los nodos raíz 21, 57 y 93 son esclavos del nodo 130.
4. Los nodos 129 y 130 permanecen independientes. Su acoplamiento solo podrá
   proceder de un operador de tren de potencia explícito y trazable.
5. Los elementos heredados tipo 3, IDs 134–137, se eliminan:
   - 134: penalización góndola–cubo;
   - 135–137: penalizaciones cubo–raíces.
6. Los elementos tipo 4, IDs 125–133, se conservan provisionalmente como
   transición flexible entre la torre y el nodo 129. Aportan aproximadamente
   26.49 t. Esta es una hipótesis declarada, no una ecuación rígida. Su
   calibración física queda pendiente de datos externos y no se confundirá con
   la aceptación matemática de `Tc`.
7. No se creará una restricción implícita si la configuración o el modelo no
   proporciona explícitamente la lista maestro–esclavo.

## 3. Ecuación maestro–esclavo

Para cada esclavo `s`, maestro `m` y
\(r_{sm}=x_s-x_m\):

\[
u_s=u_m-S(r_{sm})\theta_m,
\qquad
\theta_s=\theta_m,
\]

con

\[
S(r)=
\begin{bmatrix}
0&-r_z&r_y\\
r_z&0&-r_x\\
-r_y&r_x&0
\end{bmatrix}.
\]

El bloque cinemático es

\[
B_{sm}=
\begin{bmatrix}
I&-S(r_{sm})\\
0&I
\end{bmatrix}.
\]

## 4. Dimensiones esperadas

- GDL completos: 828.
- Nodos esclavos: 3.
- GDL dependientes eliminados: 18.
- GDL independientes: 810.
- Con base fija, GDL libres posteriores: 804.
- `Tc`: dispersa, 828×810, rango 810.

Estas dimensiones son criterios de regresión para la geometría heredada, no
valores codificados dentro de la función genérica.

## 5. Archivos que se modificarán o crearán

- `+rigid/rigid_constraint_matrix.m`
  - eliminar la restricción heredada implícita;
  - exigir restricciones explícitas;
  - conservar validaciones de duplicidad, cadenas y rango.
- `+validation/check_rigid_constraints.m`
  - dejar de asumir que el ID nodal coincide con la fila;
  - verificar la identidad matricial completa entre filas de `Tc`, no solo un
    vector de prueba.
- `+validation/run_rigid_constraint_suite.m`
  - nueva suite especializada de aceptación.
- `cases/config_action03_rigid_constraints.m`
  - caso aislado que no añade masas de cuerpos, equilibrio ni dinámica.
- `main.m`
  - rama `action03_rigid_constraints`.
- `+io/save_results.m`
  - persistencia de `Tc`, `M`, `Ke` y operadores reducidos de Acción 03.
- `+post/export_action03.m` y `+post/export_all.m`
  - CSV de validación, mapa de restricciones y resumen.
- `tests/test_action03_constraints.m`
  - pruebas unitarias y del modelo real.
- `docs/ACTION03_ACCEPTANCE_REPORT.md`
  - se escribirá después de una corrida exitosa y reproducida.

## 6. Procedimiento de implementación

1. Reproducir Acción 02 y la suite global.
2. Confirmar que la malla flexible excluye los IDs 134–137.
3. Confirmar que los IDs 125–133 permanecen como transición y registrar su
   masa distribuida.
4. Construir `Tc` exclusivamente desde `modelData.rigidBodies.constraints`.
5. Comprobar maestros/esclavos existentes y no repetidos.
6. Prohibir que 129 y 130 sean esclavos uno del otro.
7. Prohibir cadenas de restricciones en esta versión.
8. Eliminar los 18 GDL dependientes de las tres raíces.
9. Verificar `sprank(Tc)==size(Tc,2)`.
10. Reducir por congruencia:

   \[
   M_r=T_c^TMT_c,
   \qquad
   K_r=T_c^TKT_c.
   \]

11. Reducir cargas mediante \(f_r=T_c^Tf\).
12. Recuperar resultados mediante \(q=T_cq_r\).
13. Mantener 129 y 130 como seis GDL independientes cada uno.
14. Guardar mapas full↔reduced y maestro↔esclavo.
15. Ejecutar suite especializada, regresión completa y corrida canónica.

## 7. Verificaciones de aceptación

### 7.1 Estructura de `Tc`

- Matriz dispersa 828×810.
- Rango completo 810.
- Esclavos exactamente `[21 57 93]`.
- Maestro de cada esclavo exactamente 130.
- Los doce GDL de 129 y 130 tienen columnas independientes y distintas.

### 7.2 Identidad cinemática

Para cada par se evaluará directamente

\[
R_{sm}=T_c(dof_s,:)-B_{sm}T_c(dof_m,:).
\]

Debe cumplirse

\[
\max\|R_{sm}\|_\infty\le10^{-12}.
\]

La validación debe funcionar con IDs nodales no contiguos y orden de filas
arbitrario.

### 7.3 Conservación por congruencia

Para varios vectores deterministas `z`:

\[
z^TM_rz=(T_cz)^TM(T_cz),
\]

\[
z^TK_rz=(T_cz)^TK(T_cz).
\]

Error relativo máximo: `1e-12`.

### 7.4 Trabajo virtual de cargas

Para cargas completas `f`:

\[
z^T(T_c^Tf)=(T_cz)^Tf.
\]

Error relativo máximo: `1e-12`.

### 7.5 Propiedades numéricas

- `M`, `Ke`, `Mr` y `Kr` dispersas y finitas.
- Simetría relativa ≤ `1e-12`.
- Ninguna fila reducida desconectada salvo una separación física declarada
  cuando no existe rigidez de tren 129–130.
- Ninguna contribución de masa o rigidez de los conectores tipo 3.

### 7.6 Alcance modal

La corrida aislada de Acción 03 no usará una rigidez inventada de tren de
potencia y, por ello, no empleará el conteo modal de la turbina completa como
criterio físico. La prueba de seis modos rígidos del conjunto conectado podrá
usar un operador de tren explícitamente marcado como benchmark numérico, pero
no se interpretará como calibración del aerogenerador.

## 8. Artefactos de la corrida canónica

```text
runs/run_..._action03_rigid_constraints/
├── SUCCESS
├── configuration.mat
├── model_snapshot.mat
├── operators.mat
├── results.mat
├── action03_matrices.mat
├── action03_validation.csv
├── action03_constraint_map.csv
├── action03_summary.csv
├── validation_summary.csv
└── execution.log
```

## 9. Puerta de salida

La Acción 03 se aceptará únicamente si:

1. La suite especializada aprueba todas sus verificaciones críticas.
2. La regresión completa del repositorio permanece en verde.
3. La corrida canónica termina con `SUCCESS`.
4. El informe documenta dimensiones, rango, residuo cinemático, errores de
   energía/trabajo y la hipótesis explícita de los elementos tipo 4.
5. Los resultados de Acción 02 siguen siendo reproducibles.

Después de esta puerta podrá comenzar la Acción 04, que añadirá masas espaciales
6×6 en los maestros sin alterar `Tc`.
