# Plan de implementación — Acción 05: masa consistente y diagonalización controlada

Fecha: 26 de agosto de 2026. Prerrequisitos aceptados: Acciones 02–04.

## 1. Objetivo

Consolidar la masa consistente como formulación de producción, demostrar su
positividad y conservación después de agregar cuerpos y aplicar `Tc`, y ofrecer
una diagonalización opcional explícita para comparaciones, sin usar valores
absolutos ni alterar las matrices espaciales 6×6 de góndola y cubo.

## 2. Decisión de formulación

`consistent` seguirá siendo la opción predeterminada y la única usada para los
resultados físicos canónicos. La suma de filas no es válida para la matriz
Timoshenko real porque produce términos negativos asociados a las funciones de
forma rotacionales; se conservará únicamente como ruta diagnóstica que falla de
forma explícita, nunca como método aceptado.

Se añadirá `hrz` como método diagonal opcional y trazable. Sobre la masa
distribuida, toma la diagonal física positiva y la escala para conservar la masa
de traslación rígida en X, Y y Z. Los GDL rotacionales reciben una escala HRZ
documentada. Las masas espaciales rígidas se agregan **después** y permanecen
completas; por ello la matriz total HRZ no es diagonal en los maestros.

La variante HRZ sirve para sensibilidad modal, no reemplaza automáticamente la
masa consistente ni pretende conservar exactamente CG e inercia global de una
distribución general.

## 3. Implementación prevista

1. Crear `assembly.hrz_lump_mass` con mapa de GDL explícito.
2. Extender `apply_mass_formulation` para `consistent`, `hrz` y la ruta
   diagnóstica `row_sum` que rechaza negativos.
3. Registrar método, escalas, masas direccionales, mínimos diagonales y la
   garantía `usesAbsoluteValue=false`.
4. Pasar `modelData` a la formulación para no inferir tipos de GDL por índices.
5. Crear un caso aislado Acción 05 que construya en paralelo:
   - masa distribuida consistente;
   - masa distribuida HRZ;
   - los mismos cuerpos espaciales completos;
   - la misma `Tc`.
6. Mantener la rama consistente como operador de producción guardado.
7. Comparar sobre un voladizo de torre las primeras frecuencias, formas mediante
   MAC y masas modales efectivas traslacionales.
8. Persistir matrices, diagnósticos y tablas comparativas.
9. Añadir suite y pruebas especializadas.

## 4. Verificaciones

### Producción consistente

- método por defecto `consistent`;
- igualdad exacta entrada–salida;
- simetría, finitud, dispersión y Cholesky de la masa reducida;
- masa total, CG e inercia conservados antes/después de `Tc`;
- cuerpos agregados después de la formulación distribuida;
- ninguna llamada a `abs` para modificar signos.

### HRZ opcional

- selección solo mediante `cfg.mass.formulation="hrz"`;
- diagonal distribuida estrictamente no negativa;
- masa de traslación rígida conservada en X/Y/Z;
- cuerpos espaciales no diagonalizados;
- masa reducida total positiva definida;
- frecuencias, MAC y participaciones exportados para la torre aislada;
- resultado reproducible y etiquetado como aproximación.

### Rutas prohibidas

- la suma de filas de la matriz real debe producir y conservar el error
  `NegativeRowSum`;
- método desconocido debe fallar;
- mapa de GDL ausente o inválido para HRZ debe fallar;
- diagonales materiales negativas deben fallar, no corregirse con `abs`.

## 5. Criterios de aceptación

- La formulación consistente satisface todos los criterios físicos de masa de
  la Acción 04.
- HRZ conserva las tres masas traslacionales con error `<=1e-12`.
- Las masas reducidas consistente y HRZ son definidas positivas.
- El benchmark modal es finito, tiene residuos `<=1e-8` y conserva asociación
  modal con MAC alto para las ramas comparadas.
- La comparación se exporta sin presentar HRZ como calibración física.
- Suite especializada, regresión completa y corrida canónica terminan en verde.

## 6. Artefactos

```text
runs/run_..._action05_mass_formulation/
├── SUCCESS
├── action05_matrices.mat
├── action05_validation.csv
├── action05_mass_comparison.csv
├── action05_modal_comparison.csv
├── action05_diagnostics.csv
└── archivos reproducibles comunes
```
