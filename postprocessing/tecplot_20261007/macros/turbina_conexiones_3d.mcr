#!MC 1410
$!NewLayout
$!FrameLayout Width = 8 Height = 6 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/turbina_conexiones_3d.dat"'
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
$!FieldMap [1] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 85 }
$!FieldMap [2] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 85 }
$!FieldMap [3] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 85 }
$!FieldMap [4] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 85 }
$!FieldMap [5] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 85 }
$!FieldMap [6] Mesh { Show = No } Shade { Show = Yes Color = CUSTOM8 } Scatter { Show = No } EdgeLayer { Show = No } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Smooth SurfaceTranslucency = 85 }
$!FieldMap [7] Mesh { Show = Yes Color = CUSTOM7 LineThickness = 0.3 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM7 FillColor = CUSTOM7 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [8] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.3 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM1 FillColor = CUSTOM1 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [9] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.3 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM1 FillColor = CUSTOM1 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [10] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.3 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM1 FillColor = CUSTOM1 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [11] Mesh { Show = Yes Color = CUSTOM7 LineThickness = 0.3 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM7 FillColor = CUSTOM7 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [12] Mesh { Show = No Color = CUSTOM7 LineThickness = 0.2 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = Yes Color = CUSTOM7 FillColor = CUSTOM7 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [13] Mesh { Show = No Color = CUSTOM2 LineThickness = 0.2 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = Yes Color = CUSTOM2 FillColor = CUSTOM2 FillMode = UseSpecificColor FrameSize = 0.7 SymbolShape { GeomShape = Sphere } }
$!FieldMap [14] Mesh { Show = Yes Color = CUSTOM2 LineThickness = 0.2 LinePattern = DASHED } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM2 FillColor = CUSTOM2 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [15] Mesh { Show = Yes Color = CUSTOM2 LineThickness = 0.2 LinePattern = DASHED } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM2 FillColor = CUSTOM2 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [16] Mesh { Show = Yes Color = CUSTOM2 LineThickness = 0.2 LinePattern = DASHED } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM2 FillColor = CUSTOM2 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [17] Mesh { Show = Yes Color = CUSTOM3 LineThickness = 0.2 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM3 FillColor = CUSTOM3 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [18] Mesh { Show = Yes Color = CUSTOM8 LineThickness = 0.2 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM8 FillColor = CUSTOM8 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [19] Mesh { Show = Yes Color = CUSTOM8 LineThickness = 0.2 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM8 FillColor = CUSTOM8 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [20] Mesh { Show = Yes Color = CUSTOM8 LineThickness = 0.2 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM8 FillColor = CUSTOM8 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [21] Mesh { Show = Yes Color = CUSTOM8 LineThickness = 0.2 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM8 FillColor = CUSTOM8 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!FieldMap [22] Mesh { Show = Yes Color = CUSTOM8 LineThickness = 0.2 LinePattern = SOLID } Shade { Show = No } EdgeLayer { Show = No } Scatter { Show = No Color = CUSTOM8 FillColor = CUSTOM8 FillMode = UseSpecificColor FrameSize = 0.38 SymbolShape { GeomShape = Sphere } }
$!ThreeDAxis XDetail { ShowAxis = No }
$!ThreeDAxis YDetail { ShowAxis = No }
$!ThreeDAxis ZDetail { ShowAxis = No }
$!ThreeDView PsiAngle = 73 ThetaAngle = 230 DrawInPerspective = No
$!View Fit
$!ThreeDView ViewWidth *= 1.25
$!AttachText PositionCoordSys = Grid3D AnchorPos { X = 9.4915 Y = -10.1912 Z = 135.53 } TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 9 } Color = Black Text = '21'
$!AttachText PositionCoordSys = Grid3D AnchorPos { X = 9.4915 Y = 10.1912 Z = 135.53 } TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 9 } Color = Black Text = '57'
$!AttachText PositionCoordSys = Grid3D AnchorPos { X = 7.7078 Y = -4.1782e-15 Z = 154.49 } TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 9 } Color = Black Text = '93'
$!AttachText PositionCoordSys = Grid3D AnchorPos { X = -5.9886 Y = -5.0 Z = 145.54 } TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 9 } Color = Black Text = '129'
$!AttachText PositionCoordSys = Grid3D AnchorPos { X = 11.9696 Y = 5.0 Z = 145.5 } TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 9 } Color = Black Text = '130'
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/turbina_conexiones_3d.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/turbina_conexiones_3d.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/turbina_conexiones_3d.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/turbina_conexiones_3d.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 4200
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/turbina_conexiones_3d.png'
$!Export ExportRegion = CurrentFrame
