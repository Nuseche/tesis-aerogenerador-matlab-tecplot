# Section properties

`legacy_sections_v0.mat` stores the extracted tower and blade section data.
The production loader interprets stiffness and mass fields explicitly; it does
not execute `Secciones.m` or derive a fictitious blade modulus from mass data.

The sectional stiffness order is `EA, GAy, GAz, GJ, EIy, EIz`. Distributed mass
uses mass per length and rotary inertias. The original zero longitudinal blade
inertia is resolved only by the declared `perpendicular_axis` rule, `Jx=Jy+Jz`.
See [mechanical conventions](../../docs/conventions.md) for frames and signs.
