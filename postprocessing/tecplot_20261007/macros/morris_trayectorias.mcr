#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 5.6 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/morris_trayectorias.dat"'
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
$!FieldLayers ShowMesh = Yes ShowContour = No ShowShade = No ShowEdge = No
$!ThreeDAxis AxisMode = XYZDependent DepXToYRatio = 1 DepXToZRatio = 1 AspectRatioLimit = 1000 BoxAspectRatioLimit = 1000 FrameAxis { Show = Yes Size = 6 XYPos { X = 9 Y = 14 } } GridArea { IsFilled = No FillColor = White UseLightSourceToFill = No DrawBorder = No }
$!FieldMap [1] Mesh { Show = Yes Color = CUSTOM2 LineThickness = 0.25 }
$!FieldMap [2] Mesh { Show = Yes Color = CUSTOM3 LineThickness = 0.25 }
$!FieldMap [3] Mesh { Show = Yes Color = CUSTOM4 LineThickness = 0.25 }
$!FieldMap [4] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.25 }
$!FieldMap [5] Mesh { Show = Yes Color = CUSTOM6 LineThickness = 0.25 }
$!FieldMap [6] Mesh { Show = Yes Color = CUSTOM7 LineThickness = 0.25 }
$!FieldMap [7] Mesh { Show = Yes Color = CUSTOM8 LineThickness = 0.25 }
$!FieldMap [8] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.25 }
$!FieldMap [9] Mesh { Show = Yes Color = CUSTOM2 LineThickness = 0.25 }
$!FieldMap [10] Mesh { Show = Yes Color = CUSTOM3 LineThickness = 0.25 }
$!FieldMap [11] Mesh { Show = Yes Color = CUSTOM4 LineThickness = 0.25 }
$!FieldMap [12] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.25 }
$!FieldMap [13] Mesh { Show = Yes Color = CUSTOM6 LineThickness = 0.25 }
$!FieldMap [14] Mesh { Show = Yes Color = CUSTOM7 LineThickness = 0.25 }
$!FieldMap [15] Mesh { Show = Yes Color = CUSTOM8 LineThickness = 0.25 }
$!FieldMap [16] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.25 }
$!FieldMap [17] Mesh { Show = Yes Color = CUSTOM2 LineThickness = 0.25 }
$!FieldMap [18] Mesh { Show = Yes Color = CUSTOM3 LineThickness = 0.25 }
$!FieldMap [19] Mesh { Show = Yes Color = CUSTOM4 LineThickness = 0.25 }
$!FieldMap [20] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.25 }
$!FieldMap [21] Mesh { Show = Yes Color = CUSTOM6 LineThickness = 0.25 }
$!FieldMap [22] Mesh { Show = Yes Color = CUSTOM7 LineThickness = 0.25 }
$!FieldMap [23] Mesh { Show = Yes Color = CUSTOM8 LineThickness = 0.25 }
$!FieldMap [24] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.25 }
$!FieldMap [25] Mesh { Show = Yes Color = CUSTOM2 LineThickness = 0.25 }
$!FieldMap [26] Mesh { Show = Yes Color = CUSTOM3 LineThickness = 0.25 }
$!FieldMap [27] Mesh { Show = Yes Color = CUSTOM4 LineThickness = 0.25 }
$!FieldMap [28] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.25 }
$!FieldMap [29] Mesh { Show = Yes Color = CUSTOM6 LineThickness = 0.25 }
$!FieldMap [30] Mesh { Show = Yes Color = CUSTOM7 LineThickness = 0.25 }
$!FieldMap [31] Mesh { Show = Yes Color = CUSTOM8 LineThickness = 0.25 }
$!FieldMap [32] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.25 }
$!FieldMap [33] Mesh { Show = Yes Color = CUSTOM2 LineThickness = 0.25 }
$!FieldMap [34] Mesh { Show = Yes Color = CUSTOM3 LineThickness = 0.25 }
$!FieldMap [35] Mesh { Show = Yes Color = CUSTOM4 LineThickness = 0.25 }
$!FieldMap [36] Mesh { Show = Yes Color = CUSTOM5 LineThickness = 0.25 }
$!FieldMap [37] Mesh { Show = Yes Color = CUSTOM6 LineThickness = 0.25 }
$!FieldMap [38] Mesh { Show = Yes Color = CUSTOM7 LineThickness = 0.25 }
$!FieldMap [39] Mesh { Show = Yes Color = CUSTOM8 LineThickness = 0.25 }
$!FieldMap [40] Mesh { Show = Yes Color = CUSTOM1 LineThickness = 0.25 }
$!ThreeDAxis XDetail { ShowAxis = Yes AxisLine { Show = Yes LineThickness = 0.15 } Title { TitleMode = UseText Offset = 7 Text = 'Masa/inercia [-]' TextShape { SizeUnits = POINT Height = 12 IsBold = No } } TickLabel { Skip = 2 TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = No } }
$!ThreeDAxis YDetail { ShowAxis = Yes AxisLine { Show = Yes LineThickness = 0.15 } Title { TitleMode = UseText Offset = 7 Text = 'Rigidez [-]' TextShape { SizeUnits = POINT Height = 12 IsBold = No } } TickLabel { Skip = 2 TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = No } }
$!ThreeDAxis ZDetail { ShowAxis = Yes AxisLine { Show = Yes LineThickness = 0.15 } Title { TitleMode = UseText Offset = 7 Text = 'Velocidad [-]' TextShape { SizeUnits = POINT Height = 12 IsBold = No } } TickLabel { Skip = 2 TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = No } }
$!ThreeDView PsiAngle = 65 ThetaAngle = 225 DrawInPerspective = No
$!View Fit
$!ThreeDView ViewWidth *= 1.25
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/morris_trayectorias.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/morris_trayectorias.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/morris_trayectorias.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/morris_trayectorias.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 2100
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/morris_trayectorias.png'
$!Export ExportRegion = CurrentFrame
