#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 4.8 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/concept_suma-velocidades.dat"'
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
$!FieldMap [1] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [2] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [3] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [4] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [5] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [6] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [7] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.3 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [8] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [9] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [10] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM5 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [11] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [12] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM5 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [13] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [14] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM5 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!ThreeDAxis XDetail { ShowAxis = No }
$!ThreeDAxis YDetail { ShowAxis = No }
$!ThreeDAxis ZDetail { ShowAxis = No }
$!ThreeDView PsiAngle = 65 ThetaAngle = 225 DrawInPerspective = No ViewerPosition { X = 62.95618477945529 Y = 65.15319054796416 Z = 42.35569269182628 } ViewWidth = 9.873416867586638
$!AttachText AnchorPos { X = 44.393859 Y = 36.653996 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = 'd<b><i>c</i></b>/dt'
$!AttachText AnchorPos { X = 61.105399 Y = 63.240537 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<i>Q</i><sub>c</sub>W <b><i>y</i></b>'
$!AttachText AnchorPos { X = 79.33617 Y = 73.579747 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<i>Q</i><sub>c</sub> d<b><i>y</i></b>/dt'
$!AttachText AnchorPos { X = 62.62463 Y = 43.300631 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = 'd<b><i>x</i></b>/dt'
$!AttachText AnchorPos { X = 9.0163934 Y = 24.943223 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM5 Text = '<b><i>E</i></b><sub>1</sub>'
$!AttachText AnchorPos { X = 23.053371 Y = 24.943223 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM5 Text = '<b><i>E</i></b><sub>2</sub>'
$!AttachText AnchorPos { X = 16.034882 Y = 42.387555 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM5 Text = '<b><i>E</i></b><sub>3</sub>'
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/concept_suma-velocidades.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/concept_suma-velocidades.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/concept_suma-velocidades.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/concept_suma-velocidades.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 4000
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/concept_suma-velocidades.png'
$!Export ExportRegion = CurrentFrame
