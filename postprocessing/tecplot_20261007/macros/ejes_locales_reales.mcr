#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 4.8 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/ejes_locales_reales.dat"'
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
$!FieldLayers ShowMesh = Yes ShowShade = Yes ShowScatter = No ShowEdge = No ShowContour = No UseTranslucency = Yes
$!GlobalThreeD LightSource { BackgroundLight = 85 Intensity = 15 IncludeSpecular = No }
$!ThreeDAxis AxisMode = XYZDependent DepXToYRatio = 1 DepXToZRatio = 1 AspectRatioLimit = 1000 BoxAspectRatioLimit = 1000 GridArea { IsFilled = No DrawBorder = No UseLightSourceToFill = No } FrameAxis { Show = No }
$!FieldMap [1] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.28 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [2] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [3] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [4] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [5] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [6] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [7] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [8] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [9] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!ThreeDAxis XDetail { ShowAxis = No }
$!ThreeDAxis YDetail { ShowAxis = No }
$!ThreeDAxis ZDetail { ShowAxis = No }
$!ThreeDView PsiAngle = 65 ThetaAngle = 225 DrawInPerspective = No ViewerPosition { X = 33.35105997813361 Y = 19.38756882881989 Z = 156.6475449392941 } ViewWidth = 5.870467303341139
$!AttachText AnchorPos { X = 58.371122 Y = 34.607026 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 11 IsBold = No } Color = CUSTOM1 Text = 'I = 21'
$!AttachText AnchorPos { X = 15.600997 Y = 9.0163934 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 11 IsBold = No } Color = CUSTOM1 Text = 'J = 22'
$!AttachText AnchorPos { X = 25.887519 Y = 15.171124 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<b><i>e</i></b><sub>1</sub>'
$!AttachText AnchorPos { X = 45.216966 Y = 90.983607 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<b><i>e</i></b><sub>2</sub>'
$!AttachText AnchorPos { X = 84.399003 Y = 32.66623 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<b><i>e</i></b><sub>3</sub>'
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/ejes_locales_reales.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/ejes_locales_reales.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/ejes_locales_reales.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/ejes_locales_reales.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 4000
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/ejes_locales_reales.png'
$!Export ExportRegion = CurrentFrame
