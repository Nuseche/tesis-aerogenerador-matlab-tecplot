# Mechanical and numerical conventions

Use coherent SI units: m, kg, s, N, Pa and rad. Each node stores
`[ux, uy, uz, theta_x, theta_y, theta_z]`. Global axes are right-handed;
positive rotations follow the right-hand rule.

For an offset `r`, `S(r)*a = cross(r,a)`. Exact rigid compatibility is
`u_slave = u_master - S(r)*theta_master`, with equal infinitesimal rotations.
The nominal rotor axis points from nacelle master 129 to hub master 130.
The root slaves are 21, 57 and 93; blade tips are 56, 92 and 128.

## Beam frames and section laws

Local axis 1 points from node I to J. Project the I-to-auxiliary-point vector
onto the plane normal to axis 1 to obtain axis 3; axis 2 is `cross(e3,e1)`.
The three blade auxiliary arrays are independent. Do not interchange `EIy/EIz`,
`GAy/GAz` or `Jy/Jz` when constructing a frame.

The rows of `R` contain local axes in global coordinates.
`Te = blkdiag(R,R,R,R)`, `q_local = Te*q_global`, and
`K_global = Te'*K_local*Te`, with the analogous relation for mass.
The local coordinate order is `[u1 v1 w1 rx1 ry1 rz1 u2 v2 w2 rx2 ry2 rz2]`.
The strain conventions are

```text
epsilon_x = du/dx        gamma_y = dv/dx - rz   gamma_z = dw/dx + ry
kappa_x   = drx/dx       kappa_y = dry/dx       kappa_z = drz/dx
```

A positive rigid rotation about local 2 requires `w2-w1 = -ry*L`;
a positive rotation about local 3 requires `v2-v1 = rz*L`.

Blade `AXIALD` is mass per length, not an area or a way to infer Young's modulus.
The original `TORDEN` column is zero. The explicit `perpendicular_axis` rule
sets `Jx = Jy + Jz` from the transverse mass moments; it does not infer inertia
from stiffness. Use the consistent mass as the default; HRZ is a separately
selected comparison. The old absolute row-sum diagonal mass is historical only.

## Rotation, equilibrium and recovery

Positive rotor speed follows the right-hand rule about the nominal axis.
Blade 1 defines zero azimuth; blades 2 and 3 are separated by `2*pi/3`.
Positive pitch is a right-handed rotation about each blade's longitudinal axis.
Original angles recorded in degrees are explicitly converted once.

A moving transformation requires
`qdot = T*zdot + Tdot*z` and
`qddot = T*zddot + 2*Tdot*zdot + Tddot*z`.
MBC and constraint transport terms must remain consistent in assembly and recovery.
Frozen-azimuth eigenvalues and trajectories do not constitute a Floquet analysis.

`Kg` contains equilibrium axial-force effects. `KOmega` contains rotational
contributions not represented by those forces; do not double-count them.
Gyroscopic power and energy-Hessian consistency are covered by the regression
suite. Aerodynamic tangents are explicit inputs, kept separate from structural
operators; absent coefficients remain zero and are reported as such.

Seismic coordinates are relative to the base. Recover absolute acceleration
by including ground acceleration and the transformation derivatives. Recover
base reactions from equilibrium including inertia, damping, elasticity and
base-motion terms, rather than stiffness alone.
