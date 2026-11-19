# Case 00 nacelle pulse and tower decay

The archived SIMPACT 7.2.0 case 00 applies equal global force components of 10 MN and equal local nacelle couple components of 10 MN m between 20 and 21 s. The base is clamped and the nominal initial rotor spin is zero. The spin constraint is released at 5 s. The linear model uses stationary operators throughout the comparison. The data audit and source file conventions are in [verification.md](verification.md). The [derived results](../data/reference/case00-decay.zip) include the window statistics, pulse replay, impulse balance and diagnostic plots.

## Reproduction

Use Python with NumPy, SciPy and Matplotlib and the existing structural model in MATLAB. From the repository root set CASE_DIR to the original case 00 directory with all five stages. Execute the first four commands, run the MATLAB command, then execute the last two Python commands.

```sh
python tools/check_case00_base_impulse.py --source "$CASE_DIR" --output runs/case00_decay/base_impulse_check.txt
python tools/analyze_case00_decay.py "$CASE_DIR"
python tools/check_case00_waveform.py "$CASE_DIR"
python tools/prepare_case00_replay.py "$CASE_DIR"
# In MATLAB: addpath('tools'); replay_case00_pulse()
python tools/compare_case00_replay.py "$CASE_DIR"
python tools/plot_case00_comparison.py "$CASE_DIR"
```

## What the reference measures

For each complete positive-going X-displacement cycle after the pulse, regress each signal on a constant and the sine and cosine at that cycle's frequency. Compute G as the complex amplitude of raw INTERNAL component 5 at node 400000 divided by that of the tower-top X displacement at node 400019. Measure 100 |G-Gref|/|Gref|, using the late cycles between 800 and 950 s to define the empirical reference. Hold out 950–1100 s. In 179 cycles, X fundamental amplitude spans 0.303–4.113 m, and the maximum relative change is 0.285%. It remains below 0.29% for the crossing-direction and one/three-cycle sensitivity tests. The maximum instantaneous absolute X excursion is 4.187 m. The raw-waveform checks in the archive use separate scalar-displacement and displacement/velocity fits and have different residual definitions. All these fits are internal to the nonlinear record.

At the fixed base the local second axis points along negative global Y. Comparing the mean terminal cumulative support impulse with the opposite external angular impulse supports the sign, axis and scale of minus C5 as the signal for global base bending. The Y impulses differ by 0.0504% using terminal times from 1000 to 1100 s. This is an integrated diagnostic and does not establish the instantaneous viscous part of the INTERNAL output. The raw-C5 phase in the window tables differs by 180 degrees from the global reaction convention used in linear_comparison.csv.

## Pulse replay

All 804 stationary linear coordinates are retained. The replay uses the measured nacelle orientation to express the applied couple in global axes over the pulse. After 21 s the calculation is unforced. It starts from rest at 20 s and retains the reference model's Rayleigh damping (1% targets at 0.2 and 2 Hz). The archived case uses a separate constitutive and damping description. Over 25–125 s the dominant frequencies are 0.17039 Hz (linear) and 0.16749 Hz (SIMPACT); the moment/displacement magnitudes at their respective dominant components are 347.37 and 344.14 MN m/m. The global phases are −179.93 and −179.72 degrees. The pointwise tower-X and moment history differences have relative L2 norms of 80.36% and 80.26% using SIMPACT as denominator. Comparison metrics use the 0.02 s output grid of the replay. Phase accumulation and different decay rates affect these history norms.

The 5% criterion was applied to the change in the within-record complex ratio. No crossing was found. The load-amplitude threshold for geometric contributions to the error of the independent structural model remains unidentified. In particular the ring-down does not establish applicability at the rotating 3P resonance.
