# Gyroscopic and centrifugal-prestress sensitivities of the base reaction

The test applies a unit axial 3P hub force, retaining the full spatial coordinates and periodic coefficients of the rotating structural model. It compares the complete system with three numerical variants. Omitting G deletes the material-frame skew gyroscopic matrix of the rotating blades and rigid hub. Omitting Kg deletes the initial-stress stiffness constructed from the centrifugal axial force on each blade. The third variant deletes both. The kinetic spin stiffness, prescribed rotation, mass transport, moving constraints, multiblade transformation and mechanical damping are retained in all variants.

Let Q map material coordinates to the fixed frame, R=TP be the complete recovery map and `H = transpose(Q) R`. Its azimuth derivative is `dH/dpsi = transpose(Q) dR/dpsi − W H`, where W is the rotation generator at unit speed. In MATLAB notation the transported material G contributes `omega * H.' * G * H` to the velocity matrix and `omega^2 * H.' * G * dH_dpsi` to stiffness. The centrifugal prestress contributes `omega^2 * H.' * Kg * H`. The forces associated with each of these matrices have zero physical row at the stationary tower base. All response histories therefore use exactly the same dynamic reaction map. The code checks the deletion matrices against independent reassembly with G and Kg individually set to zero at an off-grid azimuth and 3.4 rpm.

## Reproduction

From the root of the MATLAB solver repository, prepare the Fourier caches with the periodic load campaign, then execute:

```matlab
addpath(pwd,fullfile(pwd,'tools'),fullfile(pwd,'cases'));
run_periodic_load_campaign("pilot");
run_periodic_load_campaign("correct_266");
run_periodic_load_campaign("correct_532");
for ne = [133 266 532]
    run_rotating_term_study(ne,0.5);
end
run_rotating_term_study(266,0.5,"stability");
for target = [1 2 5]
    run_rotating_term_study(266,target);
end
```

Run `python3 tools/summarize_rotating_term_study.py` after the MATLAB campaigns. Results reside in `runs/rotating_term_study`. The file-name suffix is the element count followed by ten times the target damping in percent. The 266-element study at 0.5% uses a 2.8–4 rpm sweep with a 0.002 rpm grid near the reference peak; the other mesh and damping cases check selected speeds. Rayleigh targets apply at 0.17 and 1 Hz. Peak positions are sampled grid values.

Each CSV provides the signed 3P phase relative to the force, the moment amplitude in N m/N and the variant-minus-complete amplitude and phase changes. The one-revolution difference (`historyChangePct`) is the norm of the difference between the two full Fourier histories divided by the norm of the complete history at the same speed. The peak-normalized discrepancy in `summary_peaks.csv` divides the complex 3P difference by the complete model's largest sampled amplitude across that sweep. Each omission alters the dynamic equilibrium; the percentages express model sensitivity, and their sum is not a decomposition of the total bending moment.

The stability option computes the eight largest-modulus Floquet multipliers of each modified full-space system at 3.400 rpm and 0.5% mechanical damping with the same 128-step one-revolution SDIRK2 and Arnoldi method as in the damping campaign. Each variant has a separate output subdirectory. The principal modulus and Arnoldi residual are collected in `term_floquet_266.csv`.

The [data archive](../data/reference/rotating-operator-checks.zip) includes the beam benchmark, turbine sweeps, mesh and harmonic checks, and multipliers. Running `python3 tools/build_rotating_terms_figure.py` emits the self-contained pgfplots figure from the 266-element sweep.
