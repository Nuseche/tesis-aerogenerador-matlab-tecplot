# Plan de implementación — Acción 07: amortiguamiento, giroscopía y aerodinámica linealizada

Fecha: 27 de agosto de 2026. Prerrequisitos aceptados: Acciones 02–06.

## 1. Objetivo

Construir, para cada estado de equilibrio, los operadores linealizados de
primer orden

\[
M\ddot q+(C+G+C_{aero})\dot q+
(K_e+K_g+K_\Omega+K_{aero})q=f,
\]

manteniendo identificable el origen de cada término. La acción debe demostrar
la antisimetría y el cambio de signo de `G`, la disipación de los términos de
amortiguamiento pasivos y la convención de signo de las tangentes
aerodinámicas. Ningún coeficiente no disponible en Version 0 se presentará
como calibración física.

## 2. Giroscopía derivada de la energía cinética

La formulación se obtiene de la parte cruzada de la energía cinética en el
marco rotante y se separa por significado físico. Para una sección de viga se
define

\[
B_{CG}=[I,-S(r_{CG})],\qquad S(\Omega)a=\Omega\times a.
\]

El operador seccional por unidad de longitud es

\[
G_s=2B_{CG}^T mS(\Omega)B_{CG}+
\begin{bmatrix}0&0\\0&S(J_{CG}\Omega)\end{bmatrix}.
\]

Se integra con la misma matriz cinemática `N` que construye la masa
Timoshenko aceptada:

\[
G_e=\int_0^L N^TG_sN\,dx.
\]

Para un cuerpo rígido se usa la expresión espacial equivalente en su maestro,
con la traslación de su CG y el bloque `S(JCG*Omega)`. Ambas expresiones son
antisimétricas y excluyen deliberadamente todo término proporcional a
`Omega^2`, ya contabilizado en la Acción 06. Se aplicará a:

- cada elemento flexible cuya etiqueta `blade` sea 1, 2 o 3, usando su masa
  consistente Timoshenko completa, incluidas inercia rotacional y
  acoplamientos traslación/rotación;
- cada cuerpo rígido marcado explícitamente `rotating=true`, recuperando masa,
  offset e inercia centroidal de su matriz espacial 6×6.

Los términos opcionales suministrados por el usuario seguirán admitidos, pero
se validarán individualmente y se reportarán por separado. No se aplicará
giroscopía a torre, góndola ni cimentación estacionarias.

## 3. Benchmarks giroscópicos

Se verificarán, antes de aceptar el modelo integrado:

1. masa puntual: `Guu=2m*S(Omega)`;
2. rotor rígido diagonal: Coriolis del CG y bloque exacto
   `S(JCG*Omega)` de momento angular;
3. elemento Timoshenko: igualdad con la derivada cruzada de una energía
   cinética evaluada por diferencias finitas;
4. antisimetría, nulidad a 0 RPM, linealidad en `Omega` y relación
   `G(-Omega)=-G(Omega)`;
5. contribuciones no nulas y separadas de palas distribuidas y cubo rígido;
6. potencia instantánea nula, `v^T Gv=0`.

## 4. Amortiguamiento estructural y conexiones

La matriz estructural podrá darse directamente o como Rayleigh:

\[
C_s=\alpha M+\beta K_e.
\]

Además de `alpha/beta`, se admitirá calibración reproducible mediante dos
frecuencias objetivo `f1,f2` y sus razones modales `zeta1,zeta2`, resolviendo

\[
\zeta_i=\frac{\alpha}{2\omega_i}+\frac{\beta\omega_i}{2}.
\]

Las frecuencias deben ser positivas y distintas; las razones, no negativas;
los coeficientes resultantes deben ser finitos y no negativos. La rigidez de
referencia será `Ke`, no la tangente geométrica dependiente de RPM.

El amortiguador del tren 129–130 usará la misma cinemática con brazo geométrico
que el resorte aceptado en la Acción 06. Así tendrá velocidad relativa nula
bajo traslación y rotación rígidas infinitesimales. Cimentación, estructura,
tren y aerodinámica permanecerán en matrices separadas. Para los componentes
declarados pasivos se comprobará semidefinición positiva de su parte simétrica.

## 5. Aerodinámica linealizada

La convención será invariable:

\[
K_{aero}=-\frac{\partial f_a}{\partial q},\qquad
C_{aero}=-\frac{\partial f_a}{\partial \dot q}.
\]

Se conservarán tres rutas explícitas: matrices proporcionadas, función de
tangente analítica y diferencias centrales de una función de carga. La ruta
numérica calculará también una estimación de convergencia al comparar los
pasos `h` y `h/2`; las matrices no se simetrizarán porque una carga seguidora
puede ser no conservativa. Se comprobarán tamaño, finitud, índices activos,
convención de signo y convergencia frente a un problema polinómico no
simétrico reproducible.

Version 0 no contiene tangentes aerodinámicas calibradas. Por ello el caso
integrado canónico almacenará `Kaero=Caero=0` con estado
`zero_unprovided_physical_coefficients`. El problema polinómico se usará solo
como benchmark del algoritmo y nunca se sumará a la turbina como dato físico.

## 6. Caso canónico

El caso de aceptación usará:

- masa consistente, base fija y los estados de equilibrio `[0,6,12] RPM` de
  la Acción 06;
- rigidez de tren del mismo benchmark numérico no calibrado;
- amortiguamiento Rayleigh calibrado de forma demostrativa con dos objetivos
  declarados y amortiguamiento de tren nulo;
- giroscopía distribuida de las tres palas y giroscopía espacial del cubo;
- tangentes aerodinámicas físicas nulas por ausencia de datos.

Los valores de amortiguamiento y rigidez de tren probarán el software; no serán
predicciones calibradas de la turbina.

## 7. Criterios de aceptación

- matrices `C`, `G`, `D`, `Kaero` y `Caero` dispersas, finitas y de dimensión
  completa/reducida correcta;
- error relativo de antisimetría de `G <= 1e-12`;
- `G(0)=0`, cambio de signo y linealidad con RPM con error `<=1e-12`;
- benchmark energético y de masa puntual con error `<=1e-11`;
- contribuciones distribuidas de las tres palas no nulas e invariantes bajo
  su separación azimutal dentro de la tolerancia geométrica;
- potencia `v^TGv` relativa `<=1e-12`;
- recuperación de los dos objetivos Rayleigh con error `<=1e-12`;
- semidefinición positiva de estructura, cimentación y tren cuando se declaran
  pasivos;
- objetividad del amortiguador 129–130 con energía disipada nula bajo
  movimiento rígido;
- error de tangentes aerodinámicas sintéticas y su estimación de convergencia
  dentro de tolerancias declaradas;
- identidad exacta `D=C+G` y suma trazable de todos los componentes;
- suite especializada, validación global y regresión completa sin fallos ni
  pruebas incompletas.

## 8. Artefactos

```text
runs/run_..._action07_dynamic_operators/
├── SUCCESS
├── action07_matrices.mat
├── action07_validation.csv
├── action07_operating_points.csv
├── action07_gyro_components.csv
├── action07_damping.csv
├── action07_aerodynamic_benchmark.csv
└── archivos reproducibles comunes
```

El informe de aceptación se redactará solo después de ejecutar el caso
canónico, inspeccionar los artefactos persistidos y aprobar la regresión
completa.
