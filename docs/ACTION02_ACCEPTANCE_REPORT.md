# Informe de aceptación — Acción 02: Timoshenko 3D

Fecha de aceptación: 26 de agosto de 2026. Entorno: MATLAB R2026a Update 4.

## Resultado

La Acción 02 queda implementada y aceptada. La corrida canónica es
`runs/run_20260826_210833_538_action02_timoshenko` y terminó con 31 de 31
verificaciones críticas aprobadas. La regresión completa del repositorio terminó
con 70 pruebas aprobadas, cero fallidas y cero incompletas.

La corrida se detiene deliberadamente en la malla flexible no restringida. No
incorpora masas rígidas, `Tc`, cimentación, tren de potencia, equilibrio,
centrifugación, giroscopía, MBC, Campbell ni sismo; esos términos pertenecen a
acciones posteriores y no contaminan estos benchmarks.

## Correspondencia con los pasos 2.1–2.10

1. Las convenciones quedaron congeladas en `docs/CONVENTIONS.md`: 6 GDL por
   nodo, eje local 1 de I a J, el punto auxiliar define el eje local 3 y
   `e2=e3×e1`.
2. La conversión seccional produce matrices canónicas `K6` y `M6`. Las palas
   conservan `AXIALD` solo como masa lineal; el artefacto importado deja `Jx`
   sin resolver y el modelo lo completa únicamente mediante la regla explícita
   `perpendicular_axis`, es decir, `Jx=Jy+Jz`.
3. `element_rotation_matrix` valida longitud, proyección auxiliar,
   ortogonalidad y determinante; las orientaciones sintéticas ±120° conservan
   energía, matrices y frecuencias con error relativo `7.89e-11`.
4. Se implementaron reglas de Gauss, funciones lineales y matrices `B` para
   deformación axial, dos cortantes, torsión y dos curvaturas.
5. La rigidez ofrece dos formulaciones: `closed_exact`, usada en producción
   por ser Timoshenko cerrada y libre de bloqueo, y `selective_integration`,
   con 2 puntos para términos normales y 1 punto para cortante, usada en el
   benchmark explícito de convergencia.
6. La masa consistente incluye traslación, inercia rotacional y acoplamiento
   por excentricidad seccional. No se usa una masa agrupada silenciosa.
7. La interfaz elemental devuelve matrices locales/globales, transformación,
   geometría, diagnóstico y operadores de recuperación. Cada elemento libre
   conserva exactamente seis modos rígidos.
8. El ensamblaje global usa tripletas dispersas, comprueba simetría antes de
   cualquier corrección numérica y conserva un caché por elemento.
9. Torre y tres palas se extraen y resuelven como voladizos aislados, con
   conservación de masa, frecuencias positivas y residuo modal verificados.
10. `main.m` incorpora el caso aislado `action02_timoshenko`; la exportación
    guarda matrices, tablas, diagnósticos y figuras reproducibles.

## Resultados numéricos aceptados

Las matrices `M` y `Ke` son dispersas de `828×828`, finitas y exactamente
simétricas en el archivo exportado. Los únicos GDL desconectados son
`775:780`, correspondientes al nodo rígido 130, lo cual es intencional porque
la Acción 02 excluye los cuerpos y restricciones rígidas.

| Subsistema aislado | Longitud (m) | Masa distribuida (kg) | Primera frecuencia (Hz) |
|---|---:|---:|---:|
| Torre | 135.0000 | 859784.72 | 0.7196683 |
| Pala 1 | 100.0820 | 111605.61 | 0.4194612 |
| Pala 2 | 100.0821 | 111608.51 | 0.4194880 |
| Pala 3 | 100.0899 | 111623.52 | 0.4194551 |

La dispersión relativa máxima entre frecuencias homólogas de las tres palas
heredadas es `1.674e-4`, por debajo de la tolerancia `1e-3`. La pequeña
diferencia remanente concuerda con las diferencias geométricas y de masa de
los datos importados; no indica una dependencia espuria de la orientación.

El benchmark de integración selectiva usa 1, 2, 4, 8, 16, 32 y 64 elementos.
En la malla final los errores relativos son:

- desplazamiento de punta: `6.103e-5`;
- primera frecuencia de flexión: `3.643e-5`;
- segunda frecuencia de flexión: `5.838e-4`.

Los tres están por debajo de la tolerancia base `1e-3`, sin ampliar la banda
para el segundo modo. El valor muy alto del segundo autovalor con un único
elemento es el modo de cortante de una discretización incapaz de representar
la segunda forma de flexión; su descenso monótono hacia la referencia al
refinar la malla es precisamente la conducta que valida la prueba.

## Interpretación y límites

Las frecuencias reportadas son propiedades de voladizos **aislados** con raíz
empotrada. Sirven para validar el elemento, la masa y las orientaciones; no son
frecuencias de la turbina ensamblada ni predicciones operacionales. En
particular, no incluyen acoplamiento torre–góndola–rotor, masas concentradas,
flexibilidad de cimentación, rigidez del tren, velocidad de giro, gravedad o
aerodinámica.

La coincidencia de las palas bajo rotaciones ±120° prueba invariancia de
coordenadas. La conservación de masa a aproximadamente `1e-16` prueba que la
masa consistente recupera la masa lineal integrada. Los residuos modales
máximos, todos menores que `1e-8`, prueban que las frecuencias son soluciones
numéricas convergidas de cada subsistema. La convergencia frente a soluciones
analíticas prueba que no hay bloqueo por cortante en el régimen ensayado.

Los resultados integrados generados antes de esta acción deben regenerarse en
las acciones posteriores, porque esta implementación corrigió de forma
explícita la semántica del punto auxiliar y la regla de inercia longitudinal de
las palas.

## Reproducción y artefactos

```matlab
cd('/Users/nuseche/Desktop/Tesis_codigos')
result = main('cases/config_action02_timoshenko.m');
addpath('tests')
testResults = run_all_tests();
```

La corrida canónica contiene `action02_matrices.mat`, los CSV de validación,
convergencia, componentes, modos y diagnósticos elementales, además de las
figuras de convergencia, comparación de palas y ejes locales. El archivo
`SUCCESS` solo se escribe después de completar también el postproceso.
