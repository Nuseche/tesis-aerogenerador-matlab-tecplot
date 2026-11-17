# User-supplied aerodynamic parameter scripts

`blade_source.m` and `generator_source.m` preserve, byte for byte, the files
`snlBLD.m` and `snlGNR.m` supplied by the user on 17 November 2026. Their checksums
are in `data/MANIFEST.sha256`. The original comments and encoding are retained
as source evidence. No author or publication attribution is inferred from the
filenames. These scripts are not executed by the solver.

Run `python tools/audit_supplied_aerodynamics.py` from the repository root to
repeat the comparison. It parses numeric assignments as text. All 34 span and
chord stations match the included Sandia geometry to roundoff. The supplied
`beta` is exactly the negative of the report's twist column. This indicates a
different sign convention; it does not establish an error in either model.

The scripts supply:

| Quantity | Supplied value or convention |
| --- | --- |
| Blade length | 100 m |
| Root offset `lac` | 6 m |
| Rotor radius `rRot` | 106 m |
| Lifting length `Lss` | 82.1 m, starting at span 17.9 m |
| Density | 1.225 kg/m³ |
| Nonzero `Clalpha` | 0.10966 per degree = 6.283055 per radian |
| `Cl0` | Span-dependent, including camber offsets |
| `Cdalpha`, `Cd0` | Both zero at every station |
| `limAng` | 20 degrees, described as a prediction limit for Cl |
| Pitch sweep | 80 to 190 degrees, increment 5 degrees |
| Wind sweep settings | Cut-in 3, cut-out 25, maximum 30 m/s |
| Maximum rotor speed parameter | `oMax = 1`; its unit is not explicitly stated |

`snlBLD.m` constructs cubic splines before restricting the lifting stations.
Interpolating these numbers linearly would not reproduce that supplied operation.
The slope is consistent with approximately 2π per radian. Treating 0.10966 as a
per-radian slope would introduce a factor-of-57.3 error.

These are parameters for a linear sectional coefficient approximation. They are
not full-angle polars and provide no Cm table, stall law, induction model or
calling function. In particular, the scripts do not specify whether `limAng`
clips the angle, clips Cl, stops a calculation, or only limits plotting. They
also do not define how the pitch sweep becomes the incidence angle. Setting
the present conventional pitch equal to `q` or automatically negating twist
would therefore be unsupported.

The completed convergence and rotor-order studies use the previously declared
OpenFAST reference polars. These supplied files are audited and versioned, but
do not silently replace that aerodynamic model. Their zero-drag linear law
would define a distinct model comparison, requiring an explicit convention
mapping before interpreting changes in loads or stability. The present growing
pole must not be attributed to these supplied coefficients.
