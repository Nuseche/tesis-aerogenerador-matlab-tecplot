# Plan de implementación — Acción 09: sismo, Newmark y recuperación dinámica

Fecha: 27 de agosto de 2026. Prerrequisitos aceptados: Acciones 02–08.

## 1. Objetivo

Integrar la respuesta relativa del aerogenerador frente a movimiento sísmico
multicomponente, recuperar cinemática absoluta, fuerzas de restricción y
fuerzas internas elementales, y demostrar convergencia temporal sobre el
modelo completo. La acción debe funcionar con los operadores estacionarios y
rotantes ya aceptados, sin reinterpretar un caso sintético como predicción
sísmica calibrada.

## 2. Registro de movimiento del suelo

`io.load_accelerogram` conservará, en unidades SI:

- aceleración `ag` en `m/s^2`;
- velocidad `vg` en `m/s`, cuando venga suministrada;
- desplazamiento `ug` en `m`, cuando venga suministrado;
- series originales y procesadas, unidades, método de corrección de línea
  base, interpolación y procedencia de cada serie.

Cuando `vg` o `ug` no existan, se integrarán de forma explícita desde los
valores iniciales declarados. Si se proporciona una malla temporal objetivo,
las tres series disponibles se interpolarán sobre la misma malla. No se
descartará silenciosamente una velocidad o desplazamiento suministrado.

El caso canónico usará dos componentes sintéticas suaves, con `ag/vg/ug`
analíticas y unidades SI. Es un registro de verificación, no un acelerograma
de diseño.

## 3. Vector de influencia y carga de base

Para cada dirección `x/y/z` se construirá primero `RFull` en los GDL
traslacionales nodales, incluidos los apoyos, porque la cinemática absoluta de
estos también sigue el terreno. Para diagnosticar la cinemática relativa se
formará además `RCompatible`, anulando solo sus filas fijas, y se verificará

\[
T_c\Gamma_k=R_{compatible}.
\]

Con masa consistente, la fuerza inercial exacta se proyectará desde el espacio
completo:

\[
f_b(t)=-T_c^TM_fR_fa_g(t).
\]

Se definirá y almacenará la influencia efectiva por masa

\[
\Gamma_m=M_r^{-1}T_c^TM_fR_f,
\]

sin formar una inversa, de modo que también se cumpla
`f_b=-Mr*Gamma_m*ag`. `Gamma_k` y `Gamma_m` no se confundirán: la primera es
cinemática relativa compatible y la segunda reproduce exactamente la carga
inercial consistente.

Las fuerzas externas adicionales deberán identificar su distribución en el
espacio completo cuando se pidan reacciones; no se presentará una elevación de
norma mínima como carga física única.

## 4. Integración Newmark

Se mantendrá el método beta–gamma para matrices generales:

\[
M\ddot q+D\dot q+Kq=f(t).
\]

El caso de producción usará aceleración promedio constante
`beta=1/4`, `gamma=1/2`. Por defecto se rechazarán parámetros que no satisfagan
la condición de estabilidad incondicional lineal

\[
\gamma\ge 1/2,\qquad
\beta\ge\frac14(\gamma+1/2)^2,
\]

salvo una habilitación explícita de un esquema condicional. Se conservarán las
condiciones iniciales y se obtendrá la aceleración inicial del equilibrio si
no se suministra.

Para paso constante se reutilizará una única factorización dispersa. El
residuo dinámico se normalizará en cada instante.

## 5. Balance energético discreto

Para Newmark promedio constante se acumulará trabajo por incrementos
compatibles con el algoritmo:

\[
\Delta W_f=\frac{f_{n+1}+f_n}{2}^T\Delta q,
\]

\[
\Delta W_D=\Delta t\,\bar v^TD\bar v,
\qquad
\Delta W_{K_a}=\Delta q^TK_a\bar q.
\]

La energía cinética y la deformación usarán las partes simétricas de `M` y
`K`. Esto separará el error del integrador de un error introducido por integrar
potencia con una cuadratura ajena al esquema.

## 6. Recuperación relativa, absoluta y de restricciones

Se conservarán `q/qd/qdd` relativos reducidos y completos. La cinemática
absoluta será

