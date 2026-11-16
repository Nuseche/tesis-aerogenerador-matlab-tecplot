# Versioned model inputs

The solver reads self-contained MAT files in `geometry`, `sections` and
`reference`, plus the declarative JSON in `rigid_bodies`. It never executes the
original MATLAB scripts during an analysis. `config_default` resolves these
paths from the repository location.

`MANIFEST.sha256` records the original model-input bytes. Verify with
`python tools/check_repository.py` or `shasum -a 256 -c data/MANIFEST.sha256`.

- [Geometry](geometry/README.md): node coordinates, connectivity, auxiliary points.
- [Sections](sections/README.md): stiffnesses and distributed mass properties.
- [Rigid bodies](rigid_bodies/README.md): masses, principal inertias and orientations.
- [References](reference/README.md): historical frequencies and operating evidence.

Measured seismic/wind inputs and preparation scripts live together in
[studies/measured_inputs](../studies/README.md). Their provenance and checksums
are independent of the model-input manifest.
