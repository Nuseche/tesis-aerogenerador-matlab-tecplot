# Original source reference

`original` contains one byte-preserved copy of the supplied structural code,
including Diego Turello's 2021 Versions 0 and 1. The original names, language,
authorship, line endings and comments are retained as source evidence. They are
not part of the maintained English solver and must not be added to its path.

`MANIFEST.sha256` verifies all 22 original files. The previous root-level copy
was identical and has been removed. Filesystem write permissions are not used
as evidence because Git does not preserve read-only bits across clones.

To regenerate imported model data, use `tools/run_legacy_v0_benchmark.m` and
`tools/import_legacy_version0.m` explicitly. These are isolated import tools;
ordinary simulation uses the versioned MAT/JSON inputs instead.
