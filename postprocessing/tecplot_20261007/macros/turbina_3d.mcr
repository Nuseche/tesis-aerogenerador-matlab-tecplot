#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 7.6 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/turbina_3d.dat"'
$!PlotType = Cartesian3D
$!BasicColor CUSTOM1 { R = 20 G = 20 B = 20 }
$!BasicColor CUSTOM2 { R = 90 G = 90 B = 90 }
$!BasicColor CUSTOM3 { R = 45 G = 45 B = 45 }
$!BasicColor CUSTOM4 { R = 115 G = 115 B = 115 }
$!BasicColor CUSTOM5 { R = 150 G = 150 B = 150 }
$!BasicColor CUSTOM6 { R = 175 G = 175 B = 175 }
$!BasicColor CUSTOM7 { R = 30 G = 30 B = 30 }
$!BasicColor CUSTOM8 { R = 200 G = 200 B = 200 }
$!PrintSetup Palette = Color
$!FieldLayers ShowMesh = Yes ShowShade = Yes ShowScatter = Yes ShowEdge = Yes ShowContour = No UseTranslucency = Yes
$!ThreeDAxis AxisMode = XYZDependent DepXToYRatio = 1 DepXToZRatio = 1 AspectRatioLimit = 1000 BoxAspectRatioLimit = 1000 GridArea { IsFilled = No UseLightSourceToFill = No DrawBorder = No } FrameAxis { Show = Yes Size = 5 XYPos { X = 9 Y = 12 } }
$!FieldMap [1] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 67 }
$!FieldMap [2] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 67 }
$!FieldMap [3] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 67 }
$!FieldMap [4] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 67 }
$!FieldMap [5] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 67 }
$!FieldMap [6] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 67 }
$!FieldMap [7] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 67 }
$!FieldMap [8] Mesh { Show = Yes Color = CUSTOM7 LineThickness = 0.3 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM7 FillColor = CUSTOM7 FillMode = UseSpecificColor FrameSize = 0.23 SymbolShape { GeomShape = Sphere } }
$!FieldMap [9] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.3 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM1 FillColor = CUSTOM1 FillMode = UseSpecificColor FrameSize = 0.23 SymbolShape { GeomShape = Sphere } }
$!FieldMap [10] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.3 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM1 FillColor = CUSTOM1 FillMode = UseSpecificColor FrameSize = 0.23 SymbolShape { GeomShape = Sphere } }
$!FieldMap [11] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.3 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM1 FillColor = CUSTOM1 FillMode = UseSpecificColor FrameSize = 0.23 SymbolShape { GeomShape = Sphere } }
$!FieldMap [12] Mesh { Show = Yes Color = CUSTOM7 LineThickness = 0.3 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM7 FillColor = CUSTOM7 FillMode = UseSpecificColor FrameSize = 0.23 SymbolShape { GeomShape = Sphere } }
$!FieldMap [13] Mesh { Show = No Color = CUSTOM7 LineThickness = 0.2 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = Yes Color = CUSTOM7 FillColor = CUSTOM7 FillMode = UseSpecificColor FrameSize = 0.23 SymbolShape { GeomShape = Sphere } }
$!FieldMap [14] Mesh { Show = No Color = CUSTOM2 LineThickness = 0.2 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = Yes Color = CUSTOM2 FillColor = CUSTOM2 FillMode = UseSpecificColor FrameSize = 0.6 SymbolShape { GeomShape = Sphere } }
$!FieldMap [15] Mesh { Show = Yes Color = CUSTOM2 LineThickness = 0.2 LinePattern = DASHED } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM2 FillColor = CUSTOM2 FillMode = UseSpecificColor FrameSize = 0.23 SymbolShape { GeomShape = Sphere } }
$!FieldMap [16] Mesh { Show = Yes Color = CUSTOM2 LineThickness = 0.2 LinePattern = DASHED } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM2 FillColor = CUSTOM2 FillMode = UseSpecificColor FrameSize = 0.23 SymbolShape { GeomShape = Sphere } }
$!FieldMap [17] Mesh { Show = Yes Color = CUSTOM2 LineThickness = 0.2 LinePattern = DASHED } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM2 FillColor = CUSTOM2 FillMode = UseSpecificColor FrameSize = 0.23 SymbolShape { GeomShape = Sphere } }
$!FieldMap [18] Mesh { Show = Yes Color = CUSTOM3 LineThickness = 0.2 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM3 FillColor = CUSTOM3 FillMode = UseSpecificColor FrameSize = 0.23 SymbolShape { GeomShape = Sphere } }
$!ThreeDAxis XDetail { ShowAxis = No }
$!ThreeDAxis YDetail { ShowAxis = No }
$!ThreeDAxis ZDetail { ShowAxis = No }
$!ThreeDView PsiAngle = 87 ThetaAngle = 258 DrawInPerspective = No
$!View Fit
$!ThreeDView ViewWidth *= 1.12
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/turbina_3d.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/turbina_3d.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/turbina_3d.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/turbina_3d.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 4200
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/turbina_3d.png'
$!Export ExportRegion = CurrentFrame
