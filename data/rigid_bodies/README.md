# Rigid-body data

`legacy_rigid_bodies_v0.json` transcribes nacelle and hub masses and principal
inertias from Version 0 `FrecuenciasTorreCompleta.m` (original lines 159-177).
The declarative input stores `[90,-5,-90]` explicitly in degrees. The loader
converts these angles once; it does not repeat the original program's accidental
interpretation of those degree values as radians.

Zero center-of-mass offsets declare colocation at master nodes 129 and 130.
They are assumptions because the source does not supply measured offsets.
