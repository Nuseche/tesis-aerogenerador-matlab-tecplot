# SNL100 external geometry and reference section polars

These files are sufficient for the section-force model; no FAST installation,
AeroDyn input file or runtime download is required. They do not reconstruct the
UVLM aerodynamic discretization used by Maza and colleagues.

`geometry.csv` contains the 34 stations in Table 1, printed page 16, of Griffith's
[SAND2013-10162 report](https://www.osti.gov/servlets/purl/1147201). The report
explicitly identifies this external geometry as common to SNL100-00, SNL100-01
and SNL100-02. Span is converted from the tabulated fraction to metres for a
100 m blade; twist remains in degrees in the CSV and becomes radians in MATLAB.
The user-supplied [original SAND2011-3779 report](sand2011_3779.pdf), Table 18
(p. 34), independently matches all 34 rows exactly in span, chord, twist and
pitch-axis fraction. Its unchanged PDF is included for traceability.
The structural stiffness and mass distributions remain the inherited model
inputs in `data/sections`; external geometry does not establish that their full
constitutive matrices coincide with Maza's PreComp model.

`polars/*.csv` are the alpha/Cl/Cd/Cm tables from the official
[OpenFAST reference dataset](https://github.com/OpenFAST/r-test/tree/dd5feaaaa500ba7283140107806300d551cff0a7/glue-codes/openfast/5MW_Baseline/Airfoils),
frozen at commit `dd5feaaaa500ba7283140107806300d551cff0a7`. The original headers
attribute the airfoil data to DOWEC and document rotational stall-delay and
Viterna corrections. These are adopted reference polars, not SNL100-00 v2
measurements or aerodynamic coefficients supplied by Maza. Their source headers
contain Re = 0.75 million; this implementation neither matches nor interpolates
Reynolds number. That header is provenance, not a demonstrated operating Reynolds
number for this blade.

The mapping is an explicit approximation: linearly interpolate coefficients
between NACA64 (18%), DU21 (21%), DU25 (25%), DU30 (30%), DU35 (35%), DU40
(40.5%) and Cylinder1 (100%) according to local thickness. Modified transition
profiles are not resolved separately. Angle interpolation is periodic over
−180° to 180°. Cylinder1 has Cl = Cm = 0 and Cd = 0.5. The unused Cylinder2
table is not included.

`maza_2023_reference.csv` transcribes the 13 nonempty combinations in Table 2 of
[Maza et al. (2023)](https://amcaonline.org.ar/ojs/index.php/mc/article/download/6643/6706).
The text says 12 combinations and Table 1 lists a broader selection; the CSV
preserves the numerical rows actually reported in Table 2. Its caption gives
m/s for displacement mean and amplitude, whereas the surrounding discussion and
figure axes identify metres; the CSV uses metres. A reported frequency alongside
zero amplitude is not automatically a measurable steady-state oscillation.

The published results are a comparison reference from another mathematical
model, not absolute truth, experimental observations, or calibration targets.
`provenance.json` records source URLs, original-file hashes and converted-CSV
hashes. Run `python tools/check_repository.py` to verify the included tables.
See [the coupling documentation](../../../docs/aeroelasticity.md) for assumptions,
coordinates and interpretation of the Maza comparison.

## Original baseline and isolated comparison are different configurations

The 2011 report gives a 2.5 m hub radius (102.5 m rotor radius), maximum speed
7.44 rpm and rated wind 11.3 m/s in Table 24. Maza's isolated case deliberately
uses a 6 m root radius and no precone, tilt or gravity. The driver preserves those
isolated conditions instead of silently substituting the original turbine's values.
The attached report documents the original 2011 baseline, not an identified v2
revision of all section data.

Pages 32–33 explain that transition shapes and modified thicknesses were developed
geometrically for structural design, without assessing their aerodynamic properties.
Thus the shared airfoil ancestry supports the choice of reference families but
does not verify the adopted interpolated Cl/Cd/Cm curves.

The report itself lists different blade-mass estimates: 114,172 kg from FAST,
115,684 kg from midpoint-averaged PreComp data and 118,634 kg from ANSYS (p. 45).
The inherited straightened 35-element blade integrates to 111,514.164 kg. It is
not rescaled to any of those figures. That observation calls for version and
section-property traceability, not automatic selection of one mass as truth.
The estimated flutter margins on pp. 50–51 are also explicitly presented by the
report as simplified model predictions with uncertain accuracy.
