# Rotating radial cantilever of Chung and Yoo

The benchmark compares the production rotating structural assembly with the authors’ own 100-element results in Tables 2 and 3 of [Chung and Yoo, Journal of Sound and Vibration 249 (2002), 147–164](https://doi.org/10.1006/jsvi.2001.3856). The [readable original paper](https://www.academia.edu/102419792/Dynamic_Analysis_of_a_Rotating_Cantilever_Beam_by_Using_the_Finite_Element_Method) gives the tabulations on page 157. Column “Present” supplies the reference. Frequencies are angular frequencies times the characteristic time. The comparison uses all nine first chordwise frequencies in Table 2 and both flapwise frequencies at all eleven speeds in Table 3.

The cantilever has uniform properties, length L, root radius a, line mass μ and equal bending stiffness EI in both planes. The characteristic time is T = sqrt(μ L⁴/EI). The paper defines δ = a/L, γ = ΩT and slenderness α = sqrt(EA L²/EI). Units set L = μ = EI = 1, giving EA = 4900 at α = 70. The axis points along positive z, the undeformed beam along positive x and the tangential direction along positive y. Torsion decouples. The FE calculation sets infinite shear stiffness and zero sectional rotary inertia to reproduce the published Euler–Bernoulli line-mass model. Modal comparisons use a clamped root, zero damping and constant prescribed spin.

The script calls the same `aero.prepare_structure` assembly as the turbine. In rotating coordinates it uses mass M, elastic stiffness K, gyroscopic matrix ΩG, spin stiffness Ω²Kspin and recovered initial-stress stiffness Ω²Kg. An eigenanalysis of the coupled radial and tangential degrees of freedom includes axial–bending Coriolis coupling. A second eigenanalysis extracts the two lowest out-of-plane bending frequencies. The auxiliary no-gyro chordwise calculation retains both stiffness contributions. The comparison uses the operating eigensystems of Eqs. (46) and (47) of the reference.

Two assembly checks fix the physical sign and scaling. Before eliminating the clamp, a spatially uniform positive radial translation velocity at positive unit spin gives the signed tangential gyroscopic resultant +2μL on the left-hand side of the equation of motion. For centrifugal tension, each constant FE axial force is compared with the element average of the analytical field N(x) = μΩ²[a(L − x) + (L² − x²)/2], with x measured from the root. The force discrepancy reported in the CSV is the largest absolute element discrepancy divided by the largest analytical element mean.

From the code repository root, run:

```matlab
addpath('tools')
check_chung_yoo_rotating_beam
```

The driver writes `runs/chung_yoo_20261119/frequencies.csv` (186 frequency comparisons for six meshes) and `operator_checks.csv` (18 checks at unit spin for six meshes and three hub radii). Signed frequency differences are percentages relative to the original rounded tabulations. The 160-element calculation gives a maximum absolute difference of 0.00782% for the first chordwise mode and 0.00131% for the first two flapwise modes. All comparisons concern the uniform beam in the bending and axial subspaces specified above. Whole-turbine reaction accuracy and terms arising from eccentricity or sectional rotary inertia require separate evidence.
