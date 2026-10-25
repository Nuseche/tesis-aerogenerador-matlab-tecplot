#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 5.6 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/detalle_raices.dat"'
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
$!LineMap [1] Name = '' Assign { Zone = 1 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM2 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM2 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Square } }
$!CreateLineMap
$!LineMap [2] Name = '' Assign { Zone = 2 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM3 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM3 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Diamond } }
$!CreateLineMap
$!LineMap [3] Name = '' Assign { Zone = 3 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM4 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM4 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Del } }
$!CreateLineMap
$!LineMap [4] Name = '' Assign { Zone = 4 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM2 LineThickness = 0.3 LinePattern = DASHED PatternLength = 2 } Symbols { Show = No Color = CUSTOM2 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Square } }
$!CreateLineMap
$!LineMap [5] Name = '' Assign { Zone = 5 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM2 LineThickness = 0.3 LinePattern = DASHED PatternLength = 2 } Symbols { Show = No Color = CUSTOM2 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Square } }
$!CreateLineMap
$!LineMap [6] Name = '' Assign { Zone = 6 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM2 LineThickness = 0.3 LinePattern = DASHED PatternLength = 2 } Symbols { Show = No Color = CUSTOM2 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Square } }
$!ActiveLineMaps = [1-6]
$!XYLineAxis ViewportPosition { X1 = 13 X2 = 94 Y1 = 16 Y2 = 94 }
$!XYLineAxis GridArea { DrawBorder = No }
$!XYLineAxis XDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = -12.98076923076923 RangeMax = 12.98076923076923 CoordScale = Linear Title { TitleMode = UseText Offset = 6 Text = 'Y [m]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!XYLineAxis YDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = 134 RangeMax = 154 CoordScale = Linear Title { TitleMode = UseText Offset = 9 Text = 'Z [m]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!LinePlotLayers ShowSymbols = Yes
$!GlobalLinePlot Legend { Show = No TextShape { SizeUnits = POINT Height = 10 IsBold = No } XYPos { X = 99 Y = 87 } }
$!AttachText AnchorPos { X = 38.083456 Y = 38.347 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '21'
$!AttachText AnchorPos { X = 30.6304 Y = 32.302 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '22'
$!AttachText AnchorPos { X = 70.476544 Y = 38.347 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '57'
$!AttachText AnchorPos { X = 78.453448 Y = 33.433 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '58'
$!AttachText AnchorPos { X = 54.28 Y = 73.291 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '93'
$!AttachText AnchorPos { X = 53.756152 Y = 84.445 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '94'
$!AttachText AnchorPos { X = 56.62 Y = 49.15 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 10 IsBold = No } Color = CUSTOM7 Text = '130'
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/detalle_raices.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/detalle_raices.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/detalle_raices.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/detalle_raices.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 2100
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/detalle_raices.png'
$!Export ExportRegion = CurrentFrame
