# Original geometry

`legacy_geometry_v0.mat` contains 138 nodal coordinates, 137 original
connectivity rows and three independent 36-by-3 blade auxiliary-point arrays.
It was extracted from Turello's Version 0 `GeoTorre.m`.

The maintained model removes the four original type-3 penalty connectors and
uses exact root/hub constraints plus the declared drivetrain connection.
The resulting flexible mesh has 133 beams: 19 tower, 105 blade and 9 transition
members. Coordinates and the original input arrays remain unchanged.
