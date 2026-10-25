# Informe de aceptación — Acción 04: masas espaciales de cuerpos rígidos

Fecha de aceptación: 26 de agosto de 2026. Entorno: MATLAB R2026a Update 4.

## Resultado

La Acción 04 queda implementada y aceptada. La corrida canónica es
`runs/run_20260826_232027_996_action04_rigid_bodies`, contiene `SUCCESS` y
aprobó sus 40 verificaciones especializadas. La regresión completa terminó con
83 pruebas aprobadas, cero fallidas y cero incompletas; seis pruebas nuevas
pertenecen a esta acción.

La corrida agrega únicamente las masas espaciales de góndola y cubo a la masa
distribuida consistente y aplica después la `Tc` aceptada en la Acción 03. No
incorpora equilibrio, gravedad, rotación, rigidez geométrica, giroscopía,
aerodinámica, análisis modal ni sismo.

## Datos, unidades y trazabilidad

Se creó el artefacto declarativo
`data/rigid_bodies/legacy_rigid_bodies_v0.json`, incluido en el manifiesto
SHA-256. Registra masas, tensores, maestros, fuente, unidad angular y estado de
los offsets sin ejecutar scripts heredados.

Los valores `[90,-5,-90]` se interpretan explícitamente en grados y se
convierten mediante `deg2rad`. La secuencia es pasiva Z-X-Z. La rotación
resultante cumple `R*R'=I` con residuo `1.70e-32`, `det(R)=1` y se distancia
`1.7803` en norma de Frobenius de la ejecución antigua que introducía esos
números directamente en `sin/cos` como radianes.

Version 0 no entrega posiciones de los centros de masa. Se conserva por ello
`rCG=0` en cada maestro como **hipótesis de colocalización pendiente de datos**.
El algoritmo y su benchmark sintético admiten offsets no nulos y conservan los
acoplamientos traslación–rotación completos.

## Cuerpos incorporados

| Cuerpo | Maestro | Masa (kg) | Inercias principales (kg·m²) |
|---|---:|---:|---:|
| Góndola | 129 | 1,184,500 | `[1.4806e7, 3.2672e7, 3.2672e7]` |
| Cubo | 130 | 196,000 | `[2.8224e6, 2.8224e6, 2.8224e6]` |

La masa concentrada total es `1,380,500 kg`. Los tensores satisfacen
positividad y desigualdades triangulares físicas. Las matrices espaciales 6×6
son finitas, simétricas y definidas positivas para los datos actuales.

La góndola orientada conserva un producto de inercia global
`Jxz=1.551199e6 kg·m²`; no se descartan términos fuera de la diagonal. El cubo
es isotrópico y, por tanto, su tensor es invariante a la orientación salvo ruido
de redondeo.

## Propiedades globales aceptadas

| Magnitud | Resultado |
|---|---:|
| Masa distribuida | `1,221,111.15284282 kg` |
| Masa de cuerpos | `1,380,500 kg` |
| Masa total | `2,601,611.15284282 kg` |
| CG global X | `0.4606633665 m` |
| CG global Y | `2.251454e-6 m` |
| CG global Z | `113.8865663265 m` |
| Compatibilidad de campos rígidos con `Tc` | `3.317e-17` |
| Conservación espacial antes/después de `Tc` | `1.359e-16` |
| Error de energía de masa por congruencia | `1.887e-16` |

La diferencia `M-Mdistributed` coincide con los dos bloques espaciales una
sola vez. La masa reducida es dispersa, simétrica y definida positiva por
factorización de Cholesky. `Ke` no se modifica en esta acción.

## Robustez añadida

- Se rechazan tensores no físicos aunque sean semidefinidos positivos si
  violan las desigualdades triangulares de los momentos principales.
- `compute_mass_properties` usa el mapa nodal de GDL y no presupone que la fila
  de un nodo coincida con una fórmula implícita.
- Los diagnósticos guardan cada matriz 6×6, tensor global en CG y maestro,
  orientación, offset, procedencia y versión de datos.
- Las masas se incorporan antes de `Tc` y nunca se diagonalizan junto con la
  masa distribuida.

## Artefactos

La corrida canónica contiene `action04_matrices.mat`,
`action04_body_matrices.csv`, `action04_mass_properties.csv`,
`action04_validation.csv`, configuración, modelo, operadores, resultados,
manifiesto, log y `SUCCESS`.

La aceptación es matemática y trazable con los datos disponibles. La
actualización futura de offsets medidos o de una orientación confirmada no
requerirá cambiar la formulación; solo sustituir el artefacto versionado y
regenerar las acciones posteriores.
