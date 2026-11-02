# Revisión de formulación, estimaciones y figuras — 2026-11-02

Se mantiene el artículo de formulación y sus tres apéndices. No se añaden
campañas numéricas ni resultados simulados. Se conservan las once funciones
explicativas de las figuras; sus nuevos originales vectoriales están en
`figures/publication`. Las figuras anteriores siguen disponibles en Git y en
`figures/tecplot`, pero ya no se insertan en el manuscrito.

## Estimaciones

La sección nueva, antes del problema modal, contiene:

1. Identidad y cota energética del sistema reducido dependiente del tiempo.
   La energía de control usa una matriz positiva H; no se atribuye positividad
   a una tangente no conservativa. Se retienen Mdot, la parte simétrica de D,
   K-H y Hdot. La cota es de tiempo finito, dependiente de la discretización.
2. Ortogonalidad de Galerkin y estimación de Céa para el subproblema elástico
   conforme, coercivo y exactamente integrado. No se inventa una tasa h^p
   para el rotor completo ni una prueba de ausencia de bloqueo.
3. Resto de Taylor O(epsilon^2) y cota del error de linealización bajo
   regularidad y permanencia en un entorno pequeño del estado nominal.

Referencias primarias verificadas:
- Céa (1964), *Approximation variationnelle des problèmes aux limites*:
  https://doi.org/10.5802/aif.181
- Arnold (1981), *Discretization by finite elements of a model parameter
  dependent problem*: https://doi.org/10.1007/BF01400318
  Texto del autor: https://www-users.cse.umn.edu/~arnold/papers/paramdep.pdf

Las pruebas algebraicas con matrices aleatorias verifican la identidad y la
cota; no constituyen una prueba de convergencia espacial ni validación física.

## Referencias gráficas examinadas

- Turello, Maza, Preidikman, Flores y Pinto (2023), *Interacción suelo-estructura
  no-lineal en el modelado de torres eólicas de eje horizontal ante carga
  sísmica*, Mecánica Computacional XL, 639–650:
  https://amcaonline.org.ar/ojs/index.php/mc/article/download/6595/6657
  Se examinó visualmente la figura 1 (p. 641): correspondencia entre la
  máquina y su idealización mecánica, con identificación de componentes.
- Maza, Turello, Flores y Preidikman (2023), *Flutter flexo-torsional de palas
  de grandes aerogeneradores*, Mecánica Computacional XL, 957–965:
  https://amcaonline.org.ar/ojs/index.php/mc/article/download/6643/6706
  Se examinó visualmente la figura 1 (p. 962): la gráfica responde a una
  pregunta concreta sobre la evolución de la perturbación. Ese principio
  se aplica aquí a las hipótesis de formulación; no se reproducen curvas ni
  resultados de ese trabajo.

Las once figuras son dibujos originales, no reproducciones de esas fuentes.
Se usa proyección ortográfica de geometría tridimensional, escala de grises,
texto matemático vectorial y pies exclusivamente en LaTeX. Las superficies
son auxiliares: no añaden grados de libertad ni afirman ser CAD comercial.

| Figura | Función en el argumento | Comprobación |
|---|---|---|
| 1 | Relacionar cuerpos físicos, vigas y conexión G-H | Nodos interiores; raíces separadas de la conexión elástica; discretización explícitamente esquemática |
| 2 | Distinguir vector y componentes | Igual vector, observador y escala; cierre de Q(Qᵀa)=a |
| 3 | Localizar orígenes N, B, G, H | Triedros paralelos a azimut cero; detalle separado sin giro ficticio |
| 4 | Fijar el signo del azimut | R1(psi) y regla de la mano derecha; E1 saliente en vista del rotor |
| 5 | Definir bases de las tres palas | Determinantes +1 y d1×d2=d3; 120 grados; detalles sin superposición |
| 6 | Localizar una partícula seccional | Plano d2-d3 y normal d1; coordenadas materiales y origen distinguibles |
| 7 | Explicar la independencia de giro y pendiente | Tangente calculada de la curva; normal independiente; ángulo ilustrativo declarado |
| 8 | Separar referencia, nominal y perturbación | Mismo material, cámara y escala; giro alrededor de E1; desplazamiento entre extremos homólogos |
| 9 | Explicar excentricidad y traslado de masa | Cierre rP=rC+rhoC; origen, centro y partícula distintos; detalle vectorial separado |
| 10 | Construir la base elemental | p perpendicular a e1; base ortonormal; punto auxiliar vacío sin grados de libertad |
| 11 | Mostrar la compatibilidad de raíz | Cierre del incremento traslacional; producto cruzado calculado; giro incremental distinto del nominal |

La revisión visual se hizo sobre cada figura y sobre las páginas de las dos
ediciones. `revision_checks.json` contiene los recuentos y hashes de los PDF.
Los scripts reproducibles están en `scripts/paper` del proyecto de simulación
(y en `tools/paper` del repositorio del artículo).

## Fuente de trabajo y sincronización

El repositorio dedicado es https://github.com/Nuseche/tesis-formulacion-overleaf,
con historial común y remotos `origin` y `overleaf`. El proyecto conectado es
https://www.overleaf.com/project/6ae8f5b71b76c4ec44c5a5f4.
El token se conserva en el llavero del equipo, nunca en archivos versionados.

`tools/sync.sh` descarga y comprueba los dos historiales antes de publicar;
se detiene ante divergencias o cambios locales sin commit. Ejecutarlo antes
y después de editar. No hay sincronización periódica en segundo plano.
Para trabajo posterior del artículo se prefiere este repositorio dedicado;
la carpeta del proyecto de simulación conserva la instantánea de esta revisión.
