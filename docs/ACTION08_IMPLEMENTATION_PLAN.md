# Plan de implementación — Acción 08: MBC, QEP y diagrama Campbell

Fecha: 27 de agosto de 2026. Prerrequisitos aceptados: Acciones 02–07.

## 1. Objetivo

Transformar correctamente el sistema de tres palas desde coordenadas nodales
globales a coordenadas multiblade homólogas, resolver el problema cuadrático
de autovalores complejo y seguir ramas modales a través de un barrido Campbell
reproducible. La acción debe conservar los operadores de cada velocidad, las
transformaciones y los diagnósticos suficientes para regenerar tablas y
figuras sin reensamblar.

## 2. Corrección de coordenadas homólogas

El mapa existente reúne los mismos números de componente global de las tres
palas. Esa operación no es físicamente válida: por ejemplo, `uy` de una pala
no representa la misma dirección local que `uy` de otra rotada 120 grados.

Para cada estación no raíz y cada pala se usará el marco aceptado
`Q_b=[e1 e2 e3]`, donde `e1` es longitudinal, `e3` procede del punto auxiliar
y `e2=e3×e1`. Se construirá una matriz dispersa `H(psi)` tal que

\[
q_{global}=H(\psi)q_{local},
\]

con bloques `blkdiag(Q_b,Q_b)` para traslaciones y rotaciones. Fuera de las
palas `H` será identidad. `H` es un cambio constante de componentes en la
configuración corrotante de referencia, por lo que `Hdot=Hddot=0`. La
dependencia temporal del rotor ya está representada por `T_MBC`, sus derivadas
y la matriz giroscópica `G` aceptada en la Acción 07. Rotar además `H` en el
tiempo duplicaría esos términos.

Las raíces se excluyen del mapa porque sus GDL dependen exactamente del
maestro 130; el movimiento colectivo del cubo permanece en coordenadas
globales independientes.

## 3. Transformación MBC compuesta

La transformación armónica normalizada seguirá usando colectivo, coseno y
seno:

\[
q_{local}=T_B(\psi)z.
\]

La transformación completa será

\[
P=HT_B,
\qquad
\dot P=\dot HT_B+H\dot T_B,
\]

\[
\ddot P=\ddot HT_B+2\dot H\dot T_B+H\ddot T_B.
\]

Su inversa será `P^-1=TB^-1*H^T`. Los operadores se obtendrán por trabajo
virtual:

\[
\bar M=P^TMP,
\]

\[
\bar D=P^T(DP+2M\dot P),
\]

\[
\bar K=P^T(KP+D\dot P+M\ddot P).
\]

Se verificarán `P^-1P=I`, las derivadas por diferencias finitas y la
reconstrucción de desplazamientos globales en varios azimuts, no solo en cero.

## 4. Formulaciones congelada y promedio azimutal

La formulación `frozen` evaluará el operador en un azimut declarado. La ruta
`azimuth_average` conservará todas las muestras y promediará los operadores
transformados. Este promedio es una aproximación de coeficientes constantes,
no un análisis de Floquet; solo puede interpretarse físicamente si las
matrices de entrada representan coherentemente cada azimut. El caso canónico
usará `frozen` porque la Acción 06 resuelve una única geometría azimutal por
velocidad.

## 5. QEP complejo

Se resolverá

\[
(\lambda^2\bar M+\lambda\bar D+\bar K)\phi=0
\]

mediante un lápiz generalizado sin invertir `M`. Se conservarán:

- espectro calculado y representante de cada par físico;
- modos derechos normalizados, residuo QEP y error del par conjugado;
- raíces oscilatorias y sobreamortiguadas clasificadas explícitamente;
- cuando el solver lo permita, modos izquierdos del lápiz, residuo adjunto y
  matriz de biortogonalidad;
- operadores MBC y transformación completa de cada velocidad.

A 0 RPM se compararán tres soluciones del mismo sistema: conservativa sin
transformar, conservativa transformada y QEP con amortiguamiento nulo. La QEP
de producción conserva el Rayleigh referido a `Ke`; su frecuencia natural se
registra por separado porque `Kg` hace que el amortiguamiento no sea
estrictamente proporcional a la rigidez tangente total.
Sus frecuencias naturales deberán coincidir dentro de la tolerancia.

## 6. Seguimiento de ramas

El emparejamiento voraz se sustituirá por asignación global de costo mínimo.
El costo combinará MAC complejo ponderado por masa y continuidad de frecuencia.
Para grupos casi degenerados se calcularán ángulos principales y MAC de
subespacio, de forma que una rotación arbitraria de la base modal no se
interprete como pérdida física de continuidad.

Se almacenarán por rama:

- MAC individual;
- calidad efectiva, usando MAC de subespacio en clusters degenerados;
- cambio relativo de frecuencia;
- asignación y pertenencia a cluster.

No se aceptará silenciosamente una correspondencia individual baja sin una
calidad de subespacio que la justifique.

## 7. Caso canónico y límites físicos

El caso usará nueve puntos `0:1.5:12 RPM`, masa consistente, base fija, equilibrio por
continuación, giroscopía completa de la Acción 07, amortiguamiento Rayleigh de
benchmark y `Kaero=Caero=0` por ausencia de datos. Se resolverán 12 ramas con
MBC compuesto congelado en azimut cero.

La rigidez del tren, los objetivos Rayleigh, offsets colocalizados y transición
tipo 4 siguen sin calibración física. El Campbell demostrará el algoritmo, no
constituirá todavía una predicción publicable de la turbina.

## 8. Criterios de aceptación

- ortogonalidad de cada marco y `P^-1P` con error `<=1e-12` en al menos cinco
  azimuts;
- errores de `Pdot` y `Pddot` contra diferencias finitas `<=1e-8` y `<=2e-5`;
- reconstrucción global/local `<=1e-12`;
- demostración de que mezclar componentes globales directamente no es
  equivalente a mezclar componentes homólogas;
- operadores MBC dispersos, finitos y persistidos en cada velocidad;
- equivalencia de frecuencias a 0 RPM `<=1e-6` relativa;
- residuos QEP máximos `<=1e-8` y errores de pares conjugados `<=1e-8`;
- benchmark QEP analítico amortiguado y benchmark giroscópico forward/backward
  `<=1e-10`;
- asignación global óptima verificada contra un caso donde el método voraz
  falla;
- MAC de subespacio invariante ante rotación de una base degenerada, con error
  `<=1e-12`;
- calidad efectiva mínima de seguimiento declarada y toda calidad individual
  baja justificada por un cluster con MAC de subespacio alto;
- nueve velocidades, 12 ramas finitas, clasificación no vacía y figura
  `campbell.png` regenerable;
- suite especializada, validación global y regresión completa sin fallos ni
  pruebas incompletas.

## 9. Artefactos

```text
runs/run_..._action08_mbc_qep_campbell/
├── SUCCESS
├── action08_matrices.mat
├── action08_validation.csv
├── action08_campbell.csv
├── action08_qep.csv
├── action08_tracking.csv
├── action08_mbc_transforms.csv
├── modal_summary.csv
├── figures/campbell.png
└── archivos reproducibles comunes
```

El informe de aceptación se redactará únicamente después de inspeccionar la
corrida canónica, comprobar su regeneración y aprobar toda la regresión.
