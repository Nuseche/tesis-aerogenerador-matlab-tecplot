#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 4.3 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/paper_vinculo_raiz.dat"'
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
$!FieldMap [5] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.28 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [6] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [7] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM1 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [8] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [9] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM5 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [10] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [11] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM5 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!FieldMap [12] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.22 } Shade { Show = No } EdgeLayer { Show = No }
$!FieldMap [13] Mesh { Show = No } EdgeLayer { Show = No } Shade { Show = Yes Color = CUSTOM5 } Surfaces { SurfacesToPlot = BoundaryFaces } Effects { LightingEffect = Paneled SurfaceTranslucency = 1 }
$!ThreeDAxis XDetail { ShowAxis = No }
$!ThreeDAxis YDetail { ShowAxis = No }
$!ThreeDAxis ZDetail { ShowAxis = No }
$!ThreeDView PsiAngle = 65 ThetaAngle = 225 DrawInPerspective = No ViewerPosition { X = 63.14558747324404 Y = 64.66048646056636 Z = 42.81561752559986 } ViewWidth = 7.503120273312176
$!AttachText AnchorPos { X = 52.383071 Y = 30.884579 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<greek>d</greek><b><i>u</i></b><sub>m</sub>'
$!AttachText AnchorPos { X = 87.70171 Y = 66.032747 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<greek>d</greek><b><i>u</i></b><sub>rot</sub>'
$!AttachText AnchorPos { X = 55.715018 Y = 69.504171 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM1 Text = '<greek>d</greek><b><i>u</i></b><sub>s</sub>'
$!AttachText AnchorPos { X = 10.965511 Y = 9.0163934 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM5 Text = '<b><i>E</i></b><sub>1</sub>'
$!AttachText AnchorPos { X = 28.494467 Y = 9.0163934 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM5 Text = '<b><i>E</i></b><sub>2</sub>'
$!AttachText AnchorPos { X = 19.729989 Y = 33.33337 } Anchor = CENTER TextShape { FontFamily = 'Times' SizeUnits = POINT Height = 12 IsBold = No } Color = CUSTOM5 Text = '<b><i>E</i></b><sub>3</sub>'
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/paper_vinculo_raiz.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/paper_vinculo_raiz.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/paper_vinculo_raiz.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/paper_vinculo_raiz.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 4000
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/paper_vinculo_raiz.png'
$!Export ExportRegion = CurrentFrame
