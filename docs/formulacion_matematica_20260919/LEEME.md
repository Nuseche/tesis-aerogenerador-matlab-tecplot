# Formulación matemática — 19 de septiembre de 2026

Documento independiente de formulación, en clase AMCA/MECOM, A4 y una columna. Contiene el planteamiento, propiedades inerciales, matrices de Timoshenko, equilibrio, derivación giroscópica completa, transformaciones temporales, cargas, autovalores y excitación sísmica. No contiene resultados ni un capítulo de pruebas.

Mantenga juntos:

- `FORMULACION_MATEMATICA.tex` — archivo principal.
- `giroscopia.tex` — derivación detallada incluida por el principal.
- `amca.cls` — clase del documento.
- `modelo.pdf` — figura vectorial con fondo blanco.

Compile desde este directorio:

```sh
tectonic --keep-logs FORMULACION_MATEMATICA.tex
```

También puede subir estos cuatro archivos a un proyecto LaTeX, seleccionando `FORMULACION_MATEMATICA.tex` como documento principal. La bibliografía está incorporada y no requiere BibTeX.

El PDF refleja un modelo de pequeñas perturbaciones con inercia de referencia, velocidad prescrita y operadores congelados en un azimut. El procedimiento energético sigue Meirovitch, sección 4.4; las matrices seccionales son la especialización derivada para el modelo. El registro de implementación y verificación está separado, en `docs/GYROSCOPIC_REVISION_20260919.md` del proyecto de cálculo.
