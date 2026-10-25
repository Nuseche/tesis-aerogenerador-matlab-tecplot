# Secciones Version 0

`legacy_sections_v0.mat` contiene 55 secciones canónicas en SI:

- IDs 1--20: torre/transición, derivados exactamente de `secc_torre` y de
  `YOUNG=2.1e11`, `POISS=0.3`, `DENS=7850` de Version 0.
- IDs 21--55: las 35 estaciones de pala; las seis rigideces generalizadas
  se conservan directamente de `secc_pala`, sin reconstruir E/A ficticios.
  `AXIALD`, `TORDEN`, `INERT2` e `INERT3` se preservan además en
  `rawMassColumns`. Como `TORDEN=0`, el artefacto deja `Jx=NaN` y exige una
  regla explícita de configuración. `model.resolve_section_mass` admite
  únicamente `perpendicular_axis`, que calcula `Jx=Jy+Jz`; nunca usa
  `EA/AXIALD` ni `GJ`.

Version 0 no entrega offsets de centroide; se conserva su formulación
centrada declarando `ycg=zcg=0` y registrando esa limitación en cada sección.
