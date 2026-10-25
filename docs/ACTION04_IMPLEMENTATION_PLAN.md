# Plan de implementación — Acción 04: masas espaciales de cuerpos rígidos

Fecha: 26 de agosto de 2026. Prerrequisitos aceptados: Acción 02 (vigas
Timoshenko) y Acción 03 (`Tc` exacta, 828×810, rango 810).

## 1. Objetivo y alcance

Representar la góndola y el cubo mediante matrices de masa espacial 6×6
trazables, con masa, centro de gravedad, tensor completo y orientación, y
demostrar que la reducción por `Tc` conserva la masa, el centro de gravedad y
la inercia global.

Esta acción no incorpora todavía equilibrio por gravedad, centrifugación,
rigidez geométrica, giroscopía, aerodinámica, Campbell ni sismo.

## 2. Datos heredados y decisiones explícitas

La fuente Version 0 proporciona:

- góndola: `m=1.1845e6 kg`, inercias principales
  `[1.4806e7, 3.2672e7, 3.2672e7] kg·m²`;
- cubo: `m=1.9600e5 kg`, inercias principales isotrópicas
  `[2.8224e6, 2.8224e6, 2.8224e6] kg·m²`;
- ángulos de Euler `[90,-5,-90]` y secuencia pasiva Z-X-Z.

El script heredado dejó comentada la multiplicación `pi/180` y, por tanto,
ejecutó accidentalmente esos valores como radianes. Las magnitudes y la
convención documental indican grados. El modelo corregido almacenará la unidad
`deg` en un artefacto versionado y ejecutará una conversión explícita a
radianes. La conducta antigua permanecerá descrita como antecedente, no como
convención válida.

La fuente no entrega offsets de los centros de masa. Para esta versión se
adopta `rCG=[0,0,0] m` en cada maestro, marcado como hipótesis de colocalización
pendiente de datos. El código conservará todos los acoplamientos cuando se
proporcione un offset no nulo.

## 3. Formulación

Para un tensor corporal respecto del centro de masa:

\[
J_G=R J_B R^T.
\]

Con `r` desde el maestro hasta el centro de masa, en coordenadas globales:

\[
M_R=\begin{bmatrix}
mI&-mS(r)\\
mS(r)&J_G-mS(r)S(r)
\end{bmatrix}.
\]

El bloque inferior derecho es la inercia trasladada al maestro. Los productos
de inercia no se descartan. Cada `MR` se suma una sola vez en los seis GDL de
su maestro y después se aplica `Mr=Tc'*M*Tc`.

## 4. Cambios previstos

1. Crear `data/rigid_bodies/legacy_rigid_bodies_v0.json` y su README.
2. Añadir el archivo al manifiesto de datos y a `cfg.data`.
3. Cargarlo sin ejecutar scripts heredados.
4. Rehacer `model.define_rigid_bodies` para consumir el artefacto, convertir
   unidades y conservar procedencia/hipótesis.
5. Reforzar `rigid_body_mass_matrix` con desigualdades físicas de los momentos
   principales y diagnósticos del tensor trasladado.
6. Crear `validation.run_rigid_body_mass_suite`.
7. Crear `cases/config_action04_rigid_bodies.m` y una rama aislada en `main`.
8. Persistir matrices, propiedades globales y tablas de cuerpos.
9. Añadir exportación CSV y `tests/test_action04_rigid_bodies.m`.
10. Ejecutar suite especializada, regresión completa y corrida canónica.

## 5. Verificaciones de aceptación

- Dos cuerpos y maestros distintos 129/130.
- Unidad de entrada explícita `deg`; ángulos internos en radianes.
- `R*R'=I`, `det(R)=1` y secuencia pasiva Z-X-Z.
- Tensor corporal finito, simétrico, semidefinido positivo y físicamente
  realizable mediante las desigualdades triangulares de sus momentos.
- `MR` finita, simétrica y definida positiva para ambos datos actuales.
- Aparición de productos de inercia globales en la góndola orientada.
- Benchmark sintético con offset no nulo y acoplamiento traslación–rotación.
- Diferencia de masa global igual exactamente a la suma de los dos bloques
  espaciales; ninguna duplicación.
- Masa de cuerpos `1,380,500 kg`.
- Masa, CG e inercia global calculados mediante campos de velocidad rígida.
- Error de conservación antes/después de `Tc <=1e-10`.
- Matrices completas/reducidas dispersas, finitas y simétricas.
- La representación física no depende de pasar números en grados directamente
  a funciones trigonométricas.

## 6. Artefactos canónicos

```text
runs/run_..._action04_rigid_bodies/
├── SUCCESS
├── action04_matrices.mat
├── action04_body_matrices.csv
├── action04_mass_properties.csv
├── action04_validation.csv
├── configuration.*
├── model_snapshot.mat
├── operators.mat
├── results.mat
├── manifest.*
└── execution.log
```

## 7. Puerta de salida

La Acción 04 se aceptará solo si la suite especializada, la regresión completa
y la corrida canónica aprueban; el informe final deberá distinguir resultados
matemáticamente verificados de los dos supuestos físicos aún no calibrados:
centros de masa colocalizados y orientación heredada interpretada en grados.