\[
u_{abs}=q+\Gamma u_g,\qquad
v_{abs}=\dot q+\Gamma v_g,\qquad
a_{abs}=\ddot q+\Gamma a_g.
\]

El residuo completo

\[
r_f=M_f\ddot q_f+D_f\dot q_f+K_fq_f-f_f
\]

se etiquetará como fuerza generalizada de restricción. Su proyección deberá
cumplir `Tc' * r_f = 0`; las filas fijas se exportarán como reacciones de
apoyo, mientras que las filas MPC conservarán su significado de fuerza de
restricción y no se confundirán con apoyo.

## 7. Fuerzas internas elementales

Usando el cache Timoshenko aceptado se recuperará, para cada elemento activo y
cada instante,

\[
q_e^l=T_eq_e^g,
\qquad
f_e^l=K_e^lq_e^l,
\qquad
f_e^g=T_e^Tf_e^l.
\]

Se almacenarán fuerzas de extremo locales, axiales, torsión y cortantes, junto
con la identidad de ensamblaje. Estas son fuerzas incrementales del modelo
linealizado alrededor del equilibrio operativo; no incluyen por segunda vez
la precarga estática.

## 8. Benchmarks

La suite especializada incluirá:

1. preservación de `ag/vg/ug` y conversión de unidades;
2. compatibilidad exacta de `Gamma` y signo de `-M Gamma ag`;
3. SDOF con excitación armónica de base y solución cerrada;
4. convergencia temporal de segundo orden;
5. superposición de dos componentes en un sistema lineal;
6. rechazo de parámetros Newmark no estables;
7. balance energético discreto conservativo y amortiguado;
8. convergencia `dt`, `dt/2`, `dt/4` del aerogenerador completo;
9. equilibrio proyectado y reacciones de apoyo;
10. identidad de fuerzas internas elementales;
11. caso estacionario y caso rotante, comprobando que este último contiene
    `G`, `Kg` y `KOmega` conforme a las acciones anteriores.

## 9. Criterios de aceptación

- error de preservación de series suministradas `<=1e-12`;
- compatibilidad cinemática
  `||Tc*Gamma_k-RCompatible||/||RCompatible|| <=1e-12`;
- identidad inercial
  `||Mr*Gamma_m-Tc'*Mfull*RFull||/||Tc'*Mfull*RFull|| <=1e-12`;
- identidad de fuerza de base `<=1e-14` relativa;
- error del benchmark SDOF `<=1e-4` y orden temporal observado `>=1.9`;
- error de superposición multicomponente `<=1e-10`;
- residuo dinámico máximo, excluido el estado inicial, `<=1e-9`;
- identidades de cinemática absoluta `<=1e-12`;
- balance energético discreto normalizado `<=1e-8` en benchmarks y `<=1e-6`
  en el modelo completo;
- equilibrio proyectado completo `<=1e-9`;
- identidad local/global y ensamblaje de fuerzas elementales `<=1e-12`;
- respuesta completa finita y convergencia monotónica; diferencia entre las
  dos mallas más finas `<=1 %` en los máximos seleccionados;
- matrices estacionarias y rotantes dispersas/finitas, `G(0)=0`, `G(12 RPM)`
  no nula y suma de operadores consistente;
- suite especializada, validación global y regresión completa sin fallos ni
  pruebas incompletas.

## 10. Caso canónico y artefactos

El caso `config_action09_seismic_newmark.m` usará base fija, masa consistente,
dos componentes sintéticas, 12 RPM como punto rotante y 0 RPM como control.
La corrida deberá contener:

```text
runs/run_..._action09_seismic_newmark/
├── SUCCESS
├── action09_matrices.mat
├── action09_validation.csv
├── action09_ground_motion.csv
├── action09_time_convergence.csv
├── action09_sdof_benchmark.csv
├── action09_response_extrema.csv
├── action09_reactions.csv
├── action09_element_forces.csv
├── time_history.csv
├── time_extrema.csv
├── figures/response.png
└── archivos reproducibles comunes
```

El informe de aceptación se redactará solo después de recargar estos
artefactos, inspeccionar la figura y aprobar la regresión completa.
