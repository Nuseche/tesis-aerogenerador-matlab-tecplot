# Comprobación complementaria de sensibilidad — 14 de octubre de 2026

Se completaron las seis combinaciones faltantes de la rejilla de cuatro niveles dentro del dominio ya aprobado. Se reutilizaron 58 puntos del Morris y se ejecutaron tres controles nuevos. Las nueve evaluaciones convergieron en 77.49 s de solve. No se modificaron rangos, hipótesis físicas, fuentes del solver ni estimadores Morris.

## Método y alcance

La rejilla cubre 64 combinaciones de masa/inercia, rigidez de palas y velocidad. Se recalcula el equilibrio en cada caso. Se preservan grupos seguidos por formas y subespacios; la rama 12 continúa excluida. Los controles nuevos son QEP estricto, continuación en un punto nuevo y repetición nominal. Las tablas mantienen indicadores sin resolución.

Los contrastes rectangulares I = f++ − f+− − f−+ + f−− dejan fijo el tercer factor. La aditividad de los dos factores implica I=0, incluso con curvatura individual. Se propaga la envolvente empírica como b=4η y se exige |I|≥10b. Esa envolvente no es una garantía matemática de error en todo el dominio. Las curvaturas individuales usan C=f_siguiente−2f_central+f_anterior a pasos iguales.

## Resultados nuevos en 10+11

| Par de factores | Magnitud del contraste [Hz] | Señal / envolvente | Lectura |
|---|---:|---:|---|
| Masa–rigidez | 0.00926–0.00940 | 26.47–26.87 | Resuelto en cuatro velocidades |
| Masa–velocidad | 0.00356–0.00362 | 10.17–10.34 | Apenas sobre el umbral |
| Rigidez–velocidad | 0.00331–0.00342 | 9.47–9.77 | No resuelto |

Los cuatro contrastes masa–rigidez son negativos. Su signo indica que el incremento de rigidez tiene menor efecto sobre la frecuencia cuando aumenta la masa. Es una observación de no aditividad en esta respuesta y estos puntos, sin separar contribuciones causales de los operadores ni asignar porcentajes de varianza.

La diagonal de factores iguales masa=rigidez cambia 0.00495–0.00519 Hz entre 0.90 y 1.10, equivalentes a 0.404–0.423 % de la frecuencia nominal de 10+11. Se comprueba en las cuatro velocidades. Esto respalda compensación parcial y muestra una posible ambigüedad al identificar propiedades con una sola frecuencia.

Seis de 32 contrastes de curvatura de masa superan el filtro en 10+11. Los de rigidez y velocidad no lo superan. La no resolución no demuestra linealidad. El contraste masa–velocidad y la dispersión Morris de velocidad son indicadores distintos; el último conserva su falta de aceptación original.

## Comparación con Morris

Las secantes de extremos conservan el orden de influencia de los cinco grupos principales, pero usan pasos y ponderaciones diferentes del muestreo Morris. No se exige igualdad entre sus números. Los 14 indicadores medios y dos dispersiones aceptados pertenecen a la campaña original y permanecen intactos.

En 1+2, la media absoluta de secantes de masa entre extremos tiene cociente señal/ruido 10.41, apenas sobre el umbral. Once de sus 16 comparaciones individuales lo superan. Este dato marginal no modifica la ausencia de aceptación del estimador Morris de masa en 1+2. El giro en 4+5 mantiene su reserva de precisión.

## Verificación

- 64 combinaciones distintas, 58 reutilizadas y seis nuevas.
- Nueve casos nuevos exitosos, cero fallidos y cero pendientes.
- Las 175 huellas de fuente del Morris permanecen idénticas.
- Grupos históricos conservados; rama 12 excluida.
- Residuo de equilibrio máximo 9.94e−9 y QEP dual de masa máximo 4.05e−9.
- Las pruebas 17/17 del módulo y 155/155 de regresión son evidencia histórica. No se presentan como ejecutadas de nuevo.

## Figuras y reproducción

La licencia de Tecplot venció. El usuario autorizó reutilizar las figuras anteriores y generar las restantes con el mismo estilo. Las tres figuras nuevas y cuatro adaptaciones de legibilidad para diapositivas usan MATLAB R2026a, fondo blanco, escala de grises y salidas PNG/PDF vectorial. `figure_catalog.json` conserva el motor y los datos. No se atribuyen a Tecplot las exportaciones nuevas.

1. `scripts/complete_grid.m`: ejecuta/reanuda exclusivamente los nueve casos complementarios y exporta la rejilla. La carpeta rechaza reanudaciones con huellas distintas.
2. `scripts/analyze_grid.py`: verifica datos y fuentes, calcula contrastes y exporta CSV/JSON.
3. `scripts/make_figures.m`: produce gráficos desde resultados guardados, sin llamar al solver.
4. `scripts/update_documentation.py`: actualiza el mismo documento de sensibilidad y conserva un respaldo.

Resultados: `/Users/nuseche/Desktop/Tesis_codigos/runs/sensitivity/grid_completion_20261014`.
Documento actualizado: `/Users/nuseche/Desktop/Tesis_codigos/docs/sensibilidad_morris_20261006/SECCION_MORRIS_REVISION.tex`.
Presentación: `/Users/nuseche/Documents/ChatGPT/Tesis/output/presentacion_sensibilidad_20261014/entrega`.

## Límites pendientes

La cobertura completa es discreta. No prueba extremos ni monotonicidad del dominio continuo. La convergencia espacial en operación sigue pendiente: el módulo existente permite refinamiento únicamente con rotor detenido. El análisis a azimut fijo y espectro parcial no demuestra estabilidad periódica de Floquet. Los rangos siguen siendo exploratorios y no definen una incertidumbre física probabilística. No se realizó calibración ni validación experimental.

Referencias: Morris (1991), doi:10.1080/00401706.1991.10484804. Campolongo, Cariboni y Saltelli (2007), doi:10.1016/j.envsoft.2006.10.004. Los contrastes finitos y sus filtros se definen explícitamente en esta comprobación.
