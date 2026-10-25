# Informe de aceptación — Acción 05: formulación de masa

Fecha de aceptación: 26 de agosto de 2026. Entorno: MATLAB R2026a Update 4.

## Resultado

La Acción 05 queda implementada y aceptada. La corrida canónica es
`runs/run_20260826_232719_219_action05_mass_formulation`, contiene `SUCCESS` y
aprobó 36 verificaciones especializadas. La regresión completa terminó con 88
pruebas aprobadas, cero fallidas y cero incompletas; cinco pruebas nuevas
pertenecen a esta acción.

`consistent` continúa como formulación predeterminada y canónica. La variante
HRZ se implementó como comparación opcional explícita; no sustituye los
resultados físicos consistentes ni se aplica a las matrices espaciales de
góndola y cubo.

## Masa consistente de producción

- La matriz ensamblada se conserva coeficiente por coeficiente.
- Las masas espaciales 6×6 se añaden después de seleccionar la formulación
  distribuida y no se diagonalizan.
- La masa completa y reducida permanece dispersa, finita y simétrica.
- La masa reducida es definida positiva por Cholesky.
- Masa total, CG e inercia se conservan por congruencia con el mismo nivel de
  precisión aceptado en la Acción 04.
- Los diagnósticos declaran `usesAbsoluteValue=false`.

La suma de filas de la matriz Timoshenko real produce diagonales negativas. La
ruta `row_sum` se mantiene solamente como diagnóstico y termina con
`assembly:apply_mass_formulation:NegativeRowSum`; no se usa `abs` para ocultar
el problema.

## Variante HRZ opcional

`assembly.hrz_lump_mass` recibe un mapa N×6 de GDL y escala la diagonal
distribuida para conservar por separado las masas de traslación rígida X, Y y
Z. Los términos rotacionales usan la escala HRZ documentada. Los cuerpos se
añaden completos después, por lo que la matriz total conserva los productos de
inercia y cualquier acoplamiento debido a offsets.

Resultados globales:

| Magnitud | Consistente | HRZ |
|---|---:|---:|
| Masa total (kg) | `2601611.15284282` | `2601611.15284282` |
| CG X (m) | `0.46066337` | `0.46210474` |
| CG Y (m) | `2.251e-6` | `-9.192e-4` |
| CG Z (m) | `113.8865663` | `113.8441515` |
| Error de masa traslacional HRZ | — | `5.720e-16` |

Las pequeñas diferencias de CG muestran por qué HRZ es una aproximación de
sensibilidad y no la representación de producción. La masa total y las tres
traslaciones rígidas sí se conservan con precisión numérica.

## Comparación modal de la torre aislada

Se compararon ocho modos del voladizo de torre con la misma rigidez:

- máxima diferencia relativa de frecuencia: `1.0738%`;
- MAC mínimo después de asociar ramas: `0.911563`;
- residuo modal máximo: `1.406e-10`;
- participaciones de masa efectiva traslacional finitas para ambos métodos.

Los pares de flexión degenerados pueden intercambiar vectores dentro del mismo
subespacio; por ello se asocian mediante MAC. Las frecuencias HRZ no se usan
como sustituto de las consistentes, sino como medida reproducible de
sensibilidad a la formulación de masa.

## Artefactos

La corrida contiene `action05_matrices.mat`, `action05_validation.csv`,
`action05_mass_comparison.csv`, `action05_modal_comparison.csv`,
`action05_diagnostics.csv`, configuración, modelo, operadores, resultados,
manifiesto, log y `SUCCESS`.

La Acción 06 debe partir exclusivamente de la masa consistente aceptada aquí.
