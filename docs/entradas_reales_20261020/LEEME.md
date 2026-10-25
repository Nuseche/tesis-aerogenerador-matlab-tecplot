# Comparación sísmica y eólica con entradas medidas

Fecha de trabajo: 20 de octubre de 2026 (America/Bogota).

Se completaron 114 evaluaciones estructurales. Se conserva la formulación heredada y las 175 fuentes congeladas. El estudio compara registros sísmicos procesados sin escalar y viento medido por DTU como fuentes independientes. El autor autorizó un empuje axial proporcional a U², con media libre.

## Resultados y alcance

- Arleta global X: máximo horizontal de góndola 0.283059 m y aceleración absoluta horizontal 0.579162 m/s².
- El viento produce un coeficiente de respuesta por 1 kN medio. Fref = 554.677210 kN iguala los máximos separados de góndola en los primeros 39,98 s; es una escala matemática de comparación, sin valor calibrado ni límite de seguridad.
- Para Fmedia = Fref, máximo combinado / máximo sísmico entre 1.545025 y 2.230980, entre 29 llegadas. La franja no es probabilística.
- 22/90 sensibilidades se estabilizan frente a los pasos; 1/90 supera el filtro conservador completo (1 máximo y 0 RMS). El único caso aceptado es giro → máximo absoluto del desplazamiento vertical relativo de la punta 92 bajo viento, S = −0.5004. Las tablas incluyen resultados rechazados y todos los pasos. La verificación temporal del máximo no garantiza convergencia de la derivada paramétrica.
- Operadores congelados, giro prescrito de 12 rpm y sin retroalimentación aerodinámica. La media eólica se equilibra con K del problema lineal, sin recalcular un equilibrio no lineal por empuje finito.
- RMS incluye la media del incremento eólico. El estudio no asigna distribuciones de incertidumbre ni calibra un sitio real.

## Fuentes primarias

1. [Wang et al. (2026)](https://doi.org/10.1080/13632469.2026.2671807), sismo PEER + viento sintético Davenport. Datos disponibles en [Zenodo, versión 19347779](https://doi.org/10.5281/zenodo.19347779). Ambos RAR descargados se verificaron con MD5 del repositorio; archivos OPJU, no series importadas a este estudio.
2. [Meng et al. (2020)](https://doi.org/10.1016/j.renene.2020.05.181), referencia experimental para amortiguamiento aerodinámico y combinación. PDF de manuscrito aceptado guardado sin modificación.
3. [DTU NM92](https://doi.org/10.11583/DTU.16743739), Hansen, Vasiljevic y Sørensen (2021), CC BY 4.0. Canal s70u, 70 m, 15000 muestras a 25 Hz, 2005-11-19. La turbina medida no es el modelo de tesis.
4. [OpenSees](https://github.com/OpenSees/OpenSees), fuente primaria de distribución de registros PEER procesados. Commit exacto, rutas y hashes en sources/earthquake_provenance.json. Tres registros cuantitativos de dos terremotos; el El Centro docente descargado se conserva solo como auxiliar y no se usa en los resultados.
5. [Turello et al. (2023)](https://cimec.org.ar/ojs/index.php/mc/article/view/6595), referencia del proyecto con sismo ajustado y cargas aeroelásticas. No se atribuyen esas entradas al caso DTU.

## Reproducción

1. `scripts/fetch_inputs.py`: descarga parcial del ZIP de DTU (sin descargar 7,19 GB completos), CRC32 del miembro y SHA-256. Los metadatos y el archivo original extraído se conservan en sources/.
2. `scripts/prepare_earthquakes.py` y `scripts/prepare_wind.py`: importación, unidades y comprobación de cabeceras.
3. MATLAB: ejecutar run_comparison.m, run_aligned.m y refine_local_steps.m. Las campañas reanudan archivos existentes. El refinamiento local responde a controles fallidos de h; el presupuesto operativo acumulado se registra en refinement_budget.mat.
4. MATLAB: analyze_comparison.m, verify_combination.m y make_figures.m. El análisis usa X para la comparación alineada y conserva Y como contraste.
5. Python: build_report.py actualiza exclusivamente el bloque nuevo del documento existente. Se guarda respaldo previo. No sincroniza automáticamente otros archivos LaTeX que ya difieren.

## Entregables y verificación

- Documento actualizado en ../sensibilidad_morris_20261006/SECCION_MORRIS_REVISION.tex y su PDF del proyecto.
- Tablas: nominal_earthquakes, time_convergence, local_sensitivities, differentiation_refinement, peak_time_switches, combined_sensitivities, input_amplitude_sensitivities, arrival_phase_comparison y direction_comparison.
- Comprobación directa de carga combinada en combined_load_verification.json; recuperación y chunking en runs/.../recovery_verification.json.
- Figuras MATLAB R2026a, blanco y negro, PNG a 300 dpi y PDF vectorial. La licencia Tecplot sigue sin renovación; se aplica la alternativa expresamente autorizada.
- Fuentes congeladas comprobadas en source_integrity.json; catálogo y huellas de entrega en delivery_audit.json.

El cierre físico con una demanda eólica de servicio requiere identificar el empuje medio o desarrollar una aerodinámica específica. El cierre periódico requiere evolución del azimut. Esos trabajos no se presentan como ejecutados.

## Verificación adicional de la tangente

La configuración heredada no resolvió las pendientes mecánicas. Se conservaron sus 114 casos y sus rechazos. Se añadieron 54 casos con la misma energía y equilibrio original, refinando solo la Hessiana dinámica con factores internos 20 y 40. En esta configuración se aceptan 1/90 indicadores. No cambió ninguna fuente congelada.

Reproducir con run_refined_tangent.m y analyze_refined_tangent.m; sus archivos viven en runs/.../refined_tangent. make_refined_figure.m genera el gráfico nuevo. Las tablas de comparación entre terremotos y llegadas conservan la configuración heredada y su trazabilidad.
