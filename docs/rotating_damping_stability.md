# Mechanical damping and stability of the periodic base reaction

The prescribed axial hub force has unit amplitude and varies as the cosine of three times the rotor azimuth. All moment errors concern the reaction about global Y at the tower base. The Rayleigh damping targets are specified at 0.17 and 1 Hz. The rotating operators, prestress and reaction map use the conventions in [the periodic load campaign](periodic_load_campaign.md).

[Download the numerical results](../data/reference/rotating-damping-stability.zip). Data in the archive are grouped by method.

* The damping sweeps contain the real and imaginary parts of the periodic and averaged 3P moments in N m/N. The peak-normalized discrepancy divides the modulus of their complex difference by the maximum periodic amplitude sampled at that damping. The history error uses the relative L2 norm over one revolution at the same speed. Half-power endpoints use linear interpolation between samples. The labels 5, 10, 20 and 50 represent 0.5, 1, 2 and 5 percent.
* The Floquet tables describe the free evolution of a state perturbation over one revolution. The steps-per-revolution field is part of each result. The explicit monodromy calculation advances the entire state identity matrix and computes all multipliers. The matrix-free calculation applies the same full-space propagator within Arnoldi and extracts the eight largest-modulus multipliers. MAT files contain multiplier values. The radius is dimensionless and the corresponding growth rate is in inverse seconds.
* The forced Newmark histories start from rest and give the bending-moment discrepancy against the full H=12 particular solution on each revolution. Each row is compared with the corresponding phases of a single Fourier period. Initial speed, mesh, damping, time-step and revolution count distinguish the records.

## Reproduction

From the MATLAB repository root, add the application paths and prepare the full Fourier operators on the original and bisected meshes. The cache-building steps only have to run once.

```matlab
addpath(pwd,fullfile(pwd,'cases'),fullfile(pwd,'tools'));
run_periodic_load_campaign("pilot");
run_periodic_load_campaign("correct_266");
run_rotating_damping_sweep();
```

The remaining drivers take the sampling choices as arguments. Examples reproduce the central radius refinement and the forced transient comparison.

```matlab
check_periodic_stability(133,3.4445,0.5,[64 128 256]);
check_floquet_leading(266,[2.95 3.394 3.4445 3.49 3.90],[0.5 1 2 5],128);
check_floquet_leading(266,3.4445,[0.5 1 2 5],256);
check_floquet_leading(266,3.4445,[0.5 5],512);
check_floquet_sweep_peaks();
summarize_floquet_study();
check_periodic_forced_transient(3.4445,1536,120,133,0.5);
```

Each sweep summary identifies the sampled periodic and averaged peaks. The same Arnoldi driver accepts these speeds individually. From the repository root, `python3 tools/build_damping_figure.py` prints the self-contained pgfplots figure using the sweep CSVs.
