#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 5.6 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/detalle_base.dat"'
$!PlotType = XYLine
$!DeleteLineMaps
$!BasicColor CUSTOM1 { R = 20 G = 20 B = 20 }
$!BasicColor CUSTOM2 { R = 90 G = 90 B = 90 }
$!BasicColor CUSTOM3 { R = 45 G = 45 B = 45 }
$!BasicColor CUSTOM4 { R = 115 G = 115 B = 115 }
$!BasicColor CUSTOM5 { R = 150 G = 150 B = 150 }
$!BasicColor CUSTOM6 { R = 175 G = 175 B = 175 }
$!BasicColor CUSTOM7 { R = 30 G = 30 B = 30 }
$!BasicColor CUSTOM8 { R = 200 G = 200 B = 200 }
$!PrintSetup Palette = Color
$!CreateLineMap
$!LineMap [1] Name = '' Assign { Zone = 1 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM7 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM7 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = LTri } }
$!CreateLineMap
$!LineMap [2] Name = '' Assign { Zone = 2 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM7 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM7 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = LTri } }
$!CreateLineMap
$!LineMap [3] Name = '' Assign { Zone = 3 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM7 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM7 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = LTri } }
$!ActiveLineMaps = [1-3]
$!XYLineAxis ViewportPosition { X1 = 13 X2 = 94 Y1 = 16 Y2 = 94 }
$!XYLineAxis GridArea { DrawBorder = No }
$!XYLineAxis XDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = -18.82211538461539 RangeMax = 18.82211538461539 CoordScale = Linear Title { TitleMode = UseText Offset = 6 Text = 'X [m]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!XYLineAxis YDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = -1 RangeMax = 28 CoordScale = Linear Title { TitleMode = UseText Offset = 9 Text = 'Z [m]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!LinePlotLayers ShowSymbols = Yes
$!GlobalLinePlot Legend { Show = No TextShape { SizeUnits = POINT Height = 10 IsBold = No } XYPos { X = 99 Y = 87 } }
$!AttachText AnchorPos { X = 54.037931 Y = 19.227586 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '1'
$!AttachText AnchorPos { X = 54.037931 Y = 38.338393 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '2'
$!AttachText AnchorPos { X = 54.037931 Y = 57.450276 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '3'
$!AttachText AnchorPos { X = 54.037931 Y = 76.560276 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '4'
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/detalle_base.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/detalle_base.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/detalle_base.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/detalle_base.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 2100
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/detalle_base.png'
$!Export ExportRegion = CurrentFrame
