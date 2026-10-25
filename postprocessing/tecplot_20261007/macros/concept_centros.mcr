#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 4.8 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/concept_centros.dat"'
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
$!FieldMap [2] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.12 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [3] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.12 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [4] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.12 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [5] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.12 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [6] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.12 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [7] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.12 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [8] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.12 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [9] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.12 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [10] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.12 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [11] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.12 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [12] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.12 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [13] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.12 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [14] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [15] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [16] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [17] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [18] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [19] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [20] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [21] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [22] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [23] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!ThreeDAxis XDetail { ShowAxis = No }
$!ThreeDAxis YDetail { ShowAxis = No }
$!ThreeDAxis ZDetail { ShowAxis = No }
$!ThreeDView PsiAngle = 65 ThetaAngle = 225 DrawInPerspective = No ViewerPosition { X = 63.98469839079253 Y = 63.98469839079252 Z = 42.5679555128397 } ViewWidth = 7.118437783705243
$!AttachText AnchorPos { X = 24.371687 Y = 27.284878 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<b><i>d</i></b><sub>1</sub>'
$!AttachText AnchorPos { X = 75.628313 Y = 27.284878 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<b><i>d</i></b><sub>2</sub>'
$!AttachText AnchorPos { X = 50 Y = 90.983607 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<b><i>d</i></b><sub>3</sub>'
$!AttachText AnchorPos { X = 63.856918 Y = 53.632056 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<i>C</i><sub>m</sub>'
$!AttachText AnchorPos { X = 47.516636 Y = 39.04044 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<i>O</i><sub>s</sub>'
$!AttachText AnchorPos { X = 36.845483 Y = 59.273728 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<i>C</i><sub>A</sub>'
$!AttachText AnchorPos { X = 51.490018 Y = 43.446409 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<b><i>r</i></b><sub>cm</sub>'
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/concept_centros.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/concept_centros.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/concept_centros.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/concept_centros.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 4000
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/concept_centros.png'
$!Export ExportRegion = CurrentFrame
