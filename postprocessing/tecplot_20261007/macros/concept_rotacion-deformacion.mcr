#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 3.9 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/concept_rotacion-deformacion.dat"'
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
$!FieldMap [1] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM8 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [2] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [3] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [4] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [5] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [6] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [7] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [8] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.1 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [9] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.1 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [10] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.1 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [11] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM8 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [12] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [13] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [14] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [15] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [16] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [17] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [18] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.1 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [19] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.1 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [20] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.1 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [21] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM8 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [22] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [23] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [24] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [25] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [26] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [27] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.14 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [28] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.1 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [29] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.1 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [30] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.1 } Shade { Show = No } EdgeLayer { Show = No }
$!ThreeDAxis XDetail { ShowAxis = No }
$!ThreeDAxis YDetail { ShowAxis = No }
$!ThreeDAxis ZDetail { ShowAxis = No }
$!ThreeDView PsiAngle = 65 ThetaAngle = 225 DrawInPerspective = No ViewerPosition { X = 60.72784216058867 Y = 67.31606725997952 Z = 42.45496489090233 } ViewWidth = 14.47254487375228
$!AttachText AnchorPos { X = 11.947903 Y = 68.664379 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 11 IsBold = No } Color = CUSTOM1 Text = '(a)'
$!AttachText AnchorPos { X = 45.11415 Y = 68.664379 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 11 IsBold = No } Color = CUSTOM1 Text = '(b)'
$!AttachText AnchorPos { X = 78.280398 Y = 68.664379 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 11 IsBold = No } Color = CUSTOM1 Text = '(c)'
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/concept_rotacion-deformacion.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/concept_rotacion-deformacion.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/concept_rotacion-deformacion.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/concept_rotacion-deformacion.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 4000
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/concept_rotacion-deformacion.png'
$!Export ExportRegion = CurrentFrame
