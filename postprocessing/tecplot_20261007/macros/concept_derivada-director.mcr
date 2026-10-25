#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 4.8 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/concept_derivada-director.dat"'
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
$!FieldMap [1] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [2] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM5 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [3] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [4] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM5 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [5] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [6] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM5 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [7] Mesh { Show = Yes Color = CUSTOM2 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [8] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM2 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [9] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [10] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [11] Mesh { Show = Yes Color = CUSTOM3 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [12] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM3 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [13] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [14] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [15] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.2 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [16] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [17] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!ThreeDAxis XDetail { ShowAxis = No }
$!ThreeDAxis YDetail { ShowAxis = No }
$!ThreeDAxis ZDetail { ShowAxis = No }
$!ThreeDView PsiAngle = 65 ThetaAngle = 225 DrawInPerspective = No ViewerPosition { X = 64.19279633995215 Y = 63.86713616817232 Z = 42.43066755486584 } ViewWidth = 6.095226063857987
$!AttachText AnchorPos { X = 9.0163934 Y = 14.252487 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM5 Text = '<b><i>E</i></b><sub>1</sub>'
$!AttachText AnchorPos { X = 32.91444 Y = 14.252487 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM5 Text = '<b><i>E</i></b><sub>2</sub>'
$!AttachText AnchorPos { X = 20.965417 Y = 43.951579 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM5 Text = '<b><i>E</i></b><sub>3</sub>'
$!AttachText AnchorPos { X = 90.983607 Y = 19.293916 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<b><i>e</i></b><sub>i</sub>(t)'
$!AttachText AnchorPos { X = 81.702504 Y = 76.364983 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<b><i>e</i></b><sub>i</sub>(t+<greek>D</greek>t)'
$!AttachText AnchorPos { X = 70.34693 Y = 47.231304 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<greek>D</greek><b><i>e</i></b><sub>i</sub>'
$!AttachText AnchorPos { X = 90.983607 Y = 71.036285 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = 'd<b><i>e</i></b><sub>i</sub>/dt'
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/concept_derivada-director.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/concept_derivada-director.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/concept_derivada-director.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/concept_derivada-director.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 4000
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/concept_derivada-director.png'
$!Export ExportRegion = CurrentFrame
